ad_page_contract {

    Registration form for a new user.  The password property should be set using 
    <code>ad_set_client_property register</code>.

    @cvs-id  $Id$

} {
    email:notnull
    return_url:optional,nohtml
    { persistent_cookie_p 0 }
} -properties {
    system_name:onevalue
    export_vars:onevalue
    password:onevalue
    email:onevalue
}

set password [ad_get_client_property register password]

# Check if the email address makes sense.
# We check it here, because this is the last chance the user has to change it

if { ![util_email_valid_p $email] } {
    ad_return_complaint 1 "<li>The email address that you typed doesn't look right to us.  Examples of valid email addresses are 
<ul>
<li>Alice1234@aol.com
<li>joe_smith@hp.com
<li>pierre@inria.fr
</ul>"
    return
}

# we're going to ask this guy to register
if { ! [db_0or1row find_person {select party_id as user_id, first_names, last_name from parties join persons on party_id = person_id where lower(email) = lower(:email)} ] } {
    set user_id [db_nextval acs_object_id_seq]
    set first_names ""
    set last_name ""
} 

db_release_unused_handles

set system_name [ad_system_name]
set export_vars [export_form_vars email return_url user_id]
set no_require_password_p [ad_parameter RegistrationProvidesRandomPasswordP security 0]
set require_question_p [ad_parameter UseCustomQuestionForPasswordReset security 1]

ad_return_template



