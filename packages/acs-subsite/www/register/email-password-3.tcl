ad_page_contract {
    When a user hasn't entered in the customized question/answer

    @author Hiro Iwashima <iwashima@mit.edu>
    @creation-date 15 Aug 2000
    @cvs-id $ID$
} {
    user_id:integer
    first_names
    last_name
    question
    answer
    email
} -properties {
    system_name:onevalue
    email:onevalue
}

if {![db_0or1row select_person_name {}]} {
    ad_return_error "Couldn't find user $user_id" "Couldn't find user $user_id. This is probably a bug in our code."
    return
}

if {![string equal -nocase $first_names $db_first_names] && ![string equal -nocase $last_name $db_last_name]} {
    ad_return_error "Validation Check Failed" "The full name given didn't match. There must be something wrong."
    return
}

if {![empty_string_p $password_question]} {
    ad_return_error "Customized question already there" "Customized question is already entered"
    return
}

db_dml update_question {}

set system_name [ad_system_name]

ad_return_template
