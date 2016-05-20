# /packages/mbryzek-subsite/www/admin/attributes/delete.tcl

ad_page_contract {

    Deletes attribute

    @author mbryzek@arsdigita.com
    @creation-date Sun Nov 12 18:03:50 2000
    @cvs-id $Id$

} {
    attribute_id:notnull,naturalnum,attribute_dynamic_p
    { return_url:localurl "" }
} -properties {
    context:onevalue
    attribute_id:onevalue
    object_type:onevalue
    attribute_pretty_name:onevalue
    export_form_vars:onevalue
}

set context [list [list [export_vars -base one attribute_id] "One attribute"] "Delete attribute"]

db_1row select_object_type {
    select a.object_type, a.pretty_name as attribute_pretty_name
      from acs_attributes a  
     where a.attribute_id = :attribute_id
}

set export_form_vars [export_vars -form {attribute_id return_url}]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
