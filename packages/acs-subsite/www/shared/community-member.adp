<master>
<property name=title>@first_names@ @last_name@</property>
<property name="context">@context@</property>

<if @inline_portrait_state@ eq "inline">
  <a href="portrait?@portrait_export_vars@"><img src="portrait-bits?@portrait_export_vars@" align="right" width="@width@" height="@height@"></a>
</if>
<else>
  <if @inline_portrait_state eq "link">
    <p>
      <b>&raquo;</b> <a href="portrait?@portrait_export_vars@">Portrait</a>
    </p>
  </if>
</else>

<p>
  A member of the @system_name@ community since <b>@pretty_creation_date@</b>.
</p>

<if @member_state@ eq "deleted">
  <blockquote>
    <font color="red">
      This user has left the community.
    </font>
  </blockquote>
</if>
<else>
  <if @member_state@ eq "banned">
    <blockquote>
      <font color="red">
        This user is deleted and banned from the community.
       </font>
    </blockquote>
  </if>
</else>

<p>
  <b>Name:</b> @first_names@ @last_name@
</p>

<if @show_email_p@ true>
  <p>
    <b>E-mail:</b> <a href="mailto:@email@">@email@</a>
  </p>
</if>

<if @url@ not nil>
  <p>
    <b>Home page:</b> <a href="@url@">@url@</a>
  </p>
</if>

<if @bio@ not nil>
  <p>
    <b>Biography:</b>
   </p>
   <blockquote>
     @bio@
   </blockquote>
</if>


<if @verified_user_id@ eq 0>
  <blockquote>
    If you were to <a href="/register/index?@login_export_vars@">log in</a>, you'd be able to get more information on your fellow community member.
  </blockquote>
</if>

<if @site_wide_admin_p@>
  <h3>For Site-Wide Administrators</h3>
  <p>
    <b>&raquo;</b> <a href="@admin_user_url@">Administrative options for this user</a>
  </p>
</if>

