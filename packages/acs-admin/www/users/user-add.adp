<master>
<property name=title>Add a user</property>

<h2>Add a user</h2>

@context_bar@

<hr>

<form action=user-add-2 method=post>
@export_vars@
<input type="hidden" name="referer" value="@referer@"></input>
<table>
<tr><td>Email:</td><td><input type=text name=email size=20 maxlength=40></td></tr>
<tr><td>Full Name:</td><td><input type=text name=first_names size=25 maxlength=40> <input type=text name=last_name size=25 maxlength=40></td></tr>
<tr><td>Password:</td><td><input type=password name=password size=10></td></tr>
<tr><td>Password confirmation:</td><td><input type=password name=password_confirmation size=10></td></tr>
<tr><td colspan=2><blockquote><font size=-1><em>(If you don't provide a password, a random password will be generated.)</em></font></blockquote></td></tr>
</table>
<P>
<center>
<input type=submit value="Add User">
</center>

</form>
<p>


