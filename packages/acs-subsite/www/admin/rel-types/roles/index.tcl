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

db_multirow roles select_roles {} {
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
