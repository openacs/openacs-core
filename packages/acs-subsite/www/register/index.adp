<master>
<property name=title>Log In</property>
<property name=focus>login.email</property>
<property name="context_bar">to <a href="/">@system_name@</a></property>

<p><strong>Current users:</strong> Please enter your email and password below.</p>
<p><strong>New users:</strong>  Welcome to @system_name@.  Please begin the
registration process by entering a valid email address and a
password for signing into the system.  We will direct you to another form to 
complete your registration.</p>

<form method="post" action="user-login" name="login">
@export_vars@
<table>
<tr><td>Your email address:</td><td><input type="text" name="email" value="@email@" /></td></tr>

<if @old_login_process@ eq 0>

 <tr><td>Your password:</td>
     <td><input type="password" name="password" /></td></tr>
 <if @allow_persistent_login_p@ eq 1>

   <tr><td colspan="2">
 
   <if @persistent_login_p@ eq 1>
       <input type="checkbox" name="persistent_cookie_p" value="1" checked="checked" /> 
   </if>
   <else>
       <input type="checkbox" name="persistent_cookie_p" value="1" /> 
   </else>
       	Remember this address and password?
	(<a href="explain-persistent-cookies">help</a>)</td></tr>
 </if>

</if>


<tr><td colspan="2" align="center"><input type="submit" value="Submit" /></td></tr>
</table>

</form>

<if @email_forgotten_password_p@ eq 1>
<p>
Have you <a href="email-for-password">forgotten your password?</a>
</p>
</if>
<p>If you keep getting thrown back here, it is probably because your
browser does not accept cookies.  We're sorry for the inconvenience
but it really is impossible to program a system like this without
keeping track of who is posting what.</p>

<p>
In Netscape 4.0, you can enable cookies from Edit -&gt; Preferences
-&gt; Advanced.  In Microsoft Internet Explorer 4.0, you can enable cookies from View -&gt; Internet Options -&gt; Advanced -&gt; Security.
</p>
