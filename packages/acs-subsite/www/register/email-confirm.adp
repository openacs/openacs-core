<master>
<property name="title">#acs-subsite.Email_Confirmation#</property>
<property name="context">#acs-subsite.Email_Confirmation#</property>

<if @email_verified_p@ eq "f">

  <if @member_state@ eq "approved">

    <h2>#acs-subsite.lt_Your_email_is_confirm#</h2>
    #acs-subsite.at# @site_link@
    <hr>
    #acs-subsite.lt_Your_email_has_been_c#
    <p>
    <form action="index" method=post>
    @export_vars@
    <input type=submit value="Continue">
    </form>
    <p>
    #acs-subsite.lt_Note_If_youve_forgott_1#</a>.

  </if>
  <else>

    <h2>#acs-subsite.lt_Your_email_is_confirm#</h2>
    #acs-subsite.at# @site_link@
    <hr>
    #acs-subsite.lt_Your_email_has_been_c_1#    

  </else>

</if>
<else>

  <h2>#acs-subsite.Email_not_Requested#</h2>
  <hr>
  
  <p>#acs-subsite.lt_We_were_not_awaiting_#

  <p>#acs-subsite.lt_Please_try_to_a_hrefi#
    
</else>

