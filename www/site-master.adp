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
  <tr>
    <td class="system-name">
      <a href="@system_url@">@system_name@</a>
    </td>

    <td align="center">
      <if @untrusted_user_id@ ne 0>
        #acs-subsite.Welcome_user#
      </if>
      <else>
        #acs-subsite.Not_logged_in#
      </else>
    </td>

    <td align="center" class="button-bar">
      <a href="@whos_online_url@">@num_users_online@ <if @num_users_online@ eq 1>user</if><else>users</else> online</a>
    </td>

    <td align="right" style="padding-right: 8px;" class="button-bar">
      <if @admin_url@ not nil>
        <a href="@admin_url@" title="#acs-subsite.Site_wide_administration#">#acs-subsite.Admin#</a>
      </if>
      <if @pvt_home_url@ not nil>
        <a href="@pvt_home_url@" title="#acs-subsite.Change_pass_email_por#">@pvt_home_name@</a>
      </if>
      <if @login_url@ not nil>
        <a href="@login_url@" title="#acs-subsite.Log_in_to_system#">#acs-subsite.Log_In#</a>
      </if>
      <if @logout_url@ not nil>
        <a href="@logout_url@" title="#acs-subsite.Logout_from_system#">#acs-subsite.Logout#</a>
      </if>
    </td>
  </tr>
</table>

<if @sw_admin_p@ true>
</if>

<slave>

<if @num_of_locales@ gt 1>
    <p><a href="@change_locale_url@">Change Locale</a>
</if>
<else>
  <if @locale_admin_url@ not nil>
    <a href="@locale_admin_url@">Install Locales</a>
  </if>
</else>

<if @curriculum_bar_p@ true>
<p><include src="/packages/curriculum/lib/bar" />
</if>
