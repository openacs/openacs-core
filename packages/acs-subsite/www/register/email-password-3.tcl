ad_page_contract {
    When a user hasn't entered in the customized question/answer

    @author Hiro Iwashima <iwashima@mit.edu>
    @creation-date 15 Aug 2000
    @cvs-id $Id$
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
    ad_return_error "[_ acs-subsite.lt_Couldnt_find_user_use]" "[_ acs-subsite.lt_Couldnt_find_user_use_1]"
    return
}

if {![string equal -nocase $first_names $db_first_names] && ![string equal -nocase $last_name $db_last_name]} {
    ad_return_error "[_ acs-subsite.lt_Validation_Check_Fail]" "[_ acs-subsite.lt_The_full_name_given_d]"
    return
}

if {![empty_string_p $password_question]} {
    ad_return_error "[_ acs-subsite.lt_Customized_question_a]" "[_ acs-subsite.lt_Customized_question_i]"
    return
}

db_dml update_question {}

set system_name [ad_system_name]

ad_return_template
