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
  <property name="header_stuff">
    <link rel="stylesheet" type="text/css" href="@css_url@" media="all">
    @header_stuff;noquote@
  </property>


<!-- Header -->

<div id="site-header">
  <div class="system-name">
    <if @system_url@ not nil><a href="@system_url@">@system_name@</a></if>
    <else>@system_name@</else>
  </div>

  <div class="action-list permanent-navigation">
    <ul>
      <if @admin_url@ not nil>
        <li><a href="@admin_url@" title="#acs-subsite.Site_wide_administration#">#acs-subsite.Admin#</a></li>
      </if>
      <if @pvt_home_url@ not nil>
        <li><a href="@pvt_home_url@" title="#acs-subsite.Change_pass_email_por#">@pvt_home_name@</a></li>
      </if>
      <if @login_url@ not nil>
        <li><a href="@login_url@" title="#acs-subsite.Log_in_to_system#">#acs-subsite.Log_In#</a></li>
      </if>
      <if @logout_url@ not nil>
        <li><a href="@logout_url@" title="#acs-subsite.Logout_from_system#">#acs-subsite.Logout#</a></li>
      </if>
    </ul>
  </div>

  <div class="action-list users-online">
    <ul>
      <li><a href="@whos_online_url@">@num_users_online@ <if @num_users_online@ eq 1>member</if><else>members</else> online</a></li>
    </ul>
  </div>

  <div class="user-greeting">
    <if @untrusted_user_id@ ne 0>
      #acs-subsite.Welcome_user#
    </if>
    <else>
      #acs-subsite.Not_logged_in#
    </else>
  </div>

</div>

<if @user_messages:rowcount@ gt 0>
  <div id="user-message">
    <ul>
      <multiple name="user_messages">
        <li>@user_messages.message;noquote@</li>
      </multiple>
    </ul>
  </div>
</if>

<div id="context-bar">
  <if @context_bar@ not nil>
    <div id="breadcrumbs">@context_bar;noquote@</div>
  </if>
  <else>
    <if @context:rowcount@ not nil>
      <div id="breadcrumbs">
        <ul>
          <multiple name="context">
            <if @context.url@ not nil>
              <li><a href="@context.url@">@context.label@</a> &#187;</li>
            </if>
            <else>
              <li>@context.label@</li>
            </else>
          </multiple>
        </ul>
      </div>
    </if>
  </else>
  <div id="navlinks">@subnavbar_link;noquote@</div>
  <div style="clear: both;"></div>
</div>

<slave>

<div id="site-footer">
  <div class="action-list">
    <ul>
      <if @num_of_locales@ gt 1>
        <li><a href="@change_locale_url@">#acs-subsite.Change_locale_label#</a></li>
      </if>
      <else>
        <if @locale_admin_url@ not nil>
          <li><a href="@locale_admin_url@">Install locales</a></li>
        </if>
      </else>
    </ul>
  </div>
</div>

<if @curriculum_bar_p@ true>
  <p><include src="/packages/curriculum/lib/bar" />
</if>
