<master>
<property name="title">Your Account is Restored</property>


<p>Your Account at @site_link@ is restored.</p>

<p>You can log in now using your old
password:

<form action="user-login" method="post">
@export_vars@
Password:  <input type="password" name="password" size="20" />
<input type="submit" value="Login" />
</form>
</p>

<p>
Note: If you've forgotten your password, <a href="email-password.tcl?user_id=@user_id@">ask this server to email it
to @email@</a>.
</p>


