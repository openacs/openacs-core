<master>
<property name="title">Update Password</property>

<h2>Update Password</h2>

for @first_names@ @last_name@ in @site_link@

<hr>

<p>@locals@</p>

<form method="post" action="password-update-2">
  <input type="hidden" name="user_id" value="@user_id@">
  <input type="hidden" name="return_url" value="@return_url@">

<table>

<if @admin_p@ false and @password_old@ eq "">
  <tr>
    <th>Current Password:</th>
    <td><input type="password" name="password_old" size="15"></td>
  </tr>
</if>
<else>
  <input type="hidden" name="password_old" value=@password_old@>
</else>

  <tr>
    <th>New Password:</th>
    <td><input type="password" name="password_1" size="15"></td>
  </tr>

  <tr>
    <th>Confirm:</th>
    <td><input type="password" name="password_2" size="15"></td>
  </tr>
</table>

<br>
<br>

<center>
  <input type="submit" value="Update">
</center>
</form>
