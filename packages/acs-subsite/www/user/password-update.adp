<master>
  <property name="title">#acs-subsite.Update_Password#</property>
  <property name="context_bar">#acs-subsite.lt_for_first_names_last_#</property>
  <property name="context">#acs-subsite.Update_Password#</property>
  <property name="focus">pwd.old_password</property>
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
 <input type="hidden" name="return_url" value="@return_url@" /> <input type="hidden" name="user_id" value="@user_id@" />
<table>

<tr>
  <th>#acs-subsite.Current_Password#</th>
  <td><input type="password" name="old_password" size="15" /></td>
</tr>

<tr>
  <th>#acs-subsite.New_Password#</th>
  <td><input type="password" name="password_1" size="15" /></td>
</tr>

<tr>
  <th>#acs-subsite.Confirm#</th>
  <td><input type="password" name="password_2" size="15" /></td>
</tr>

<tr>
  <th></th>
  <td><input type="submit" value="#acs-subsite.Update#" /></td>
</tr>

</table>

</form>
