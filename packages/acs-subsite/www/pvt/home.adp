<master>
  <property name=title>@page_title@</property>
  <property name="context">@context;noquote@</property>
  <property name="focus">user_info.first_names</property>

<h2>#acs-subsite.Basic_Information#</h2>

<include src="/packages/acs-subsite/lib/user-info">

<if @account_status@ eq "closed">
  #acs-subsite.Account_closed_workspace_msg#
</if>

<ul class="action-links">
  <li><a href="../user/password-update">#acs-subsite.Change_my_Password#</a></li>
  <if @change_locale_url@ not nil>
    <li><a href="@change_locale_url@">#acs-subsite.Change_locale_label#</a></li>
  </if>

  <if @notifications_url@ not nil>
    <li><a href="@notifications_url@">#acs-subsite.Manage_your_notifications#</a></li>
  </if>

  <if @account_status@ ne "closed">
    <li><a href="unsubscribe">#acs-subsite.Close_your_account#</a></li>
  </if>

  <li><a href="@community_member_url@">#acs-subsite.lt_What_other_people_see#</a></li>
</ul>

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

<ul class="action-links">
  <li><a href="@whos_online_url@">#acs-subsite.Whos_Online_link_label#</a></li>
</ul>

<if @invisible_p@ true>
  #acs-subsite.Currently_invisible_msg#
  <ul class="action-links">
    <li><a href="@make_visible_url@">#acs-subsite.Make_yourself_visible_label#</a></li>
  </ul>
</if>
<else>
  #acs-subsite.Currently_visible_msg#
  <ul class="action-links">
    <li><a href="@make_invisible_url@">#acs-subsite.Make_yourself_invisible_label#</a></li>
  </ul>
</else>
