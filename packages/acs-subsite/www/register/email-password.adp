<master>
<property name=title>Email Password</property>

<H2>Confirmation of Resetting and Emailing New Password</H2>
<hr>

Please verify yourself by providing the information below:<br>

<form method=POST action="email-password-2">
<input type=hidden name=user_id value="@user_id@">

<if @question_answer_p@ eq 0>

Full Name: <input type=text name=first_names size=20> <input type=text name=last_name size=20>

</if>
<else>

@password_question@: <input type=text name=answer size=20>

</else>
    <br>
<input type=submit value="Reset and Email New Password">
</form>



