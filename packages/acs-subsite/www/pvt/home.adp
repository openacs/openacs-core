<master>
<property name=title>@full_name;noquote@'s workspace at @system_name;noquote@</property>
<property name="context">@context;noquote@</property>

<ul>

<p>

<li><a href="@subsite_url@register/logout?return_url=@subsite_url@">Log Out</a>
<p>

<li><a href="@subsite_url@user/password-update?return_url=@pvt_home_url@">#acs-subsite.Change_my_Password#</a>


</ul>

<h3>#acs-subsite.lt_What_we_tell_other_us#</h3>

#acs-subsite.lt_In_general_we_identif#

<p>

#acs-subsite.lt_If_you_want_to_check_#

<h4>#acs-subsite.Basic_Information#</h4>

<ul>
<li>#acs-subsite.Name#  @full_name@</li>
<li>#acs-subsite.email_address#  @email@</li>
<li>#acs-subsite.personal_URL#  <a target=new_window href="@url@">@url@</a></li>
<li>#acs-subsite.screen_name#  @screen_name;noquote@</li>
<li>#acs-subsite.bio# @bio@</li>
</ul>
<p>(<a href="@subsite_url@user/basic-info-update?return_url=@pvt_home_url@">#acs-subsite.Update#</a>)</p>


<if @portrait_state@ eq upload>

<h4>#acs-subsite.Your_Portrait#</h4>
#acs-subsite.lt_Show_everyone_else_at#  <a href="@subsite_url@user/portrait/upload?return_url=@pvt_home_url@">#acs-subsite.upload_a_portrait#</a>

</if>
<if @portrait_state@ eq show>

<h4>#acs-subsite.Your_Portrait#</h4>
#acs-subsite.lt_On_portrait_publish_d#.

</if>



<h3>#acs-subsite.lt_If_youre_getting_too_#</h3>

#acs-subsite.lt_Then_you_should_eithe# 

<ul>
<li><a href="alerts?return_url=@pvt_home_url@">#acs-subsite.edit_your_alerts#</a></li>
</ul>
<p>#acs-subsite.or#</p>
<ul>
<li><a href="unsubscribe?return_url=@pvt_home_url@">#acs-subsite.Unsubscribe#</a> (#acs-subsite.lt_for_a_period_of_vacat#)</li>
</ul>
