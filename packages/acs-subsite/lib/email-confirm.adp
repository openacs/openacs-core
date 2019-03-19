
<property name="doc(title)">#acs-subsite.lt_Your_email_is_confirm#</property>

<if @user_info.member_state@ eq "approved">

  #acs-subsite.lt_Your_email_has_been_c#
  <p>
    <form action="index" method=post>
      @export_vars;noquote@
      <input type="submit" value="#acs-kernel.common_continue#">
    </form>

</if>
<else>

  <p> #acs-subsite.lt_Your_email_has_been_c_1# </p>

</else>
