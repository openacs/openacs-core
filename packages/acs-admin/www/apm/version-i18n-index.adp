<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar@</property>

<ul>
<p>
<li><a href="version-i18n?version_id=@version_id@">Convert adp and tcl files to using the message catalog</a></li>
</p>

<p>
<li><a href="version-i18n-export?version_id=@version_id@">Export (dump) messages from database to xml catalog files</a></li>
</p>

<p>
<li><a href="version-i18n-import?version_id=@version_id@&format=xml">Import messages from xml catalog files to database</a> (overwrites texts in the database)</li>
</p>

<p>
<li><a href="version-i18n-import?version_id=@version_id@&format=tcl">Import messages from old tcl-based catalog files (.cat files) to database</a> (overwrites texts in the database)</li>
</p>
</ul>
