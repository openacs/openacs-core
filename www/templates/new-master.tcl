ad_page_contract {

    OpenACS.org  homepage 

    @author modified by Patrick Colgan pat pat@museatech.net
    @creation-date 9/6/2001


} {
    { email "" }
} -properties {
    form_vars:onevalue
    allow_persistent_login_p:onevalue
    remember_password:onevalue
    name:onevalue
    first_names:onevalue
    email:onevalue
    home_url:onevalue
    home_url_name:onevalue
    oacs_admin_p:onevalue
    pkid:onevalue
}

oacs_set_login_vars

set pkid [ad_conn package_id]

if [template::util::is_nil title]     { set title        [ad_system_name]   }
if [template::util::is_nil signatory] { set signatory    [ad_system_owner] }
if ![info exists header_stuff]        { set header_stuff {}                }

if [template::util::is_nil context_bar] { set context_bar "" }


# Edit This Page - format the etp link for style sheet
set etp_link [etp::get_etp_link]
regsub "^<a" $etp_link "<a class=\"top\"" etp_link

# Setup for navigation bar

set top_dir [lindex [ns_conn urlv] 0]
set urlc [ns_conn urlc]

set n_registered_users [util_memoize {db_string select_n_users "select count(user_id) from users" -default "unknown"} 120]