<master>
  <property name="title">@page_title@</property>
  <property name="context_bar">@context_bar@</property>

<h3>Import/Export Messages</h3>

<ul>
  <p>
    <li>
      <a href="version-i18n-export?version_id=@version_id@"><b>Export</b>
      messages from the database to catalog files</a>
    </li>
  </p>
  <p>
    <li>
      <a
      href="version-i18n-import?version_id=@version_id@&format=xml"><b>Import</b>
      messages from catalog files to the database</a> (NB! Overwrites
      messages in the database)
    </li>
  </p>
</ul>

<h3>Internationalize Package</h3>

<ul>
  <p>
    <li>
      <a href="version-i18n?version_id=@version_id@"><b>Convert</b> ADP, 
       Tcl, and SQL files to using the message catalog</a>.
    </li>
  </p>
</ul>

<if @num_cat_files@ gt 0>
  <h3>Convert Message Catalog to New Format</h3>
  
  <ul>
    <p>
      <li>
        <a
        href="version-i18n-import?version_id=@version_id@&format=tcl"><b>Import</b>
        old Tcl-based catalog files (.cat files) into the
        database</a>. This will allow you to export them back out in the
        new format. (NB! Overwrites texts in the database)
      </li>
    </p>
  </ul>
</if>