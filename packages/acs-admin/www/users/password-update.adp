<master>
<property name="title">Update_Password</property>
<property name="context_bar">@context_bar@</property>


<form method="post" action="password-update-2">
  <input type="hidden" name="user_id" value="@user_id@">
  <input type="hidden" name="return_url" value="@return_url@">

<table>
  <tr>
    <th>New Password</th>
    <td><input type="password" name="password_1" size="15"></td>
  </tr>

  <tr>
    <th>Confirm</th>
    <td><input type="password" name="password_2" size="15"></td>
  </tr>
</table>

<br>
<br>

<center>
  <input type="submit" value="Update">
</center>
</form>

