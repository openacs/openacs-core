<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>

<h3>Import/Export Messages</h3>

<p>
  <b>&raquo;</b> <a href="@export_url@"><b>Export</b>
      messages from the database to catalog files</a>
</p>

<p>
  <b>&raquo;</b> <a
      href="@import_url@"><b>Import</b>
      messages from catalog files to the database</a>
</p>


<h3>Localize Package</h3>

<p>
  <b>&raquo;</b> <a href="@localize_url@">Localize messages in this package</a>
</p>

<h3>Internationalize Package</h3>

<p>
  <b>&raquo;</b>
    <a href="version-i18n?version_id=@version_id@"><b>Convert</b> ADP, 
     Tcl, and SQL files to using the message catalog</a>.
</p>

<if @num_cat_files@ gt 0>
  <h3>Convert Message Catalog to New Format</h3>
  
  <p>
    <b>&raquo;</b>
      <a
      href="version-i18n-import?version_id=@version_id@&format=tcl"><b>Import</b>
      old Tcl-based catalog files (.cat files) into the
      database</a>. This will allow you to export them back out in the
      new format. (NB! Overwrites texts in the database)
  </p>
</if>
