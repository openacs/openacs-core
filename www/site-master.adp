<master src="/www/blank-master">
  <if @title@ not nil>
    <property name="title">@title;noquote@</property>
  </if>
  <if @signatory@ not nil>
    <property name="signatory">@signatory;noquote@</property>
  </if>
  <if @focus@ not nil>
    <property name="focus">@focus;noquote@</property>
  </if>
  <if @context_bar@ not nil>
    <property name="context_bar">@context_bar;noquote@</property>
  </if>
  <if @context@ not nil>
    <property name="context">@context;noquote@</property>
  </if>
  <property name="header_stuff">
    @header_stuff;noquote@
    <link rel="stylesheet" type="text/css" href="@css_url@" media="all">
  </property>


<!-- Header -->

<table cellspacing="0" cellpadding="0" width="100%" class="subsite-header" border="0">
  <tr class="subsite-header">
    <td class="system-name">
      <a href="@system_url@" class="system-name">@system_name@</a>
    </td>

    <td align="center" class="subsite-header">
      <if @user_id@ ne 0>#acs-subsite.Welcome_user#</if>
      <else>
        #acs-subsite.Not_logged_in#
      </else>
    </td>

    <td align="right" class="subsite-header" style="padding-right: 8px;">
      <if @admin_url@ not nil>
        &nbsp;
        <a href="@admin_url@" title="#acs-subsite.Site_wide_administration#"
          class="button">#acs-subsite.Admin#</a>
      </if>
      <if @devhome_url@ not nil>
        &nbsp;
        <a href="@devhome_url@" title="#acs-subsite.Developers_Admin#"
          class="button">#acs-subsite.DevAdmin#</a>
      </if>
      <if @pvt_home_url@ not nil>
        &nbsp;
        <a href="@pvt_home_url@" title="#acs-subsite.Change_pass_email_por#"
          class="button">@pvt_home_name@</a>
      </if>
      <if @logout_url@ not nil>
        &nbsp;
        <a href="@logout_url@?return_url=@subsite_url@" title="#acs-subsite.Logout_from_system#"
          class="button">#acs-subsite.Logout#</a>
      </if>
      <if @login_url@ not nil>
        &nbsp;
        <a href="@login_url@" title="#acs-subsite.Log_in_to_system#"
          class="button">#acs-subsite.Log_In#</a>
      </if>
    </td>
  </tr>
</table>

<slave>

<if @curriculum_bar_p@ true>
<include src="/packages/curriculum/lib/bar" />
</if>
