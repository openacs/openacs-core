# /packages/mbryzek-subsite/tcl/package-procs.tcl

ad_library {

    Procs to help build PL/SQL packages

    @author mbryzek@arsdigita.com
    @creation-date Wed Dec 27 16:02:44 2000
    @cvs-id $Id$

}

ad_proc -public package_type_dynamic_p {
    object_type
} {
    Returns 1 if the object type is dynamic. 0 otherwise

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/30/2000
} {
    return [db_string object_type_dynamic_p {
        	select case when exists (select 1 
                                   from acs_object_types t
                                  where t.dynamic_p = 't'
                                    and t.object_type = :object_type)
	            then 1 else 0 end
	  from dual
    }]
}


ad_proc -private package_create_attribute_list {
    { -supertype "" }
    { -object_name "" }
    { -limit_to "" }
    { -table "" }
    { -column "" }
    { -column_value "" }
    object_type
} {
    Generates the list of attributes for this object type. Each
    element in the list is (table_name, column_name, default_value, column_value) where
    <code>default_value</code> and <code>column_value</code> are
    optional.

    Note that if either of table_name, id_column is unspecified, we
    retrieve the values for both from the acs_object_types table

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

    @param supertype The supertype of the object we are creating. If
    specified, along with object_name, we lookup the parameters to
    supertype.object_name and include any missing parameters in our
    argument list.

    @param object_name The name of the function / procedure we are
    creating. See supertype for explanation.

    @param limit_to If empty, this argument is ignored. Otherwise, it
    is a list of all the columns to be included in the attribute list. Any
    attribute whose column_name is not in this list is then ignored.

    @param table  The <code>table_name</code> for this object_type
    (from the <code>acs_object_types</code> tables)

    @param column The <code>id_column</code> for this object_type
    (from the <code>acs_object_types</code> tables)

    @param column_value The value for this column in the present
    calling function. Useful when you are calling supertype function and
    need to refer to the supertype argument by a different name locally.

    @param object_type The object type for which we are generating
    attributes

} {
    if { $table eq "" || $column eq "" } {
        # pull out the table and column names based on the object type
        db_1row select_type_info {
            select t.table_name as table, t.id_column as column
            from acs_object_types t
            where t.object_type = :object_type
        }
    }

    # set toupper for case-insensitive searching
    set limit_to [string toupper $limit_to]

    # For the actual package spec and body, we build up a list of
    # the arguments and use a helper proc to generate the actual
    # pl/sql code. Note that the helper procs also return nicely
    # formatted pl/sql code

    set attr_list [list]

    # Start with the primary key for this object type. Continuing with
    # convention that id_column can be null (will default to new
    # object_id)
    lappend attr_list [list $table "$column" NULL $column_value]

    # the all_attributes array is used to ensure we do not have
    # duplicate column names
    set all_attributes([string toupper $column]) 1

    if { $column_value ne "" } {
        # column value is the same physical column as $column - just
        # named differently in the attribute list. We still don't want
        # duplicates
        set all_attributes([string toupper $column_value]) 1
    }

    # Now, loop through and gather all the attributes for this object
    # type and all its supertypes in order starting with this object
    # type up the type hierarchy

    db_foreach select_all_attributes {} {
        # First make sure the attribute is okay
        if { $limit_to ne "" } {
            # We have a limited list of arguments to use. Make sure
            # this attribute is one of them
            if {$attr_column_name ni $limit_to} {
                # This column is not in the list of allowed
                # columns... ignore
                continue
            }
        }
        set default [package_attribute_default \
                         -min_n_values $min_n_values \
                         -attr_default $default_value \
                         $object_type $attr_table_name $attr_column_name]
        lappend attr_list [list $attr_table_name $attr_column_name $default]
        set all_attributes($attr_column_name) 1
    }

    if { $supertype ne "" && $object_name ne "" } {
        foreach row [util_memoize [list package_table_columns_for_type $supertype]] {
            lassign $row table_name column_name

            # Note that limit_to doesn't apply here as we always need
            # to include these arguments else the call will fail

            if { [info exists all_attributes($column_name)] } {
                continue
            }
            set all_attributes($column_name) 1
            set default [package_attribute_default $object_type $table_name $column_name]
            lappend attr_list [list $table_name $column_name $default]
        }
    }

    return $attr_list
}



ad_proc -private package_attribute_default {
    { -min_n_values "0" }
    { -attr_default "" }
    object_type
    table
    column
} {
    Returns a sql value to be used as the default in a pl/sql function
    or procedure parameter list. This is a special case, hardcoded
    function that specifies defaults for standard acs_object
    attributes.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/28/2000

    @param object_type  The object type that owns the attribute we are
    using. Used only to set a default for
    <code>acs_object.object_type</code>
    stored (either table_name from the attribute or for the object_type)
    @param table        The table in which the value of this attribute is
    stored (either table_name from the attribute or for the object_type)
    @param column       The column in which the value of this attribute is
    stored (either column_name or attribute_name from
            the attributes table)
    @param min_n_values Used to determine if an argument is required
    (e.g. required = min_n_values != 0)
    @param attr_default The default values for this attribute as
    specified in the attributes table.

} {

    # We handle defaults grossly here, but I don't currently have
    # a better idea how to do this
    if { $attr_default ne "" } {
        return "'[DoubleApos $attr_default]'"
    }

    # Special cases for acs_object and acs_rels
    # attributes. Default case sets default to null unless the
    # attribute is required (min_n_values > 0)

    if {$table eq "ACS_OBJECTS"} {
        switch -- $column {
            "OBJECT_TYPE"   { return "'[DoubleApos $object_type]'" }
            "CREATION_DATE" { return [db_map creation_date] }
            "CREATION_IP"   { return "NULL" }
            "CREATION_USER" { return "NULL" }
            "LAST_MODIFIED" { return [db_map last_modified] }
            "MODIFYING_IP"  { return "NULL" }
        }
    } elseif {$table eq "ACS_RELS"} {
        switch -- $column {
            "REL_TYPE"      { return "'[DoubleApos $object_type]'" }
        }
    }

    # return to null unless this attribute is required
    # (min_n_values > 0)
    return [ad_decode $min_n_values 0 "NULL" ""]
}


ad_proc -public package_recreate_hierarchy {
    object_type
} {
    Recreates all the packages for the hierarchy starting with the
    specified object type down to a leaf. Resets the
    package_object_view cache. Note: Only updates packages for dynamic
    objects (those with dynamic_p set to t)

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/28/2000

    @param object_type The object type for which to recreate packages,
    including all children types.

} {
    set object_type_list [db_list select_object_types {}]

    # Something changed... flush the data dictionary cache for the
    # type hierarchy starting with this object's type. Note that we
    # flush the cache in advance to reuse it when generating future packages
    # for object_types in the same level of the hierarchy. Note also that
    # maintaining this cache only gives us a few hits in the cache in
    # the degenerate case (one subtype), but the query we're caching
    # is dreadfully slow because of data dictionary tables. So
    # ensuring we only run the query once significantly improves
    # performance. -mbryzek

    foreach object_type $object_type_list {
        if { [util_memoize_cached_p [list package_table_columns_for_type $object_type]] } {
            util_memoize_flush [list package_table_columns_for_type $object_type]
        }
    }

    foreach type $object_type_list {
        package_create $type
    }

}


ad_proc -private package_create {
    { -debug_p "f" }
    object_type
} {
    Creates a packages with a new function and delete procedure for
    the specified object type. This function uses metadata exclusively
    to create the package. Resets the package_object_view cache

    Throws an error if the specified object type does not exist or is
    not dynamic

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/27/2000

    @param object_type The object type for which to create a package
    @param debug_p If "t" then we return a text block containing the
    sql to create the package. Setting debug_p to t will not create the
    package.

} {

    if { ![package_type_dynamic_p $object_type] } {
        error "The specified object, $object_type, either does not exist or is not dynamic. Therefore, a package cannot be created for it"
    }

    # build up a list of the pl/sql to execute as it will make it
    # easier to return a string for debugging purposes.

    set package_name [db_string select_package_name {
        select t.package_name
        from acs_object_types t
        where t.object_type = :object_type
    }]

    lappend plsql \
        [list "package" "create_package" [package_generate_spec $object_type]] \
        [list "package body" "create_package_body" [package_generate_body $object_type]]

    if { $debug_p == "t" } {
        foreach pair $plsql {
            #        append text "[plsql_utility::parse_sql [lindex $pair 1]]\n\n"
            append text [lindex $pair 2]
        }
        return $text
    }

    foreach pair $plsql {
        lassign $pair type stmt_name code

        db_exec_plsql $stmt_name $code

        # Let's check to make sure the package is valid
        #
        # This seems to be a speciality in Oracle: The status of a
        # program unit (PL/SQL package, procedure, or function) is set
        # to INVALID if a database object on which it depends is
        # changed. That program unit must then be recompiled (which
        # Oracle Database will often do automatically the next time
        # you try to use that program unit).
        #
        if { ![db_string package_valid_p {}] } {
            error "$object_type \"$package_name\" is not valid after compiling:\n\n$code\n\n"
        }
    }

    # Now reset the object type view in case we've cached some attribute queries
    package_object_view_reset $object_type

    # Return the object type - what else to return?
    return $object_type
}


ad_proc -private package_generate_spec {
    object_type
} {
    Generates pl/sql to create a package specification. Does not
    execute the pl/sql - simply returns it.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 10/2000

    @param object_type The object for which to create a package spec
} {
    # First pull out some basic information about this object type
    db_1row select_type_info {
        select t.table_name, t.id_column, lower(t.package_name) as package_name, t.supertype
        from acs_object_types t
        where t.object_type = :object_type
    }

    return [db_map spec]
}


ad_proc -private package_generate_body {
    object_type
} {
    Generates plsql to create the package body

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 10/2000

    @param object_type The name of the object type for which we are creating the package

} {
    # Pull out information about this object type
    db_1row select_type_info {
        select t.table_name, t.id_column, lower(t.package_name) as package_name, t.supertype
        from acs_object_types t
        where t.object_type = :object_type
    }

    # Pull out information about the supertype
    db_1row select_type_info {
        select t.table_name as supertype_table_name, t.id_column as supertype_id_column,
        lower(t.package_name) as supertype_package_name
        from acs_object_types t
        where t.object_type = :supertype
    }

    set attribute_list [package_create_attribute_list \
                            -supertype $supertype \
                            -object_name "NEW" \
                            -table $table_name \
                            -column $id_column \
                            $object_type]

    # Prune down the list of attributes in supertype_attr_list to
    # those specific to the function call in the supertype's package
    set supertype_params [db_list select_supertype_function_params {}]

    set supertype_attr_list [package_create_attribute_list \
                                 -supertype $supertype \
                                 -object_name "NEW" \
                                 -limit_to $supertype_params \
                                 -table $supertype_table_name \
                                 -column $supertype_id_column \
                                 -column_value $id_column \
                                 $supertype]

    return [db_map body]
}

ad_proc -public package_object_view_reset {
    object_type
} {
    Resets the cached views for all chains (e.g. all variations of
    start_with in package_object_view) for the specified object type.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

} {
    # First flush the cache for all pairs of object_type, ancestor_type (start_with)
    db_foreach select_ancestor_types {} {
        if { [util_memoize_cached_p [list package_object_view_helper -start_with $ancestor_type $object_type]] } {
            util_memoize_flush [list package_object_view_helper -start_with $ancestor_type $object_type]
        }
    }

    # flush the cache for all pairs of sub_type, object_type(start_with)
    db_foreach select_sub_types {} {
        if { [util_memoize_cached_p [list package_object_view_helper -start_with $object_type $sub_type]] } {
            util_memoize_flush [list package_object_view_helper -start_with $object_type $sub_type]
        }
    }
}

ad_proc -public package_object_view {
    { -refresh_p "f" }
    { -start_with "acs_object" }
    object_type
} {
    Returns a select statement to be used as an inner view for
    selecting out all the attributes for the
    object_type. util_memoizes the result

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 10/2000

    @param refresh_p If t, force a reload of the cache
    @param start_with The highest parent object type for which to include attributes
    @param object_type The object for which to create a package spec
} {
    if {$refresh_p == "t"} {
        package_object_view_reset $object_type
    }
    return [util_memoize [list package_object_view_helper -start_with $start_with $object_type]]
}



ad_proc -private package_object_view_helper {
    { -start_with "acs_object" }
    object_type
} {
    Returns a select statement to be used as an inner view for
    selecting out all the attributes for the object_type.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 10/2000

    @param start_with The highest parent object type for which to include attributes
    @param object_type The object for which to create a package spec
} {

    # Let's add the primary key for our lowest object type. We do this
    # separately in case there are no other attributes for this object type
    # Note that we also alias this primary key to object_id so
    # that the calling code can generically use it.

    db_1row select_type_info {
        select t.table_name, t.id_column
        from acs_object_types t
        where t.object_type = :object_type
    }


    set columns [list "${table_name}.${id_column}"]
    if { [string tolower $id_column] ne "object_id" } {
        # Add in an alias for object_id
        lappend columns "${table_name}.${id_column} as object_id"
    }
    set tables [list "${table_name}"]
    set primary_keys [list "${table_name}.${id_column}"]

    foreach row [package_object_attribute_list -start_with $start_with $object_type] {
        set table [lindex $row 1]
        set column [lindex $row 2]
        set object_column [lindex $row 8]

        if {[string tolower $column] eq "object_id"} {
            # We already have object_id... skip this column
            continue
        }

        # Do the column check first to include only the tables we need
        if {"$table.$column" in $columns} {
            # We already have a column with the same name. Keep the
            # first one as it's lower in the type hierarchy.
            continue
        }
        # first time we're seeing this column
        lappend columns "${table}.${column}"

        if {$table ni $tables} {
            # First time we're seeing this table
            lappend tables $table
            lappend primary_keys "${table}.${object_column}"
        }
    }

    set pk_formatted [list]
    for { set i 0 } { $i < [llength $primary_keys] - 1 } { incr i } {
        lappend pk_formatted "[lindex $primary_keys $i] = [lindex $primary_keys $i+1]"
    }
    return "SELECT [string tolower [join $columns ",\n       "]]
  FROM [string tolower [join $tables ", "]]
[ad_decode [llength $pk_formatted] "0" "" " WHERE [join [string tolower $pk_formatted] "\n   AND "]"]"

}



ad_proc -private package_insert_default_comment { } {
    Returns a string to be used verbatim as the default comment we
    insert into meta-generated packages and package bodies. If we have
    a connection, we grab the user's name from ad_conn user_id.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/29/2000

} {
    if { [ad_conn isconnected] } {
        set user_id [ad_conn user_id]
        db_1row select_comments {}
    } else {
        db_1row select_author_unknwon {
            select 'Unknown' as author,
            sysdate as creation_date
            from dual
        }
    }
    return "
  --/** THIS IS AN AUTO GENERATED PACKAGE. $author was the
  --    user who created it
  --
  --    @creation-date $creation_date
  --*/
"
}

ad_proc package_object_attribute_list {
    { -start_with "acs_object" }
    { -include_storage_types {type_specific} }
    object_type
} {
    Returns a list of lists all the attributes (column name or
                                                attribute_name) to be used for this object type. Each list
    elements contains:
    <code>(attribute_id, table_name, attribute_name, pretty_name, datatype, required_p, default_value)</code>

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/29/2000

    @param start_with The highest parent object type for which to include attributes
    @param object_type The object type for which to include attributes
} {

    set storage_clause ""

    if {$include_storage_types ne ""} {
        set storage_clause "
          and a.storage in ('[join $include_storage_types "', '"]')"
    }

    return [db_list_of_lists attributes_select {}]
}


ad_proc -private package_plsql_args {
    { -object_name "NEW" }
    package_name
} {
    Generates a list of parameters expected to a plsql function defined within
    a given package.

    <p>

    @author Ben Adida (ben@openforce.net)
    @creation-date 11/2001

    @param package_name The package which owns the function

    @param object_name The function name which we're looking up
} {
    # Get just the args
    return [db_list select_package_func_param_list {}]
}

ad_proc -private package_function_p {
    -object_name:required
    package_name
} {
    Returns true if the package's object is a function.
} {
    return [db_0or1row function_p ""]
}

ad_proc -private package_table_columns_for_type {
    object_type
} {

    Generates the list of tables and columns that are parameters of
    the object named <code>NEW</code> for PL/SQL package associated
    with this object type.

    <p>

    Note we limit the argument list to only object_type to make it
    possible to use <code>util_memoize_flush<code> to clear any cached
    values for this procedure.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

    @param object_type The object type for which we are generating the
    list

    @return a list of lists where each list element is a pair of table
    name, column name

} {

    set object_name "NEW"

    db_1row select_type_info {
        select t.package_name
        from acs_object_types t
        where t.object_type = :object_type
    }

    # We need to hit the data dictionary to find the table and column names
    # for all the arguments to the object_types function/procedure
    # named "object_name." Note that we join against
    # acs_object_types to select out the tables and columns for the
    # object_type up the type tree starting from this object_type.
    #
    # NOTE: This query is tuned already, yet still slow (~1
    # second on my box right now). Be careful modifying
    # it... It's slow because of the underlying data dictionary query
    # against user_arguments

    return [db_list_of_lists select_object_type_param_list {}]

}

ad_proc -public package_instantiate_object {
    { -creation_user "" }
    { -creation_ip "" }
    { -package_name "" }
    { -var_list "" }
    { -extra_vars "" }
    { -start_with "" }
    { -form_id "" }
    { -variable_prefix "" }
    object_type
} {

    Creates a new object of the specified type by calling the
    associated PL/SQL package new function.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @author Ben Adida (ben@openforce.net)
    @creation-date 02/01/2001

    @param creation_user The current user. Defaults to <code>[ad_conn
                                                              user_id]</code> if not specified and there is a connection

    @param creation_ip The current user's ip address. Defaults to <code>[ad_conn
                                                                         peeraddr]</code> if not specified and there is a connection

    @param package_name The PL/SQL package associated with this object
    type. Defaults to <code>acs_object_types.package_name</code>

    @param var_list A list of pairs of additional attributes and their
    values to pass to the constructor. Each pair is a list of two
    elements: key => value

    @param extra_vars an ns_set of extra vars

    @param start_with The object type to start with when gathering
    attributes for this object type.  Defaults to the object type.

    @param form_id The form id from templating form system if we're
    using the forms API to specify attributes

    @param object_type The object type of the object we are
    instantiating

    @return The object id of the newly created object

    <p><b>Example:</b>
    <pre>

    template::form create add_group
    template::element create add_group group_name -value "Publisher"

    set var_list [list \
                      [list context_id $context_id]  \
                      [list group_id $group_id]]

    return [package_instantiate_object \
                -start_with "group" \
                -var_list $var_list \
                -form_id "add_group" \
                "group"]

    </pre>


} {

    if {$variable_prefix ne ""} {
        append variable_prefix "."
    }

    # Select out the package name if it wasn't passed in
    if { $package_name eq "" } {
        if { ![db_0or1row package_select {
            select t.package_name
            from acs_object_types t
            where t.object_type = :object_type
        }] } {
            error "Object type \"$object_type\" does not exist"
        }
    }

    if { [ad_conn isconnected] } {
        if { $creation_user eq "" } {
            set creation_user [ad_conn user_id]
        }
        if { $creation_ip eq "" } {
            set creation_ip [ad_conn peeraddr]
        }
    }

    if {$creation_user == 0} {
        set creation_user ""
    }

    lappend var_list [list creation_user $creation_user]
    lappend var_list [list creation_ip $creation_ip]
    lappend var_list [list object_type $object_type]

    # The first thing we need to do is select out the list of all
    # the parameters that can be passed to this object type's new function.
    # This will prevent us from passing in any parameters that are
    # not defined

    foreach arg [util_memoize [list package_plsql_args $package_name]] {
        set real_params([string toupper $arg]) 1
    }

    # Use pieces to generate the parameter list to the new
    # function. Pieces is just a list of lists where each list contains only
    # one item - the name of the parameter. We keep track of
    # parameters we've already added in the array param_array (all keys are
    # in upper case)

    set pieces [list]

    foreach pair $var_list {
        lassign $pair __key __value
        if { ![info exists real_params([string toupper $__key])] } {
            # The parameter is not accepted as a parameter to the
            # pl/sql function. Ignore it.
            continue;
        }
        lappend pieces [list $__key]
        set param_array([string toupper $__key]) 1
        # Set the value for binding
        set $__key $__value
    }

    # Go through the extra_vars (ben - OpenACS)
    if {$extra_vars ne "" } {
        for {set i 0} {$i < [ns_set size $extra_vars]} {incr i} {
            set __key [ns_set key $extra_vars $i]
            set __value [ns_set value $extra_vars $i]

            if { ![info exists real_params([string toupper $__key])] } {
                # The parameter is not accepted as a parameter to the
                # pl/sql function. Ignore it.
                continue;
            }
            lappend pieces [list $__key]
            set param_array([string toupper $__key]) 1
            # Set the value for binding
            set $__key $__value
        }
    }


    if { $form_id ne ""} {

        #DRB: This needs to be cached!
        set __id_column [db_string get_id_column {}]
        if { [info exists real_params([string toupper $__id_column])]
             && ![info exists param_array([string toupper $__id_column])]
         } {
            set param_array([string toupper $__id_column]) 1
            set $__id_column [template::element::get_value $form_id "$variable_prefix$__id_column"]
            lappend pieces [list $__id_column]
        }

        if {$start_with eq ""} {
            set start_with $object_type
        }

        # Append the values from the template form for each attribute
        foreach row [package_object_attribute_list -start_with $start_with $object_type] {
            set __attribute [lindex $row 2]
            if { [info exists real_params([string toupper $__attribute])]
                 && ![info exists param_array([string toupper $__attribute])]
             } {
                set param_array([string toupper $__attribute]) 1
                set $__attribute [template::element::get_value $form_id "$variable_prefix$__attribute"]

                lappend pieces [list $__attribute]
            }
        }
    }

    set object_id [db_exec_plsql create_object {}]

    if { [ad_conn isconnected] } {
        subsite_callback -object_type $object_type "insert" $object_id
    }

    # BUG FIX (ben - OpenACS)
    return $object_id

}

ad_proc -public package_exec_plsql {
    { -var_list "" }
    package_name
    object_name
} {

    Calls a pl/[pg]sql proc/func defined within the object type's package.  Use of
    this Tcl APi proc avoids the need for the developer to write separate SQL for each
    RDBMS we support.

    @author Don Baccus (dhogaza@pacifier.com)
    @creation-date 12/31/2003

    @param package_name The PL/[pg]SQL package
    @param object_name The PL/[pg]SQL function within the package

    @param var_list A list of pairs of additional attributes and their
    values to pass to the constructor. Each pair is a list of two
    elements: key => value

    @return empty string for procs, function return value for funcs

    <p><b>Example:</b>
    <pre>

    set var_list [list \
                      [list group_id $group_id]]

    package_exec_plsql -var_list $var_list group delete

    </pre>
} {
    # Ugly hack for the case where a proc has params named "package_name" or "object_name".

    set __package_name $package_name
    set __object_name $object_name

    foreach arg [util_memoize [list package_plsql_args -object_name $__object_name $__package_name]] {
        set real_params([string toupper $arg]) 1
    }

    # Use pieces to generate the parameter list to the new
    # function. Pieces is just a list of lists where each list contains only
    # one item - the name of the parameter. We keep track of
    # parameters we've already added in the array param_array (all keys are
    # in upper case)

    set pieces [list]

    foreach pair $var_list {
        lassign $pair __key __value
        if { ![info exists real_params([string toupper $__key])] } {
            # The parameter is not accepted as a parameter to the
            # pl/sql function. Ignore it.
            ns_log Warning "package_exec_plsql: skipping $__key not found in params for $__package_name $__object_name"
            continue;
        }
        lappend pieces [list $__key]
        set param_array([string toupper $__key]) 1
        # Set the value for binding
        set $__key $__value
    }

    if { [util_memoize [list package_function_p -object_name $__object_name $__package_name]] } {
        return [db_exec_plsql exec_func_plsql {}]
    } else {
        db_exec_plsql exec_proc_plsql {}
    }

}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
