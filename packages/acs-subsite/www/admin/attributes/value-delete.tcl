# /packages/mbryzek-subsite/www/admin/attributes/value-delete.tcl

ad_page_contract {

    Deletes a value

    @author mbryzek@arsdigita.com
    @creation-date Sun Dec 10 14:45:29 2000
    @cvs-id $Id$

} {
    attribute_id:naturalnum,notnull
    enum_value:trim,notnull
    { return_url [export_vars -base one attribute_id] }    
} -properties {
    context:onevalue
    export_vars:onevalue
    pretty_name:onevalue
}

if { ![db_0or1row select_pretty_name {
    select v.pretty_name
      from acs_enum_values v
     where v.attribute_id = :attribute_id
       and v.enum_value = :enum_value
}] } {
    # Already deleted
    ad_returnredirect $return_url
    ad_script_abort
}

set context [list [list [export_vars -base one attribute_id] "One attribute"] "Delete value"]
set export_vars [export_vars -form {attribute_id enum_value return_url}]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
