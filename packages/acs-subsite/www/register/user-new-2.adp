<master>
<property name=title>@title@</property>

<if @email_verified_p@ eq f>

<h2>Please read your email</h2>

<hr>

Registration information for this service has been
sent to @email@.
<p>
Please read and follow the instructions in this email.

</if>
<else>

<h2>Awaiting Approval</h2>

<hr>

Your registration is in the database now.  A site administrator has
been notified of your request to use the system.  Once you're
approved, you'll get an email message and you can return to
@site_link@ to use the service.

</else>
