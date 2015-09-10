# /packages/mbryzek-subsite/www/admin/rel-types/roles.tcl

ad_page_contract {

    Shows all roles with links to add/delete

    @author mbryzek@arsdigita.com
    @creation-date Mon Dec 11 11:08:34 2000
    @cvs-id $Id$

} {
} -properties {
    context:onevalue
    
}

set context [list [list "../" "Relationship types"] "Roles"]

db_multirow roles select_roles {
    select r.role, r.pretty_name, nvl(num1.number_rels,0) + nvl(num2.number_rels,0) as number_rel_types
      from (select t.role_one as role, count(*) as number_rels
             from acs_rel_types t
            group by t.role_one) num1,
           (select t.role_two as role, count(*) as number_rels
             from acs_rel_types t
            group by t.role_two) num2,
           acs_rel_roles r
     where r.role = num1.role(+)
       and r.role = num2.role(+)
     order by lower(r.role)
} {
    # The role pretty names can be message catalog keys that need
    # to be localized before they are displayed
    set pretty_name [lang::util::localize $pretty_name]
}

ad_return_template



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
