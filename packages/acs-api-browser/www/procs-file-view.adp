<master>
  <property name="doc(title)">@title;literal@</property>
  <property name="context">@context;literal@</property>
  <property name="head">
  <style type="text/css">
  div.api-doc {background: #e4e4e4;}
  dd {margin-left: 2em;}
  </style>
  </property>

  @dimensional_slider;noquote@
  @library_documentation;noquote@

  <br style="clear:both">

  <h3>Procedures in this file</h3>

  <ul>
    <multiple name="proc_list">
      <li>@proc_list.proc;noquote@
    </multiple>
  </ul>

  <h3>Detailed information</h3>

  <multiple name="proc_doc_list">
    <div class="api-doc">
      @proc_doc_list.doc;noquote@
    </div>
  </multiple>

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
    <h4>Content File Source</h4>

    <!-- directly display file contents var to avoid translating i18n strings etc -->
    <blockquote><pre class='code'>@file_contents;literal@</pre></blockquote>
  </if>
