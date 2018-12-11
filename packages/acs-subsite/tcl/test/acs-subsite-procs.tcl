ad_library {
    Automated tests.

    @author Joel Aufrecht
    @creation-date 2 Nov 2003
    @cvs-id $Id$
}

aa_register_case \
    -bugs {775} \
    -procs {
        group::delete
        group::new
        permission::grant
        rel_segments_new
        relation_add
    } \
    acs_subsite_expose_bug_775 {
    Exposes Bug 775.

    @author Don Baccus
} {

    aa_run_with_teardown \
        -rollback \
        -test_code {

        set group_id [group::new -group_name group_775]
        set rel_id [rel_segments_new $group_id membership_rel segment_775]
        relation_add membership_rel $group_id 0
        permission::grant -object_id $group_id -party_id 0 -privilege read

        if { [catch {group::delete $group_id} errmsg] } {
            aa_error "Delete of group \"group_775\" failed."
        } else {
            aa_true "Delete of group \"group_775\" succeeded." 1
        }
    }

}

aa_register_case \
    -bugs {1144} \
    -procs {
        acs_user::delete
        application_group::group_id_from_package_id
        auth::create_user
        group::add_member
    } \
    acs_subsite_expose_bug_1144 {
    Exposes Bug 1144.

    @author Peter Marklund
} {

    aa_run_with_teardown \
        -rollback \
        -test_code {

            array set main_node [site_node::get_from_url -url "/"]
            set main_group_id [application_group::group_id_from_package_id \
                              -package_id $main_node(package_id)]
            
            set email "__test@test.test"
            array set creation_info [auth::create_user \
                                     -username "__test" \
                                     -email $email \
                                     -first_names "__Test first" \
                                     -last_name "__Test last" \
                                     -password 1 \
                                     -password_confirm 1]
     
            group::add_member \
                -group_id $main_group_id \
                -user_id $creation_info(user_id) \
                -rel_type admin_rel

            set cc_users_count [db_string count_cc_users {
                select count(*)
                from cc_users
                where email = :email
            }]
            aa_equals "New user occurs only once in cc_users" $cc_users_count 1

            set registered_users_count [db_string count_registered_users {
                select count(*)
                from registered_users
                where email = :email
            }]
            aa_equals "New user occurs only once in registered_users" $registered_users_count 1
            acs_user::delete -user_id $creation_info(user_id)
        }
}

aa_register_case \
    -cats smoke \
    -procs {subsite::main_site_id} \
    acs_subsite_trivial_smoke_test {
    Minimal smoke test.
} {    

    aa_run_with_teardown \
        -rollback \
        -test_code {
            # initialize random values
            set name [ad_generate_random_string]
            set main_subsite_id [subsite::main_site_id]
            aa_true "Main subsite exists" {$main_subsite_id ne ""}
        }
}

aa_register_case \
    -cats smoke \
    acs_subsite_unregistered_visitor {
    Test that unregistered visitor is not in any groups
} {

    aa_equals "Unregistered vistior is not in any groups except The Public" \
        [db_string count_rels {
	    select count(*)
	    from group_member_map g, acs_magic_objects a
	    where g.member_id = 0
	      and g.group_id <> a.object_id
              and a.name = 'the_public'} -default 0] 0
}


aa_register_case \
    -cats smoke \
    -procs {
        acs_user::get_by_username_not_cached
        auth::authority::local
        auth::create_user
        group::add_member
        group::new
        relation_add
        util_memoize_flush
    } acs_subsite_check_composite_group {
    Build a 3-level hierarchy of composite groups and check memberships. This test case covers the membership and composition rel insertion triggers and composability of basic membership and admin rels.

    @author Michael Steigman
} {

    aa_run_with_teardown \
        -rollback \
        -test_code {

            # create groups and relate them to one another
            set level_1_group [group::new -group_name "Level 1 Group"]
            set level_2_group [group::new -group_name "Level 2 Group"]
            relation_add composition_rel $level_1_group $level_2_group

            set authority_id [auth::authority::local]

            # flush cache from previous call of this test
            util_memoize_flush [list acs_user::get_by_username_not_cached \
                                    -authority_id $authority_id \
                                     -username "__test1"]
            
            if {[set user_1_id [acs_user::get_by_username_not_cached \
                                    -authority_id $authority_id \
                                    -username "__test1"]] eq ""} {
                array set user_1 [auth::create_user \
                                      -username "__test1" \
                                      -email "__user1@test.test" \
                                      -first_names "__user1.Test first" \
                                      -last_name "__user1.Test last" \
                                      -password 1 \
                                      -password_confirm 1]
                set user_1_id $user_1(user_id)
            }

            # flush cache from previous call of this test
            util_memoize_flush [list acs_user::get_by_username_not_cached \
                                    -authority_id $authority_id \
                                     -username "__test2"]            

            if {[set user_2_id [acs_user::get_by_username_not_cached \
                                    -authority_id $authority_id \
                                    -username "__test2"]] eq ""} {                
                array set user_2 [auth::create_user \
                                      -username "__test2" \
                                      -email "__user2@test.test" \
                                      -first_names "__user2.Test first" \
                                      -last_name "__user2.Test last" \
                                      -password 1 \
                                      -password_confirm 1]                    
                set user_2_id $user_2(user_id)
            }
            
            group::add_member -group_id $level_2_group -user_id $user_1_id -rel_type membership_rel
            group::add_member -group_id $level_2_group -user_id $user_1_id -rel_type admin_rel

            # check that user_1 is a member of level_1_group but not admin
            aa_true "User 1 is a member of Level 1 Group" [db_0or1row member_p {
                SELECT 1
                FROM group_member_map
                WHERE group_id = :level_1_group
                AND member_id = :user_1_id
                AND rel_type = 'membership_rel'
            }]

            aa_false "User 1 is not an admin of Level 1 Group" [db_0or1row member_p {
                SELECT 1
                FROM group_member_map
                WHERE group_id = :level_1_group
                AND member_id = :user_1_id
                AND rel_type = 'admin_rel'
            }]
            # create new group then relate it to level_2_group
            set level_3_group [group::new -group_name "Level 3 Group"]
            group::add_member -group_id $level_3_group -user_id $user_2_id -rel_type membership_rel
            group::add_member -group_id $level_3_group -user_id $user_2_id -rel_type admin_rel
            relation_add composition_rel $level_2_group $level_3_group

            # check that user_2 is a member of level_1_group but not admin
            aa_true "User 2 is a member of Level 1 Group" [db_0or1row member_p {
                SELECT 1
                FROM group_member_map
                WHERE group_id = :level_1_group
                AND member_id = :user_2_id
                AND rel_type = 'membership_rel'
            }]

            aa_false "User 2 is not an admin of Level 1 Group" [db_0or1row member_p {
                SELECT 1
                FROM group_member_map
                WHERE group_id = :level_1_group
                AND member_id = :user_2_id
                AND rel_type = 'admin_rel'
            }]

        }
}

aa_register_case \
    -cats smoke \
    -procs {
        group_type::new
        acs_object_type::get
        group::new
        group::get
        group_type::delete
        _
    } acs_subsite_group_type {
        Create a new group type, create a new instance of it, check
        that everything was created according to expectations and
        cleanup at the end.

        @author Antonio Pisano
    } {
        set group_type "aa_test_group_type"

        try {
            # Make sure the group type does not exist
            group_type::delete -group_type $group_type

            # Create the group type
            set pretty_name "Test Group"
            set pretty_plural "Test Groups"
            set returned_group_type [group_type::new \
                                         -group_type $group_type \
                                         -supertype "group" \
                                         $pretty_name $pretty_plural]
            aa_true "Function returns the expected value (the group type)" \
                {$group_type eq $returned_group_type}

            # Test group type info
            acs_object_type::get -object_type $group_type -array type
            aa_true "Group type is an ACS Object created with expected values" \
                {$pretty_name eq $type(pretty_name) && $pretty_plural eq $type(pretty_plural)}

            # Create a group type instance
            set group_name "${group_type}_instance_1"
            set pretty_name "${pretty_name} Instance 1"
            set group_id [group::new \
                              -group_name  $group_name \
                              -pretty_name $pretty_name \
                              $group_type]

            # Test group info
            set group [group::get -group_id $group_id]
            set expected_group_name  [dict get $group group_name]
            # Pretty name is stored in an automatically generated message key
            set expected_pretty_name [_ [string trim [dict get $group title] "#"]]
            aa_true "Group was created with supplied values: $group_name eq $expected_group_name && $pretty_name eq $expected_pretty_name" \
                {$group_name eq $expected_group_name && $pretty_name eq $expected_pretty_name}

        } finally {
            # Cleanup
            group_type::delete -group_type $group_type
        }
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
