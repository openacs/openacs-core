<master>
<property name="title">#acs-subsite.Log_In#</property>
<property name="focus">login.email</property>
<property name="context_bar">#acs-subsite.to# <a href="/">@system_name@</a></property>

<p><strong>#acs-subsite.Current_users#</strong> #acs-subsite.lt_Please_enter_your_ema#</p>
<p><strong>#acs-subsite.New_users#</strong> #acs-subsite.lt_welcome_please_register#</p>

<form method="post" action="user-login" name="login">
@export_vars@
<table>
<tr><td>#acs-subsite.Your_email_address#</td><td><input type="text" name="email" value="@email@" /></td></tr>

<if @old_login_process@ eq 0>
  <tr>
    <td>#acs-subsite.Your_password#</td>
    <td><input type="password" name="password" /></td>
  </tr>
  <if @allow_persistent_login_p@ eq 1>
    <tr><td colspan="2">
    <if @persistent_login_p@ eq 1>
      <input type="checkbox" name="persistent_cookie_p" value="1" checked="checked" /> 
    </if>
    <else>
      <input type="checkbox" name="persistent_cookie_p" value="1" /> 
    </else>
    #acs-subsite.lt_Remember_this_address#
    (<a href="explain-persistent-cookies">#acs-subsite.help#</a>)</td></tr>
  </if>
</if>

<tr><td colspan="2" align="center"><input type="submit" value="Submit" /></td></tr>
</table>

</form>

<if @email_forgotten_password_p@ eq "1">
  <p>#acs-subsite.lt_Have_you_a_hrefemail-#</p>
</if>

<p>#acs-subsite.lt_no_cookies#</p>
<p>#acs-subsite.lt_enable_cookies#</p>

