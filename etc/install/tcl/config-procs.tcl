# Procs to support testing OpenACS with Tclwebtest.
#
# Procs for getting config info. If those tests were to run
# from within OpenACS some of these procs could go away.
#
# @author Peter Marklund

namespace eval ::twt::config {}

####################
#
# Global variables
#
####################

# TODO: put variables in twt namespace

global __serverroot
set __serverroot $serverroot

global __server_url
set __server_url $server_url

global __admin_last_name
set __admin_last_name $admin_last_name

global __admin_email
set __admin_email $admin_email

global __admin_password
set __admin_password $admin_password

global __url_history
set __url_history [list]

global __demo_users_password
if { [info exists demo_users_password] } {
    set __demo_users_password $demo_users_password
} else {
    set __demo_users_password "guest"
}

global __dotlrn_users_data_file
if { [info exists dotlrn_users_data_file] } {
    set __dotlrn_users_data_file $dotlrn_users_data_file
} else {
    set __dotlrn_users_data_file users-data.csv
} 

global __alert_keyword
set __alert_keyword $alert_keyword

ad_proc ::twt::config::server_url { } {
    global __server_url

    return $__server_url
}

ad_proc ::twt::config::admin_email { } {
    global __admin_email

    return $__admin_email
}

ad_proc ::twt::config::admin_password { } {
    global __admin_password

    return $__admin_password
}

ad_proc ::twt::config::serverroot { } {
    global __serverroot

    return $__serverroot
}

ad_proc ::twt::config::alert_keyword { } {
    global __alert_keyword

    return $__alert_keyword
}
