ad_library {

    Automated tests for procs in tcl/authentication-procs.tcl

}

aa_register_case \
    -cats {api} \
    -procs {
        auth::can_admin_system_without_authority_p
    } \
    auth__can_admin_system_without_authority_p {
        Test auth::can_admin_system_without_authority_p
    } {
        aa_run_with_teardown \
            -rollback \
            -test_code {

                set authorities [db_list get_authorities {
                    select authority_id from auth_authorities
                }]

                # First make sure that proc returns the expected value
                # in any setup...
                foreach authority_id $authorities {
                    set expected [db_0or1row admins_left_p {
                        select 1 from dual where exists
                        (
                          select 1
                          from acs_permissions p,
                             party_approved_member_map m,
                             acs_magic_objects amo,
                             cc_users u
                          where amo.name = 'security_context_root'
                          and p.object_id = amo.object_id
                          and p.grantee_id = m.party_id
                          and u.user_id = m.member_id
                          and u.member_state = 'approved'
                          and u.authority_id <> :authority_id
                          and acs_permission.permission_p(amo.object_id, u.user_id, 'admin')
                        )
                    }]
                    aa_equals "Proc should return $expected for authority $authority_id" \
                        $expected [auth::can_admin_system_without_authority_p \
                                       -authority_id $authority_id]
                }

                # Now revoke SWA permissions to everybody and create a
                # single SWA in the test authority. The expected
                # result is that the proc should return true for any
                # authority except the test one, as it is the only one
                # with an admin.
                aa_log "Revoking all SWA privileges"
                foreach user_id [db_list get_swas {
                    select u.user_id
                    from acs_permissions p,
                    party_approved_member_map m,
                    acs_magic_objects amo,
                    cc_users u
                    where amo.name = 'security_context_root'
                    and p.object_id = amo.object_id
                    and p.grantee_id = m.party_id
                    and u.user_id = m.member_id
                    and u.member_state = 'approved'
                    and acs_permission.permission_p(amo.object_id, u.user_id, 'admin')
                }] {
                    permission::revoke \
                        -party_id $user_id \
                        -object_id [acs_magic_object security_context_root] \
                        -privilege "admin"
                }

                foreach authority_id $authorities {
                    aa_equals "Proc should return 0 for authority $authority_id, as no admins are left" \
                        0 [auth::can_admin_system_without_authority_p \
                               -authority_id $authority_id]
                }

                aa_log "Creating a new SWA in the test authority"
                set test_authority_id [auth::authority::get_id -short_name "acs_testing"]
                set result [acs::test::user::create]
                set user_id [dict get $result user_id]
                permission::grant \
                    -party_id $user_id \
                    -object_id [acs_magic_object security_context_root] \
                    -privilege "admin"

                foreach authority_id $authorities {
                    set expected [expr {$authority_id != $test_authority_id}]
                    aa_equals "Proc should return $expected for authority $authority_id" \
                        $expected \
                        [auth::can_admin_system_without_authority_p \
                             -authority_id $authority_id]
                }

            }
    }

aa_register_case \
    -cats {api} \
    -procs {
        auth::delete_local_account
        acs_user::registered_user_p
        auth::get_local_account_status
    } \
    auth__delete_local_account  {
        Test mainly auth::delete_local_account and
        auth::get_local_account_status
    } {
        aa_run_with_teardown \
            -rollback \
            -test_code {
                set authority_id [auth::authority::get_id -short_name "acs_testing"]
                set result [acs::test::user::create]
                set user_id [dict get $result user_id]
                set username [dict get $result username]

                set account_status [auth::get_local_account_status -user_id $user_id]
                aa_equals "User '$username' should have local status 'ok'" ok $account_status

                set registered_p [acs_user::registered_user_p -user_id $user_id]
                aa_true "User '$username' is currently approved" $registered_p

                aa_log "Calling auth::delete_local_account on the user"
                set r [auth::delete_local_account \
                           -authority_id $authority_id \
                           -username $username]

                set registered_p [acs_user::registered_user_p -user_id $user_id]
                aa_false "User '$username' is not approved anymore" $registered_p
                aa_true "User '$username' still exists" [db_0or1row get_user {
                    select 1 from users where user_id = :user_id
                }]
                set account_status [auth::get_local_account_status -user_id $user_id]
                aa_equals "User '$username' should have local status 'closed'" closed $account_status

                set not_a_user [acs_magic_object security_context_root]
                set account_status [auth::get_local_account_status -user_id $not_a_user]
                aa_equals "Object '$not_a_user' is not an account" no_account $account_status

                aa_true "Proc returns 'delete_status'" [dict exists $r delete_status]
                aa_true "Proc returns 'delete_message'" [dict exists $r delete_status]
            }
    }

aa_register_case \
    -cats {api} \
    -procs {
        auth::get_all_registration_elements
    } \
    authority__get_sc_impl_columns {
        Test auth::get_all_registration_elements
    } {
        aa_equals "Proc returns the expected result with flag 'include_password_confirm' set" \
            [lsort [auth::get_all_registration_elements -include_password_confirm]] [lsort {
                email username first_names last_name password
                password_confirm screen_name url
                secret_question secret_answer
            }]
        aa_equals "Proc returns the expected result with flag 'include_password_confirm' NOT set" \
            [lsort [auth::get_all_registration_elements]] [lsort {
                email username first_names last_name password
                screen_name url secret_question secret_answer
            }]
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
