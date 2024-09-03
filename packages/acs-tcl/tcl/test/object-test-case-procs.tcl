ad_library {

    @author byron Haroldo Linares Roman (bhlr@galileo.edu)
    @creation-date 2006-08-11
    @cvs-id $Id$
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        acs_object::get
        acs_object::get_element
        acs_object::set_context_id
        db_name
        db_nextval
        apm_package_id_from_key

        db_1row
    } acs_object_procs_test \
    {
        test the acs_object::* procs
    } {

        set pretty_name [ad_generate_random_string]
        set object_type [string tolower $pretty_name]
        set name_method "${object_type}.name"
        set creation_user [ad_conn user_id]
        set creation_ip [ad_conn peeraddr]
        set context_id  [ad_conn package_id]
        set context_id2 [apm_package_id_from_key "acs-tcl"]
        set the_id [db_nextval acs_object_id_seq]
        aa_run_with_teardown -test_code {

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
                                              :name_method);"

                set new_type_sql "select acs_object__new (
                                 :the_id,
                                 :object_type,
                                 now(),
                                 :creation_user,
                                 :creation_ip,
                                 :context_id
                                 );"
                set object_del_sql "select acs_object__delete(:the_id)"
                set type_drop_sql "select acs_object_type__drop_type(
                                                                     :object_type,
                                                                     't'
                                                                     )"
            } else {
                # oracle
                set type_create_sql "begin
                acs_object_type.create_type (
                        object_type => :object_type,
                        pretty_name => :pretty_name,
                        pretty_plural => :pretty_name,
                        supertype => 'acs_object',
                        abstract_p => 'f',
                        name_method => :name_method);
                end;"

                set new_type_sql "begin
                :1 := acs_object.new (
                        object_id => :the_id,
                        object_type => :object_type,
                        creation_user => :creation_user,
                        creation_ip => :creation_ip,
                        context_id => :context_id);
                end;"

                set object_del_sql "begin
                  acs_object.del(:the_id);
                  end;"

                set type_drop_sql "begin
                  acs_object_type.drop_type(object_type => :object_type);
                  end;"
            }




            aa_log "test object_type $object_type :: $context_id2"

            db_exec_plsql type_create $type_create_sql

            set the2_id [db_exec_plsql new_type $new_type_sql]

            acs_object::get -object_id $the_id -array array

            aa_true "object_id $the_id :: $array(object_id)" \
                [string match $the_id $array(object_id)]

            aa_true "object_type $object_type :: $array(object_type)" \
                [string equal $object_type $array(object_type)]

            aa_true "context_id $context_id :: $array(context_id)" \
                [string equal $context_id $array(context_id)]

            aa_true \
                "creation_user $creation_user :: [acs_object::get -object_id $the_id -element creation_user]" \
                [string equal $creation_user [acs_object::get_element \
                                                  -object_id $the_id \
                                                  -element creation_user]]
            aa_true \
                "creation_ip $creation_ip :: [acs_object::get -object_id $the_id -element creation_ip]" \
                [string equal $creation_ip [acs_object::get_element \
                                                -object_id $the_id \
                                                -element creation_ip]]

            acs_object::set_context_id -object_id $the_id \
                -context_id $context_id2

            aa_true \
                "context_id $context_id2 :: [acs_object::get_element -object_id $the_id -element context_id]" \
                [string equal $context_id2 [acs_object::get -object_id $the_id -element context_id]]


        } -teardown_code {

            db_exec_plsql object_del $object_del_sql
            db_exec_plsql type_drop $type_drop_sql
        }
    }


aa_register_case -cats {
    api
    smoke
} -procs {
    acs_object::object_p
    package_instantiate_object
} object_p {
    Test the acs_object::object_p proc.
} {
    aa_run_with_teardown -rollback -test_code {
        #
        # Check with an unused object_id
        #
        set object_id [db_nextval acs_object_id_seq]
        aa_false "Is $object_id an object?" [acs_object::object_p -id $object_id]
        #
        # Fetch an existing object
        #
        set object_id [db_string q {select max(object_id) from acs_objects}]
        aa_true "Is $object_id an object?" [acs_object::object_p -id $object_id]
        #
        # Create an object and check
        #
        set object_id [package_instantiate_object acs_object]
        aa_true "Is $object_id an object?" [acs_object::object_p -id $object_id]
    }
}

aa_register_case -cats {
    api
    smoke
} -procs {
    acs_object::is_type_p
    acs_object_type::supertypes
    acs_object_type::supertype
} is_object_type_p {
    Test the acs_object::is_type_p proc.
} {
    aa_run_with_teardown -rollback -test_code {
        aa_section "Check with an unused object_id"
        set object_id [db_nextval acs_object_id_seq]
        aa_false "Is $object_id an acs_object?" \
            [acs_object::is_type_p -object_id $object_id -object_type acs_object]

        aa_section "Check with an invalid object_id"
        set object_id abc
        aa_false "Is $object_id an acs_object?" \
            [acs_object::is_type_p -object_id $object_id -object_type acs_object]

        aa_section "Fetch an existing object"
        set object_id [db_string q {select max(object_id) from acs_objects}]
        aa_true "Is $object_id an acs_object?" \
            [acs_object::is_type_p -object_id $object_id -object_type acs_object]

        aa_section "Supertypes"
        aa_true "true supertype" \
            [acs_object_type::supertype -supertype acs_object -subtype user]
        aa_true "equlas supertype" \
            [acs_object_type::supertype -supertype user -subtype user]
        aa_false "false supertype" \
            [acs_object_type::supertype -supertype user -subtype party]

        aa_section "Fetch an existing user"
        set object_id [db_string q {select max(user_id) from users}]
        aa_true "Is $object_id a user?" \
            [acs_object::is_type_p -object_id $object_id -object_type user]
        aa_true "Is $object_id a person?" \
            [acs_object::is_type_p -object_id $object_id -object_type person]
        aa_true "Is $object_id a party?" \
            [acs_object::is_type_p -object_id $object_id -object_type party]
        aa_true "Is $object_id a user (no hierarchy)?" \
            [acs_object::is_type_p -object_id $object_id -object_type user -no_hierarchy]
        aa_false "Is $object_id a person (no hierarchy)?" \
            [acs_object::is_type_p -object_id $object_id -object_type person -no_hierarchy]
        aa_false "Is $object_id a party (no hierarchy)?" \
            [acs_object::is_type_p -object_id $object_id -object_type party -no_hierarchy]

        aa_true "Is $object_id a user os a package?" \
            [acs_object::is_type_p -object_id $object_id -object_type {apm_package user}]
        aa_true "Is $object_id a person or a package?" \
            [acs_object::is_type_p -object_id $object_id -object_type {apm_package person}]
        aa_true "Is $object_id a party or a package?" \
            [acs_object::is_type_p -object_id $object_id -object_type {apm_package party}]
        aa_true "Is $object_id a user or a package (no hierarchy)?" \
            [acs_object::is_type_p -object_id $object_id -object_type {apm_package user} -no_hierarchy]
        aa_false "Is $object_id a person or a package (no hierarchy)?" \
            [acs_object::is_type_p -object_id $object_id \
                 -object_type {apm_package person} \
                 -no_hierarchy]
        aa_false "Is $object_id a party or a package (no hierarchy)?" \
            [acs_object::is_type_p -object_id $object_id \
                 -object_type {apm_package party} -no_hierarchy]


        aa_section "Create an object and check"
        set object_id [package_instantiate_object acs_object]
        aa_true "Is $object_id an acs_object?" \
            [acs_object::is_type_p -object_id $object_id -object_type acs_object]
    }
}

aa_register_case -cats {
    api
    smoke
} -procs {
    acs_magic_object
} magic_objects {
    Test the magic objects api
} {
    db_foreach get_objects {
        select object_id, name from acs_magic_objects
    } {
        aa_equals "Api retrieves the correct magic object_id for '$name'" \
            [acs_magic_object $name] $object_id
    }
}

aa_register_case -cats {
    api
    smoke
} -procs {
    acs_object_name
} object_name {
    Test the acs_object_name api
} {
    db_foreach get_objects {
        select object_id, acs_object.name(object_id) as name
        from acs_objects
        order by object_id desc
        fetch first 10 rows only
    } {
        aa_equals "Api retrieves the correct name '$name' for object_id '$object_id'" \
            [acs_object_name $object_id] $name
    }
}

aa_register_case -cats {
    api
    smoke
} -procs {
    db_table_exists
    acs_object_type::get_table_name
} object_type_table_name {
    Test the acs_object_type::get_table_name api
} {
    db_foreach get_objects {
        select object_type, table_name from acs_object_types
    } {
        aa_equals "Api retrieves the correct table name '$table_name' for object_type '$object_type'" \
            [acs_object_type::get_table_name -object_type $object_type] $table_name
        if {$table_name ne ""} {
            aa_true "Table 'table_name' exists" [db_table_exists $table_name]
        }
    }
}

aa_register_case -cats {
    api
    smoke
} -procs {
    acs_object_type_hierarchy
    lang::util::localize
    acs_object_type::supertypes
} object_type_hierarchy {
    Test the acs_object_type_hierarchy api
} {
    set object_type user
    set supertypes [list $object_type {*}[acs_object_type::supertypes -subtype $object_type]]

    aa_section "When object_type is specified"

    aa_equals "When object_type is not empty, indent_string, indent_width and join string have no effect" \
        [acs_object_type_hierarchy \
             -object_type $object_type \
             -indent_string __test_indent_string \
             -indent_width 3 \
             -join_string __test_join_string \
             -additional_html __test_additional_html] \
        [acs_object_type_hierarchy \
             -object_type $object_type \
             -indent_string __test_indent_string2 \
             -indent_width 1000 \
             -join_string __test_join_string2 \
             -additional_html __test_additional_html]

    set hierarchy [acs_object_type_hierarchy \
                       -object_type $object_type \
                       -additional_html __test_additional_html]
    #aa_log [ns_quotehtml $hierarchy]
    aa_true "Hierarchy is HTML" \
        [ad_looks_like_html_p $hierarchy]
    aa_true "Additional HTML was appended at the end of the output" \
        [regexp {^.*__test_additional_html$} $hierarchy]

    foreach h $supertypes {
        set pretty_name [db_string q {
            select pretty_name
            from acs_object_types
            where object_type = :h
        }]
        set pretty_name [lang::util::localize $pretty_name]
        aa_true "Pretty name '$pretty_name' is in the output" \
            {[string first $pretty_name $hierarchy] >= 0}

        set href [export_vars -base ./one {{object_type $h}}]
        aa_true "URL '$href' is in the output" \
            {[string first $href $hierarchy] >= 0}
    }

    aa_section "When object_type is not specified"

    set n_types [db_string q {select count(*) from acs_object_types}]
    set indent_width 97
    set hierarchy [acs_object_type_hierarchy \
                       -indent_string __test_indent_string \
                       -indent_width $indent_width \
                       -join_string __test_join_string \
                       -additional_html __test_additional_html]
    aa_true "Hierarchy is HTML" \
        [ad_looks_like_html_p $hierarchy]

    aa_true "Additional HTML was appended at the end of the output" \
        [regexp {^.*__test_additional_html$} $hierarchy]

    aa_true "There is a multiple of indent_width indent_strings:" \
        {[regsub -all __test_indent_string $hierarchy {} _] % $indent_width == 0}

    aa_true "There are n_object_types -1 join strings" \
        {[regsub -all __test_join_string $hierarchy {} _] == ($n_types - 1)}

}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
