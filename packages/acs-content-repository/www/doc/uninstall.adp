
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Content Repository: Uninstalling}</property>
<property name="doc(title)">Content Repository: Uninstalling</property>
<master>
<h2>Uninstalling the Content Repository</h2>
<strong><a href="index">Content Repository</a></strong>
<p>The content repository includes an uninstall script,
<kbd>sql/content-drop.sql</kbd>. This script does two things:</p>
<ol>
<li>Drops the attribute storage tables for all content types you
have defined.</li><li>Drops the general tables for the content repository.</li>
</ol>
<p>The uninstall script does <strong>not</strong> do the
following:</p>
<ol>
<li>It does <strong>not</strong> delete rows from the
<kbd>acs_objects</kbd> table. Many other tables reference the
<kbd>object_id</kbd> column in this table, so there is the
possibility that the uninstall script will encounter foreign key
reference errors.</li><li>It does <strong>not</strong> delete types from the
<kbd>acs_object_types</kbd> table. As for objects themselves, it is
impossible for an automatic script to properly handle disposal of
all foreign key references.</li>
</ol>
<p>Because of what the uninstall script does <strong>not</strong>
do, it is only appropriate for removing the content repository
<em>in preparation for removing the entire ACS Objects data
model</em>. If you wish to upgrade an existing installation and
cannot afford to lose your data, you must run an upgrade script
rather than uninstalling the entire data model.</p>
<hr>
<a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a>
<br>

Last revised: $&zwnj;Id: uninstall.html,v 1.1.1.1.30.1 2016/06/22
07:40:41 gustafn Exp $
