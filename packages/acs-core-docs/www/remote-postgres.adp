
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Running a PostgreSQL database on another server}</property>
<property name="doc(title)">Running a PostgreSQL database on another server</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="database-management" leftLabel="Prev"
		    title="
Chapter 7. Database Management"
		    rightLink="install-openacs-delete-tablespace" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="remote-postgres" id="remote-postgres"></a>Running a PostgreSQL database on another
server</h2></div></div></div><p>To run a database on a different machine than the webserver
requires changes to the database configuration file and access
control file, and to the OpenACS service&#39;s configuration
file.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>Edit the database configuration file, which in a Reference
install is located at <code class="computeroutput">/usr/local/pgsql/data/postgresql.conf</code> and
change</p><pre class="programlisting">
#tcpip_socket = false
</pre><p>to</p><pre class="programlisting">
tcpip_socket = true
</pre>
</li><li class="listitem"><p>Change the access control file for the database to permit
specific remote clients to access. Access can be controlled ...
(add notes from forum post)</p></li><li class="listitem">
<p>Change the OpenACS service&#39;s configuration file to point to
the remote database. Edit <code class="computeroutput">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/etc/config.tcl</code>
and change</p><pre class="programlisting"></pre><p>to</p><pre class="programlisting"></pre>
</li>
</ul></div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="database-management" leftLabel="Prev" leftTitle="
Chapter 7. Database Management"
		    rightLink="install-openacs-delete-tablespace" rightLabel="Next" rightTitle="Deleting a tablespace"
		    homeLink="index" homeLabel="Home" 
		    upLink="database-management" upLabel="Up"> 
		