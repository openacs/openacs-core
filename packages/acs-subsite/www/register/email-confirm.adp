<master>
<property name=title>Email Confirmation</property>

<if @email_verified_p@ eq "f">

  <if @member_state@ eq "approved">

    <h2>Your email is confirmed</h2>
    at @site_link@
    <hr>
    Your email has been confirmed. You may now log into
    @system_name@.
    <p>
    <form action="index" method=post>
    @export_vars@
    <input type=submit value="Continue">
    </form>
    <p>
    Note: If you've forgotten your password, <a
    href="email-password.tcl?user_id=@user_id@">ask this server to email it
    to @email@</a>.

  </if>
  <else>

    <h2>Your email is confirmed</h2>
    at @site_link@
    <hr>
    Your email has been confirmed. You are now awaiting approval
    from the @system_name@ administrator.    

  </else>

</if>
<else>

  <h2>Email not Requested</h2>
  <hr>
  
  <p>We were not awaiting your email.  There must be some mistake.

  <p>Please try to <a href="index">log in</a> again
    
</else>

