ad_library {
    Automated tests.

    @author Joel Aufrecht
    @creation-date 2 Nov 2003
    @cvs-id $Id$
}

aa_register_case acs_subsite_expose_bug_775 {
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

aa_register_case acs_subsite_expose_bug_1144 {
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

aa_register_case -cats smoke acs_subsite_trivial_smoke_test {
    Minimal smoke test.
} {    

    aa_run_with_teardown \
        -rollback \
        -test_code {
            # initialize random values
            set name [ad_generate_random_string]

            set main_subsite_id [subsite::main_site_id]

            aa_true "Main subsite exists" [expr {$main_subsite_id ne ""}]

        }
}

aa_register_case -cats smoke acs_subsite_unregistered_visitor {
    Test that unregistered visitor is not in any groups
} {

    aa_equals "Unregistered vistior is not in any groups except The Public" \
        [db_string count_rels "
	    select count(*)
	    from group_member_map g, acs_magic_objects a
	    where g.member_id = 0
	      and g.group_id <> a.object_id
	      and a.name = 'the_pubic'" -default 0] 0
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
