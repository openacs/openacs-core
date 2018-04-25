
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install AOLserver 4}</property>
<property name="doc(title)">Install AOLserver 4</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="postgres" leftLabel="Prev"
			title="Chapter 3. Complete
Installation"
			rightLink="openacs" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="aolserver4" id="aolserver4"></a>Install AOLserver 4</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">by <a class="ulink" href="mailto:sussdorff\@sussdorff.de" target="_top">Malte
Sussdorff</a>
</span></p><span style="color: red">&lt;/authorblurb&gt;</span><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>
<strong>Check suitability of previously installed
TCL. </strong> Start Tcl (type <strong class="userinput"><code>tclsh</code></strong> or find it using
<strong class="userinput"><code>which tclsh</code></strong>).</p><pre class="screen">[root root]% <strong class="userinput"><code>info exists tcl_platform(threaded)</code></strong>
1
[root root]% <strong class="userinput"><code>info patchlevel</code></strong>
8.4.7
[root root]%
<span class="action">tclsh
info exists tcl_platform(threaded)
info patchlevel
</span>
</pre><p>If the first command returns anything other than <code class="computeroutput">1</code>, then Tcl is not threaded. If Tcl is
threaded and the version is 8.4 or higher, then installing Tcl from
source is optional.</p><p>
<a name="tcl-download" id="tcl-download"></a><strong>Retrieve
Tcl 8.4 (or higher). </strong> Download and install Tcl 8.4
from source</p><p>Note for Debian users: you can apt-get install tcl8.4-dev if you
have the right version (stable users will need to add tcl8.4 to
their sources.list file as described on the <a class="link" href="postgres" title="Install PostgreSQL">Install Postgres</a>
page). You&#39;ll have to use /usr/lib/tcl8.4/ instead of
/usr/local/lib when you try to find the Tcl libraries, however.</p><p>If you have not installed Tcl already, download the latest Tcl
version from Sourceforge</p><p>
<span class="bold"><strong>Debian:</strong></span><code class="computeroutput"><span class="action">apt-get install tcl8.4
tcl8.4-dev</span></code> and proceed to the next step. In that
step, replace <code class="computeroutput">--with-tcl=/usr/local/lib/</code> with
<code class="computeroutput">--with-tcl=/usr/lib/tcl8.4</code>.</p><p>Remember that you have to be root if you want to follow these
instructions. On Mac OS X type <strong class="userinput"><code>sudo
su -</code></strong> to become root.</p><p>Alternatively use <strong class="userinput"><code>curl -L
-O</code></strong> instead of <strong class="userinput"><code>wget</code></strong> (especially on Mac OS
X).</p><pre class="screen">[root root]# <strong class="userinput"><code>cd /usr/local/src</code></strong>
[root src]# <strong class="userinput"><code>wget http://heanet.dl.sourceforge.net/sourceforge/tcl/tcl8.4.9-src.tar.gz</code></strong>
[root src]# <strong class="userinput"><code>tar xfz tcl8.4.9-src.tar.gz</code></strong>
[root src]# <strong class="userinput"><code>cd tcl8.4.9/unix</code></strong>
[root unix]# <strong class="userinput"><code>./configure --enable-threads</code></strong>
[root unix]# <strong class="userinput"><code>make install</code></strong>
[root root]# 
<span class="action">cd /usr/local/src
wget http://heanet.dl.sourceforge.net/sourceforge/tcl/tcl8.4.9-src.tar.gz
tar xfz tcl8.4.9-src.tar.gz
cd tcl8.4.9/unix
./configure --enable-threads
make install</span>
</pre>
</li><li class="listitem">
<a name="aolserver4-download" id="aolserver4-download"></a><p>
<strong>Retrieve AOLserver. </strong> Download the
AOLserver from CVS.</p><pre class="screen">[root root]# <strong class="userinput"><code>cd /usr/local/src</code></strong>
[root src]# <strong class="userinput"><code>mkdir aolserver40r10</code></strong>
[root src]# <strong class="userinput"><code>cd aolserver40r10</code></strong>
[root aolserver]# <strong class="userinput"><code>cvs -z3 -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/aolserver login</code></strong>
[root aolserver]# <strong class="userinput"><code>cvs -z3 -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/aolserver co  -r aolserver_v40_r10 aolserver</code></strong>
[root aolserver]# <strong class="userinput"><code>cvs -z3 -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/aolserver co nscache</code></strong>
[root aolserver]# <strong class="userinput"><code>cvs -z3 -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/aolserver co nspostgres</code></strong>
[root aolserver]# <strong class="userinput"><code>cvs -z3 -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/aolserver co nssha1</code></strong>
[root aolserver]# <strong class="userinput"><code>cvs -z3 -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/aolserver co -r v2_7 nsoracle</code></strong>
[root aolserver]# <strong class="userinput"><code>wget http://www.tdom.org/tDOM-0.7.8.tar.gz</code></strong>
[root aolserver]# <strong class="userinput"><code>tar xvfz tDOM-0.7.8.tar.gz</code></strong>
[root aolserver]# <strong class="userinput"><code>cvs -z3 -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/tcllib co -r tcllib-1-8 tcllib</code></strong>
[root root]# 
<span class="action">cd /usr/local/src
mkdir aolserver40r10
cd aolserver40r10
cvs -z3 -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/aolserver co -r aolserver_v40_r10 AOLserver
cvs -z3 -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/aolserver co nscache
cvs -z3 -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/aolserver co nspostgres
cvs -z3 -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/aolserver co nssha1
cvs -z3 -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/aolserver co -r v2_7 nsoracle
wget http://www.tdom.org/files/tDOM-0.8.0.tar.gz
tar xvfz tDOM-0.8.0.tar.gz
cvs -z3 -d:pserver:anonymous\@cvs.sourceforge.net:/cvsroot/tcllib co -r tcllib-1-8 tcllib</span>
</pre>
</li><li class="listitem">
<a name="aolserver4-install" id="aolserver4-install"></a><p>
<strong>Configure, compile and install AOLserver. </strong>
Many people need to run more than one version of AOLserver in
parallel. This section accommodates future upgrades by installing
AOLserver 4 in <code class="computeroutput">/usr/local/aolserver40r9</code>.</p><pre class="screen">[root aolserver]# <strong class="userinput"><code>cd /usr/local/src/aolserver40r10/aolserver</code></strong>
[root aolserver]# <strong class="userinput"><code>./configure --prefix=/usr/local/aolserver40r10 --with-tcl=/usr/local/lib/</code></strong>
[root aolserver]# <strong class="userinput"><code>make install</code></strong><span class="action">cd /usr/local/src/aolserver40r10/aolserver
./configure --prefix=/usr/local/aolserver40r10 --with-tcl=/usr/local/lib/
make install
</span>
</pre><p>If you are using gcc 4 or later, see <a class="ulink" href="http://openacs.org/forums/message-view?message_id=309814" target="_top">http://openacs.org/forums/message-view?message_id=309814</a>
</p><p>If this is the only version of AOLserver in use, or is the
default version, create a symlink. If not, then be sure to use
<code class="computeroutput">/usr/local/aolserver40r10</code>
instead of <code class="computeroutput">/usr/local/aolserver</code>
in the steps below and check both scripts and makefiles to ensure
they use the correct path.</p><pre class="screen">[root aolserver]# <strong class="userinput"><code>ln -s /usr/local/aolserver40r10 /usr/local/aolserver</code></strong>
</pre>
</li><li class="listitem">
<a name="aolserver4-modules-install" id="aolserver4-modules-install"></a><p><strong>Configure, compile and install the
modules. </strong></p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem">
<p>Install nscache</p><pre class="screen">[root aolserver]# <strong class="userinput"><code>cd /usr/local/src/aolserver40r10/nscache</code></strong>
[root nscache]# <strong class="userinput"><code>make install AOLSERVER=/usr/local/aolserver</code></strong>
</pre>
</li><li class="listitem">
<p>Install nsoracle (if you want to use Oracle)</p><pre class="screen">[root nscache]# <strong class="userinput"><code>cd ../nsoracle</code></strong>
[root nsoracle]# <strong class="userinput"><code>make install AOLSERVER=/usr/local/aolserver</code></strong>
</pre><p>OpenACS looks for the Oracle driver at
/usr/local/aolserver/bin/ora8.so, but some versions of nsoracle may
create nsoracle.so instead. In that case, you can symlink
(<strong class="userinput"><code>ln -s nsoracle.so
ora8.so</code></strong>) to fix it.</p>
</li><li class="listitem">
<p>Install nspostgres (if you want to use Postgres)</p><pre class="screen">[root nscache]# <strong class="userinput"><code>cd ../nspostgres</code></strong>
[root nspostgres]# <strong class="userinput"><code>export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/pgsql/lib:/usr/local/aolserver/lib</code></strong>
[root nspostgres]# <strong class="userinput"><code>make install POSTGRES=LSB ACS=1 INST=/usr/local/aolserver  AOLSERVER=/usr/local/aolserver</code></strong>
</pre><p>If you get errors like:</p><pre class="programlisting">
nspostgres.c: In function `Ns_PgTableList':
nspostgres.c:679: warning: passing arg 3 of `Tcl_DStringAppend' as signed due to prototype</pre><p>then PostGreSQL is probably not in the standard location. The
location of PostGreSQL is very dependent on which method was used
to install it. To correct the problem, replace <code class="computeroutput">LSB</code> with the path to the path to your
PostGreSQL installation. Often this is <code class="computeroutput">/usr/local/pgsql</code>.</p><p>You can use the <code class="computeroutput">ldd</code> command
to verify that all libraries are linked in: <strong class="userinput"><code>ldd
/usr/local/src/aolserver40r10/nspostgres/nspostgres.so</code></strong>
</p><p>If you run into problems with libpq.a do the following (and
repeat the step above)</p><pre class="screen">[root nspostgres]# <strong class="userinput"><code>ranlib /usr/local/pgsql/lib/libpq.a</code></strong>
</pre><p>If you run into problems with the linker, edit the Makefile. Add
<code class="computeroutput">-lnsdb</code> to the <code class="computeroutput">MODLIBS</code> var.</p><pre class="programlisting">MODLIBS = -L$(PGLIB) -lpq <span class="bold"><strong>-lnsdb</strong></span>
</pre>
</li><li class="listitem">
<p>Install nssha1</p><pre class="screen">[root nspostgres]# <strong class="userinput"><code>cd ../nssha1</code></strong>
</pre><p>Now install nssha1:</p><pre class="screen">[root nssha1]# <strong class="userinput"><code>make install AOLSERVER=/usr/local/aolserver</code></strong>
</pre><p>If the make fails you will have to edit nssha1.c. Comment out
the following 2 lines (lines 139-140):</p><pre class="programlisting">
<span class="bold"><strong>//</strong></span> typedef unsigned int u_int32_t;
<span class="bold"><strong>//</strong></span> typedef unsigned char u_int8_t;</pre>
</li><li class="listitem">
<p>Install tDOM</p><pre class="screen">[root nssha1]# <strong class="userinput"><code>cd ../tDOM-0.8.0/unix</code></strong>
</pre><p>Edit the <code class="computeroutput">CONFIG</code> file.
Uncomment the instructions meant for AOLserver 4, but edit it to
look like this:</p><pre class="screen">
../configure --enable-threads --disable-tdomalloc
          --prefix=/usr/local/aolserver --with-tcl=/usr/local/lib</pre><p>Note that the location of the Tcl library may vary on different
platforms (e.g. for Debian 3.0: --with-tcl=/usr/lib/tcl8.4)</p><p>Now you can compile and configure tDOM</p><pre class="screen">[root unix]# <strong class="userinput"><code>sh CONFIG</code></strong>
[root unix]# <strong class="userinput"><code>make install</code></strong>
</pre>
</li><li class="listitem">
<p>Install TCLLIB</p><pre class="screen">[root nssha1]# <strong class="userinput"><code>cd ../tcllib</code></strong>
</pre><p>Configure and compile TCLLIB</p><pre class="screen">[root unix]# <strong class="userinput"><code>./configure -prefix=/usr/local/aolserver40r10</code></strong>
[root unix]# <strong class="userinput"><code>make install</code></strong>
</pre>
</li>
</ol></div>
</li><li class="listitem">
<a name="aolserver4-db-wrapper" id="aolserver4-db-wrapper"></a><p>
<strong>Add a database-specific wrapper script. </strong>
This script sets database environment variables before starting
AOLserver; this allows the AOLserver instance to communicate with
the database. There is one script for Oracle and one for
PostgreSQL. They do not conflict. If you plan to use both
databases, install both. Note that this section requires you to
have OpenACS files available, which you can get through CVS,
through a tarball, or by other means. You can come back to this
section after you acquire the OpenACS code, but don&#39;t forget to
come back. (Note to maintainers: this should be moved to the next
page and integrated into the text there)</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>Oracle</p><pre class="screen">[root aolserver]# <strong class="userinput"><code>cd /usr/local/aolserver/bin</code></strong>
[root bin]# <strong class="userinput"><code>cp /tmp/openacs-5.9.0/packages/acs-core-docs/www/files/nsd-oracle.txt ./nsd-oracle</code></strong>
[root bin]# <strong class="userinput"><code>chmod 750 nsd-oracle</code></strong>
[root bin]#
<span class="action">cd /usr/local/aolserver/bin
cp /var/tmp/openacs-5.9.0/packages/acs-core-docs/www/files/nsd-oracle.txt ./nsd-oracle
chmod 750 nsd-oracle</span>
</pre>
</li><li class="listitem">
<p>PostgreSQL</p><pre class="screen">[root aolserver]# <strong class="userinput"><code>cd /usr/local/aolserver/bin</code></strong>
[root bin]# <strong class="userinput"><code>cp /var/tmp/openacs-5.9.0/packages/acs-core-docs/www/files/nsd-postgres.txt ./nsd-postgres</code></strong>
[root bin]# <strong class="userinput"><code>chmod 755 nsd-postgres</code></strong>
[root bin]#
<span class="action">cd /usr/local/aolserver/bin
cp /var/tmp/openacs-5.9.0/packages/acs-core-docs/www/files/nsd-postgres.txt ./nsd-postgres
chmod 755 nsd-postgres</span>
</pre>
</li>
</ul></div><p>You may need to edit these scripts if you are not using
/usr/local/aolserver as the directory of Aolserver4.</p>
</li><li class="listitem"><p>
<strong>Change startup script (optional). </strong> If you
want to run AOLserver on a port below 1024 (normally, for a
webserver you will use 80), you will have to change the
<code class="computeroutput">/var/lib/aolserver/<em class="replaceable"><code>service0</code></em>/etc/daemontools/run</code>
script according to the documentation found there (namely: Add the
-b <em class="replaceable"><code>yourip:yourport</code></em>
switch)</p></li><li class="listitem"><p>
<a class="link" href="aolserver">Test
AOLserver</a>.</p></li>
</ol></div><p><span class="cvstag">($&zwnj;Id: aolserver4.xml,v 1.32 2017/08/07
23:47:54 gustafn Exp $)</span></p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="postgres" leftLabel="Prev" leftTitle="Install PostgreSQL"
			rightLink="openacs" rightLabel="Next" rightTitle="Install OpenACS 5.9.0"
			homeLink="index" homeLabel="Home" 
			upLink="complete-install" upLabel="Up"> 
		    