# /packages/mbryzek-subsite/www/admin/attribute-add.tcl

ad_page_contract {

    Adds attributes

    @author mbryzek@arsdigita.com
    @creation-date Tue Nov  7 12:14:42 2000
    @cvs-id $Id$

} {
    object_type:notnull,trim
    pretty_name:notnull,trim
    pretty_plural:notnull,trim
    default_value:trim
    datatype:notnull,trim
    required_p:notnull
    { return_url "" }
} -properties {
    context:onevalue
    export_vars:onevalue
    pretty_name:onevalue
    datatypes:multirow
} -validate {
    dynamic_type -requires {object_type:notnull} {
	if { ![package_type_dynamic_p $object_type] } {
	    ad_complain "The specified object type, $object_type, is not dynamic and therefore cannot be modified."
	}
    }
}

# Let's see if the attribute already exists

if { [attribute::exists_p $object_type $pretty_name] } {
    ad_return_complaint 1 "<li> The specified attribute, $pretty_name, already exists"

    return
}

# Right now, we do not support multiple values for attributes
set max_n_values 1
if { [string eq $required_p "t"] } {
    set min_n_values 1
} else {
    set min_n_values 0
}

# Add the attributes to the specified object_type

db_transaction {
    set attribute_id [attribute::add -min_n_values $min_n_values -max_n_values $max_n_values -default $default_value $object_type $datatype $pretty_name $pretty_plural]

    # Recreate all the packages to use the new attribute
    package_recreate_hierarchy $object_type

}

# If we're an enumeration, redirect to start adding possible values.
if { [string equal $datatype "enumeration"] } {
    ad_returnredirect enum-add?[ad_export_vars {attribute_id return_url}]
} elseif { [empty_string_p $return_url] } {
    ad_returnredirect add?[ad_export_vars {object_type}]
} else {
    ad_returnredirect $return_url
}

