# /www/pvt/set-on-vacation-to-null.tcl
ad_page_contract {
    Set on vacation to null.

    @author Multiple
    @cvs-id $Id$
} -properties {
    site_link:onevalue
    home_link:onevalue
}

set user_id [ad_conn user_id]

db_dml pvt_unset_no_alerts_until {
    update users 
    set no_alerts_until = null
    where user_id = :user_id
}

set site_link [ad_site_home_link]
set home_link [ad_pvt_home_link]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
