<master>
  <property name="title">#acs-subsite.Update_Password#</property>
  <property name="context_bar">#acs-subsite.lt_for_first_names_last_#</property>
  <property name="context">@context@</property>
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
  @export_vars;noquote@

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
