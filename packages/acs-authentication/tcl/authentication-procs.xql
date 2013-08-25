<?xml version="1.0"?>
<queryset>

<fullquery name="auth::create_local_account_helper.update_question_answer">
      <querytext>

            update users
            set    password_question = :password_question,
                   password_answer = :password_answer
            where  user_id = :user_id

      </querytext>
</fullquery>

</queryset>
