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

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
