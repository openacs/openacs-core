
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Upgrading Platform components}</property>
<property name="doc(title)">Upgrading Platform components</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="upgrade-openacs-files" leftLabel="Prev"
		    title="
Chapter 5. Upgrading"
		    rightLink="maintenance-web" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="upgrade-supporting" id="upgrade-supporting"></a>Upgrading Platform components</h2></div></div></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="upgrade-openfts-0.2-to-0.3.2" id="upgrade-openfts-0.2-to-0.3.2"></a>Upgrading OpenFTS from 0.2 to
0.3.2</h3></div></div></div><p>OpenACS Full Text Search requires several pieces: the OpenFTS
code, some database functions, and the OpenFTS Engine. This section
describes how to upgrade OpenFTS from 0.2 to 0.3.2 and upgrade the
search engine on an OpenACS site at the same time.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>Uninstall the old OpenFTS Engine from the <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> database.</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem"><p><span class="bold"><strong>Browse to <code class="computeroutput">http://<span class="replaceable"><span class="replaceable">yourserver</span></span>/openfts</code>.</strong></span></p></li><li class="listitem"><p><span class="bold"><strong>Click <code class="computeroutput"><span class="guilabel"><span class="guilabel">Administration</span></span></code>.</strong></span></p></li><li class="listitem"><p><span class="bold"><strong>Click <code class="computeroutput"><span class="guibutton"><span class="guibutton">Drop OpenFTS
Engine</span></span></code>
</strong></span></p></li>
</ol></div>
</li><li class="listitem">
<p>Build and install the new OpenFTS driver and supporting Tcl
procedures. (This section of shell code is not fully documented;
please exercise care.)</p><pre class="screen">
cd /usr/local/src/
          tar xzf /var/tmp/Search-OpenFTS-tcl-0.3.2.tar.gz
          chown -R root.root Search-OpenFTS-tcl-0.3.2/
          cd Search-OpenFTS-tcl-0.3.2/
          ./configure --with-aolserver-src=/usr/local/src/aolserver/aolserver --with-tcl=/usr/lib/
          cd aolserver/
          make
          
</pre><p>Back up the old fts driver as a precaution and install the newly
compiled one</p><pre class="screen">
mv /usr/local/aolserver/bin/nsfts.so /usr/local/aolserver/bin/nsfts-0.2.so 
          cp nsfts.so /usr/local/aolserver/bin
          
</pre><p>Build and install the OpenFTS code for PostGresSQL</p><pre class="screen">
cd /usr/local/src/Search-OpenFTS-tcl-0.3.2/
          cp -r pgsql_contrib_openfts /usr/local/src/postgresql-7.2.3/contrib /usr/local/src/postgresql-7.2.3/contrib/pgsql_contrib_openfts
          make
          su - postgres
          cd tsearch/
          make
          make install
          exit
</pre><p>In order for the OpenACS 4.6 OpenFTS Engine to use the OpenFTS
0.3.2 driver, we need some commands added to the database.</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
          [$OPENACS_SERVICE_NAME dev]$ <strong class="userinput"><code>psql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> -f /usr/local/pgsql/share/contrib/openfts.sql</code></strong>
          CREATE
          CREATE
          [$OPENACS_SERVICE_NAME dev]$ <strong class="userinput"><code>psql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> -f /usr/local/src/postgresql-7.2.3/contrib/tsearch/tsearch.sql</code></strong>
          BEGIN
          CREATE
          (~30 more lines)
          [$OPENACS_SERVICE_NAME dev]$ <strong class="userinput"><code>exit</code></strong>
          [root root]# 
          <span class="action"><span class="action">su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
psql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> -f /usr/local/pgsql/share/contrib/openfts.sql
psql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> -f /usr/local/src/postgresql-7.2.3/contrib/tsearch/tsearch.sql
exit</span></span>
</pre>
</li><li class="listitem">
<p>
<strong>OPTIONAL: Install the new OpenFTS
Engine. </strong>If you want to upgrade the OpenFTS
Engine, do these steps. (You must have already upgraded the OpenFTS
driver to 0.3.2.)</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem"><p>Browse to <code class="computeroutput">http://<span class="replaceable"><span class="replaceable">yourserver</span></span>/admin/site-map</code>
</p></li><li class="listitem"><p>On the <code class="computeroutput">openfts</code> line, click
on <code class="computeroutput"><span class="guilabel"><span class="guilabel">set parameters</span></span></code>.</p></li><li class="listitem"><p>Change the value of <code class="computeroutput">openfts_tcl_src_path</code> from <code class="computeroutput">/usr/local/src/Search-OpenFTS-tcl-0.2/</code> to
<code class="computeroutput">/usr/local/src/Search-OpenFTS-tcl-0.3.2/</code>
</p></li><li class="listitem"><p>Click <code class="computeroutput"><span class="guibutton"><span class="guibutton">Set
Parameters</span></span></code>
</p></li><li class="listitem"><pre class="screen">
[root root]# restart-aolserver <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</pre></li><li class="listitem"><p>Browse to <code class="computeroutput">http://<span class="replaceable"><span class="replaceable">yourserver</span></span>/openfts</code>
</p></li><li class="listitem"><p><span class="bold"><strong>Click <code class="computeroutput"><span class="guilabel"><span class="guilabel">Administration</span></span></code>.</strong></span></p></li><li class="listitem"><p><span class="bold"><strong>Click <code class="computeroutput"><span class="guibutton"><span class="guibutton">Initialize OpenFTS
Engine</span></span></code>
</strong></span></p></li>
</ol></div>
</li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="upgrade-postgres-7.2-to-7.3" id="upgrade-postgres-7.2-to-7.3"></a>Upgrading from PostGreSQL 7.2 to
7.3</h3></div></div></div><p>An OpenACS database created in PostGreSQL 7.2 will not work
correctly in PostGreSQL 7.3. This is because 7.2 truncates function
names to 31 characters, but 7.3 does not. This does not cause
problems in 7.2, because truncation occurs both at function
creation and at function calling, so they still match. But if you
use a database created in 7.2 in 7.3, the function names in the
database remain truncated but the function calls are not, and so
they don&#39;t match. Also some functions use casting commands that
no longer work in 7.3 and these functions must be recreated.</p><p>To upgrade an OpenACS site from PostGreSQL 7.2 to 7.3, first
upgrade the kernel to 4.6.3. Then, dump the database, run the
upgrade script <code class="computeroutput">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/bin/pg_7.2to7.3_upgrade_helper.pl</code>
on the dump file, and reply the dump. See <a class="ulink" href="http://openacs.org/forums/message-view?message_id=109337" target="_top">Forum OpenACS Q&amp;A: PG 7.2-&gt;7.3 upgrade gotcha?</a>.
Example:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Back up the database as per <a class="xref" href="snapshot-backup" title="PostgreSQL">PostgreSQL</a>.</p></li><li class="listitem">
<p>Run the upgrade script on the backup file.</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
          [$OPENACS_SERVICE_NAME <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>]# <strong class="userinput"><code>cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/bin</code></strong>
          [$OPENACS_SERVICE_NAME bin]$ <strong class="userinput"><code>./pg_7.2to7.3_upgrade_helper.pl \
          ../database-backup/nightly.dmp \
          ../database-backup/upgrade-7.3.dmp \
          /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
          ==================================================================
          looking for function acs_object__check_object_ancest in oacs
          grep result: /var/lib/aolserver/aufrecht-dev/packages/acs-kernel/sql/postgresql/acs-objects-create.sql:create function acs_object__check_object_ancestors (integer,integer,integer)

          replacing acs_object__check_object_ancest with acs_object__check_object_ancestors

          <span class="emphasis"><em>(many lines omitted)</em></span>
          [$OPENACS_SERVICE_NAME bin]$
          
</pre>
</li><li class="listitem"><p>Use perl to replace <code class="computeroutput">timestamp</code> with <code class="computeroutput">timestamptz</code> in the dump file. See example
perl code in step two in <a class="ulink" href="http://cvs.openacs.org/browse/OpenACS/openacs-4/contrib/misc/upgrade_4.6_to_5.0.sh?r=1.6" target="_top">/contrib/misc/upgrade_4.6_to_5.0.sh</a>
</p></li><li class="listitem"><p>Create a new user for PostgreSQL 7.3.x, as per the Postgres
installation guide. Keep in mind that your installation location is
different, and your startup script (/etc/init.d/postgres73 should
be named differently. You might even need to edit that file to make
the paths correct). You&#39;ll also need to add <code class="computeroutput">export PGPORT=5434</code> to the .bashrc and/or
.bash_profile for the postgres73 user.</p></li><li class="listitem"><p>Install PostgreSQL 7.3.x. Note that you PostgreSQL must listen
on a different port in order to work correctly, so you&#39;ll need
to edit the configuration file
(/usr/local/pgsql73/data/postgresql.conf) and change the port (to
5433, say). create a second postgres user to differentiate between
the two postgres installs. When you do ./configure, you&#39;ll need
to include --prefix=$HOME to ensure that it is installed in the
postgres73 user&#39;s home directory.</p></li><li class="listitem"><p>Change the path in <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>'s .bashrc or
.bash_profile (or both) files to reflect the new postgres73 user
directory. Also add in the PGPORT.</p></li><li class="listitem"><p>Restore the database from dump as per the <a class="link" href="snapshot-backup" title="Postgres">recovery
instructions</a>.</p></li>
</ol></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="upgrade-openacs-files" leftLabel="Prev" leftTitle="Upgrading the OpenACS files"
		    rightLink="maintenance-web" rightLabel="Next" rightTitle="
Chapter 6. Production Environments"
		    homeLink="index" homeLabel="Home" 
		    upLink="upgrade" upLabel="Up"> 
		