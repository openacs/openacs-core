ad_page_contract {
    Verifies the person's answer, whether it's their customized answer
    or their full name

    @author Hiro Iwashima <iwashima@mit.edu>
    @creation-date 15 Aug 2000
    @cvs-id $ID$
} {
    user_id:integer
    {answer ""}
    {first_names ""}
    {last_name ""}
} -properties {
    system_owner:onevalue
    system_name:onevalue
    ask_question_p:onevalue
    email:onevalue
    first_names:onevalue
    last_name:onevalue
    user_id:onevalue
}

if {![ad_parameter EmailForgottenPasswordP security 1]} {
    ad_return_error "Feature disabled" "This feature is disabled on this server."
    return    
}

if ![db_0or1row users_state_authorized_or_deleted "select 
email from cc_users where user_id=:user_id
-- and user_state in ('authorized','deleted')"] {
    db_release_unused_handles
    ad_return_error "Couldn't find user $user_id" "Couldn't find user $user_id.  This is probably a bug in our code."
    return
}

# Use exists

if [exists_and_not_null answer] {
    # There was a question
    set value [db_string password_answer "select password_answer from users where user_id = :user_id"]
    if {![string compare $value $answer]} {
	set validated_p 1
    } else {
	set validated_p 0
    }

    set ask_question_p 0

} else {
    # We check their first and last names
    
    db_0or1row first_last_name "select first_names db_first_names, last_name db_last_name from cc_users where user_id = $user_id"

    if { [string compare $first_names $db_first_names] || [string compare $last_name $db_last_name] } {
	set validated_p 0
    } else {
	set validated_p 1
    }
    
    if { [ad_parameter UseCustomQuestionForPasswordReset security 1] } {

	set ask_question_p 1

    }

}

if { $validated_p != 1 } {
    # Unauthorized Access
    ad_return_error "Unauthorized Access" "The validation didn't match what we had.  Either press back on the browser and retype it in, or <a href=\"/register\">go back to the login page</a>."
    return
}


#generate a random password
set password [ad_generate_random_string]
ad_change_password $user_id $password

# Send email
if [catch { ns_sendmail $email [ad_system_owner] "Your forgotten password on [ad_system_name]" "Here's how you can log in at [ad_url]:

Username:  $email
Password:  $password

"} errmsg] {
    ad_return_error "Error sending mail" "Now we're really in trouble because we got an error trying to send you email: 
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
    return
}

set system_owner [ad_system_owner]
set system_name [ad_system_name]

ad_return_template