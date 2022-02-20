ad_library {

    Low level interface for defining interface stubs to application
    specific DB functions.

    @author Gustaf Neumann
    @creation-date 2022-02-07
}

namespace eval ::acs {}
namespace eval ::acs::db {}
namespace eval ::acs::db::sql {}

namespace eval ::acs::db {

    #
    # Interface for directly calling SQL functions and procedures.
    #

    #
    # Definition of mapping from DB types to tcl types in the argument lists
    #
    ::acs::db::postgresql method typemap {} {
        return {integer int32 bigint integer}
    }

    ::acs::db::oracle method typemap {} {
        return {NUMBER int32}
    }

    #
    # Definition of expected/handled result types as reported by the
    # database management systems.
    #
    ::acs::db::postgresql method expected_result_types {} {
        return {integer boolean text interval character "character varying" record}
    }

    ::acs::db::oracle method expected_result_types {} {
        # Be aware: DATE is just a date (without a time part), e.g.
        #
        #    ::acs::dc call content_item get_publish_date -item_id ...
        #
        return {CHAR NUMBER VARCHAR2 DATE TABLE}
    }


    #
    # Mapping of SQL "package" name and "object" name to the names as
    # stored in the database.
    #
    ::acs::db::oracle method sql_function_name {package_name object_name} {
        return ${package_name}__${object_name}
    }
    ::acs::db::oracle method sql_function_name {package_name object_name} {
        return ${package_name}.${object_name}
    }


    #
    # Generator function
    #
    ::acs::db::SQL public method create_db_function_interface {
        {-dbn ""}
        {-match "*"}
        -verbose:switch
    } {
        #
        # Obtain all function definitions from the DB and turn these into
        # callable Tcl methods like the following examples:
        #
        #   ::acs::dc call content_type drop_type -content_type ::xowiki::FormInstance
        #   ::acs::dc call content_folder delete -folder_id $root_folder_id -cascade_p 1
        #
        # In the Oracle-biased terminology such calls are defined in
        # terms of a "package_name" and an "object_name":
        #
        #   ::acs::dc call /package_name/ /object_name/ ?/args/?
        #
        set db_definitions ""
        foreach item [:get_all_package_functions -dbn $dbn] {
            lassign $item package_name object_name sql_info
            if {[string match "*TRG" [string toupper $object_name]]} {
                # no need to provide interface to trigger functions
                continue
            }
            set package_name [string tolower $package_name]
            set object_name [string tolower $object_name]
            set key ${package_name}.${object_name}
            if {$match ne "*" && ![string match $match $key]} {
                continue
            }
            ns_log notice "generate stub for '$key'"
            if {![dict exists $db_definitions $key]} {
                dict set db_definitions $key package_name $package_name
                dict set db_definitions $key object_name $object_name
                dict set db_definitions $key sql_info $sql_info
            } else {
                #
                # We have multiple definitions. Take the definition
                # with the longest argument list.
                #
                set old_sql_info [dict get $db_definitions $key sql_info]
                if {[llength [dict get $old_sql_info argument_names] <
                     [llength dict get $sql_info argument_names]]} {
                    dict set db_definitions $key sql_info $sql_info
                }
            }
        }
        foreach {key v} $db_definitions {
            dict with v {
                :dbfunction_to_tcl -verbose=$verbose \
                    $package_name $object_name $sql_info
            }
        }
    }

    ::acs::db::SQL method dbproc_arg {
        {-name:required}
        {-type:required}
        {-required:switch}
        {-allow_empty:switch}
    } {
        set props {}
        if {[dict exists [:typemap] $type]} {
            lappend props [dict get [:typemap] $type]
        }
        if {$required} {
            lappend props required
        } elseif {$allow_empty} {
            # one is not allowed to use both, "allow_empty" and "required"
            lappend props 0..1
        }
        if {[llength $props] == 0} {
            return "-$name"
        } else {
            return -$name:[join $props ,]
        }
    }

    ::acs::db::oracle method db_proc_opt_arg_spec {-name -type -default} {
        return [:dbproc_arg -name $name -type $type]
    }

    ::acs::db::postgresql method db_proc_opt_arg_spec {-name -type -default} {
        # Handling of default values:
        #  - $optional eq "N", default ignored, the attribute is required
        #  - default value different from NULL --> make it default
        #  - otherwise: non-required argument, bindvars e.g. empty it to null
        #
        if {[string tolower $default] eq "null"} {
            set default_value ""
            set allowedEmtpyOpt "-allow_empty"
        } else {
            set default_value $default
            set allowedEmtpyOpt ""
        }
        return [list [:dbproc_arg -name $name -type $type {*}$allowedEmtpyOpt] $default_value]
    }

    ::acs::db::SQL method build_function_argument_list {dict} {
        #
        # Return argument list as used for procs and
        # methods. Different backend provide data in different forms
        # (types, meta model data), so we use in the case of Oracle a
        # dict with the assembled data and we normalize to common
        # grounds here.
        #
        set result {}
        #ns_log notice "build_function_argument_list $dict"
        foreach \
            argument_name [dict get $dict argument_names] \
            type [dict get $dict types] \
            optional [dict get $dict defaulted] \
            default [dict get $dict defaults] \
            {
                set arg_name [expr {$argument_name eq "DBN" ? "DBN"
                                    : [string tolower $argument_name]}]
                if {$optional eq "N"} {
                    set arg [:dbproc_arg -name $arg_name -type $type -required]
                } else {
                    set arg [:db_proc_opt_arg_spec -name $arg_name -type $type -default $default]
                }
                lappend result $arg
            }
        return $result
    }

    ::acs::db::postgresql public method get_all_package_functions {{-dbn ""}} {
        #
        # PostgreSQL version of obtaining information about the
        # procedures and functions stored in the DB. For PostgreSQL,
        # we keep this in the table "function_args".
        #
        # The information from "acs_function_args" defines, for which
        # functions we want to create an interface. The information is
        # completed with the definitions from the system catalog of
        # PostgreSQL.
        #
        # The resulting list contains entries of the form:
        #    sqlpackage object {argument_names ... types ... defaulted ... defaults result_type ....}
        #
        # Currently, "defaults" are only available for PostgreSQL
        #

        set definitions [::acs::dc list_of_lists -dbn $dbn get_all_package_functions {
            select function, arg_name, arg_default
            from   acs_function_args
            order by function, arg_seq
        }]
        set db_definitions {}
        set last_function ""
        set argument_names {}; set defaulted {}; set defaults {}
        foreach definition $definitions {
            lassign $definition function arg_name default
            if {$last_function ne "" && $last_function ne $function} {
                dict set db_definitions $last_function \
                    [list argument_names $argument_names defaulted $defaulted defaults $defaults]
                set argument_names {}; set defaulted {}; set defaults {}
            }
            lappend argument_names $arg_name
            lappend defaulted [expr {$default eq "" ? "N" : "Y"}]
            lappend defaults $default
            set last_function $function
        }
        dict set db_definitions $last_function \
            [list argument_names $argument_names defaulted $defaulted defaults $defaults]
        ns_log notice "loaded [dict size $db_definitions] definitions from function args"

        #
        # Get all package functions (package name, object name,
        # argument types, return type) from PostgreSQL system
        # catalogs.
        #
        set pg_data [::xo::dc list_of_lists -dbn $dbn [current method] {
            select distinct
            af.function,
            substring(af.function from 0 for position('__' in af.function)) as package_name,
            substring(af.function from position('__' in af.function)+2) as object_name,
            oidvectortypes(proargtypes),
            format_type(prorettype, NULL)
            from pg_proc, acs_function_args af
            where proname = lower(af.function)
        }]

        foreach item $pg_data {
            lassign $item key package_name object_name argument_types result_type
            set argument_types [lmap argument_type [split $argument_types ,] {
                string trim $argument_type
            }]
            set nr_defined_args [llength [dict get $db_definitions $key argument_names]]
            if {[llength $argument_types] < $nr_defined_args} {
                #
                # This might be a definition with fewer arguments; we
                # aim always for the definition with the most
                # arguments.
                #
                continue
            } elseif {[llength $argument_types] < $nr_defined_args} {
                ns_log warning "generate_stubs: $key has lessf arguments in " \
                    "function_definitions ($nr_defined_args) than in DB [llength $argument_types]"
                continue
            }
            dict set db_definitions $key result_type $result_type
            dict set db_definitions $key types $argument_types
            dict set db_definitions $key package_name $package_name
            dict set db_definitions $key object_name $object_name
        }
        return [lmap {key entry} $db_definitions {
            if {![dict exists $entry package_name]} {
                ns_log warning "missing DB for $key: <$entry>"
                continue
            }
            list [dict get $entry package_name] [dict get $entry object_name] $entry
        }]
        return $db_definitions
    }

    ::acs::db::oracle public method get_all_package_functions {{-dbn ""}} {
        #
        # Get all package functions (package name, object name) from Oracle
        # system catalogs. The resulting list contains entries of the form:
        #
        #    sqlpackage object {argument_names ... types ... defaulted ... result_type ....}
        #
        # Note, that we assume, that the "owner" of this functions is
        # the user "OPENACS".  This way we cover only these functions
        # defined by openacs (this has a similar functionality like
        # the "function_args" in PostgreSQL.
        #
        set last_func ""
        set result {}
        set d {argument_names "" types "" defaulted "" defaults "" result_type ""}
        foreach tuple [:list_of_lists -dbn $dbn dbqd..[current method] {
            select package_name, object_name, position, argument_name, data_type, defaulted
            from all_arguments
            where package_name is not null
            and owner = 'OPENACS'
            order by package_name, object_name, position
        }] {
            lassign $tuple package_name object_name position argument_name data_type defaulted
            set func $package_name.$object_name
            if {$func ne $last_func && $last_func ne ""} {
                lappend result [list [dict get $d package_name] [dict get $d object_name] $d]
                set last_func $func
                set d {argument_names "" types "" defaulted "" defaults "" result_type ""}
            }
            #ns_log notice "$func ($last_func): $position $argument_name $data_type"
            dict set d package_name $package_name
            dict set d object_name $object_name
            set last_func $func
            if {$position == 0} {
                dict set d result_type $data_type
            } else {
                dict lappend d types $data_type
                dict lappend d argument_names $argument_name
                dict lappend d defaulted $defaulted
                dict lappend d defaults [expr {$defaulted eq "Y" ? "null" : ""} ]
            }
        }
        if {$last_func ne ""} {
            lappend result [list [dict get $d package_name] [dict get $d object_name] $d]
        }
        return $result
    }


    ##########################################################################
    #
    # Lower level support functions
    #
    ##########################################################################

    ::acs::db::SQL method dbfunction_to_tcl {-verbose:switch package_name object_name sql_info} {
        #
        # This method compiles a stored procedure into proc
        # using a classic nonpositional argument style interface.
        #
        if {$sql_info eq ""} {
            return
        }

        #
        # Probably, we have to adjust the result type handling for Oracle.
        #
        set result_type [dict get $sql_info result_type]

        if {$result_type ne "" && $result_type ni [:expected_result_types]} {
            ns_log notice "??? ${package_name}__$object_name has unhandled result: $result_type"
            #return
        }

        set nonposarg_list [list [list -dbn ""]]

        lappend nonposarg_list {*}[:build_function_argument_list $sql_info]
        set body [:build_stub_body $package_name $object_name $sql_info]

        #
        # Define the methods based on the backend. Hopefully this is
        # sufficient, and we do not need definitions based on the
        # driver as well.
        #
        set body_prefix "\n # Automatically generated method\n\n"
        set cmd [list ::acs::db::${:backend} public method \
                     "call ${package_name} $object_name" \
                     $nonposarg_list \
                     "$body_prefix$body" \
                    ]
        if {$verbose} {
            ns_log notice FINAL=$cmd
        }
        {*}$cmd
    }

    #
    # In some cases, we need locks on SQL select statements, when the
    # select updates tuples, e.g., via a function. This is required at
    # least in PostgreSQL.
    #
    ::acs::db::postgresql eval {
        set :statement_suffix(content_item,set_live_revision) "FOR NO KEY UPDATE"
        set :statement_suffix(content_item,del) "FOR UPDATE"
        set :statement_suffix(content_item,new) "FOR UPDATE"
    }

    ::acs::db::postgresql method psql_statement_suffix {package_name object_name} {
        set key :statement_suffix($package_name,$object_name)
        if {[::acs::db::${:backend} eval [list info exists $key]]} {
            return [::acs::db::${:backend} eval [list set $key]]
        }
        return ""
    }

    #
    # The construction of the SQL statement is specific to PostgreSQL,
    # the final command to be executed in Tcl is specific to the driver.
    #
    #
    # nsdb-postgresql interface method generation:
    #
    ::acs::db::nsdb-postgresql method build_psql_body {tcl sql result_type} {
        if {$result_type eq "record"} {
            return [ns_trim -delimiter | [string map [list @SQL@ $sql] {
                | set result {}; set start_time [expr {[clock clicks -microseconds]/1000.0}]
                | db_with_handle -dbn $dbn __DB {
                |    set s [ns_pg_bind select $__DB {select r.* from @SQL@ as r}]
                |    while {[ns_db getrow $__DB $s]} {lappend result [ns_set values $s]}
                | }
                | ds_collect_db_call $dbn call "" "@SQL@" $start_time 0 ""
                | ns_set free $s
                | return $result
            }]]
        } else {
            return [ns_trim -delimiter | [string map [list @SQL@ $sql] {
                | db_with_handle -dbn $dbn __DB {
                |    set s [ns_pg_bind 0or1row $__DB {select @SQL@}]
                |    return [ns_set value $s 0]
                | }
            }]]
        }
    }

    #
    # nsdbi-postgresql interface method generation:
    #
    ::acs::db::nsdbi-postgresql method build_psql_body {tcl sql result_type} {
        if {$result_type eq "record"} {
            return [string map [list @SQL@ $sql] [ns_trim -delimiter | {
                | return [::dbi_rows -result lists {*}[expr {$dbn ne "" ? [list -db $dbn] : ""}] {
                |             select r.* from @SQL@ as r
                |         }]
            }]]
        } else {
            return [ns_trim -delimiter | [string map [list @SQL@ $sql] {
                | set __result ""
                | ::dbi_0or1row -autonull {*}[expr {$dbn ne "" ? [list -db $dbn] : ""}] {
                |    select @SQL@ as __result
                | }
                | return $__result
            }]]
        }
    }


    #
    # :nsdb-oracle interface method generation:
    #
    ::acs::db::nsdb-oracle method build_psql_body {tcl sql result_type} {

        if {$result_type eq ""} {
            #
            # Call an SQL procedure.
            #
            set sql [subst {BEGIN $sql; END;}]
            set sql_cmd [subst {ns_ora dml \$__DB \[subst {$sql}\]}]

        } elseif {$result_type eq "TABLE"} {
            #
            # Function returning a table
            #
            return [ns_trim -delimiter | [string map [list @SQL@ $sql @TCL@ $tcl] {
                | @TCL@; set result {}; set start_time [expr {[clock clicks -microseconds]/1000.0}]
                | db_with_handle -dbn $dbn __DB {
                |    set s [ns_ora select $__DB [subst {select * from @SQL@}]]
                |    while {[ns_db getrow $__DB $s]} {lappend result [ns_set values $s]}
                | }
                | ds_collect_db_call $dbn call "" "@SQL@" $start_time 0 ""
                | ns_set free $s
                | return $result
            }]]

        } else {
            #
            # Call an SQL function returing a scalar.
            #
            set sql [subst {BEGIN :1 := $sql; END;}]
            set sql_cmd [subst {ns_ora exec_plsql_bind \$__DB \[subst {$sql}\] 1 {}}]
        }

        return [ns_trim -delimiter | [subst {
            |$tcl
            |db_with_handle -dbn \$dbn __DB {
            |  ns_log notice "Oracle: $sql_cmd"
            |  return \[ $sql_cmd \]
            |}
        }]]
    }

    ::acs::db::postgresql method sql_function_argument_list {sql_info} {
        #
        # Build interface based on bind vars for PostgreSQL
        #
        set bind_var_names [lmap argument_name [dict get $sql_info argument_names] {
            string cat : [string tolower $argument_name]
        }]
        return [list tcl "" sql_arguments [join $bind_var_names ,]]
    }

    ::acs::db::oracle method sql_function_argument_list {sql_info} {
        #
        # Build interface based on bind vars and named parameters Oracle
        #
        set optional_parameters {}
        set arguments ""
        foreach \
            argument_name [dict get $sql_info argument_names] \
            defaulted [dict get $sql_info defaulted] {
                set argument_name [string tolower $argument_name]
                if {$defaulted eq "Y"} {
                    lappend optional_parameters $argument_name
                } else {
                    lappend arguments  "$argument_name => :$argument_name"
                }
            }
        #
        # We have to check at runtime if the arguments where provided
        #
        if {[llength $optional_parameters] > 0} {
            set tcl_code [ns_trim -delimiter | [string map [list @optional_parameters@ $optional_parameters] {
                |set __optional_parameters ""
                |foreach __var {@optional_parameters@} {
                |    if {[info exists $__var]} { append __optional_parameters ",$__var => :$__var" }
                |}
            }]]
            set arguments [join $arguments ,]\$__optional_parameters
        } else {
            set tcl_code ""
            set arguments [join $arguments ,]
        }
        return [list tcl $tcl_code sql_arguments $arguments]
    }

    ::acs::db::SQL method build_stub_body {package_name object_name sql_info} {
        #
        # Generate stub for calling the DB function.
        #
        set sql_function_name [:sql_function_name ${package_name} ${object_name}]
        #ns_log notice "... $sql_function_name -> [dict get $sql_info result_type]"

        if {$sql_info eq ""} {
            ns_log notice "... ignore definition: $sql_function_name"
            return ""
        }

        set arg_info [:sql_function_argument_list $sql_info]
        return [:build_psql_body \
                    [dict get $arg_info tcl] \
                    "${sql_function_name}([dict get $arg_info sql_arguments])" \
                    [dict get $sql_info result_type]]
    }

}

::acs::dc create_db_function_interface ;# -verbose ;# -match test.*

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
#    eval: (setq tcl-type-alist (remove* "method" tcl-type-alist :test 'equal :key 'car))
# End:
