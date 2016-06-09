<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>

<h3>Import/Export Messages</h3>

<p>
  <strong>&raquo;</strong> <a href="@export_url@"><strong>Export</strong>
      messages from the database to catalog files</a>
</p>

<p>
  <strong>&raquo;</strong> <a
      href="@import_url@"><strong>Import</strong>
      messages from catalog files to the database</a>
</p>


<h3>Localize Package</h3>

<p>
  <strong>&raquo;</strong> <a href="@localize_url@">Localize messages in this package</a>
</p>

<h3>Internationalize Package</h3>

<p>
  <strong>&raquo;</strong>
    <a href="version-i18n?version_id=@version_id@"><strong>Convert</strong> ADP, 
     Tcl, and SQL files to using the message catalog</a>.
</p>

<if @num_cat_files@ gt 0>
  <h3>Convert Message Catalog to New Format</h3>
  
  <p>
    <strong>&raquo;</strong>
      <a
      href="version-i18n-import?version_id=@version_id@&format=tcl"><strong>Import</strong>
      old Tcl-based catalog files (.cat files) into the
      database</a>. This will allow you to export them back out in the
      new format. (NB! Overwrites texts in the database)
  </p>
</if>
