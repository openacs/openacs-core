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
    <!--<link rel="stylesheet" type="text/css" href="@css_url@" media="all">-->
  </property>

<div id="body">
  <div id="subsite-name">
    <if @subsite_url@ not nil><a href="@subsite_url@" class="subsite-name">@subsite_name@</a></if>
    <else>@subsite_name@</else>
  </div>

<!-- Context bar -->

    <div class="subsite-context-bar">
      @context_bar;noquote@&nbsp;
    </div>

<!-- Top level navigation -->

  <div id="navbar-div">
  <div id="navbar-container">
  <div id="navbar"> 
    <multiple name="sections">
      <if @sections.selected_p@ true>
        <div class="tab" id="navbar-here">
          <if @sections.link_p@ true>
            <a href="@sections.url@" title="@sections.title@">@sections.label@</a>
          </if>
          <else>        
            @sections.label@
          </else>
        </div>
      </if>
      <else>
        <div class="tab">
          <if @sections.link_p@ true>
            <a href="@sections.url@" title="@sections.title@">@sections.label@</a>
          </if>
          <else>        
            @sections.label@
          </else>
        </div>
      </else>
    </multiple>
  </div>
  </div>
  </div>
  <div id="navbar-body">

<!-- Second level navigation -->
  
    <if @subsections:rowcount@ gt 0>

      <div id="subnavbar-div">
      <div id="subnavbar-container">
      <div id="subnavbar">
        <multiple name="subsections">
          <if @subsections.selected_p@ true>
            <div class="tab" id="subnavbar-here">
              <if @subsections.link_p@ true>
                <a href="@subsections.url@" title="@subsections.title@">@subsections.label@</a>
              </if>
              <else>        
                @subsections.label@
              </else>
            </div>
          </if>
          <else>
            <div class="tab">
              <if @subsections.link_p@ true>
                <a href="@subsections.url@" title="@subsections.title@">@subsections.label@</a>
              </if>
              <else>        
                @subsections.label@
              </else>
            </div>
          </else>
        </multiple>
      </div>
      </div>
      </div>
    </if>
    <else>
      <div id="subnavbar-div"></div>
    </else>
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

 
