
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Backup Strategy}</property>
<property name="doc(title)">Backup Strategy</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="backup-recovery" leftLabel="Prev"
		    title="
Chapter 8. Backup and Recovery"
		    rightLink="snapshot-backup" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-next-backups" id="install-next-backups"></a>Backup
Strategy</h2></div></div></div><p>The purpose of backup is to enable recovery. Backup and recovery
are always risky; here are some steps that minimize the chance
recovery is necessary:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Store everything on a fault-tolerant disk array (RAID 1 or 5 or
better).</p></li><li class="listitem"><p>Use battery backup.</p></li><li class="listitem"><p>Use more reliable hardware, such as SCSI instead of IDE.</p></li>
</ul></div><p>These steps improve the chances of successful recovery:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Store backups on a third disk on another controller</p></li><li class="listitem"><p>Store backups on a different computer on a different network in
a different physical location. (Compared to off-line backup such as
tapes and CDRs, on-line backup is faster and more likely to
succeed, but requires maintenance of another machine.)</p></li><li class="listitem"><p>Plan and configure for recovery from the beginning.</p></li><li class="listitem"><p>Test your recovery strategy from time to time.</p></li><li class="listitem"><p>Make it easy to maintain and test your recovery strategy, so
that you are more likely to do it.</p></li>
</ul></div><p>OpenACS installations comprise files and database contents. If
you follow the reference install and put all files, including
configuration files, in <code class="filename">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/</code>,
and back up the database nightly to a file in <code class="filename">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/database-backup</code>,
then you can apply standard file-based backup strategies to
<code class="filename">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code>
</p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="backup-recovery" leftLabel="Prev" leftTitle="
Chapter 8. Backup and Recovery"
		    rightLink="snapshot-backup" rightLabel="Next" rightTitle="Manual backup and recovery"
		    homeLink="index" homeLabel="Home" 
		    upLink="backup-recovery" upLabel="Up"> 
		