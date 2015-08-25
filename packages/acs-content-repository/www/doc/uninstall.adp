
<property name="context">{/doc/acs-content-repository {Content Repository}} {Content Repository: Uninstalling}</property>
<property name="doc(title)">Content Repository: Uninstalling</property>
<master>
<h2>Uninstalling the Content Repository</h2>
<p>The content repository includes an uninstall script,
<tt>sql/content-drop.sql</tt>. This script does two things:</p>
<ol>
<li>Drops the attribute storage tables for all content types you
have defined.</li><li>Drops the general tables for the content repository.</li>
</ol>
<p>The uninstall script does <b>not</b> do the following:</p>
<ol>
<li>It does <b>not</b> delete rows from the <tt>acs_objects</tt>
table. Many other tables reference the <tt>object_id</tt> column in
this table, so there is the possibility that the uninstall script
will encounter foreign key reference errors.</li><li>It does <b>not</b> delete types from the
<tt>acs_object_types</tt> table. As for objects themselves, it is
impossible for an automatic script to properly handle disposal of
all foreign key references.</li>
</ol>
<p>Because of what the uninstall script does <b>not</b> do, it is
only appropriate for removing the content repository <em>in
preparation for removing the entire ACS Objects data model</em>. If
you wish to upgrade an existing installation and cannot afford to
lose your data, you must run an upgrade script rather than
uninstalling the entire data model.</p>
<hr>
<a href="mailto:karlg\@arsdigita.com">karlg\@arsdigita.com</a>
<br>

Last revised: $Id: uninstall.html,v 1.1.1.1 2001/03/13 22:59:26 ben
Exp $
