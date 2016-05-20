# /packages/mbryzek-subsite/www/admin/attributes/edit-one.tcl

ad_page_contract {

    Edits one attribute

    @author mbryzek@arsdigita.com
    @creation-date Thu Nov  9 20:06:49 2000
    @cvs-id $Id$

} {
    attribute_id:naturalnum
    id_column:trim,integer
    { attribute_value "" }
    { return_url:localurl "" }
} -properties {
    context:onevalue
    focus:onevalue
    attribute_pretty_name:onevalue    
}

permission::require_permission -object_id $id_column -privilege "write"

set context [list "Edit attribute"]

db_1row attribute_properties {}
db_1row select_value {}

template::form create edit_attribute

template::element create edit_attribute attribute_id -value $attribute_id \
	-label "Attribute ID" -datatype text -widget hidden

template::element create edit_attribute object_type -value $object_type \
	-label "Object type" -datatype text -widget hidden

# add the space to avoid looking like a switch
template::element create edit_attribute id_column -value " $id_column" \
	-datatype text -widget hidden

template::element create edit_attribute return_url -value $return_url \
	-optional -datatype text -widget hidden


if {$datatype eq "enumeration"} {
    set focus ""
    set option_list [db_list_of_lists select_enum_values {
	select enum.pretty_name, enum.enum_value
	  from acs_enum_values enum
	 where enum.attribute_id = :attribute_id 
	 order by enum.sort_order
    }]
    if { $min_n_values == 0 } {
	# This is not a required option list... offer a default
	lappend option_list [list " (no value) " ""]
    }

    template::element create edit_attribute attribute_value \
	    -value $current_value \
	    -datatype "text" \
	    -widget select \
	    -optional \
	    -options $option_list \
	    -label "$attribute_pretty_name"
} else {
    set focus "edit_attribute.attribute_value"
    template::element create edit_attribute attribute_value \
	    -value $current_value \
	    -datatype "text" \
	    -optional \
	    -label "$attribute_pretty_name"
}

if { [template::form is_valid edit_attribute] } {
   
    set attribute_value [ns_set get [ns_getform] "attribute_value"]

    db_dml attribute_update \
	    "update $type_table 
                set $attribute_column = :attribute_value 
              where $type_column = :id_column"

    ad_returnredirect $return_url
    ad_script_abort
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
