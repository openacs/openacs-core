ad_library {
    Automated tests.

    @author Joel Aufrecht
    @creation-date 2 Nov 2003
    @cvs-id $Id$
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

            aa_true "Main subsite exists" [exists_and_not_null main_subsite_id]

        }
}