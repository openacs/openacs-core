ad_page_contract {
    Verifies the person's answer, whether it's their customized answer
    or their full name

    @author Hiro Iwashima <iwashima@mit.edu>
    @creation-date 15 Aug 2000
    @cvs-id $Id$
} {
    user_id:integer,notnull
    {validated_p 0}
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

if {![db_0or1row select_email {}]} {
    db_release_unused_handles
    ad_return_error "Couldn't find user $user_id" "Couldn't find user $user_id. This is probably a bug in our code."
    return
}

set ask_question_p 0
if {!$validated_p} {
    if {[exists_and_not_null answer]} {
        if {[db_string select_answer_matches_p {}]} {
            set validated_p 1
        }
    } else {
        if {[db_string select_names_match_p {} -default 0]} {
            set validated_p 1
        }

        if {[ad_parameter UseCustomQuestionForPasswordReset security 1]} {
            set ask_question_p 1
        }
    }
}

if {!$validated_p} {
    ad_return_error \
        "Unauthorized Access" \
        "The validation didn't match what we had. Either press back on the browser and retype it in, or <a href=\"/register\">go back to the login page</a>."
    return
}

set require_question_p [ad_parameter "RequireQuestionForPasswordResetP" security 0]

# generate a random password
set password [ad_generate_random_string]
ad_change_password $user_id $password

set system_owner [ad_system_owner]
set system_name [ad_system_name]

set subject "Your forgotten password on $system_name"
set body "Please follow the following link to reset your password:

[ad_url]/user/password-update?return_url=/&[export_vars {user_id {password_old $password}}]

"

# Send email
if [catch {ns_sendmail $email $system_owner $subject $body} errmsg] {
    ad_return_error \
        "Error sending mail" \
        "Now we're really in trouble because we got this error:
<blockquote>
  <pre>
    $errmsg
  </pre>
</blockquote>
when trying to send you the following email:
<blockquote>
  <pre>
Subject: $subject

$body
  </pre>
</blockquote>
"
    return
}

ad_return_template
