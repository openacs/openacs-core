ad_library {

    Test for Permission Procedures

    @author Cesar Hernandez (cesarhj@galileo.edu)
    @creation-date 2006-07-14
    @cvs-id $Id$
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        permission::grant
        permission::permission_p
        permission::revoke
        site_node::instantiate_and_mount
        db_nextval
        acs::test::user::create
    } \
    ad_proc_permission_grant_and_revoke {

    Test for permission procedures of grant and revoke.

} {
    aa_run_with_teardown -rollback -test_code {
        # We get a user_id as party_id.
        set user_id [db_nextval acs_object_id_seq]

        # Create the user
        set user_info [acs::test::user::create -user_id $user_id]

        # Create and mount new subsite to test the permissions on this
        # instance.
        set site_name [ad_generate_random_string]
        set new_package_id [site_node::instantiate_and_mount \
                                -node_name $site_name \
                                -package_key acs-subsite]
        # Grant privileges of admin,read,write and create, after check
        # this ones, after revoke this ones.

        # Grant admin privilege
        permission::grant -party_id $user_id -object_id $new_package_id -privilege "admin"
        # Verifying the admin privilege on the user
        aa_true "testing admin privilege" \
            [permission::permission_p -party_id $user_id -object_id $new_package_id -privilege "admin"]
        # Revoking admin privilege
        permission::revoke -party_id $user_id -object_id $new_package_id -privilege "admin"
        aa_false "testing if admin privilege was revoked" \
            [permission::permission_p -party_id $user_id -object_id $new_package_id -privilege "admin"]

        # Grant read privilege
        permission::grant -party_id $user_id -object_id $new_package_id -privilege "read"
        # Verifying  the read privilege on the user
        aa_true "testing read permissions" \
            [permission::permission_p -party_id $user_id -object_id $new_package_id -privilege "read"]
        # Revoking read privilege
        permission::revoke -party_id $user_id -object_id $new_package_id -privilege "read"
        # We tested with a query because we have problems with inherit
        aa_false "testing if read privilege was revoked" \
            [db_string test_read {
                select 1 from acs_permissions
                where object_id = :new_package_id and grantee_id = :user_id
            } -default 0]

        # Grant write privilege
        permission::grant -party_id $user_id -object_id $new_package_id -privilege "write"
        # Verifying the write privilege  on the user
        aa_true "testing write permissions" \
            [permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "write"]
        # Revoking write privilege
        permission::revoke -party_id $user_id -object_id $new_package_id -privilege "write"
        aa_false "testing if write permissions was revoked" \
            [permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "write"]

        # Grant create privilege
        permission::grant -party_id $user_id -object_id $new_package_id -privilege "create"
        # Verifying the create privilege  on the user
        aa_true "testing create permissions" \
            [permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "create"]
        # Revoking create privilege
        permission::revoke -party_id $user_id -object_id $new_package_id -privilege "create"
        aa_false "testing if create privileges was revoked" \
            [permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "create"]

        # Grant delete privilege
        permission::grant -party_id $user_id -object_id $new_package_id -privilege "delete"
        # Verifying the delete privilege on the user
        aa_true "testing delete permissions" \
            [permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "delete"]
        # Revoking delete privilege
        permission::revoke -party_id $user_id -object_id $new_package_id -privilege "delete"
        aa_false "testing if delete permissions was revoked" \
            [permission::permission_p -party_id $user_id  -object_id  $new_package_id -privilege "delete"]
    }
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        permission::grant
        permission::permission_p
        permission::revoke
        site_node::instantiate_and_mount
        db_nextval
        acs::test::user::create

        db_1row
    } \
    ad_proc_permission_permission_p {

    Test for Permission Procedures of permission_p

} {
    aa_run_with_teardown -rollback -test_code {
        # We get a user_id as party_id.
        set user_id [db_nextval acs_object_id_seq]

        # Create the user
        set user_info [acs::test::user::create -user_id $user_id]

        # Create and mount new subsite to test the permissions on this
        # instance
        set site_name [ad_generate_random_string]
        set new_package_id [site_node::instantiate_and_mount \
                                -node_name $site_name \
                                -package_key acs-subsite]
        #Grant permissions for this user in this object
        permission::grant -party_id $user_id -object_id $new_package_id -privilege "delete"
        aa_true "testing admin permissions" \
            [permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "delete"]
        permission::revoke -party_id $user_id -object_id $new_package_id -privilege "delete"

        permission::grant -party_id $user_id -object_id $new_package_id -privilege "create"
        aa_true "testing create permissions" \
            [permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "create"]
        permission::revoke -party_id $user_id -object_id $new_package_id -privilege "create"

        permission::grant -party_id $user_id -object_id $new_package_id -privilege "write"
        aa_true "testing write permissions" \
            [permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "write"]
        permission::revoke -party_id $user_id -object_id $new_package_id -privilege "write"

        permission::grant -party_id $user_id -object_id $new_package_id -privilege "read"
        aa_true "testing read permissions" \
            [db_string test_read {
                select 1 from acs_permissions
                where object_id = :new_package_id and grantee_id = :user_id
            } -default 0]
        permission::revoke -party_id $user_id -object_id $new_package_id -privilege "read"

        permission::grant -party_id $user_id -object_id $new_package_id -privilege "admin"
        aa_true "testing delete permissions" \
            [permission::permission_p -party_id $user_id -object_id  $new_package_id -privilege "admin"]
        permission::revoke -party_id $user_id -object_id $new_package_id -privilege "admin"

    }
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        permission::inherit_p
        permission::set_inherit
        permission::set_not_inherit
        permission::toggle_inherit
        permission::get_parties_with_permission
        permission::permission_p
        permission::grant
        site_node::instantiate_and_mount
        application_group::group_id_from_package_id
        group::add_member
    } ad_proc_permission_inheritance_and_groups {

        Test "advanced" permission use cases: inheritance via
        permission context and group permissions.

        @author Antonio Pisano <antonio@elettrotecnica.it>

    } {
        #
        # Create a couple of test users
        #
        for {set i 1} {$i <= 4} {incr i} {
            set user_$i [dict get [acs::test::user::create] user_id]
        }

        aa_run_with_teardown -rollback -test_code {
            #
            # To test permissions on some object, we create 2
            # subsites. The second subsite inherits the permission
            # context from the first.
            #
            set test_subsite_1 [site_node::instantiate_and_mount \
                                    -node_name test-subsite-[db_nextval acs_object_id_seq] \
                                    -package_key acs-subsite]
            set test_subsite_2 [site_node::instantiate_and_mount \
                                    -node_name test-subsite-[db_nextval acs_object_id_seq] \
                                    -package_key acs-subsite \
                                    -context_id $test_subsite_1]

            #
            # One advantage of using subsites to test is that they
            # come with their own application group for free.
            #
            set test_group_1 [application_group::group_id_from_package_id \
                                  -package_id $test_subsite_1]
            set test_group_2 [application_group::group_id_from_package_id \
                                  -package_id $test_subsite_2]

            #
            # Split the test users in the two application groups.
            #
            group::add_member \
                -no_perm_check \
                -group_id $test_group_1 \
                -user_id $user_1
            group::add_member \
                -no_perm_check \
                -group_id $test_group_1 \
                -user_id $user_2

            group::add_member \
                -no_perm_check \
                -group_id $test_group_2 \
                -user_id $user_3
            group::add_member \
                -no_perm_check \
                -group_id $test_group_2 \
                -user_id $user_4

            #
            # Grant admin privilege for users of group 1 in the first subsite.
            #
            permission::grant -party_id $test_group_1 -object_id $test_subsite_1 -privilege "admin"

            #
            # Grant admin privilege for user_4 in the second subsite.
            #
            permission::grant -party_id $user_4 -object_id $test_subsite_2 -privilege "admin"

            #
            # Do a roundtrip on the inheritance settings api
            #
            aa_section "Check inheritance API"

            aa_true "Default inherit status is true" \
                [permission::inherit_p -object_id $test_subsite_2]

            permission::toggle_inherit -object_id $test_subsite_2
            aa_false "Inheritance off" \
                [permission::inherit_p -object_id $test_subsite_2]

            permission::toggle_inherit -object_id $test_subsite_2
            aa_true "Inheritance on" \
                [permission::inherit_p -object_id $test_subsite_2]

            #
            # We do this twice to check for consistency
            #
            permission::set_not_inherit -object_id $test_subsite_2
            aa_false "Inheritance off" \
                [permission::inherit_p -object_id $test_subsite_2]
            permission::set_not_inherit -object_id $test_subsite_2
            aa_false "Inheritance off" \
                [permission::inherit_p -object_id $test_subsite_2]

            #
            # We do this twice to check for consistency
            #
            permission::set_inherit -object_id $test_subsite_2
            aa_true "Inheritance on" \
                [permission::inherit_p -object_id $test_subsite_2]
            permission::set_inherit -object_id $test_subsite_2
            aa_true "Inheritance on" \
                [permission::inherit_p -object_id $test_subsite_2]

            #
            # Now verify permissions in various inheritance settings
            #

            aa_section "Inheritance ON"

            for {set i 1} {$i <= 2} {incr i} {
                set user_id [set user_$i]
                aa_true "User '$user_id' from group 1, is an admin of subsite 2" \
                    [permission::permission_p -party_id $user_id -object_id $test_subsite_2 -privilege "admin"]
            }
            for {set i 3} {$i <= 4} {incr i} {
                set user_id [set user_$i]
                aa_false "User '$user_id' from group 2, is NOT an admin of subsite 1" \
                    [permission::permission_p -party_id $user_id -object_id $test_subsite_1 -privilege "admin"]
            }
            aa_true "User 4 has admin privilege on subsite 2" \
                [permission::permission_p -party_id $user_4 -object_id $test_subsite_2 -privilege "admin"]
            aa_true "Group 1 has admin privilege on subsite 2" \
                [permission::permission_p -party_id $test_group_1 -object_id $test_subsite_2 -privilege "admin"]

            set parties_with_permissions [list]
            foreach entry [permission::get_parties_with_permission \
                               -object_id $test_subsite_2 \
                               -privilege admin] {
                lassign $entry party_name party_id
                lappend parties_with_permissions $party_id
            }
            foreach party_id [list $test_group_1 $user_1 $user_2 $user_4] {
                aa_true "'$party_id' belongs to the parties with admin privileges '$parties_with_permissions'" \
                    {$party_id in $parties_with_permissions}
            }
            foreach party_id [list $test_group_2 $user_3] {
                aa_true "'$party_id' does NOT belong to the parties with admin privileges '$parties_with_permissions'" \
                    {$party_id ni $parties_with_permissions}
            }

            aa_section "Inheritance OFF"

            permission::toggle_inherit -object_id $test_subsite_2

            for {set i 1} {$i <= 2} {incr i} {
                set user_id [set user_$i]
                aa_false "User '$user_id' from group 1, is NOT an admin of subsite 2" \
                    [permission::permission_p -party_id $user_id -object_id $test_subsite_2 -privilege "admin"]
            }
            for {set i 3} {$i <= 4} {incr i} {
                set user_id [set user_$i]
                aa_false "User '$user_id' from group 2, is NOT an admin of subsite 1" \
                    [permission::permission_p -party_id $user_id -object_id $test_subsite_1 -privilege "admin"]
            }
            aa_true "User 4 has admin privilege on subsite 2" \
                [permission::permission_p -party_id $user_4 -object_id $test_subsite_2 -privilege "admin"]
            aa_false "Group 1 has NO admin privilege on subsite 2" \
                [permission::permission_p -party_id $test_group_1 -object_id $test_subsite_2 -privilege "admin"]

            set parties_with_permissions [list]
            foreach entry [permission::get_parties_with_permission \
                               -object_id $test_subsite_2 \
                               -privilege admin] {
                lassign $entry party_name party_id
                lappend parties_with_permissions $party_id
            }
            foreach party_id [list $user_4] {
                aa_true "'$party_id' belongs to the parties with admin privileges '$parties_with_permissions'" \
                    {$party_id in $parties_with_permissions}
            }
            foreach party_id [list $test_group_1 $test_group_2 $user_1 $user_2 $user_3] {
                aa_true "'$party_id' does NOT belong to the parties with admin privileges '$parties_with_permissions'" \
                    {$party_id ni $parties_with_permissions}
            }


        } -teardown_code {
            for {set i 1} {$i <= 4} {incr i} {
                set user_id [set user_$i]
                acs::test::user::delete \
                    -user_id $user_id \
                    -delete_created_acs_objects
            }
        }
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
