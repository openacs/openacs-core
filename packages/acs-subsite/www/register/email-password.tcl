ad_page_contract {
    Sends the user their password.  Depending on the configuration,
    this password may be a new random password.
    @cvs-id $Id$
} {
    user_id:integer
} -properties {
    user_id:onevalue
    question_answer_p:onevalue
    password_question:onevalue
}


if {![ad_parameter EmailForgottenPasswordP security 1]} {
    ad_return_error "Feature disabled" "This feature is disabled on this server."
    return    
}

set password_question [db_string question "select password_question from users where user_id = :user_id"]
if { [empty_string_p $password_question] } {
    # No question. User their full name
    set question_answer_p 0
} else {
    set question_answer_p 1
}

ad_return_template

