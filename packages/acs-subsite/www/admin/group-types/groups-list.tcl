ad_page_contract {
    Group type list
} {
    group_type:notnull
}

# sets up datasource for groups-list.adp

set user_id    [ad_conn user_id]
set package_id [ad_conn package_id]

db_multirow groups select_groups {}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
