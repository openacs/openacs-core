<master>
<property name="title">#acs-subsite.Update_Password#</property>
<property name="context_bar">#acs-subsite.lt_for_first_names_last_#</property>

<form method="post" action="password-update-2">
  <input type="hidden" name="user_id" value="@user_id@" />
  <input type="hidden" name="return_url" value="@return_url@" />

<table>

<if @admin_p@ false and @password_old@ eq "">
  <tr>
    <th>#acs-subsite.Current_Password#</th>
    <td><input type="password" name="password_old" size="15" /></td>
  </tr>
</if>
<else>
  <input type="hidden" name="password_old" value="@password_old@" />
</else>

  <tr>
    <th>#acs-subsite.New_Password#</th>
    <td><input type="password" name="password_1" size="15" /></td>
  </tr>

  <tr>
    <th>#acs-subsite.Confirm#</th>
    <td><input type="password" name="password_2" size="15" /></td>
  </tr>
</table>

<p><center>
  <input type="submit" value="#acs-subsite.Update#" />
</center>
</p>
</form>
