
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Vacuum Postgres nightly}</property>
<property name="doc(title)">Vacuum Postgres nightly</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="install-openacs-delete-tablespace" leftLabel="Prev"
		    title="
Chapter 7. Database Management"
		    rightLink="backup-recovery" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-next-nightly-vacuum" id="install-next-nightly-vacuum"></a>Vacuum Postgres nightly</h2></div></div></div><p>The "vacuum" command must be run periodically to
reclaim space in versions of PostgreSQL before 7.4. The
"vacuum analyze" form additionally collects statistics on
the disbursion of columns in the database, which the optimizer uses
when it calculates just how to execute queries. The availability of
this data can make a tremendous difference in the execution speed
of queries. This command can also be run from cron, but it probably
makes more sense to run this command as part of your nightly backup
procedure - if "vacuum" is going to screw up the
database, you&#39;d prefer it to happen immediately after (not
before!) you&#39;ve made a backup! The "vacuum" command
is very reliable, but conservatism is the key to good system
management. So, if you&#39;re using the export procedure described
above, you don&#39;t need to do this extra step.</p><p>Edit your crontab:</p><pre class="programlisting">
[joeuser ~]$ <strong class="userinput"><code>crontab -e</code></strong>
</pre><p>We&#39;ll set vacuum up to run nightly at 1 AM. Add the
following line:</p><pre class="programlisting">
0 1 * * * /usr/local/pgsql/bin/vacuumdb <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</pre><div class="cvstag">($&zwnj;Id: database-maintenance.xml,v 1.8.14.1
2016/06/23 08:32:46 gustafn Exp $)</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="install-openacs-delete-tablespace" leftLabel="Prev" leftTitle="Deleting a tablespace"
		    rightLink="backup-recovery" rightLabel="Next" rightTitle="
Chapter 8. Backup and Recovery"
		    homeLink="index" homeLabel="Home" 
		    upLink="database-management" upLabel="Up"> 
		