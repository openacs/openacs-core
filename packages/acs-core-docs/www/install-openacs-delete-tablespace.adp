
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Deleting a tablespace}</property>
<property name="doc(title)">Deleting a tablespace</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="remote-postgres" leftLabel="Prev"
		    title="
Chapter 7. Database Management"
		    rightLink="install-next-nightly-vacuum" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-openacs-delete-tablespace" id="install-openacs-delete-tablespace"></a>Deleting a tablespace</h2></div></div></div><p>Skip down for instructions on <a class="xref" href="install-openacs-delete-tablespace" title="Deleting a PostgreSQL tablespace">Deleting a PostgreSQL
tablespace</a>.</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-openacs-delete-oracle-tablespace" id="install-openacs-delete-oracle-tablespace"></a>Deleting an Oracle
tablespace</h3></div></div></div><p>Should it become necessary to rebuild a tablespace from scratch,
you can use the <code class="computeroutput">drop user</code>
command in SVRMGRL with the <code class="computeroutput">cascade</code> option. This command will drop the
user and every database object the user owns.</p><pre class="programlisting">
SVRMGR&gt; <strong class="userinput"><code>drop user <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> cascade;</code></strong>
</pre><p>If this does not work because svrmgrl "cannot drop a user
that is currently connected", make sure to kill the AOLserver
using this user. If it still does not work, do:</p><pre class="programlisting">
SVRMGR&gt; <strong class="userinput"><code>select username, sid, serial# from v$session where lower(username)='<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>';</code></strong>
</pre><p>and then</p><pre class="programlisting">
SVRMGR&gt; <strong class="userinput"><code>alter system kill session '<span class="replaceable"><span class="replaceable">sid, serial#</span></span>';</code></strong>
</pre><p>where <span class="emphasis"><em>sid</em></span> and
<span class="emphasis"><em>serial#</em></span> are replaced with
the corresponding values for the open session.</p><p><span class="strong"><strong>Use with
caution!</strong></span></p><p>If you feel the need to delete <span class="emphasis"><em>everything</em></span> related to the service, you
can also issue the following:</p><pre class="programlisting">
SVRMGR&gt; <strong class="userinput"><code>drop tablespace <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> including contents cascade constraints;</code></strong>
</pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-openacs-delete-postgres-tablespace" id="install-openacs-delete-postgres-tablespace"></a>Deleting a
PostgreSQL tablespace</h3></div></div></div><p>Dropping a PostgreSQL tablespace is easy. You have to stop any
AOLserver instances that are using the database that you wish to
drop. If you&#39;re using daemontools, this is simple, just use the
'down' flag (-d). If you&#39;re using inittab, you have to
comment out your server in <code class="computeroutput">/etc/inittab</code>, reread the inittab with
<code class="computeroutput">/sbin/init q</code>, and then
<code class="computeroutput">restart-aolserver <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code>.</p><p>Then, to drop the db, just do:</p><pre class="programlisting">
[$OPENACS_SERVICE_NAME ~]$ <strong class="userinput"><code>dropdb <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
DROP DATABASE
</pre>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="remote-postgres" leftLabel="Prev" leftTitle="Running a PostgreSQL database on
another server"
		    rightLink="install-next-nightly-vacuum" rightLabel="Next" rightTitle="Vacuum Postgres nightly"
		    homeLink="index" homeLabel="Home" 
		    upLink="database-management" upLabel="Up"> 
		