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

<if @notifications_url@ not nil>
  <p>
    <b>&raquo;</b> <a href="@notifications_url@">#acs-subsite.Manage_your_notifications#</a>
  </p>
</if>

<if @account_status@ ne "closed">
  <p>
    <b>&raquo;</b> <a href="unsubscribe">#acs-subsite.Close_your_account#</a> 
  </p>
</if>

<p>
  <b>&raquo;</b> <a href="@community_member_url@">#acs-subsite.lt_What_other_people_see#</a>
</p>

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

<h2>#acs-subsite.Whos_Online_title#</h2>

<p>
  <b>&raquo;</b> <a href="@whos_online_url@">#acs-subsite.Whos_Online_link_label#</a>
</p>

<if @invisible_p@ true>
  #acs-subsite.Currently_invisible_msg#
  <p> 
    <b>&raquo;</b> <a href="@make_visible_url@">#acs-subsite.Make_yourself_visible_label#</a>
  </p>
</if>
<else>
  #acs-subsite.Currently_visible_msg#
  <p> 
    <b>&raquo;</b> <a href="@make_invisible_url@">#acs-subsite.Make_yourself_invisible_label#</a>
  </p>
</else>
