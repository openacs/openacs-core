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
    ad_return_error "[_ acs-subsite.Feature_disabled]" "[_ acs-subsite.lt_This_feature_is_disab]"
    return
}

if {![db_0or1row select_email {}]} {
    db_release_unused_handles
    ad_return_error "[_ acs-subsite.lt_Couldnt_find_user_use]" "[_ acs-subsite.lt_Couldnt_find_user_use_1]"
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
        "[_ acs-subsite.Unauthorized_Access]" \
        "[_ acs-subsite.lt_The_validation_didnt_]"
    return
}

set require_question_p [ad_parameter "RequireQuestionForPasswordResetP" security 0]

# generate a random password
set password [ad_generate_random_string]
ad_change_password $user_id $password

set system_owner [ad_system_owner]
set system_name [ad_system_name]
set reset_password_url "[ad_url]/user/password-update?[export_vars {user_id {password_old $password}}]" 

set subject "[_ acs-subsite.lt_Your_forgotten_passwo]"
set body "[_ acs-subsite.lt_Please_follow_the_fol]"

# Send email
if [catch {ns_sendmail $email $system_owner $subject $body} errmsg] {
    ad_return_error \
        "[_ acs-subsite.Error_sending_mail]" \
        "[_ acs-subsite.lt_Now_were_really_in_tr]
<blockquote>
  <pre>
    $errmsg
  </pre>
</blockquote>
[_ acs-subsite.lt_when_trying_to_send_y]
<blockquote>
  <pre>
[_ acs-subsite.Subject] $subject

$body
  </pre>
</blockquote>
"
    return
}

ad_return_template
