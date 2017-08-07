<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>
  <property name="displayed_object_id">@user_id;literal@</property>

<if @inline_portrait_state@ eq "inline">
      <div style="float:right">
        <a href="@portrait_url;noi18n@"><img src="@portrait_image_url;noi18n@"
	width="@width@" height="@height@" alt="Portrait of @first_names@ @last_name@"></a>
      </div>
</if>
<else>
  <if @inline_portrait_state@ eq "link">
    <ul class="action-links">
      <li><a href="@portrait_url;noi18n@">#acs-subsite.Portrait#</a></li>
    </ul>
  </if>
</else>

<p>
  #acs-subsite.A_member_of_the_system# <strong>@pretty_creation_date@</strong>.
</p>

<if @member_state@ eq "deleted">
  <blockquote>
    <font color="red">
      #acs-subsite.This_user_has_left_the#
    </font>
  </blockquote>
</if>
<else>
  <if @member_state@ eq "banned">
    <blockquote>
      <font color="red">
        #acs-subsite.lt_This_user_is_deleted#
       </font>
    </blockquote>
  </if>
</else>

<p>
  <strong>#acs-subsite.Name#:</strong> @first_names@ @last_name@
</p>

<if @show_email_p;literal@ true>@email_image;noquote@</if>

<if @verified_user_id@ ne 0 and @url@ not nil>
  <p>
    <strong>#acs-subsite.Home_page#:</strong> 
    <a href="@url@">@url@</a>
  </p>
</if>

<if @verified_user_id@ ne 0>
    <if @bio@ not nil>
      <p>
	<strong>#acs-subsite.Biography#:</strong>
      </p>
      <blockquote>
	@bio;noquote@
      </blockquote>
    </if>
</if>
<else>
  <blockquote>
    #acs-subsite.If_you_were_to# <a href="@subsite_url@register/index?@login_export_vars@">#acs-subsite.log_in#</a>#acs-subsite.lt__youd_be_able_to_get#
  </blockquote>
</else>

<if @site_wide_admin_p;literal@ true>
  <h3>#acs-subsite.lt_For_Site-Wide_Adminis#</h3>
  <ul class="action-links">
    <li><a href="@admin_user_url@">#acs-subsite.Administrative_options#</a></li>
  </ul>
</if>


