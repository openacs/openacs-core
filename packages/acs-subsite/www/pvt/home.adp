<master>
  <property name=title>@page_title@</property>
  <property name="context">@context;noquote@</property>
  <property name="focus">user_info.first_names</property>

<h2>#acs-subsite.Basic_Information#</h2>

<include src="/packages/acs-subsite/lib/user-info">

<if @account_status@ eq "closed">
  #acs-subsite.Account_closed_workspace_msg#
</if>

<p>
  <b>&raquo;</b> <a href="../user/password-update">#acs-subsite.Change_my_Password#</a>
</p>

<if @change_locale_url@ not nil>
  <p>
    <b>&raquo;</b> <a href="@change_locale_url@">#acs-subsite.Change_locale_label#</a>
  </p>
</if>

<p>
  <b>&raquo;</b> <a href="@community_member_url@">#acs-subsite.lt_What_other_people_see#</a>
</p>

<if @account_status@ ne "closed">
  <p>
    <b>&raquo;</b> <a href="unsubscribe">#acs-subsite.Close_your_account#</a> 
  </p>
</if>

<if @portrait_state@ eq upload>
  <h2>#acs-subsite.Your_Portrait#</h2>
  <p>
    #acs-subsite.lt_Show_everyone_else_at#  <a href="@portrait_upload_url@">#acs-subsite.upload_a_portrait#</a>
  </p>
</if>
<if @portrait_state@ eq show>
  <h2>#acs-subsite.Your_Portrait#</h2>
  <p>
    #acs-subsite.lt_On_portrait_publish_d#.
  </p>
</if>

