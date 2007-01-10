# Procs related to users to support testing of OpenACS and .LRN with
# Tclwebtest.
#
# @author Peter Marklund

namespace eval ::twt::user {}

ad_proc ::twt::user::get_users { {type ""} } {
    Return a list of emails for .LRN users of a certain type. If type
    is not specified, returns all .LRN users.
} {
    set user_emails [list]

    foreach user_data [get_test_data] {
        if { $type eq "" || \
                [string equal -nocase [lindex $user_data 4] $type] } {
            
            lappend user_emails [lindex $user_data 2]
        }
    }

    return $user_emails
}

ad_proc ::twt::user::get_random_users { type number } {
    Get emails for a random set of .LRN users of a certain type.
} {
    set email_list [get_users $type]

    return [::twt::get_random_items_from_list $email_list $number]
}

ad_proc ::twt::user::get_password { email } {

    if {$email eq [::twt::config::admin_email]} {
        return [::twt::config::admin_password]
    } else {
        global __demo_users_password
        return $__demo_users_password
    }
}

ad_proc ::twt::user::login { email } {

    ::twt::user::logout

    # Request the start page
    ::twt::do_request "[::twt::config::server_url]/register"

    # Login the user
    form find ~n login
    field find ~n email
    field fill "$email"
    field find ~n password
    field fill [get_password $email]
    form submit
}

ad_proc ::twt::user::logout {} {
    ::twt::do_request "[::twt::config::server_url]/register/logout"
}

ad_proc ::twt::user::login_site_wide_admin {} {

    ::twt::user::login [::twt::config::admin_email]
}

ad_proc ::twt::user::add { 
    server_url 
    first_names 
    last_name 
    email 
    id
    type
    full_access
    guest
} {
    ::twt::do_request "/dotlrn/admin/users"
    link follow ~u "user-add"

    form find ~a "/dotlrn/user-add"
    field find ~n "email"
    field fill $email
    field find ~n "first_names"
    field fill $first_names
    field find ~n "last_name"
    field fill $last_name
    field find ~n "password"
    field fill [get_password $email]
    field find ~n "password_confirm"
    field fill [get_password $email]
    form submit

    form find ~n add_user
    ::twt::multiple_select_value type $type
    ::twt::multiple_select_value can_browse_p $full_access
    ::twt::multiple_select_value guest_p $guest
    form submit    
}

ad_proc ::twt::user::get_test_data {} {

    # Let's cache the data
    global __users_data
    
    if { [info exists __users_data] } {
        return $__users_data
    }

    global __dotlrn_users_data_file

    set file_id [open "$__dotlrn_users_data_file" r]
    set file_contents [read -nonewline $file_id]
    set file_lines_list [split $file_contents "\n"]

    set return_list [list]

    foreach line $file_lines_list {
	set fields_list [split $line ","]

	# Allow commenting of lines with hash
	if { ![regexp {\#.+} "[string trim [lindex $fields_list 0]]" match] } {
            # Get the first 6 items without leading/trailing space
            set trimmed_list [list]
            foreach item [lrange $fields_list 0 6] {
                lappend trimmed_list [string trim $item]
            }

	    lappend return_list $trimmed_list
	}
    }

    set __users_data $return_list

    return $return_list
}

ad_proc ::twt::user::upload_users { server_url } {

    set users_data_list [get_test_data]

    foreach user_data $users_data_list {

	    ::twt::user::add $server_url \
		    [lindex $user_data 0] \
		    [lindex $user_data 1] \
		    [lindex $user_data 2] \
		    [lindex $user_data 3] \
		    [lindex $user_data 4] \
		    [lindex $user_data 5] \
		    [lindex $user_data 6]

    }

    # We want the users to have a known password so people can log in with them
    set_passwords $server_url

    # Since Einstein will be posting in all classes
    # we make him site-wide-admin
    ::twt::user::make_site_wide_admin albert_einstein@dotlrn.test
}

ad_proc ::twt::user::set_passwords { server_url } {
    
    foreach user_email [get_users] {
        # User admin page
        ::twt::do_request "/dotlrn/admin/users"

        form find ~a "users-search"
        field fill $user_email ~n name    
        form submit

        # User workspace
        link follow ~u {user\?}

        # change password
        link follow ~u {password-update\?}

        form find ~a password-update-2
        field fill [get_password $user_email] ~n password_1
        field fill [get_password $user_email] ~n password_2
        form submit
    }
}

ad_proc ::twt::user::make_site_wide_admin { email } {
    ::twt::do_request [::twt::dotlrn::get_user_admin_url $email]

    # Do nothing if the user is already site-wide-admin
    catch {link follow ~u {site-wide-admin-toggle.*value=grant}}
}