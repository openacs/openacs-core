<master>
<property name=title>Your Account is Restored</property>

<h2>Your Account is Restored</h2>

at @site_link@

<hr>

Your account has been restored.  You can log in now using your old
password:

<p>

<form action="user-login" method=post>
@export_vars@
Password:  <input type=password name=password size=20>
<input type=submit value="Login">
</form>

<p>

Note: If you've forgotten your password, <a
href="email-password.tcl?user_id=@user_id@">ask this server to email it
to @email@</a>.



