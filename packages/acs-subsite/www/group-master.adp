<master src="/www/blank-master">
  <if @title@ not nil>
    <property name="title">@title@</property>
  </if>
  <if @signatory@ not nil>
    <property name="signatory">@signatory@</property>
  </if>
  <if @focus@ not nil>
    <property name="focus">@focus@</property>
  </if>
  <if @context_bar@ not nil>
    <property name="context_bar">@context_bar@</property>
  </if>
  <if @context@ not nil>
    <property name="context">@context@</property>
  </if>
  <property name="header_stuff">
    @header_stuff@
    <link rel="stylesheet" type="text/css" href="@css_url@" media="all">
  </property>


<!-- Header -->

<table cellspacing="0" cellpadding="0" width="100%" class="subsite-header" border="0">
  <tr class="subsite-header">
    <td class="system-name" width="34%">
      <a href="@system_url@" class="system-name">@system_name@</a>
    </td>

    <td align="center" class="subsite-header" width="33%">
      <if @user_id@ ne 0>
        Welcome, @user_name@
      </if>
      <else>
        Not logged in
      </else>
    </td>

    <td align="right" class="subsite-header" style="padding-right: 8px;" width="33%">
      <if @sw_admin_url@ not nil>
        &nbsp;
        <span class="button-header"><a href="@sw_admin_url@" title="Visit the site-wide administration pages where you can install new applications on to the system" class="button">Site-Wide Admin</a></span>
      </if>
      <if @pvt_home_url@ not nil>
        &nbsp;
        <span class="button-header"><a href="@pvt_home_url@" title="You can change your password, portrait, and other information from here" class="button">@pvt_home_name@</a></span>
      </if>
      <if @logout_url@ not nil>
        &nbsp;
        <span class="button-header"><a href="@logout_url@" title="Logout from @system_name@" class="button">Logout</a></span>
      </if>
      <if @login_url@ not nil>
        &nbsp;
        <span class="button-header"><a href="@login_url@" title="Log in to @system_name@" class="button">Log in</a></span>
      </if>
    </td>
  </tr>
</table>


<!-- Body -->

<div id="body">
  <div id="subsite-name">
    <a href="@subsite_url@" class="subsite-name">@subsite_name@</a>
  </div>


<!-- Top level navigation -->

  <div id="navbar"> 
    <multiple name="sections">
      <if @sections.selected_p@ true>
        <div class="navbar-selected">
          <if @sections.link_p@ true>
            <a href="@sections.url@" title="@sections.title@" class="navbar-selected">@sections.label@</a>
          </if>
          <else>        
            @sections.label@
          </else>
        </div>
      </if>
      <else>
        <div class="navbar-unselected">
          <if @sections.link_p@ true>
            <a href="@sections.url@" title="@sections.title@" class="navbar-unselected">@sections.label@</a>
          </if>
          <else>        
            @sections.label@
          </else>
        </div>
      </else>
    </multiple>
  </div>
  <div id="navbar-body">

<!-- Context bar -->

    <div class="subsite-context-bar">
      @context_bar@&nbsp;
    </div>

<!-- Second level navigation -->
  
    <if @subsections:rowcount@ gt 0>
      <div id="subnavbar">
        <multiple name="subsections">
          <if @subsections.selected_p@ true>
            <div class="subnavbar-selected">
              <if @subsections.link_p@ true>
                <a href="@subsections.url@" title="@subsections.title@" class="subnavbar-selected">@subsections.label@</a>
              </if>
              <else>        
                @subsections.label@
              </else>
            </div>
          </if>
          <else>
            <div class="subnavbar-unselected">
              <if @subsections.link_p@ true>
                <a href="@subsections.url@" title="@subsections.title@" class="subnavbar-unselected">@subsections.label@</a>
              </if>
              <else>        
                @subsections.label@
              </else>
            </div>
          </else>
        </multiple>
      </div>
    </if>
    <div id="subnavbar-body">

<!-- Page Title -->

      <if @title@ not nil>
        <h1 class="subsite-page-title">@title@</h1>
      </if>

<!-- Body -->

      <slave>

    </div>
  </div>
</div>

