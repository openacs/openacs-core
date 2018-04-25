
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Automated Backup}</property>
<property name="doc(title)">Automated Backup</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="snapshot-backup" leftLabel="Prev"
			title="Chapter 8. Backup and
Recovery"
			rightLink="backups-with-cvs" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="automated-backup" id="automated-backup"></a>Automated Backup</h2></div></div></div><p>The recommended backup strategy for a production sit is to use
an automated script which first backs up the database to a file in
<code class="filename">/var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/database-backup</code>
and then backs up all of <code class="filename">/var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>
</code> to a
single zip file, and then copies that zip file to another
computer.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Make sure that the manual backup process described above
works.</p></li><li class="listitem"><p>Customize the default backup script. Edit <code class="filename">/var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/etc/backup.sh</code>
with your specific parameters.</p></li><li class="listitem">
<p>Make sure the file is executable:</p><pre class="programlisting">chmod +x backup.sh</pre>
</li><li class="listitem">
<p>Set this file to run automatically by adding a line to
root&#39;s crontab. (Typically, with <code class="computeroutput">export EDITOR=emacs; crontab -e</code>.) This
example runs the backup script at 1:30 am every day.</p><pre class="programlisting">
30 1 * * *        sh /var/lib/aolserver/<em class="replaceable"><code>$OPENACS_SERVICE_NAME</code></em>/etc/backup.sh</pre>
</li>
</ol></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="snapshot-backup" leftLabel="Prev" leftTitle="Manual backup and recovery"
			rightLink="backups-with-cvs" rightLabel="Next" rightTitle="Using CVS for backup-recovery"
			homeLink="index" homeLabel="Home" 
			upLink="backup-recovery" upLabel="Up"> 
		    