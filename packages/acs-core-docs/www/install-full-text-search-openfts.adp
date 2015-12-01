
<property name="context">{/doc/acs-core-docs {Documentation}} {Install Full Text Search using OpenFTS (deprecated see
tsearch2)}</property>
<property name="doc(title)">Install Full Text Search using OpenFTS (deprecated see
tsearch2)</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="install-full-text-search-tsearch2" leftLabel="Prev"
		    title="
Appendix B. Install additional supporting
software"
		    rightLink="install-nsopenssl" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="install-full-text-search-openfts" id="install-full-text-search-openfts"></a>Install Full Text Search
using OpenFTS (deprecated see tsearch2)</h2></div></div></div><div class="authorblurb">
<p>By <a class="ulink" href="mailto:joel\@aufrecht.org" target="_top">Joel Aufrecht</a> and <a class="ulink" href="mailto:openacs\@sussdorff.de" target="_top">Malte Sussdorff</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>OpenFTS and tsearch1 use is deprecated in favor of Tsearch2. See
<a class="xref" href="install-full-text-search-tsearch2" title="Install Full Text Search using Tsearch2">Install Full Text
Search using Tsearch2</a>. Tsearch2 is much easier to install,
requiring only compilation of one module from PostgreSQL contrib,
with an automated install process using the tsearch2-driver
package.</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-openfts" id="install-openfts"></a>Install OpenFTS module</h3></div></div></div><a class="indexterm" name="idp140216766778544" id="idp140216766778544"></a><p>If you want full text search, and you are running PostgreSQL,
install this module to support FTS. Do this step after you have
installed both PostgreSQL and AOLserver. You will need the
<a class="link" href="individual-programs">openfts tarball</a> in
<code class="computeroutput">/tmp</code>.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>Install Tsearch. This is a PostgreSQL module that OpenFTS
requires.</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - postgres</code></strong>
[postgres pgsql]$ <strong class="userinput"><code>cd /usr/local/src/postgresql-7.3.4/contrib/tsearch/</code></strong>
[postgres tsearch]$ <strong class="userinput"><code>make</code></strong>
sed 's,MODULE_PATHNAME,$libdir/tsearch,g' tsearch.sql.in &gt;tsearch.sql
/usr/bin/flex  -8 -Ptsearch_yy -o'parser.c' parser.l<span class="emphasis"><em>(many lines omitted)</em></span>
rm -f libtsearch.so
ln -s libtsearch.so.0.0 libtsearch.so
[postgres tsearch]$ <strong class="userinput"><code>make install</code></strong>
mkdir /usr/local/pgsql/share/contrib
mkdir /usr/local/pgsql/doc/contrib
(2 lines omitted)
/bin/sh ../../config/install-sh -c -m 755 libtsearch.so.0.0 /usr/local/pgsql/lib/tsearch.so
[postgres tsearch]$ <strong class="userinput"><code>exit</code></strong>
logout

[root root]#
<span class="action"><span class="action">su - postgres
cd /usr/local/src/postgresql-7.3.4/contrib/tsearch
make
make install
exit</span></span>
</pre>
</li><li class="listitem">
<p>Unpack the OpenFTS tarball and compile and install the
driver.</p><pre class="screen">
[root root]# <strong class="userinput"><code>cd /usr/local/src</code></strong>
[root src]# <strong class="userinput"><code>tar xzf /tmp/Search-OpenFTS-tcl-0.3.2.tar.gz</code></strong>
[root src]# <strong class="userinput"><code>cd /usr/local/src/Search-OpenFTS-tcl-0.3.2/</code></strong>
[root Search-OpenFTS-tcl-0.3.2]# <strong class="userinput"><code>./configure --with-aolserver-src=/usr/local/src/aolserver/aolserver --with-tcl=/usr/lib/</code></strong>
checking prefix... /usr/local
checking for gcc... gcc
<span class="emphasis"><em>(many lines omitted)</em></span>
configure: creating ./config.status
config.status: creating Makefile.global
[root Search-OpenFTS-tcl-0.3.2]#<strong class="userinput"><code> make</code></strong>
(cd parser; make all)
make[1]: Entering directory `/usr/local/src/Search-OpenFTS-tcl-0.3.2/parser'
<span class="emphasis"><em>(many lines omitted)</em></span>
packages provided were {Lingua::Stem::Snowball 0.3.2}
processed fts_base_snowball.tcl
[root Search-OpenFTS-tcl-0.3.2]# <strong class="userinput"><code>cd aolserver</code></strong>
[root aolserver]# <strong class="userinput"><code>make</code></strong>
gcc -c -fPIC  -DPACKAGE=\"OPENFTS\" -DVERSION=\"0.3.2\" -DHAVE_UNISTD_H=1 -DSTDC_HEADERS=1 -DHAVE_SYS_TYPES_H=1 -DHAVE_SYS_STAT_H=1 -DHAVE_STDLIB_H=1 -DHAVE_STR
<span class="emphasis"><em>(many lines omitted)</em></span>
n_stem.o italian_stem.o norwegian_stem.o portuguese_stem.o russian_stem.o nsfts.o  -o nsfts.so
[root aolserver]# <strong class="userinput"><code>cp nsfts.so /usr/local/aolserver/bin/</code></strong>
[root aolserver]#
<span class="action"><span class="action">cd /usr/local/src 
tar xzf /tmp/Search-OpenFTS-tcl-0.3.2.tar.gz
cd /usr/local/src/Search-OpenFTS-tcl-0.3.2/
./configure --with-aolserver-src=/usr/local/src/aolserver/aolserver --with-tcl=/usr/lib/
make
cd aolserver
make
cp nsfts.so /usr/local/aolserver/bin
</span></span>
</pre>
</li><li class="listitem">
<p>Build some supplemental modules.</p><pre class="screen">
[root aolserver]# <strong class="userinput"><code>cd /usr/local/src/Search-OpenFTS-tcl-0.3.2</code></strong>
[root Search-OpenFTS-tcl-0.3.2]# <strong class="userinput"><code>cp -r pgsql_contrib_openfts /usr/local/src/postgresql-7.3.4/contrib</code></strong>
[root Search-OpenFTS-tcl-0.3.2]# <strong class="userinput"><code>cd /usr/local/src/postgresql-7.3.4/contrib/pgsql_contrib_openfts</code></strong>
[root pgsql_contrib_openfts]#<strong class="userinput"><code> make</code></strong>
sed 's,MODULE_PATHNAME,$libdir/openfts,g' openfts.sql.in &gt;openfts.sql
gcc -O2 -Wall -Wmissing-prototypes -Wmissing-declarations -fpic -I. -I../../src/include   -c -o openfts.o openfts.c
gcc -shared -o openfts.so openfts.o
rm openfts.o
[root pgsql_contrib_openfts]# <strong class="userinput"><code>su postgres</code></strong>
[postgres pgsql_contrib_openfts]$ <strong class="userinput"><code>make install</code></strong>
/bin/sh ../../config/install-sh -c -m 644 openfts.sql /usr/local/pgsql/share/contrib
/bin/sh ../../config/install-sh -c -m 755 openfts.so /usr/local/pgsql/lib
/bin/sh ../../config/install-sh -c -m 644 ./README.openfts /usr/local/pgsql/doc/contrib
[postgres pgsql_contrib_openfts]$<strong class="userinput"><code> exit</code></strong>
[root pgsql_contrib_openfts]#
<span class="action"><span class="action">cd /usr/local/src/Search-OpenFTS-tcl-0.3.2
cp -r pgsql_contrib_openfts /usr/local/src/postgresql-7.3.4/contrib
cd /usr/local/src/postgresql-7.3.4/contrib/pgsql_contrib_openfts
make
su postgres
make install
exit</span></span>
</pre>
</li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-openfts-postgres" id="install-openfts-postgres"></a>Install OpenFTS prerequisites in
PostgreSQL instance</h3></div></div></div><a class="indexterm" name="idp140216766084352" id="idp140216766084352"></a><p>If you are installing Full Text Search, add required packages to
the new database. (In order for full text search to work, you must
also <a class="link" href="install-full-text-search-openfts" title="Install OpenFTS module">install</a> the PostgreSQL OpenFTS module
and prerequisites.)</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>/usr/local/pgsql/bin/psql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> -f /usr/local/src/postgresql-7.3.4/contrib/tsearch/tsearch.sql</code></strong>
BEGIN
CREATE
<span class="emphasis"><em>(many lines omitted)</em></span>
INSERT 0 1
COMMIT
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>/usr/local/pgsql/bin/psql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> -f /usr/local/src/postgresql-7.3.4/contrib/pgsql_contrib_openfts/openfts.sql</code></strong>
CREATE
CREATE
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$
<span class="action"><span class="action">/usr/local/pgsql/bin/psql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> -f /usr/local/src/postgresql-7.3.4/contrib/tsearch/tsearch.sql
/usr/local/pgsql/bin/psql <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> -f /usr/local/src/postgresql-7.3.4/contrib/pgsql_contrib_openfts/openfts.sql</span></span>
</pre><div class="note" style="margin-left: 0.5in; margin-right: 0.5in;">
<h3 class="title">Note</h3><p>If you get the error <code class="computeroutput">ERROR: could
not access file "$libdir/tsearch": no such file or directory</code>
It is probably because PostgreSQL's libdir configuration variable
points to a diffent directory than where tsearch is. You can find
out where PostgreSQL expects to find tsearch via</p><pre class="screen"><strong class="userinput"><code>pg_config --pkglibdir</code></strong></pre>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="enable-openfts" id="enable-openfts"></a>Enable OpenFTS in config.tcl</h3></div></div></div><p>If you have <a class="link" href="install-full-text-search-openfts" title="Install OpenFTS module">installed OpenFTS</a>, you can enable it
for this service. Uncomment this line from <code class="computeroutput">config.tcl</code>. (To uncomment a line in a tcl
file, remove the <code class="computeroutput">#</code> at the
beginning of the line.)</p><pre class="programlisting">
#ns_param   nsfts           ${bindir}/nsfts.so
</pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-fts-engine-openfts" id="install-fts-engine-openfts"></a>Install Full Text Search
Engine</h3></div></div></div><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Click <code class="computeroutput"><span class="guilabel"><span class="guilabel">Admin</span></span></code> on the
top of the default home page. If prompted, log in with the account
and password you entered during install.</p></li><li class="listitem"><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Install
software</span></span></code> link.</p></li><li class="listitem"><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Install new
service</span></span></code> link.</p></li><li class="listitem"><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Install</span></span></code> link
next to OpenFTS Driver.</p></li><li class="listitem">
<p>Restart the service.</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>svc -t /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$
</pre>
</li><li class="listitem"><p>Wait a minute, then browse back to the home page.</p></li><li class="listitem"><p>Click on <code class="computeroutput"><span class="guilabel"><span class="guilabel">Admin</span></span></code> on the
top of the screen.</p></li><li class="listitem"><p>Click on <code class="computeroutput"><span class="guilabel"><span class="guilabel">Main Site
Administration</span></span></code> in the "Subsite Administration"
section.</p></li><li class="listitem"><p>Click on <code class="computeroutput"><span class="guilabel"><span class="guilabel">Site Map</span></span></code> in
the "Advanced Features" section.</p></li><li class="listitem">
<p>Mount the OpenFTS Full Text Search Engine in the site map.</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem"><p>Click the <code class="computeroutput"><span class="guilabel"><span class="guilabel">new sub
folder</span></span></code> link on the "/" line, the first line
under Main Site:/.</p></li><li class="listitem"><p>Type <strong class="userinput"><code>openfts</code></strong> and
click <code class="computeroutput"><span class="guibutton"><span class="guibutton">New</span></span></code>.</p></li><li class="listitem"><p>On the new <code class="computeroutput"><span class="guilabel"><span class="guilabel">openfts</span></span></code>
line, click the <code class="computeroutput"><span class="guilabel"><span class="guilabel">mount</span></span></code>
link.</p></li><li class="listitem"><p>Click <code class="computeroutput"><span class="guilabel"><span class="guilabel">OpenFTS
Driver</span></span></code>.</p></li><li class="listitem"><p>On the <code class="computeroutput"><span class="guilabel"><span class="guilabel">openfts</span></span></code>
line, click <code class="computeroutput"><span class="guilabel"><span class="guilabel">set
parameters</span></span></code>.</p></li><li class="listitem"><p>Change <code class="computeroutput"><span class="guilabel"><span class="guilabel">openfts_tcl_src_path</span></span></code> to
<strong class="userinput"><code>/usr/local/src/Search-OpenFTS-tcl-0.3.2/</code></strong>
and click <code class="computeroutput"><span class="guibutton"><span class="guibutton">Set
Parameters</span></span></code>
</p></li>
</ol></div>
</li><li class="listitem">
<p>Mount the Search interface in the site map.</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem"><p>Click the <code class="computeroutput"><span class="guilabel"><span class="guilabel">new sub
folder</span></span></code> link on the Main Site line.</p></li><li class="listitem"><p>Type <strong class="userinput"><code>search</code></strong> and
click <code class="computeroutput"><span class="guibutton"><span class="guibutton">New</span></span></code>.</p></li><li class="listitem"><p>Click the <code class="computeroutput"><span class="guilabel"><span class="guilabel">new
application</span></span></code> link on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">search</span></span></code> line.</p></li><li class="listitem"><p>Type <strong class="userinput"><code>search</code></strong>
where it says <code class="computeroutput"><span class="guilabel"><span class="guilabel">untitled</span></span></code>,
choose <code class="computeroutput"><span class="guilabel"><span class="guilabel">search</span></span></code> from
the drop-down list, and click <code class="computeroutput"><span class="guibutton"><span class="guibutton">New</span></span></code>.</p></li>
</ol></div>
</li><li class="listitem">
<p>Restart the service.</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>svc -t /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$
</pre>
</li><li class="listitem"><p>Wait a minute, then click on <code class="computeroutput"><span class="guilabel"><span class="guilabel">Main
Site</span></span></code> at the top of the page.</p></li><li class="listitem">
<p>Initialize the OpenFTS Engine. This creates a set of tables in
the database to support FTS.</p><p>Near the bottom of the page, click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">OpenFTS Driver</span></span></code> link. Click on
<code class="computeroutput"><span class="guilabel"><span class="guilabel">Administration</span></span></code>. Click on
<code class="computeroutput"><span class="guilabel"><span class="guilabel">Initialize OpenFTS Engine</span></span></code>. Click
<code class="computeroutput"><span class="guibutton"><span class="guibutton">Initialize OpenFTS Engine</span></span></code>.</p>
</li><li class="listitem">
<p>Add the FTS Engine service contract</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem"><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">DevAdmin</span></span></code>.</p></li><li class="listitem"><p>Click on the <code class="computeroutput"><span class="guilabel"><span class="guilabel">Service
Contract</span></span></code> link.</p></li><li class="listitem"><p>On the <code class="computeroutput"><span class="guilabel"><span class="guilabel">FtsEngineDriver</span></span></code> line, click
<code class="computeroutput"><span class="guilabel"><span class="guilabel">Install</span></span></code>.</p></li>
</ol></div>
</li><li class="listitem">
<p>Restart the service.</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>svc -t /service/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$
</pre>
</li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-fts-content-provider-openfts" id="install-fts-content-provider-openfts"></a>Enable Full Text
Search in packages</h3></div></div></div><p>Enabling Full Text Search in packages at the moment is not
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
		    leftLink="install-full-text-search-tsearch2" leftLabel="Prev" leftTitle="Install Full Text Search using
Tsearch2"
		    rightLink="install-nsopenssl" rightLabel="Next" rightTitle="Install nsopenssl"
		    homeLink="index" homeLabel="Home" 
		    upLink="install-more-software" upLabel="Up"> 
		