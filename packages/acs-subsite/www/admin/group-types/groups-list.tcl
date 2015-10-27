# /packages/acs-subsite/www/admin/group-types/groups-list.tcl

# sets up datasource for groups-list.adp

if { (![info exists group_type] || $group_type eq "") } {
    error "Group type must be specified"
}

set user_id [ad_conn user_id]

set package_id [ad_conn package_id]

db_multirow groups select_groups {}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
