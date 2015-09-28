
<property name="context">{/doc/acs-core-docs {Documentation}} {Diagnosing Performance Problems}</property>
<property name="doc(title)">Diagnosing Performance Problems</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="uptime" leftLabel="Prev"
		    title="
Chapter 6. Production Environments"
		    rightLink="database-management" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="maint-performance" id="maint-performance"></a>Diagnosing Performance Problems</h2></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Did performance problems happen overnight, or did they sneak up
on you? Any clue what caused the performance problems (e.g. loading
20K users into .LRN)</p></li><li class="listitem"><p>Is the file system out of space? Is the machine swapping to disk
constantly?</p></li><li class="listitem">
<p>Isolating and solving database problems.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Without daily internal maintenance, most databases slowly
degrade in performance. For PostGreSQL, see <a class="xref" href="install-next-nightly-vacuum" title="Vacuum Postgres nightly">the section called
&ldquo;Vacuum Postgres nightly&rdquo;</a>. For
Oracle, use <code class="computeroutput">exec
dbms_stats.gather_schema_stats('SCHEMA_NAME')</code> (<a class="ulink" href="http://www.piskorski.com/docs/oracle.html" target="_top">Andrew Piskorski's Oracle notes</a>).</p></li><li class="listitem">
<p>You can track the exact amount of time each database query on a
page takes:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Go to <a class="ulink" href="/acs-admin/install" target="_top">Main Site : Site-Wide Administration : Install
Software</a>
</p></li><li class="listitem"><p>Click on "Install New Application" in "Install from OpenACS
Repository"</p></li><li class="listitem"><p>Choose "ACS Developer Support"&gt;</p></li><li class="listitem"><p>After install is complete, restart the server.</p></li><li class="listitem"><p>Browse to Developer Support, which is automatically mounted at
<code class="computeroutput"><a class="ulink" href="/ds" target="_top">/ds</a></code>.</p></li><li class="listitem"><p>Turn on Database statistics</p></li><li class="listitem"><p>Browse directly to a slow page and click "Request Information"
at the bottom of the page.</p></li><li class="listitem">
<p>This should return a list of database queries on the page,
including the exact query (so it can be cut-paste into psql or
oracle) and the time each query took.</p><div class="figure">
<a name="idp140302493769296" id="idp140302493769296"></a><p class="title"><b>Figure 6.8. Query
Analysis example</b></p><div class="figure-contents"><div class="mediaobject"><img src="images/query-duration.png" alt="Query Analysis example"></div></div>
</div><br class="figure-break">
</li>
</ol></div>
</li><li class="listitem">
<p>Identify a runaway Oracle query: first, use <strong class="userinput"><code>ps aux</code></strong> or <strong class="userinput"><code>top</code></strong> to get the UNIX process ID of
a runaway Oracle process.</p><p>Log in to SQL*Plus as the admin:</p><pre class="screen">
[<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> ~]$ svrmgrl

Oracle Server Manager Release 3.1.7.0.0 - Production

Copyright (c) 1997, 1999, Oracle Corporation.  All Rights Reserved.

Oracle8i Enterprise Edition Release 8.1.7.3.0 - Production
With the Partitioning option
JServer Release 8.1.7.3.0 - Production

SVRMGR&gt; <strong class="userinput"><code>connect internal</code></strong>              
Password:
</pre><p>See all of the running queries, and match the UNIX PID:</p><pre class="programlisting">
select p.spid  -- The UNIX PID
       ,s.sid  ,s.serial#
       ,p.username  as os_user
       ,s.username  ,s.status
       ,p.terminal  ,p.program
  from v$session s  ,v$process p
 where p.addr = s.paddr
 order by s.username ,p.spid ,s.sid ,s.serial# ;
</pre><p>See the SQL behind the oracle processes:</p><pre class="programlisting">
select s.username
       ,s.sid  ,s.serial#
       ,sql.sql_text
  from v$session s, v$sqltext sql
 where sql.address    = s.sql_address
   and sql.hash_value = s.sql_hash_value
 --and upper(s.username) like 'USERNAME%'
 order by s.username ,s.sid ,s.serial# ,sql.piece ;
</pre><p>To kill a troubled process:</p><pre class="programlisting">
alter system kill session 'SID,SERIAL#';  --substitute values for SID and SERIAL#
</pre><p>(See <a class="ulink" href="http://www.piskorski.com/docs/oracle.html" target="_top">Andrew
Piskorski's Oracle notes</a>)</p>
</li><li class="listitem">
<p>Identify a runaway Postgres query. First, logging must be
enabled in the database. This imposes a performance penalty and
should not be done in normal operation.</p><p>Edit the file <code class="computeroutput">postgresql.conf</code> - its location depends on
the PostGreSQL installation - and change</p><pre class="programlisting">
#stats_command_string = false
</pre><p>to</p><pre class="programlisting">
stats_command_string = true
</pre><p>Next, connect to postgres (<code class="computeroutput">psql
<span class="replaceable"><span class="replaceable">service0</span></span>
</code>) and <code class="computeroutput">select * from pg_stat_activity;</code>. Typical
output should look like:</p><pre class="programlisting">
  datid   |   datname   | procpid | usesysid | usename |  current_query
----------+-------------+---------+----------+---------+-----------------
 64344418 | openacs.org |   14122 |      101 | nsadmin | &lt;IDLE&gt;
 64344418 | openacs.org |   14123 |      101 | nsadmin |
                                                         delete
                                                         from acs_mail_lite_queue
                                                         where message_id = '2478608';
 64344418 | openacs.org |   14124 |      101 | nsadmin | &lt;IDLE&gt;
 64344418 | openacs.org |   14137 |      101 | nsadmin | &lt;IDLE&gt;
 64344418 | openacs.org |   14139 |      101 | nsadmin | &lt;IDLE&gt;
 64344418 | openacs.org |   14309 |      101 | nsadmin | &lt;IDLE&gt;
 64344418 | openacs.org |   14311 |      101 | nsadmin | &lt;IDLE&gt;
 64344418 | openacs.org |   14549 |      101 | nsadmin | &lt;IDLE&gt;
(8 rows)
openacs.org=&gt;
</pre>
</li>
</ul></div>
</li>
</ul></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-oracle-monitoring" id="install-oracle-monitoring"></a>Creating an appropriate tuning and
monitoring environment</h3></div></div></div><p>The first task is to create an appropriate environment for
finding out what is going on inside Oracle. Oracle provides
Statspack, a package to monitor and save the state of the v$
performance views. These reports help finding severe problems by
exposing summary data about the Oracle wait interface, executed
queries. You'll find the installation instructions in
$ORACLE_HOME/rdbms/admin/spdoc.txt. Follow the instructions
carefully and take periodic snapshots, this way you'll be able to
look at historical performance data.</p><p>Also turn on the timed_statistics in your init.ora file, so that
Statspack reports (and all other Oracle reports) are timed, which
makes them a lot more meaningful. The overhead of timing data is
about 1% per Oracle Support information.</p><p>To be able to get a overview of how Oracle executes a particular
query, install "autotrace". I usually follow the instructions here
<a class="ulink" href="http://asktom.oracle.com/~tkyte/article1/autotrace.html" target="_top">http://asktom.oracle.com/~tkyte/article1/autotrace.html</a>.</p><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="idp140302493792016" id="idp140302493792016"></a>Make sure, that the Oracle CBO works with
adequate statistics</h4></div></div></div><p>The Oracle Cost Based optimizer is a piece of software that
tries to find the "optimal" execution plan for a given SQL
statement. For that it estimates the costs of running a SQL query
in a particular way (by default up to 80.000 permutations are being
tested in a Oracle 8i). To get an adequate cost estimate, the CBO
needs to have adequate statistics. For that Oracle supplies the
<a class="ulink" href="http://download-west.oracle.com/docs/cd/B10501_01/appdev.920/a96612/d_stats.htm#999107" target="_top">dbms_stats package</a>.</p>
</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="uptime" leftLabel="Prev" leftTitle="External uptime validation"
		    rightLink="database-management" rightLabel="Next" rightTitle="
Chapter 7. Database Management"
		    homeLink="index" homeLabel="Home" 
		    upLink="maintenance-web" upLabel="Up"> 
		