<?xml version="1.0"?>
<queryset>

    <fullquery name="select_person_name">
        <querytext>
            select first_names as db_first_names,
                   last_name as db_last_name,
                   password_question
            from cc_users
            where user_id = :user_id
        </querytext>
    </fullquery>

    <fullquery name="update_question">
        <querytext>
            update users
            set password_question = :question,
                password_answer = :answer
            where user_id = :user_id
        </querytext>
    </fullquery>

</queryset>
