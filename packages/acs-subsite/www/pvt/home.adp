<master>
  <property name=title>@page_title@</property>
  <property name="context">@context;noquote@</property>
  <property name="focus">user_info.first_names</property>
  <property name="displayed_object_id">@user_id@</property>


<table> <tr valign="top"> 
<td width="35%">
<div class="portlet-wrapper">
	<div class="portlet-title">
	<span><h2>#acs-subsite.Edit_Options#</h2></span>
	</div>
	<div class="portlet">
  <ul>
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

  </ul>
</div>
</div>


<div class="portlet-wrapper">
  <div class="portlet-title">
  <span><h2>#acs-subsite.Privacy#</h2></span>
  </div>
  <div class="portlet">
  <ul>
    <li><a href="@community_member_url@">#acs-subsite.lt_What_other_people_see#</a></li>
    <li><a href="@whos_online_url@">#acs-subsite.Whos_Online_link_label#</a></li>
    <li><a href="../user/email-privacy-level">#acs-subsite.Change_my_email_P#</a></li>
  </ul>

  <if @invisible_p@ true>
    #acs-subsite.Currently_invisible_msg#
    <ul>
      <li><a href="@make_visible_url@">#acs-subsite.Make_yourself_visible_label#</a></li>
    </ul>
  </if>
  <else>
    #acs-subsite.Currently_visible_msg#
    <ul>
      <li><a href="@make_invisible_url@">#acs-subsite.Make_yourself_invisible_label#</a></li>
    </ul>
  </else>
</div>
</div>

</td>
<td>

<div class="portlet-wrapper">
	<div class="portlet-title">
	<span><h2> #acs-subsite.My_Account# </h2></span>
	</div>
        <div class="portlet">
  	<include src="/packages/acs-subsite/lib/user-info" />
  	<if @account_status@ eq "closed">
    	#acs-subsite.Account_closed_workspace_msg#
  	</if>
</div>
</div>


  <if @portrait_state@ eq upload>

<div class="portlet-wrapper">
        <div class="portlet-title">
	     <span><h2>#acs-subsite.Your_Portrait#</h2></span>
	</div>
        <div class="portlet">
	    <p>
	    #acs-subsite.lt_Show_everyone_else_at#  <a href="@portrait_upload_url@">#acs-subsite.upload_a_portrait#</a>
	    </p>
	</div>
</div>
</if>

  <if @portrait_state@ eq show>
<div class="portlet-wrapper">  
  <div class="portlet-title">
             <span><h2>#acs-subsite.Your_Portrait#</h2></span>
  </div>
  <div class="portlet">
    <p>
      #acs-subsite.lt_On_portrait_publish_d#.
    </p>
<table><tr valign="top"><td>
<img height=100 src="/shared/portrait-bits.tcl?user_id=@user_id@" alt="Portrait"><p>
<a href="/user/portrait/?return_url=/pvt/home">#acs-subsite.Edit#</a>
</td><td>@portrait_description@</td></tr>
</table>
</div>
</div>
  </if>

<div class="portlet-wrapper">
        <div class="portlet-title">
  	<span><h2><list name="fragments"><h2></span>
	</div>
	<div class="portlet">
    	@fragments:item;noquote@
  	</list>
</div>
</td></tr>
</table>
