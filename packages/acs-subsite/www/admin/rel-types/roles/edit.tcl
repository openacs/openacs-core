# /packages/mbryzek-subsite/www/admin/rel-types/roles/edit.tcl

ad_page_contract {

    Form to edit a role

    @author mbryzek@arsdigita.com
    @creation-date Wed Dec 13 10:20:29 2000
    @cvs-id $Id$

} {
    role:notnull
    { return_url "" }
} -properties {
    context:onevalue
    
}

db_1row select_role_props {
    select r.pretty_name, r.pretty_plural
      from acs_rel_roles r 
     where r.role = :role
}

set context [list [list "../" "Relationship types"] [list "one?[ad_export_vars role]" "One role"] "Edit"]

template::form create role_form

template::element create role_form return_url \
	-optional \
	-value $return_url \
	-datatype text \
	-widget hidden

template::element create role_form role \
	-value $role \
	-datatype text \
	-widget hidden

template::element create role_form pretty_name \
	-label "Pretty name" \
	-value $pretty_name \
	-datatype text \
	-html {maxlength 100}

template::element create role_form pretty_plural \
	-label "Pretty plural" \
	-value $pretty_plural \
	-datatype text \
	-html {maxlength 100}

if { [template::form is_valid role_form] } {
    db_dml update_role {
	update acs_rel_roles r
	   set r.pretty_name = :pretty_name,
	       r.pretty_plural = :pretty_plural
	 where r.role = :role
    } -bind [ns_getform]
    if { $return_url eq "" } {
	set return_url "one?[ad_export_vars role]"
    }
    ad_returnredirect $return_url
    ad_script_abort
}
