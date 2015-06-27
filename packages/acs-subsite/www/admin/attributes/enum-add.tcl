# /packages/mbryzek-subsite/www/admin/attribute-add.tcl

ad_page_contract {

    Adds attributes

    @author mbryzek@arsdigita.com
    @creation-date Tue Nov  7 12:14:42 2000
    @cvs-id $Id$

} {
    attribute_id:naturalnum,notnull
    { return_url "" }
} -properties {
    context:onevalue
    export_vars:onevalue
    attribute_pretty_name:onevalue
    attribute_src:multirow
    max_values:onevalue
}

set number_values [db_string number_values {
    select count(*) 
      from acs_enum_values v
     where v.attribute_id = :attribute_id
}]

# Set up datasource of existing attribute values

db_multirow current_values select_current_values {
    select v.enum_value
      from acs_enum_values v
     where v.attribute_id = :attribute_id
     order by v.sort_order
}

set max_values 5
# Set up a datasource to enter multiple attributes

template::multirow create value_form sort_order field_name

for { set i 1 } { $i <= $max_values } { incr i } {
    template::multirow append value_form [expr {$i + $number_values}] "attribute_enum_values.[expr {$i + $number_values}]"
}

db_1row select_attr_name {
    select a.pretty_name as attribute_pretty_name
      from acs_attributes a
     where a.attribute_id = :attribute_id
}

set context [list [list [export_vars -base one {attribute_id}] "One attribute"] "Add values"]

set export_vars [export_vars -form {attribute_id return_url}]

ad_return_template
