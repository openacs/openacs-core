<master>
  <property name="doc(title)">@title;literal@</property>
  <property name="context">@context;literal@</property>

  @script_documentation;noquote@

  <if @xql_links:rowcount;literal@ gt 0>
    <h4>Related Files</h4>
    <ul>
      <multiple name="xql_links">
        <li><a href="@xql_links.link@">@xql_links.filename@</a></li>
      </multiple>
    </ul>
  </if>

<if @source_link@ ne 0>
  <p>
    <if @source_p;literal@ false>
      [ <a href="@source_toggle_url;noi18n@">show source</a> ]
    </if>
    <else>
      [ <a href="@source_toggle_url;noi18n@">hide source</a> ]
    </else>


    <if @source_p@ ne @default_source_p@> 
      | [ <a href="@set_default_url@">make this
        the default</a> ]
    </if>

    <if @source_p;literal@ true>
      <h4>@contents_title@</h4>

      <!-- directly display file contents var to avoid translating i18n strings etc -->
      <blockquote><pre class='code'>@file_contents;literal@</pre></blockquote>

    </if>
</if>
