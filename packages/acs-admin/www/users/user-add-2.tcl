ad_page_contract {
    Processes a new user created by an admin
    @cvs-id $Id$
} -query {
    user_id
    email
    first_names
    last_name
    password
    password_confirmation
    {referer "/acs-admin/users"}
} -properties {
    context_bar:onevalue
    export_vars:onevalue
    system_name:onevalue
    system_url:onevalue
    first_names:onevalue
    last_name:onevalue
    email:onevalue
    password:onevalue
    administration_name:onevalue
}

set admin_user_id [ad_verify_and_get_user_id]

# email first_names last_name, user_id

# Error Count and List
set exception_count 0
set exception_text ""

# Check input

if {![info exists user_id] || [empty_string_p $user_id] } {
    incr exception_count
    append exception_text "<li>Your browser dropped the user_id variable or something is wrong with our code.\n"
}



if {![info exists email] || ![util_email_valid_p $email]} {
    incr exception_count
    append exception_text "<li>The email address that you typed doesn't look right to us.  Examples of valid email addresses are 
<ul>
<li>Alice1234@aol.com
<li>joe_smith@hp.com
<li>pierre@inria.fr
</ul>
"
} else {
    set email_count [db_string unused "select count(email)
from parties where email = lower(:email)
and party_id <> :user_id"]

    # note, we dont' produce an error if this is a double click
    if {$email_count > 0} {
	incr exception_count
	append exception_text "<li> $email was already in the database."
    }

}

if {![info exists first_names] || [empty_string_p $first_names]} {
    incr exception_count
    append exception_text "<li> You didn't enter a first name."
}

if {![info exists last_name] || [empty_string_p $last_name]} {
    incr exception_count
    append exception_text "<li> You didn't enter a last name."
}

if { ![string equal $password $password_confirmation] } {
    incr exception_count
    append exception_text "<li> The two passwords didn't match."
}

# We've checked everything.
# If we have an error, return error page, otherwise, do the insert

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

if { [empty_string_p $password] } {
    set password [ad_generate_random_string]
}

set user_id [ad_user_new $email $first_names $last_name $password "" "" "" "t" "approved" $user_id]

if { !$user_id && [db_string unused "select count(user_id) from users where user_id = :user_id"] == 0} {
    # not a double click, and it failed
    ad_return_error "Insert Failed" "We were unable to create your user record in the database.  Here's what the error looked like:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
return 
}


set administration_name [db_string admin_name "select
first_names || ' ' || last_name from persons where person_id = :admin_user_id"]

set context_bar [ad_admin_context_bar [list "index.tcl" "Users"] "Notify added user"]
set system_name [ad_system_name]
set export_vars [export_form_vars email first_names last_name user_id]
set system_url [ad_parameter -package_id [ad_acs_kernel_id] SystemURL ""].

ad_return_template
