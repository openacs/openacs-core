<master>
<property name="title">Bad Password</property>
<property name="context_bar">in <a href="/index">@system_name@</a></property>

<p>The password you typed doesn't match what we have in the database.
If you think you made a typo, please back up using your browser and
try again.</p>

<if @email_forgotten_password_p@ eq 1>
<p>If you've forgotten your password, you can
    <a href=email-password?user_id=@user_id@>ask this server to reset
    your password and email a new randomly generated password to you</a>.</p>
</if>


