
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Manual backup and recovery}</property>
<property name="doc(title)">Manual backup and recovery</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="install-next-backups" leftLabel="Prev"
			title="Chapter 8. Backup and
Recovery"
			rightLink="automated-backup" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="snapshot-backup" id="snapshot-backup"></a>Manual backup and recovery</h2></div></div></div><p>This section describes how to make a one-time backup and restore
of the files and database. This is useful for rolling back to
known-good versions of a service, such as at initial installation
and just before an upgrade. First, you back up the database to a
file within the file tree. Then, you back up the file tree. All of
the information needed to rebuild the site, including the AOLserver
config files, is then in tree for regular file system backup.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p><strong>Back up the database to a file. </strong></p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>
<a name="oracle-snapshot-backup" id="oracle-snapshot-backup"></a><strong>Oracle. </strong>
</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Download the backup script. Save the file <a class="ulink" href="files/export-oracle.txt" target="_top">export-oracle.txt</a> as
<code class="filename">/var/tmp/export-oracle.txt</code>
</p></li><li class="listitem">
<p>Login as root. The following commands will install the export
script:</p><pre class="programlisting">[joeuser ~]$ <strong class="userinput"><code>su -</code></strong>
[root ~]# <strong class="userinput"><code>cp /var/tmp/export-oracle.txt /usr/sbin/export-oracle</code></strong>
[root ~]# <strong class="userinput"><code>chmod 700 /usr/sbin/export-oracle</code></strong>
</pre>
</li><li class="listitem">
<p>Setup the export directory; this is the directory where backups
will be stored. We recommend the directory <code class="filename">/ora8/m02/oracle-exports</code>.</p><pre class="programlisting">[root ~]# <strong class="userinput"><code>mkdir <em class="replaceable"><code>/ora8/m02/</code></em>oracle-exports</code></strong>
[root ~]# <strong class="userinput"><code>chown oracle:dba <em class="replaceable"><code>/ora8/m02/</code></em>oracle-exports</code></strong>
[root ~]# <strong class="userinput"><code>chmod 770 <em class="replaceable"><code>/ora8/m02/</code></em>oracle-exports</code></strong>
</pre>
</li><li class="listitem">
<p>Now edit <code class="filename">/usr/sbin/export-oracle</code>
and change the <code class="computeroutput">SERVICE_NAME</code> and
<code class="computeroutput">DATABASE_PASSWORD</code> fields to
their correct values. If you want to use a directory other than
<code class="filename">/ora8/m02/oracle-exports</code>, you also
need to change the <code class="computeroutput">exportdir</code>
setting.</p><p>Test the export procedure by running the command:</p><pre class="programlisting">[root ~]# <strong class="userinput"><code>/usr/sbin/export-oracle</code></strong>
mv: /ora8/m02/oracle-exports/oraexport-service_name.dmp.gz: No such file or directory

Export: Release 8.1.6.1.0 - Production on Sun Jun 11 18:07:45 2000

(c) Copyright 1999 Oracle Corporation.  All rights reserved.

Connected to: Oracle8i Enterprise Edition Release 8.1.6.1.0 - Production
With the Partitioning option
JServer Release 8.1.6.0.0 - Production
Export done in US7ASCII character set and US7ASCII NCHAR character set
  . exporting pre-schema procedural objects and actions
  . exporting foreign function library names for user SERVICE_NAME 
  . exporting object type definitions for user SERVICE_NAME 
  About to export SERVICE_NAME&#39;s objects ...
  . exporting database links
  . exporting sequence numbers
  . exporting cluster definitions
  . about to export SERVICE_NAME&#39;s tables via Conventional Path ...
  . exporting synonyms
  . exporting views
  . exporting stored procedures
  . exporting operators
  . exporting referential integrity constraints
  . exporting triggers
  . exporting indextypes
  . exporting bitmap, functional and extensible indexes
  . exporting posttables actions
  . exporting snapshots
  . exporting snapshot logs
  . exporting job queues
  . exporting refresh groups and children
  . exporting dimensions
  . exporting post-schema procedural objects and actions
  . exporting statistics
Export terminated successfully without warnings.</pre>
</li>
</ul></div>
</li><li class="listitem">
<p>
<a name="postgres-snapshot-backup" id="postgres-snapshot-backup"></a><strong>PostgreSQL. </strong>
Create a backup file and verify that it was created and has a
reasonable size (several megabytes).</p><pre class="screen">[root root]# <strong class="userinput"><code>su - $OPENACS_SERVICE_NAME</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>pg_dump -f /var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/database-backup/before_upgrade_to_4.6.dmp <em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>ls -al /var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/database-backup/before_upgrade_to_4.6.dmp </code></strong>
-rw-rw-r-x    1 $OPENACS_SERVICE_NAME  $OPENACS_SERVICE_NAME   4005995 Feb 21 18:28 /var/lib/aolserver/$OPENACS_SERVICE_NAME/database-backup/before_upgrade_to_4.6.dmp
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>exit</code></strong>
[root root]#
<span class="action">su - $OPENACS_SERVICE_NAME
pg_dump -f /var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/database-backup/before_upgrade_to_4.6.dmp <em class="replaceable"><code>openacs-dev</code></em>
ls -al /var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/database-backup/before_upgrade_to_4.6.dmp
exit</span>
</pre>
</li>
</ul></div>
</li><li class="listitem">
<a name="backup-file-system" id="backup-file-system"></a><p>
<strong>Back up the file system. </strong> Back up all of
the files in the service, including the database backup file but
excluding the auto-generated <code class="filename">supervise</code> directory, which is unnecessary and has
complicated permissions.</p><p>In the tar command,</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<code class="computeroutput">c</code> create a new tar
archive</p></li><li class="listitem"><p>
<code class="computeroutput">p</code> preserves permissions.</p></li><li class="listitem"><p>
<code class="computeroutput">s</code> preserves file sort
order</p></li><li class="listitem"><p>
<code class="computeroutput">z</code> compresses the output with
gzip.</p></li><li class="listitem"><p>The <code class="computeroutput">--exclude</code> clauses skips
some daemontools files that are owned by root and thus cannot be
backed up by the service owner. These files are autogenerated and
we don&#39;t break anything by omitting them.</p></li><li class="listitem"><p>The <code class="computeroutput">--file</code> clause specifies
the name of the output file to be generated; we manually add the
correct extensions.</p></li><li class="listitem"><p>The last clause, <code class="filename">/var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/</code>,
specifies the starting point for backup. Tar defaults to recursive
backup.</p></li>
</ul></div><pre class="screen">[root root]# <strong class="userinput"><code>su - <em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>tar -cpsz --exclude /var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/etc/daemontools/supervise \
   --file /var/tmp/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>-backup.tar.gz /var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/</code></strong>
tar: Removing leading `/' from member names
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$</pre>
</li><li class="listitem">
<p>
<strong>Suffer a catastrophic failure on your production
system. </strong> (We&#39;ll simulate this step)</p><pre class="screen">[root root]# <strong class="userinput"><code>svc -d /service/$OPENACS_SERVICE_NAME</code></strong>
[root root]# <strong class="userinput"><code>mv /var/lib/aolserver/$OPENACS_SERVICE_NAME/ /var/lib/aolserver/$OPENACS_SERVICE_NAME.lost</code></strong>
[root root]#<strong class="userinput"><code> rm /service/$OPENACS_SERVICE_NAME</code></strong>
rm: remove symbolic link `/service/$OPENACS_SERVICE_NAME'? y
[root root]# <strong class="userinput"><code>ps -auxw | grep $OPENACS_SERVICE_NAME</code></strong>
root      1496  0.0  0.0  1312  252 ?        S    16:58   0:00 supervise $OPENACS_SERVICE_NAME
[root root]#<strong class="userinput"><code> kill<em class="replaceable"><code> 1496</code></em>
</code></strong>
[root root]# <strong class="userinput"><code>ps -auxw | grep $OPENACS_SERVICE_NAME</code></strong>
[root root]# <strong class="userinput"><code>su - postgres</code></strong>
[postgres pgsql]$ <strong class="userinput"><code>dropdb $OPENACS_SERVICE_NAME</code></strong>
DROP DATABASE
[postgres pgsql]$ <strong class="userinput"><code>dropuser $OPENACS_SERVICE_NAME</code></strong>
DROP USER
[postgres pgsql]$ <strong class="userinput"><code>exit</code></strong>
logout
[root root]#</pre>
</li><li class="listitem">
<p>
<a name="recovery" id="recovery"></a><strong>Recovery. </strong>
</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem"><p>Restore the operating system and required software. You can do
this with standard backup processes or by keeping copies of the
install material (OS CDs, OpenACS tarball and supporting software)
and repeating the install guide. Recreate the service user
(<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>).</p></li><li class="listitem">
<p>Restore the OpenACS files and database backup file.</p><pre class="screen">[root root]# <strong class="userinput"><code>su - <em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cd /var/lib/aolserver</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$<strong class="userinput"><code> tar xzf /var/tmp/$OPENACS_SERVICE_NAME-backup.tar.gz</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>chmod -R 775 <em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>
</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>chown -R <em class="replaceable"><code>$OPENACS_SERVICE_NAME.web</code></em><em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>
</code></strong>
</pre>
</li><li class="listitem">
<p>Restore the database</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p><strong>Oracle. </strong></p><div class="orderedlist"><ol class="orderedlist" type="i">
<li class="listitem"><p>Set up a clean Oracle database user and tablespace with the same
names as the ones exported from (<a class="link" href="openacs" title="Prepare Oracle for OpenACS">more information</a>).</p></li><li class="listitem">
<p>Invoke the import command</p><pre class="screen"><span class="action">imp <em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em> FILE=/var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/database-backup/nighty_backup.dmp FULL=Y</span></pre>
</li>
</ol></div>
</li><li class="listitem">
<p>
<a name="restore-postgres" id="restore-postgres"></a><strong>Postgres. </strong> If the database user does not
already exist, create it.</p><pre class="screen">[root root]# <strong class="userinput"><code>su - postgres</code></strong>
[postgres ~]$ <strong class="userinput"><code>createuser <em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>
</code></strong>
Shall the new user be allowed to create databases? (y/n) <strong class="userinput"><code>y</code></strong>
Shall the new user be allowed to create more new users? (y/n) <strong class="userinput"><code>y</code></strong>
CREATE USER
[postgres ~]$ <strong class="userinput"><code>exit</code></strong>
</pre><p>Because of a bug in Postgres backup-recovery, database objects
are not guaranteed to be created in the right order. In practice,
running the OpenACS initialization script is always sufficient to
create any out-of-order database objects. Next, restore the
database from the dump file. The restoration will show some error
messages at the beginning for objects that were pre-created from
the OpenACS initialization script, which can be ignored.</p><pre class="screen">[root root]# <strong class="userinput"><code>su - <em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>
</code></strong>
[$OPENACS_SERVICE_NAME ~]$ <strong class="userinput"><code>createdb <em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>
</code></strong>
CREATE DATABASE
[$OPENACS_SERVICE_NAME ~]$<strong class="userinput"><code> psql -f /var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/packages/acs-kernel/sql/postgresql/postgresql.sql <em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>
</code></strong><span class="emphasis"><em>(many lines omitted)</em></span>
[$OPENACS_SERVICE_NAME ~]$ <strong class="userinput"><code>psql <em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em> &lt; /var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/database-backup/<em class="replaceable"><code>database-backup.dmp</code></em>
</code></strong><span class="emphasis"><em>(many lines omitted)</em></span>
[$OPENACS_SERVICE_NAME ~]$ <strong class="userinput"><code>exit</code></strong>
[postgres ~]$ <strong class="userinput"><code>exit</code></strong>
logout</pre>
</li>
</ul></div>
</li><li class="listitem">
<p>Activate the service</p><pre class="screen">[root root]# <strong class="userinput"><code>ln -s /var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/etc/daemontools /service/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>
</code></strong>
[root root]# <strong class="userinput"><code>sleep 10</code></strong>
[root root]# <strong class="userinput"><code>svgroup web /service/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>
</code></strong>
</pre>
</li>
</ol></div>
</li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="install-next-backups" leftLabel="Prev" leftTitle="Backup Strategy"
			rightLink="automated-backup" rightLabel="Next" rightTitle="Automated Backup"
			homeLink="index" homeLabel="Home" 
			upLink="backup-recovery" upLabel="Up"> 
		    