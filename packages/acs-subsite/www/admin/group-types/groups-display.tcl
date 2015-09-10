# /packages/acs-subsite/www/admin/group-types/groups-display.tcl

ad_page_contract {

    Shows elements for a group

    @author mbryzek@arsdigita.com
    @creation-date Mon Jan  8 16:31:12 2001
    @cvs-id $Id$

} {
    group_type:notnull
} -properties {
    context:onevalue
    group_type_pretty_name:onevalue
    group_type:onevalue
    group_type_enc:onevalue
}

set user_id [ad_conn user_id]
set context [list [list "[ad_conn package_url]admin/group-types/" "Group types"] [list [export_vars -base one group_type] "One type"] "Groups"]
set group_type_enc [ad_urlencode $group_type]

if { ![db_0or1row select_type_info {
    select t.pretty_name as group_type_pretty_name
      from acs_object_types t
     where t.object_type = :group_type
}] } {
    ad_return_error "Error" "Group type, $group_type, does not exist"
    ad_script_abort
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
