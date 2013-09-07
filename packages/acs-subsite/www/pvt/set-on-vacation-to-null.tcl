# /www/pvt/set-on-vacation-to-null.tcl
ad_page_contract {
    Set on vacation to null.

    @author Multipe
    @cvs-id $Id$
} -properties {
    site_link:onevalue
    home_link:onevalue
}

set user_id [ad_conn user_id]

set no_alerts_until [db_string no_alerts_until {
    select no_alerts_until from users where user_id = :user_id
} -default ""] 

if { $no_alerts_until ne "" } {
    set clear [db_null] 
    db_dml pvt_unset_no_alerts_until {
	    update users 
	    set no_alerts_until = :clear
	    where user_id = :user_id
    }
}

set site_link [ad_site_home_link]
set home_link [ad_pvt_home_link]

ad_return_template
