# 

ad_library {
    
    Handle extra arguments not defined in service contract.
    Preliminary support for package_ids and object_type as an example
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2009-03-13
    @cvs-id $Id$
}

ad_proc -callback search::extra_arg -impl object_type {
    -value
    -object_table_alias
} {
    Implement per object type search
} {
    if {$object_table_alias eq "" || ![info exists object_table_alias] || $value eq ""} {
        return [list]
    }
    return [list from_clause {} where_clause "$object_table_alias.object_type = '[db_quote $value]'"]

}

ad_proc -callback search::extra_arg -impl package_ids {
    -value
    -object_table_alias
} {
    Implement per package_id search
} {
    if {$object_table_alias eq "" || ![info exists object_table_alias] || $value eq ""} {
        return [list]
    }
    return [list from_clause {} where_clause "$object_table_alias.package_id in ([template::util::tcl_to_sql_list $value])"]
}