<master>
<property name="title">#acs-subsite.Register#</property>



#acs-subsite.lt_Register_as_a_user_of# <a href="index">@system_name@</a>

<form method=post action="user-new-2">
@export_vars;noquote@

<if @no_require_password_p@ eq 0>

  <h3>#acs-subsite.Security#</h3>

  #acs-subsite.lt_We_need_a_password_fr#

  <p>
  <table>
  <tr>
    <td>#acs-subsite.Password#</td>
    <td><input type="password" name="password" value="@password@" size="10" /></td>
  </tr>
  <tr>
    <td>#acs-subsite.lt_Password_Confirmation#</td>
    <td><input type="password" name="password_confirmation" size="10" /></td>
  </tr>
  </table>
  <p>

  #acs-subsite.lt_Leading_or_trailing_s#

</if>
<else>
  <h3>#acs-subsite.Security#</h3>

  #acs-subsite.lt_We_will_generate_and_#
  <input type="hidden" name="password" value="somevalue" />
  <input type="hidden" name="password_confirmation" value="othervalue" />
</else>

<h3>#acs-subsite.About_You#</h3>

#acs-subsite.lt_We_know_your_email_ad#

<p>

#acs-subsite.Full_Name#    <input type="text" name="first_names" size="20" value="@first_names@" /> <input type="text" name="last_name" size="25" value="@last_name@" />
<p>

<if @require_question_p@ true and @custom_question_p@ true>

  #acs-subsite.lt_We_also_need_a_custom#

  <p>
  
  #acs-subsite.Question# <input type="text" name="question" size="30" /><br>
  #acs-subsite.Answer# <input type="text" name="answer" size="30" />

  <p>

</if>

#acs-subsite.lt_If_you_have_a_Web_sit#

<p>

#acs-subsite.lt_Personal_Home_Page_UR#  <input type="text" name="url" size="50" value="http://">

<p>

<center>
<input type="submit" value="#acs-subsite.Register#">
</center>
</form>



