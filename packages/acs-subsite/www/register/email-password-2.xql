<?xml version="1.0"?>
<queryset>

    <fullquery name="select_email">
        <querytext>
            select email
            from cc_users
            where user_id = :user_id
        </querytext>
    </fullquery>

    <fullquery name="select_answer_matches_p">
        <querytext>
            select count(*)
            from dual
            where exists (select 1
                          from users
                          where user_id = :user_id
                          and password_answer = :answer)
        </querytext>
    </fullquery>

    <fullquery name="select_names_match_p">
        <querytext>
            select count(*)
            from dual
            where exists (select 1
                          from persons
                          where first_names = :first_names
                          and last_name = :last_name)
        </querytext>
    </fullquery>

</queryset>
