ad_library {
    Automated tests.

    @author Joel Aufrecht
    @creation-date 2 Nov 2003
    @cvs-id $Id$
}

aa_register_case \
    group_localization_leftovers {
        Checks that no leftover group title localizations can be
        found belonging to groups that do not exist anymore.
    } {
        aa_false "Leftover group localization message keys do not exist in the database" [db_string leftovers_exist {
            select case when exists (select 1 from lang_message_keys k
                                     where package_key = 'acs-translations'
                                     and message_key like 'group_title_%'
                                     and not exists (select 1 from groups
                                                     where group_id = cast(split_part(k.message_key, '_', 3) as integer)))
            then 1 else 0 end
            from dual
        }]
    }

aa_register_case \
    -procs {
        _
        group::delete
        group::new
        lang::message::unregister
        lang::util::convert_to_i18n

        util_memoize_flush_pattern
    } \
    group_localization {
        Create a group and check that the automagical localization
        cleans after itself once it has been deleted.
    } {
        set group_name [ad_generate_random_string]

        aa_log "Creating group '$group_name'"
        set group_id [group::new -group_name $group_name]
        set package_key acs-translations
        set message_key "group_title_${group_id}"

        aa_true "Message key was registered correctly" [db_string get_key {
            select case when exists (select 1 from lang_message_keys
                                     where package_key = :package_key
                                     and message_key = :message_key)
            then 1 else 0 end
            from dual
        }]

        aa_equals "Pretty group name was stored correctly" $group_name [_ ${package_key}.$message_key]

        aa_log "Deleting group"
        group::delete $group_id

        aa_false "Message key was deleted correctly" [db_string get_key {
            select case when exists (select 1 from lang_message_keys
                                     where package_key = :package_key
                                     and message_key = :message_key)
            then 1 else 0 end
            from dual
        }]

        aa_false "Message key has been flushed from all possible caches" {$group_name eq [_ ${package_key}.$message_key]}

        set new_value [ad_generate_random_string]
        set pretty_name [lang::util::convert_to_i18n \
                             -message_key $message_key \
                             -text $new_value]

        aa_equals "One can override the previously existing message key safely" $new_value [_ ${package_key}.$message_key]

        aa_log "Cleaning up"
        lang::message::unregister $package_key $message_key
    }

aa_register_case \
    -bugs {775} \
    -procs {
        aa_error
        group::delete
        group::new
        permission::grant
        rel_segment::new
        relation_add

        util_memoize_flush_pattern
    } \
    acs_subsite_expose_bug_775 {
    Exposes Bug 775.

    @author Don Baccus
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {

        set group_id [group::new -group_name group_775]
        set rel_id [rel_segment::new $group_id membership_rel segment_775]
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
        acs::test::user::create
        acs_user::delete
        application_group::group_id_from_package_id
        auth::set_email_verified
        group::add_member
        site_node::get_from_url
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

            set user_info [acs::test::user::create]
            set user_id [dict get $user_info user_id]
            set email   [string tolower [dict get $user_info email]]

            # Make sure email is verified. The real process of
            # verifying is tested elsewhere.
            auth::set_email_verified -user_id $user_id

            group::add_member \
                -group_id $main_group_id \
                -user_id $user_id \
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
            acs_user::delete -user_id $user_id
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
             from group_member_map g,
                  acs_magic_objects a
            where g.member_id = 0
              and g.group_id <> a.object_id
              and a.name = 'the_public'} -default 0] 0
}


aa_register_case \
    -cats smoke \
    -procs {
        acs::test::user::create
        group::add_member
        group::admin_p
        group::member_p
        group::new
        relation_add

        util_memoize_flush_pattern
    } acs_subsite_check_composite_group {

        Build a 3-level hierarchy of composite groups and check
        memberships. This test case covers the membership and composition
        rel insertion triggers and composability of basic membership and
        admin rels.

    @author Michael Steigman
} {

    aa_run_with_teardown \
        -rollback \
        -test_code {

            # create groups and relate them to one another
            set level_1_group [group::new -group_name "Level 1 Group"]
            set level_2_group [group::new -group_name "Level 2 Group"]
            relation_add composition_rel $level_1_group $level_2_group

            set user_info_1 [acs::test::user::create]
            set user_1_id [dict get $user_info_1 user_id]

            set user_info_2 [acs::test::user::create]
            set user_2_id [dict get $user_info_2 user_id]

            group::add_member -group_id $level_2_group -user_id $user_1_id -rel_type membership_rel
            group::add_member -group_id $level_2_group -user_id $user_1_id -rel_type admin_rel

            # check that user_1 is a direct member of level_2_group via the tcl api
            aa_true "User 1 is a direct member of Level 2 Group" [group::member_p -user_id $user_1_id -group_id $level_2_group]
            aa_true "User 1 is an admin of Level 2 Group" [group::admin_p -group_id $level_2_group -user_id $user_1_id]

            # check that user_1 is a indirect member of level_1_group via the tcl api
            aa_true "User 1 is an indirect member of Level 1 Group" [group::member_p -user_id $user_1_id -group_id $level_1_group -cascade]

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
        group::get_id
        group::title
        group::description
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

            set api_group_id [group::get_id -group_name $group_name]
            aa_equals "group::get_id -group_name $group_name returns the same id as that from group::new" \
                $group_id $api_group_id
            aa_true "group::get_id -group_name $group_name returns a valid object_id" [db_0or1row check {
                select 1 from acs_objects where object_id = :api_group_id
            }]

            # Test group info
            set group [group::get -group_id $group_id]
            set expected_group_name  [dict get $group group_name]
            # Pretty name is stored in an automatically generated message key
            set expected_pretty_name [_ [string trim [dict get $group title] "#"]]
            aa_true "Group was created with supplied values: $group_name eq $expected_group_name && $pretty_name eq $expected_pretty_name" \
                {$group_name eq $expected_group_name && $pretty_name eq $expected_pretty_name}

            aa_equals "group::description returns the expected value" \
                [group::description -group_id $group_id] \
                [db_string description {select description from groups where group_id = :group_id}]
            aa_equals "group::title returns the expected value" \
                [group::title -group_id $group_id] \
                [db_string title {select title from acs_objects where object_id = :group_id}]

        } finally {
            # Cleanup
            group_type::delete -group_type $group_type
        }
    }

aa_register_case \
    -cats smoke \
    -urls {
        /register/email-confirm
    } \
    -procs {
        parameter::get
        subsite::main_site_id
        acs_user::get_user_info
        auth::get_user_secret_token
        party::get
        export_vars
        acs_user::delete
        acs::test::confirm_email
        acs::test::user::create
    } acs_subsite_test_email_confirmation {
        Calls the mail confirmation page with a new user and checks
        that result is as expected

        @author Antonio Pisano
    } {
        try {
            # Create dummy user
            set user [acs::test::user::create]
            set user_id [dict get $user user_id]

            # Check if email verification status fits instance
            # configuration
            if {[parameter::get \
                     -package_id [subsite::main_site_id] \
                     -parameter RegistrationRequiresEmailVerificationP -default 0]} {
                aa_false "Email is NOT verified" [acs_user::get_user_info \
                                                      -user_id $user_id -element email_verified_p]
            } else {
                aa_log "Main subsite does not require email verification"
            }

            ::acs::test::confirm_email -user_id $user_id

            # Check that email is verified after confirmation
            aa_true "Email is verified" [acs_user::get_user_info \
                                             -user_id $user_id -element email_verified_p]
        } finally {
            # Delete the user
            if {[info exists user_id] && [string is integer -strict $user_id]} {
                acs_user::delete -user_id $user_id -permanent
            }
        }
    }

aa_register_case -cats {
    api
    smoke
} -procs {
    attribute::add
    attribute::exists_p
    attribute::delete
    attribute::value_add
    attribute::value_delete
    ad_page_contract_filter_proc_attribute_dynamic_p

    db_column_exists
} acs_subsite_attributes {
    Test different attribute procs

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 26 February 2021
} {
    aa_run_with_teardown -rollback -test_code {
        #
        # Create new dynamic object_type
        #
        set pretty_name "foo_type"
        set object_type $pretty_name
        set name_method "${object_type}.name"
        if {[db_name] eq "PostgreSQL"} {
            set type_create_sql "select acs_object_type__create_type (
                                          :object_type,
                                          :pretty_name,
                                          :pretty_name,
                                          'acs_object',
                                          null,
                                          null,
                                          null,
                                          'f',
                                          null,
                                          :name_method,
                                          't',
                                          't');"
        } else {
            # oracle
            set type_create_sql "begin
                acs_object_type.create_type (
                        object_type => :object_type,
                        pretty_name => :pretty_name,
                        pretty_plural => :pretty_name,
                        supertype => 'acs_object',
                        abstract_p => 'f',
                        name_method => :name_method,
                        create_table_p => 't',
                        dynamic_p => 't');
                end;"
        }
        aa_log "Create object_type: $object_type"
        db_exec_plsql type_create $type_create_sql
        #
        # Create new attribute
        #
        set attribute_name "foo"
        set attribute_name_plural "foos"
        set attribute_type "text"
        set min_n_values 1
        set max_n_values 1
        set default_value "fooooo"
        aa_log "Add new attribute $attribute_name to object_type: $object_type"
        set attribute_id [attribute::add -min_n_values $min_n_values \
                                         -max_n_values $max_n_values \
                                         -default $default_value \
                                         $object_type \
                                         $attribute_type \
                                         $attribute_name \
                                         $attribute_name_plural]
        aa_true "New attribute exists" \
            [attribute::exists_p $object_type $attribute_name]
        #
        # Add value to attribute
        #
        set enum_value "enum_foo"
        set sort_order "1"
        attribute::value_add $attribute_id $enum_value $sort_order
        set value_exists_p [db_0or1row value {
            select 1
              from acs_enum_values
             where attribute_id=:attribute_id
               and enum_value=:enum_value
        }]
        aa_true "Value added to attribute" "$value_exists_p"

        dict set cases attribute_dynamic_p [list $attribute_id 1 1 0]
        foreach filter [dict keys $cases] {
            foreach { value result } [dict get $cases $filter] {
                if { $result } {
                    aa_true "'[ns_quotehtml $value]' is $filter" \
                        [ad_page_contract_filter_invoke $filter dummy value]
                } else {
                    aa_false "'[ns_quotehtml $value]' is NOT $filter" \
                        [ad_page_contract_filter_invoke $filter dummy value]
                }
            }
        }
        #
        # Delete value from attribute
        #
        attribute::value_delete $attribute_id $enum_value
        set value_exists_p [db_0or1row value {
            select 1
              from acs_enum_values
             where attribute_id=:attribute_id
               and enum_value=:enum_value
        }]
        aa_false "Value exists after deletion" "$value_exists_p"
        #
        # Delete attribute
        #
        attribute::delete $attribute_id
        aa_false "Attribute exists after deletion" \
            [attribute::exists_p $object_type $attribute_name]
    }
}

aa_register_case -cats {
    api
    production_safe
} -procs {
    attribute::translate_datatype
    attribute::datatype_validator_exists_p
} acs_subsite_attribute_datatypes {
    Test different attribute datatype procs

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 01 March 2021
} {
    #
    # Datatype validators
    #
    set datatype_validator {
        boolean boolean
        keyword keyword
        integer integer
          money integer
         string string
           text text
            foo text
    }
    dict for {datatype validator} $datatype_validator {
        aa_equals "Datatype $datatype" \
            [attribute::translate_datatype $datatype] "$validator"
    }
    #
    # Explicit validator exists for datatype?
    #
    set datatype_validator_p {
        enumeration 1
            boolean 1
            keyword 1
            integer 1
             string 1
              money 0
               date 0
               text 1
                foo 0
    }
    dict for {datatype validator_p} $datatype_validator_p {
        aa_equals "Datatype $datatype validator exists" \
            [attribute::datatype_validator_exists_p $datatype] "$validator_p"
    }

}

aa_register_case -cats {
    api
    smoke
} -procs {
    relation_add
    relation_remove
    relation::get_object_one
    relation::get_object_two
    relation::get_objects
    relation::get_id
} acs_subsite_relation_procs {
    Test different relation procs

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 24 June 2021
} {
    aa_run_with_teardown -rollback -test_code {
        #
        # Create a couple of objects
        #
        set object_id_1 [package_instantiate_object acs_object]
        set object_id_2 [package_instantiate_object acs_object]
        set object_ids [list $object_id_1 $object_id_2]
        #
        # Add a new relation
        #
        set rel_type relationship
        set rel_id [relation_add $rel_type $object_id_1 $object_id_2]
        aa_equals "Check new relation $rel_id" \
            [relation::get_id \
                -object_id_one $object_id_1 \
                -object_id_two $object_id_2 \
                -rel_type $rel_type] \
            $rel_id
        #
        # Check object one
        #
        aa_equals "Check object_one in the relation $rel_id" \
            [relation::get_object_one \
                -rel_type $rel_type \
                -object_id_two $object_id_2] \
            $object_id_1
        #
        # Check object two
        #
        aa_equals "Check object_two in the relation $rel_id" \
            [relation::get_object_two \
                -rel_type $rel_type \
                -object_id_one $object_id_1] \
            $object_id_2
        #
        # Check both
        #
        aa_equals "Check object_one in the relation $rel_id" \
            [relation::get_objects \
                -rel_type $rel_type \
                -object_id_two $object_id_2] \
            $object_id_1
        aa_equals "Check object_two in the relation $rel_id" \
            [relation::get_objects \
                -rel_type $rel_type \
                -object_id_one $object_id_1] \
            $object_id_2
        #
        # Delete
        #
        relation_remove $rel_id
        aa_equals "Check relation deletion $rel_id" \
            [relation::get_id \
                -object_id_one $object_id_1 \
                -object_id_two $object_id_2 \
                -rel_type $rel_type] \
            ""
    }
}

aa_register_case -cats {
    api
    smoke
} -procs {
    rel_types::create_role
    rel_types::delete_role
} acs_subsite_rel_type_roles {
    Test rel_type role creation/deletion

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 25 June 2021
} {
    aa_run_with_teardown -rollback -test_code {
        #
        # Create role
        #
        set role foo
        set pretty_name foo
        set pretty_plural foos
        rel_types::create_role \
            -pretty_name $pretty_name \
            -pretty_plural $pretty_plural \
            -role $role
        aa_true "New role $role exists" [db_0or1row role_exists_p {
            select 1 from acs_rel_roles where role = :role
        }]
        #
        # Delete role
        #
        rel_types::delete_role -role $role
        aa_false "New role $role exists after deletion" [db_0or1row role_p {
            select 1 from acs_rel_roles where role = :role
        }]
    }
}

aa_register_case -cats {
    api
    smoke
} -procs {
    application_group::new
    application_group::delete
} acs_subsite_application_group_new {
    Test application group creation/deletion

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 25 June 2021
} {
    aa_run_with_teardown -rollback -test_code {
        #
        # Create application group
        #
        set group_id [application_group::new]
        aa_true "New application group exists" [db_0or1row group_exists_p {
            select 1 from application_groups where group_id = :group_id
        }]
        #
        # Delete application group
        #
        application_group::delete -group_id $group_id
        aa_false "Group exists after deletion" [db_0or1row group_exists_p {
            select 1 from application_groups where group_id = :group_id
        }]
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
