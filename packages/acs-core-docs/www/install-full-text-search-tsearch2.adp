
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install Full Text Search using Tsearch2}</property>
<property name="doc(title)">Install Full Text Search using Tsearch2</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="install-nspam" leftLabel="Prev"
		    title="
Appendix B. Install additional supporting
software"
		    rightLink="install-full-text-search-openfts" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-full-text-search-tsearch2" id="install-full-text-search-tsearch2"></a>Install Full Text Search
using Tsearch2</h2></div></div></div><div class="authorblurb">
<p>By <a class="ulink" href="mailto:dave\@thedesignexperience.org" target="_top">Dave Bauer</a>, <a class="ulink" href="mailto:joel\@aufrecht.org" target="_top">Joel Aufrecht</a> and
<a class="ulink" href="mailto:openacs\@sussdorff.de" target="_top">Malte Sussdorff</a> with help from <a class="ulink" href="http://www.sai.msu.su/~megera/postgres/gist/tsearch/V2/docs/tsearch-V2-intro.html" target="_top">Tsearch V2 Introduction by Andrew J. Kopciuch</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-tsearch2" id="install-tsearch2"></a>Install Tsearch2 module</h3></div></div></div><a class="indexterm" name="idp140592107348664" id="idp140592107348664"></a><p>If you want full text search, and you are running PostgreSQL,
install this module to support FTS. Do this step after you have
installed both PostgreSQL and AOLserver. You will need the tsearch2
module form PostgreSQL contrib. This is included with the
PostgreSQL full source distribution. It is also available with the
PostgreSQL contrib package provided by most distribution packages.
On debian it is called postgresql-contrib.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>For PostgreSQL 7.3 or 7.4, download the
http://www.sai.msu.su/~megera/postgres/gist/tsearch/V2/regprocedure_7.4.patch.gz
tsearch2 patch to correctly restore from a pg_dump backup. If you
installed tsearch2 from a package, you can use the
http://www.sai.msu.su/~megera/postgres/gist/tsearch/V2/regprocedure_update.sql
regprocedure script to update the database after tsearch2 is
installed into it. TODO link to section describing how to fix an
existing tsearch2 database with this patch.</p></li><li class="listitem">
<p>As of May 9, 2004 there is a source patch available for
tsearch2. The patch provides changes to the pg_ts_ configuration
tables to allow for easy dump and restore of a database containing
tsearch2. The patch is available here : <a class="ulink" href="http://www.sai.msu.su/~megera/postgres/gist/tsearch/V2/regprocedure_7.4.patch.gz" target="_top">[http://www.sai.msu.su/~megera/postgres/gist/tsearch/V2/regprocedure_7.4.patch.gz]</a>
</p><p>To apply this patch, download the mentioned file and place it in
your postgreSQL source tree ($PGSQL_SRC). This patch makes the
backup and restore procedures very simple.</p><pre class="screen">
            [postgres pgsql]$ <strong class="userinput"><code>cd /tmp</code></strong>
            [postgres tmp]$ <strong class="userinput"><code>wget http://www.sai.msu.su/~megera/postgres/gist/tsearch/V2/regprocedure_7.4.patch.gz</code></strong>
            [postgres pgsql]$ <strong class="userinput"><code>cd /usr/local/src/postgresql-7.4.5/</code></strong>
            [postgres postgresql-7.4.5] <strong class="userinput"><code>gunzip /tmp/regprocedure_7.4.patch.gz</code></strong>
            [postgres postgresql-7.4.5] <strong class="userinput"><code>patch -b -p1 &lt; regprocedure_7.4.patch</code></strong>
</pre><p>If you have a working version of tsearch2 in your database, you
do not need to re-install the tsearch2 module. Just apply the patch
and run make. This patch only affects the tsearch2.sql file. You
can run the SQL script found : <a class="ulink" href="http://www.sai.msu.su/~megera/postgres/gist/tsearch/V2/regprocedure_update.sql" target="_top">[right here]</a> This script will make the
modifications found in the patch, and update the fields from the
existing data. From this point on, you can dump and restore the
database in a normal fashion. Without this patch, you must follow
the instructions later in this document for backup and restore.</p><p>This patch is only needed for tsearch2 in PostgreSQL versions
7.3.x and 7.4.x. The patch has been applied to the sources for
8.0.</p>
</li><li class="listitem">
<p>Install Tsearch2. This is a PostgreSQL module that the
tsearch2-driver OpenACS package requires. These instructions assume
you are using the latest point release of PostgreSQL 7.4.5.</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - postgres</code></strong>
[postgres pgsql]$ <strong class="userinput"><code>cd /usr/local/src/postgresql-7.4.5/contrib/tsearch2/</code></strong>
[postgres tsearch2]$ <strong class="userinput"><code>make</code></strong>
[postgres tsearch2]$ <strong class="userinput"><code>make install</code></strong>
mkdir /usr/local/pgsql/share/contrib
mkdir /usr/local/pgsql/doc/contrib
(2 lines omitted)
/bin/sh ../../config/install-sh -c -m 755 libtsearch.so.0.0 /usr/local/pgsql/lib/tsearch.so
[postgres tsearch]$ <strong class="userinput"><code>exit</code></strong>
logout

[root root]#
<span class="action"><span class="action">su - postgres
cd /usr/local/src/postgresql-7.4.5/contrib/tsearch2
make
make install
exit</span></span>
</pre>
</li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-fts-engine" id="install-fts-engine"></a>Install Full Text Search Engine Package in
OpenACS</h3></div></div></div><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Click <code class="computeroutput"><span class="guilabel"><span class="guilabel">Admin</span></span></code> on the
top of the default home page. If prompted, log in with the account
and password you entered during install.</p></li><li class="listitem"><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Install
software</span></span></code> link.</p></li><li class="listitem"><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Install new
service</span></span></code> link.</p></li><li class="listitem"><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Install</span></span></code> link
next to Tsearch2 Driver. If you have installed tsearch2 into your
PostgreSQL database, the installer will automatically enable
tsearch in your OpenACS database instance.</p></li><li class="listitem">
<p>Restart the service.</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>svc -t /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$
</pre>
</li><li class="listitem"><p>Wait a minute, then browse back to the home page.</p></li><li class="listitem"><p>Click on <code class="computeroutput"><span class="guilabel"><span class="guilabel">Admin</span></span></code> on the
top of the screen.</p></li><li class="listitem"><p>Click on <code class="computeroutput"><span class="guilabel"><span class="guilabel">Main Site
Administration</span></span></code> in the "Subsite
Administration" section.</p></li><li class="listitem"><p>Click on <code class="computeroutput"><span class="guilabel"><span class="guilabel">Site Map</span></span></code> in
the "Advanced Features" section.</p></li><li class="listitem">
<p>Mount the Search interface in the site map.</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem"><p>Click the <code class="computeroutput"><span class="guilabel"><span class="guilabel">new sub
folder</span></span></code> link on the Main Site line.</p></li><li class="listitem"><p>Type <strong class="userinput"><code>search</code></strong> and
click <code class="computeroutput"><span class="guibutton"><span class="guibutton">New</span></span></code>.</p></li><li class="listitem"><p>Click the <code class="computeroutput"><span class="guilabel"><span class="guilabel">new
application</span></span></code> link on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">search</span></span></code> line.</p></li><li class="listitem"><p>Type <strong class="userinput"><code>search</code></strong>
where it says <code class="computeroutput"><span class="guilabel"><span class="guilabel">untitled</span></span></code>,
choose <code class="computeroutput"><span class="guilabel"><span class="guilabel">search</span></span></code> from
the drop-down list, and click <code class="computeroutput"><span class="guibutton"><span class="guibutton">New</span></span></code>.</p></li><li class="listitem"><p>Click the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Parameters</span></span></code>
link next to the Search package istance.</p></li><li class="listitem"><p>Type <strong class="userinput"><code>tsearch2-driver</code></strong> where it says
<code class="computeroutput"><span class="guilabel"><span class="guilabel">openfts-driver</span></span></code> in the <code class="computeroutput"><span class="guilabel"><span class="guilabel">FtsEngineDriver</span></span></code> parameter.</p></li>
</ol></div>
</li><li class="listitem">
<p>Restart the service.</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>svc -t /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$
</pre>
</li><li class="listitem"><p>Wait a minute, then click on <code class="computeroutput"><span class="guilabel"><span class="guilabel">Main
Site</span></span></code> at the top of the page.</p></li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-fts-content-provider" id="install-fts-content-provider"></a>Enable Full Text Search in
packages</h3></div></div></div><p>Enabling Full Text Search in packages at the moment is not
trivial. It involves a couple of steps, which I will illustrate
taking lars-blogger as an example package</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>Install the package.</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem"><p>Click <code class="computeroutput"><span class="guilabel"><span class="guilabel">Admin</span></span></code> on the
top of the default home page. If prompted, log in with the account
and password you entered during install.</p></li><li class="listitem"><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Install
software</span></span></code> link.</p></li><li class="listitem"><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Install new
application</span></span></code> link.</p></li><li class="listitem"><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Install</span></span></code> link
next to Weblogger.</p></li><li class="listitem"><p>Install all required packages as well (always say okay until you
shall restart the server)</p></li>
</ol></div>
</li><li class="listitem">
<p>Load the service contracts datamodell and enable the service
contract</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cd packages/lars-blogger/sql/postgresql</code></strong>
[$OPENACS_SERVICE_NAME postgresql]$ psql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> -f lars-blogger-sc-create.sql
</pre><p>Note: Usually this script is called <span class="replaceable"><span class="replaceable">package_name</span></span>-sc-create.sql</p>
</li><li class="listitem">
<p>Restart the service.</p><pre class="screen">
[$OPENACS_SERVICE_NAME postgresql]$ <strong class="userinput"><code>svc -t /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
                [$OPENACS_SERVICE_NAME postgresl]$
</pre>
</li>
</ol></div><p>If you are lucky, Full Text Search is enabled now, if not
consult <a class="ulink" href="http://openacs.org/forums/message-view?message_id=154759" target="_top">http://openacs.org/forums/message-view?message_id=154759</a>.
This link also contains some hints on how to make sure it is
enabled.</p>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="install-nspam" leftLabel="Prev" leftTitle="Install nspam"
		    rightLink="install-full-text-search-openfts" rightLabel="Next" rightTitle="Install Full Text Search using
OpenFTS (deprecated see tsearch2)"
		    homeLink="index" homeLabel="Home" 
		    upLink="install-more-software" upLabel="Up"> 
		