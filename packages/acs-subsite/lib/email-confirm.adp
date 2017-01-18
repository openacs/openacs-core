
<if @user_info.email_verified_p;literal@ true>

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

</if>
<else>

  <property name="doc(title)">#acs-subsite.Email_not_Requested#</property>

  <p> #acs-subsite.lt_We_were_not_awaiting_# </p>

  <p> #acs-subsite.lt_Please_try_to_a_hrefi# </p>
    
</else>

