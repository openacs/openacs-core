<master>
  <property name="doc(title)">@title;literal@</property>
  <property name="context">@context;literal@</property>
  <property name="head">
  <style type="text/css">
  td.doc {background: #e4e4e4;}
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
    <table width="100%">
      <tr><td class="doc">@proc_doc_list.doc;noquote@</td></tr>
    </table>
    &nbsp;<p>
  </multiple>

  <if @source_p@ eq 0>
    [ <a href="procs-file-view?@url_vars@&amp;source_p=1">show source</a> ]
  </if>
  <else>
    [ <a href="procs-file-view?@url_vars@&amp;source_p=0">hide source</a> ]
  </else>


  <if @source_p@ ne @default_source_p@> 
    | [ <a href="set-default?source_p=@source_p@&amp;return_url=@return_url@">make this
    the default</a> ]
  </if>

  <if @source_p@ eq 1>
    <h4>Content File Source</h4>

    <!-- directly display file contents var to avoid translating i18n strings etc -->
    <blockquote><pre class='code'>@file_contents;literal@</pre></blockquote>
  </if>
