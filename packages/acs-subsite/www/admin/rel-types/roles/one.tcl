# /packages/mbryzek-subsite/www/admin/rel-types/roles/one.tcl

ad_page_contract {

    Shows one role

    @author mbryzek@arsdigita.com
    @creation-date Mon Dec 11 11:08:34 2000
    @cvs-id $Id$

} {
    role:notnull
} -properties {
    context:onevalue
    role:onevalue
    role_enc:onevalue
    role_props:onerow
    rels_side_one:multirow
    rels_side_two:multirow
}

set role_enc [ad_urlencode $role]
set context [list [list "../" "Relationship types"] [list "[ad_conn package_url]admin/rel-types/roles/" "Roles"] "One role"]

if { ![db_0or1row select_role_props {
    select r.pretty_name, r.pretty_plural
      from acs_rel_roles r 
     where r.role = :role
} -column_array role_props] } {
    ad_return_error "Role doesn't exist" "The role \"$role\" could not be found."
    ad_script_abort
}

# The role pretty names can be message catalog keys that need
# to be localized before they are displayed
set role_props(pretty_name) [lang::util::localize $role_props(pretty_name)]
set role_props(pretty_plural) [lang::util::localize $role_props(pretty_plural)]

db_multirow rels select_rel_types_one {
    select r.rel_type as role, t.pretty_name, r.rel_type,
           decode(r.role_one,:role,'Side one', 'Side two') as side
      from acs_object_types t, acs_rel_types r
     where t.object_type = r.rel_type
       and (r.role_one = :role or r.role_two = :role)
     order by side, t.pretty_name
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
