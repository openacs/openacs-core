ad_page_contract {

    @cvs-id $Id$
} {} -properties {
    site_link:onevalue
    on_vacation_p:onevalue
    pretty_no_alerts_until_date:onevalue
    date_entry_widget:onevalue
    parameter_enabled_p:onevalue
    dont_spam_me_p:onevalue
}

set user_id [ad_maybe_redirect_for_registration]

db_1row vacation_time "select no_alerts_until, acs_user.receives_alerts_p(:user_id) as on_vacation_p 
from users
where user_id = :user_id"

set site_link [ad_site_home_link]

set pretty_no_alerts_until_date [lc_time_fmt $no_alerts_until "%q"]
set date_entry_widget [ad_dateentrywidget_default_to_today on_vacation_until]

if [db_0or1row nospam "select dont_spam_me_p
from user_preferences
where user_id = :user_id"] {
    set parameter_enabled_p 1
} else {
    set parameter_enabled_p 0
}

ad_return_template
