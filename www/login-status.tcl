set user_id [ad_conn user_id]

if { $user_id != 0 } {
    set user_name [person::name -person_id $user_id]
}

set pvt_home_url [ad_pvt_home]

if {[ad_conn url] eq $pvt_home_url} {
    set pvt_home_url {}
}

set pvt_home_name [ad_pvt_home_name]

set login_url "/register/.?[export_vars { { return_url [ad_return_url]} }]"
set logout_url "/register/logout"
