
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Using CVS for backup-recovery}</property>
<property name="doc(title)">Using CVS for backup-recovery</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="automated-backup" leftLabel="Prev"
		    title="
Chapter 8. Backup and Recovery"
		    rightLink="install-redhat" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="backups-with-cvs" id="backups-with-cvs"></a>Using CVS for backup-recovery</h2></div></div></div><p>CVS-only backup is often appropriate for development sites. If
you are already using CVS and your data is not important, you
probably don&#39;t need to do anything to back up your files. Just
make sure that your current work is checked into the system. You
can then roll back based on date - note the current system time,
down to the minute. For maximum safety, you can apply a tag to your
current files. You will still need to back up your database.</p><p>Note that, if you did the CVS options in this document, the
<code class="filename">/var/lib/aolserver/$OPENACS_SERVICE_NAME/etc</code>
directory is not included in cvs and you may want to add it.</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - $OPENACS_SERVICE_NAME</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cvs commit -m "last-minute commits before upgrade to 4.6"</code></strong>
cvs commit: Examining .
cvs commit: Examining bin
<span class="emphasis"><em>(many lines omitted)</em></span>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cvs tag before_upgrade_to_4_6</code></strong>
cvs server: Tagging bin
T bin/acs-4-0-publish.sh
T bin/ad-context-server.pl
(many lines omitted)
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>exit</code></strong>
[root root]# 
<span class="action"><span class="action">su - $OPENACS_SERVICE_NAME
cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
cvs commit -m "last-minute commits before upgrade to 4.6"
cvs tag before_upgrade_to_4_6
exit</span></span>
</pre><p>To restore files from a cvs tag such as the one used above:</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - $OPENACS_SERVICE_NAME</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cvs up -r current</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>exit</code></strong><span class="action"><span class="action">su - $OPENACS_SERVICE_NAME
cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
cvs up -r current</span></span>
</pre>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="automated-backup" leftLabel="Prev" leftTitle="Automated Backup"
		    rightLink="install-redhat" rightLabel="Next" rightTitle="
Appendix A. Install Red Hat 8/9"
		    homeLink="index" homeLabel="Home" 
		    upLink="backup-recovery" upLabel="Up"> 
		