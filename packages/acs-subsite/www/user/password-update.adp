<master>
<property name="title">Update Password</property>
<property name="context_bar">for @first_names@ @last_name@ in @site_link@</property>
<property name="focus">@focus@</property>

<if @expired_p@ true>
  <p>
    Welcome to @system_name@. 
  </p>
  <p>
    Your login was successful, but your password has expired, and must
    be updated now, before you can proceed to use @system_name@.
  </p>
</if>

<form method="post" action="password-update-2" name="pwd">
  @export_vars@

<table>

<if @admin_p@ false and @password_old@ eq "">
  <tr>
    <th>Current Password:</th>
    <td><input type="password" name="password_old" size="15" /></td>
  </tr>
</if>
<else>
  <input type="hidden" name="password_old" value="@password_old@" />
</else>

  <tr>
    <th>New Password:</th>
    <td><input type="password" name="password_1" size="15" /></td>
  </tr>

  <tr>
    <th>Confirm:</th>
    <td><input type="password" name="password_2" size="15" /></td>
  </tr>
</table>

<p><center>
  <input type="submit" value="Update" />
</center>
</p>
</form>
