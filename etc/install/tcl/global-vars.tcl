# Global variables used by the test procs to reduce the number
# of parameters we need to pass around to the procs.
#
# @author Peter Marklund

# TODO: put variables in twt namespace

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
