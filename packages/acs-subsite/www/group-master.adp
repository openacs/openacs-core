<master src="/www/site-master">
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
      @context_bar;noquote@&nbsp;
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
      <div style="clear: both;"></div>

    </div>
  </div>
</div>

 
