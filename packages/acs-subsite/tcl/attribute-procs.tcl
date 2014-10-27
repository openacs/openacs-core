# /packages/mbryzek-subsite/tcl/attribute-procs.tcl

ad_library {
    
    Procs to help with attributes for object types
    

    @author mbryzek@arsdigita.com
    @creation-date Thu Dec  7 10:30:57 2000
    @cvs-id $Id$
}

ad_page_contract_filter attribute_dynamic_p { name value } {
    Checks whether the value (assumed to be an integer) is an
    attribute of a dynamic type.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/30/2000

} {
    if { [db_string attribute_for_dynamic_object_p {
	select case when exists (select 1 
                                   from acs_attributes a, acs_object_types t
                                  where t.dynamic_p = 't'
                                    and a.object_type = t.object_type
                                    and a.attribute_id = :value)
	            then 1 else 0 end
	  from dual
    }] } {
	return 1
    }
    ad_complain "Attribute does not belong to a dynamic object and cannot be modified"
    return 0
}


namespace eval attribute { 


ad_proc -public exists_p {
    { -convert_p "t" }
    object_type
    orig_attribute
} {
    Returns 1 if the object type already has an attribute of the given name.
    
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

    @param convert_p If <code>t</code>, we convert the attribute using
    plsql_utility::generate_oracle_name

    @param orig_attribute The attribute in which we are
    interested. Note that if <code>convert_p</code> is set to
    <code>t</code>, we will internally look for the converted attribute
    name

    @return 1 if the object type already has an attribute of the
    specified name. 0 otherwise
    
} {
    if { $convert_p == "t" } {
	set attribute [plsql_utility::generate_oracle_name $orig_attribute]
    } else {
	set attribute $orig_attribute
    }
    
    set attr_exists_p [db_string attr_exists_p {
       select 1 from acs_attributes a 
       where (a.attribute_name = :attribute or a.column_name = :attribute)
       and a.object_type = :object_type
    } -default 0]
	
    if { $attr_exists_p || $convert_p == "f" } {
	# If the attribute exists, o
        return $attr_exists_p
    }    
    return [exists_p -convert_p f $object_type $orig_attribute]
}

ad_proc -public add {
    { -default "" }
    { -min_n_values "" }
    { -max_n_values "" }
    object_type
    datatype
    pretty_name
    pretty_plural
} {
    wrapper for the <code>acs_attribute.create_attribute</code>
    call. Note that this procedure assumes type-specific storage.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

    @return The <code>attribute_id</code> of the newly created
    attribute
    
} {
    
    set default_value $default

    # We always use type-specific storage. Grab the tablename from the
    # object_type
    if { ![db_0or1row select_table {
        select t.table_name
          from acs_object_types t
         where t.object_type = :object_type
    }] } {
        error "Specified object type \"$object_type\" does not exist"
    }
    
    # In OpenACS, where we care that SQL must be separate from code, we don't
    # use these annoying formatting procs on our SQL. We write out the queries in full. (ben)

    # Attribute name returned from this function will be oracle
    # friendly and is thus used as the column name
    set attribute_name [plsql_utility::generate_oracle_name $pretty_name]
    
#      set attr_list [list]
#      lappend attr_list [list "object_type" '$object_type']
#      lappend attr_list [list "attribute_name" '$attribute_name']
#      lappend attr_list [list "min_n_values" '$min_n_values']
#      lappend attr_list [list "max_n_values" '$max_n_values']
#      lappend attr_list [list "default_value" '$default']
#      lappend attr_list [list "datatype" '$datatype']
#      lappend attr_list [list "pretty_name" '$pretty_name']
#      lappend attr_list [list "pretty_plural" '$pretty_plural']
    
    # A note (by ben, OpenACS)
    # the queries are empty because they are pulled out later in db_exec_plsql
    
    set plsql [list]
    lappend plsql_drop [list "drop_attribute" "FOO" db_exec_plsql]
    lappend plsql [list "create_attribute" "FOO" db_exec_plsql]

    set sql_type [datatype_to_sql_type -default $default_value $table_name $attribute_name $datatype]
    
    lappend plsql_drop [list "drop_attr_column" "FOO" db_dml]
    lappend plsql [list "add_column" "FOO" db_dml]
    
    for { set i 0 } { $i < [llength $plsql] } { incr i } {
        set cmd [lindex $plsql $i]
        if { [catch $cmd err_msg] } {
            # Rollback what we've done so far. The loop contitionals are:
            #  start at the end of the plsql_drop list (Drop things in reverse order of creation)
            # execute drop statements until we reach position $i+1
            #  This position represents the operation on which we failed, and thus
            #  is not executed
            for { set inner [expr {[llength $plsql_drop] - 1}] } { $inner > $i + 1 } { set inner [expr {$inner - 1}] } {
                set drop_cmd [lindex $plsql_drop $inner]
                if { [catch $drop_cmd err_msg_2] } {
                    append err_msg "\nAdditional error while trying to roll back: $err_msg_2"
                    return -code error $err_msg
                }
            }
            return -code error $err_msg
        }
    }
    
    return [db_string select_attribute_id {
        select a.attribute_id
          from acs_attributes a
         where a.object_type = :object_type
           and a.attribute_name = :attribute_name
    }]

}


ad_proc -private datatype_to_sql_type { 
    { -default "" }
    table 
    column 
    datatype 
} {
    Returns the appropriate sql type for a table definitation
    based on the table, column, datatype, and default value. Note that for
    default values, this proc automatically generates appropriate
    constraint names as well.
    
    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

    @param default If specified, we add a default clause to the sql statement

} {
    set type ""
    set constraint ""
    
    switch $datatype {
        "string" { set type "varchar(1000)" }
        "boolean" { set type "char(1)"
                    set constraint "[plsql_utility::generate_constraint_name $table $column "ck"] check ($column in ('t','f'))" }
        "number" { set type "number" }
        "money" { set type "number (12,2)" }
        "date" { set type "date" }
        "text" { set type "varchar(4000)" }
        "integer" { set type "integer" }
        "enumeration" { set type "varchar(100)" }
        "keyword" { set type "varchar(1000)" }
        default {error "Unsupported datatype. Datatype $datatype is not implemented at this time"}
    }

    set sql "$type"
    
    if { $default ne "" } {
        # This is also pretty nasty - we have to make sure we
        # treat db literals appropriately - null is much different
        # than 'null' - mbryzek
        set vars [list null sysdate]
        if {[string tolower $default] ni $vars} {
            set default "'$default'"
        }
        append sql " default $default"
    }
    if { $constraint ne "" } {
        append sql " constraint $constraint"
    }
    return $sql
}


ad_proc -public delete { attribute_id } {
    Delete the specified attribute id and all its values. This is
    irreversible. Returns 1 if the attribute was actually deleted. 0
    otherwise.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

} { 
    
    # 1. Drop the column
    # 2. Drop the attribute
    # 3. Return
    
    if { ![db_0or1row select_attr_info {
        select a.object_type, a.attribute_name, 
               decode(a.storage,'type_specific',t.table_name,a.table_name) as table_name,
	       nvl(a.column_name, a.attribute_name) as column_name
          from acs_attributes a, acs_object_types t
         where a.attribute_id = :attribute_id
           and t.object_type = a.object_type
    }] } {
        # Attribute doesn't exist
        return 0
    }
    if { $table_name eq "" || $column_name eq "" } {
	# We have to have both a non-empty table name and column name
	error "We do not have enough information to automatically remove this attribute. Namely, we are missing either the table name or the column name"
    }

    set plsql [list]
    lappend plsql [list "drop_attribute" "FOO" "db_exec_plsql"]
    if { [db_column_exists $table_name $column_name] } {
        lappend plsql [list "drop_attr_column" "FOO" "db_dml"]
    }

    foreach cmd $plsql {
        {*}$cmd
    }
    
    return 1
}

ad_proc -public value_add {attribute_id enum_value sort_order} {
    adds the specified enumeration value to the attribute.

    @author Ben Adida (ben@openforce.net)
    @creation-date 08/2001

    @param attribute_id The attribute to which we are adding
    @param enum_value The value which we are adding to the enum
} {
    # Just insert it if we can
    db_dml insert_enum_value {
	insert into acs_enum_values
	(attribute_id, sort_order, enum_value, pretty_name)
	select :attribute_id, :sort_order, :enum_value, :enum_value
	from dual
	where not exists (select 1 
	from acs_enum_values v2
	where v2.pretty_name = :enum_value
	and v2.attribute_id = :attribute_id)
    }
}

ad_proc -public value_delete { attribute_id enum_value } {
    deletes the specified enumeration value from the attribute. The
    net effect is that this attribute will have one fewer options for
    acceptable values.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

    @param attribute_id The attribute from which we are deleting
    @param enum_value The value of we are deleting

} {
    # This function should remove all occurrences of the
    # attribute, but we don't do that now.
    
    if { ![db_0or1row select_last_sort_order {
        select v.sort_order as old_sort_order
          from acs_enum_values v
         where v.attribute_id = :attribute_id
           and v.enum_value = :enum_value
    }] } {
        # nothing to delete
        return
    }
    
    db_dml delete_enum_value {
        delete from acs_enum_values v
        where v.attribute_id = :attribute_id
        and v.enum_value = :enum_value
    }
    if { [db_resultrows] > 0 } {
        # update the sort order
        db_dml update_sort_order {
            update acs_enum_values v
               set v.sort_order = v.sort_order - 1
             where v.attribute_id = :attribute_id
               and v.sort_order > :old_sort_order
        }
    }

    return
    
}


ad_proc -public translate_datatype {
    datatype
} {
    translates the datatype into one that can be
    validated. Default datatype is text (when no validator is found)

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

} {
    if { [datatype_validator_exists_p $datatype] } {
	return $datatype
    }
    switch -- $datatype {
	boolean { set datatype "text" }
	keyword { set datatype "text" }
	money { set datatype "integer" }
	number { set datatype "integer" }
	string { set datatype "text" }
    }
    if { [datatype_validator_exists_p $datatype] } {
	return $datatype
    }
    # No validator exists... return text as default
    return "text"
}

ad_proc -public datatype_validator_exists_p {
    datatype
} { 

    Returns 1 if we have a validator for this datatype. 0
    otherwise. We currently do not support the "date" datatype and
    hardcoded support for enumeration. This
    is hardcoded in this procedure. Also, this procedure assumes that
    validators are procedures named
    <code>::template::data::validate::$datatype</code>

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

} {
    if {$datatype eq "date"} { 
	return 0
    }
    if {$datatype eq "enumeration"} { 
	return 1
    }
    if { [info commands "::template::data::validate::$datatype"] eq "" } {
	return 0
    }
    return 1
}

ad_proc -public array_for_type {
    { -start_with "acs_object" }
    { -include_storage_types {type_specific} }
    array_name
    enum_array_name
    object_type
} {

    Fills in 2 arrays used for displaying attributes

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 1/8/2001

    @param array_name The name of the array to hold the basic
    attribute information. The attributes defined are:
    <code>
      * array_name(pretty_name:$name) The pretty_name of the attribute 
      * array_name(id:$name) The attribute_id of the attribute 
      * array_name(datatype:$name) The datatype of the attribute
    </code>

    @param enum_array_name The name of the array to hold the pretty
    name of the values of an enumeration. This is only used when the
    datatype of the attribute_name is enumeration. This array is a
    mapping from "$attribute_name:enum_value" to value_pretty_name.

    @param object_type The object for which we are looking up
    attributes

    @return A list of all the names of attributes we looked up. This
    list can be used to iterated through the arrays: 
    <pre>
        set attr_list [attribute::array_for_type attr_props enum_values "group"]
	foreach key $attr_list {
	    set attribute_id $attr_props(id:$attribute_name)
	    ...
        }    
    </pre>

} { 
    upvar $array_name attr_props
    upvar $enum_array_name enum_values
    set attr_list [list]

    set storage_clause ""

    if {$include_storage_types ne ""} {
	set storage_clause "
          and a.storage in ('[join $include_storage_types "', '"]')"
    }

    db_foreach select_attributes "
	select nvl(a.column_name, a.attribute_name) as name, 
               a.pretty_name, a.attribute_id, a.datatype, 
               v.enum_value, v.pretty_name as value_pretty_name
	from acs_object_type_attributes a,
               acs_enum_values v,
               (select t.object_type, level as type_level
                  from acs_object_types t
                 start with t.object_type = :start_with
               connect by prior t.object_type = t.supertype) t 
         where a.object_type = :object_type
           and a.attribute_id = v.attribute_id(+)
           and t.object_type = a.ancestor_type $storage_clause
        order by type_level, a.sort_order
    " {
	# Enumeration values show up more than once...
	if {$name ni $attr_list} {
	    lappend attr_list $name
	    set attr_props(pretty_name:$name) $pretty_name
	    set attr_props(datatype:$name) $datatype
	    set attr_props(id:$name) $attribute_id
	}
	if {$datatype eq "enumeration"} {
	    set enum_values($name:$enum_value) $value_pretty_name
	}
    }
    return $attr_list
}

ad_proc -public multirow {
    { -start_with "acs_object" }
    { -include_storage_types {type_specific} }
    { -datasource_name "attributes" }
    { -object_type "" }
    { -return_url "" }
    object_id
} {
    Sets up a multirow datasource containing the attribute values of object_id.
    We only support specific storage attributes.
    We include all attributes of the object's type, or any of its supertypes,
    up to $start_with.
} {

    upvar $datasource_name attributes

    if {$object_type eq ""} {
	set object_type [db_string object_type_query {
	    select object_type from acs_objects where object_id = :object_id
	}]
    }

    if {$return_url eq ""} {
	set return_url "[ad_conn url]?[ad_conn query]"
    }

    # Build up the list of attributes for the type specific lookup
    set attr_list [attribute::array_for_type \
	    -start_with $start_with \
	    -include_storage_types $include_storage_types \
	    attr_props enum_values $object_type]

    # Build up a multirow datasource to present these attributes to the user
    template::multirow create $datasource_name pretty_name value export_vars

    set package_object_view [package_object_view \
	    -start_with "acs_object" \
	    $object_type]

    if { [array size attr_props] > 0 } {
	db_foreach attribute_select "
        select * 
          from ($package_object_view) 
         where object_id = :object_id
	" {
	    foreach key $attr_list {
		set col_value [set $key]
		set attribute_id $attr_props(id:$key)
		if { $attr_props(datatype:$key) eq "enumeration" && [info exists enum_values($key:$col_value)] } {
		    # Replace the value stored in the column with the
		    # pretty name for that attribute
		    set col_value $enum_values($key:$col_value)
		}
		template::multirow append $datasource_name $attr_props(pretty_name:$key) $col_value "id_column=$object_id&[export_vars {attribute_id return_url}]"
	    }
	}
    }
}

ad_proc -public add_form_elements {
    { -form_id "" }
    { -start_with "acs_object" }
    { -object_type "acs_object" }
    { -variable_prefix "" }
} {
    Adds form elements to the specified form_id.  Each form element
    corresponds to an attribute belonging to the given object_type.

    @param form_id ID of a form to add form elements to.
    @param start_with Object type to start with.  Defaults to acs_object.
    @param object_type Object type to extract attributes for.
    Defaults to acs_object.
    @param variable_prefix Variable prefix.
} {

    if {$form_id eq ""} {
	error "attribute::add_form_elements - form_id not specified"
    }

    if {$object_type eq ""} {
	error "attribute::add_form_elements - object type not specified"
    }

    if {$variable_prefix ne ""} {
	append variable_prefix "."
    }

    # pull out all the attributes up the hierarchy from this object_type
    # to the $start_with object type
    set attr_list_of_lists [package_object_attribute_list -start_with $start_with $object_type]

    foreach row $attr_list_of_lists {
	lassign $row  attribute_id . attribute_name pretty_name datatype required_p default
	# Might translate the datatype into one for which we have a
	# validator (e.g. a string datatype would change into text).
	set datatype [translate_datatype $datatype]

	if {$datatype eq "enumeration"} {
	    # For enumerations, we generate a select box of all the possible values
	    set option_list [db_list_of_lists select_enum_values {
		select enum.pretty_name, enum.enum_value
		from acs_enum_values enum
		where enum.attribute_id = :attribute_id 
		order by enum.sort_order
	    }]
	    if {$required_p == "f"} {
		# This is not a required option list... offer a default
		lappend option_list [list " (no value) " ""]
	    }
	    template::element create $form_id "$variable_prefix$attribute_name" \
		    -datatype "text" [ad_decode $required_p "f" "-optional" ""] \
		    -widget select \
		    -options $option_list \
		    -label "$pretty_name" \
		    -value $default
	} else {
	    template::element create $form_id "$variable_prefix$attribute_name" \
		    -datatype $datatype [ad_decode $required_p "f" "-optional" ""] \
		    -widget text \
		    -label $pretty_name \
		    -value $default
	}
    }
}

}

