<master>
<property name=title>Check Your Inbox</property>

Please check your inbox. Within the next few minutes, you should find
a message from @system_owner@ containing your password.

<br />

<if @ask_question_p@ eq 1 and @require_question_p@ eq 1>

  <form method="post" action="email-password-3.tcl">
    <input type="hidden" name="first_names" value="@first_names@" />
    <input type="hidden" name="last_name" value="@last_name@" />
    <input type="hidden" name="user_id" value="@user_id@" />
    <input type="hidden" name="email" value="@email@" />

    for future reference, please type in a question and an answer to use as
    verification.

    <br /><br />

    question: <input type="text" name="question" size="40" /><br />
    answer: <input type="text" name="answer" size="40" /><br />

    <input type="submit" value="Customize Question" />
  </form>

</if>
<else>

  Then come back to <a href="index?email=@email@">the login page</a> and use
  @system_name@.

</else>
