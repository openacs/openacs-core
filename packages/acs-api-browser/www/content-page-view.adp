<master>
  <property name=title>@title;noquote@</property>
  <property name="context">@context;noquote@</property>

  @script_documentation;noquote@

  <if @xql_links:rowcount@ gt 0>
    <h4>Related Files</h4>
    <ul>
      <multiple name="xql_links">
        <li><a href="@xql_links.link@">@xql_links.filename@</a></li>
      </multiple>
    </ul>
  </if>

  <p>
    <if @source_p@ eq 0>
      [ <a href="content-page-view?@url_vars@&amp;source_p=1">show source</a> ]
    </if>
    <else>
      [ <a href="content-page-view?@url_vars@&amp;source_p=0">hide source</a> ]
    </else>


    <if @source_p@ ne @default_source_p@> 
      | [ <a href="set-default?source_p=@source_p@&amp;return_url=@return_url@">make this
        the default</a> ]
    </if>

    <if @source_p@ eq 1>
      <h4>Content File Source</h4>

      <!-- directly display file contents var to avoid translating i18n strings etc -->
      <pre><%= $file_contents %></pre>
    </if>

