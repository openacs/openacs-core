<master src="site-master">
  <property name="title">@title;noquote@</property>
  <if @header_stuff@ not nil><property name="header_stuff">@header_stuff;noquote@</property></if>
  <if @focus@ not nil><property name="focus">@focus;noquote@</property></if>
  <if @doc_type@ not nil><property name="doc_type">@doc_type;noquote@</property></if>

<div id="body">
  <div id="navbar-body">
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

    <div id="subsite-name">
      <if @title@ not nil>
        <h1 class="subsite-page-title">@title;noquote@</h1>
      </if>
    </div>
    <slave>
    <div style="clear: both;"></div>

  </div>
</div>


