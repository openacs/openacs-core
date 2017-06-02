
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install AOLserver 3.3oacs1}</property>
<property name="doc(title)">Install AOLserver 3.3oacs1</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="install-ldap-radius" leftLabel="Prev"
		    title="
Appendix B. Install additional supporting
software"
		    rightLink="credits" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="aolserver" id="aolserver"></a>Install AOLserver 3.3oacs1</h2></div></div></div><div class="authorblurb">
<p>by <a class="ulink" href="mailto:vinod\@kurup.com" target="_top">Vinod Kurup</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>We recommend the use of <a class="link" href="aolserver4" title="Install AOLserver 4">AOLserver 4.0.1</a> or later. These
instructions are retained as a resource.</p><p>Debian users: we do not recommend installing Debian packages for
Aolserver or Postgres. Several people have reported problems while
trying to install using apt-get instead of from source. If you have
the time to debug these and submit what you did, that&#39;s great,
but if not, you should stick to installing from source.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<a name="aolserver-tarball" id="aolserver-tarball"></a><p>
<strong>Unpack the Aolserver
tarball. </strong>Download the <a class="link" href="individual-programs">aolserver tarball</a>
and unpack it.</p><pre class="screen">
[root root]# <strong class="userinput"><code>cd /usr/local/src</code></strong>
[root src]# <strong class="userinput"><code>wget --passive http://uptime.openacs.org/aolserver-openacs/aolserver3.3oacs1.tar.gz</code></strong>
--15:38:08--  http://uptime.openacs.org/aolserver-openacs/aolserver3.3oacs1.tar.gz
           =&gt; `aolserver3.3oacs1.tar.gz'
Resolving uptime.openacs.org... done.
Connecting to uptime.openacs.org[207.166.200.199]:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 3,858,074 [application/x-compressed]

100%[====================================&gt;] 3,858,074     66.56K/s    ETA 00:00

15:39:05 (66.56 KB/s) - `aolserver3.3oacs1.tar.gz' saved [3858074/3858074]
[root src]# <strong class="userinput"><code>tar xzf aolserver3.3oacs1.tar.gz</code></strong>
[root src]#
<span class="action"><span class="action">cd /usr/local/src
wget --passive http://uptime.openacs.org/aolserver-openacs/aolserver3.3oacs1.tar.gz
tar xzf aolserver3.3oacs1.tar.gz</span></span>
</pre><p>This section also relies on some OpenACS files, which you can
get with <a class="xref" href="openacs-unpack" title="Unpack the OpenACS tarball">the section called
&ldquo;Unpack the OpenACS
tarball&rdquo;</a>.</p>
</li><li class="listitem">
<a name="install-aolserver-compile" id="install-aolserver-compile"></a><p>
<strong>Compile AOLserver. </strong>Compile and
install AOLserver. First, prepare the installation directory and
the source code. The message about BUILD-MODULES can be
ignored.</p><pre class="screen">
root\@yourserver root]# <strong class="userinput"><code>mkdir -p /usr/local/aolserver</code></strong>
[root root]# <strong class="userinput"><code>cd /usr/local/src/aolserver</code></strong>
[root aolserver]# <strong class="userinput"><code>./conf-clean</code></strong>
cat: BUILD-MODULES: No such file or directory
Done.
[root aolserver]#<span class="action"><span class="action">mkdir -p /usr/local/aolserver
cd /usr/local/src/aolserver
./conf-clean</span></span>
</pre><p>If you are using Oracle, edit <code class="computeroutput">conf-db</code> and change <code class="computeroutput">postgresql</code> to <code class="computeroutput">oracle</code>, or to the word <code class="computeroutput">both</code> if you want both drivers installed. In
order to get nsoracle to compile, you may need to su - oracle, and
then su (without the -) root to set the environment variables
properly.</p><p>
<code class="computeroutput">conf-inst</code> should contain the
location where AOLserver is to be installed. Overwrite the
tarball&#39;s default value with our default value, <code class="computeroutput">/usr/local/aolserver</code>:</p><pre class="screen">
[root aolserver]# <strong class="userinput"><code>echo "/usr/local/aolserver" &gt; conf-inst</code></strong>
[root aolserver]#
</pre><p>
<code class="computeroutput">conf-make</code> should contain the
name of the GNU Make command on your system. It defaults to
<code class="computeroutput">gmake</code>. Debian users:
<code class="computeroutput"><strong class="userinput"><code>ln -s
/usr/bin/make /usr/bin/gmake</code></strong></code>.</p><p>Set an environment variable that the nspostgres driver Makefile
needs to compile correctly and run <code class="computeroutput">conf</code>, which compiles AOLserver, the default
modules, and the database driver, and installs them.</p><p>Debian users, see warning above, but if you do use apt-get for
AOLserver 3.3+ad13 and postgresql from apt-get may need to make
these symlinks: <code class="computeroutput">ln -s
/usr/include/postgresql/ /usr/include/pgsql</code> and <code class="computeroutput">ln -s /usr/lib/postgresql
/usr/local/pgsql</code>)</p><pre class="screen">
[root aolserver]# <strong class="userinput"><code>export POSTGRES=/usr/local/pgsql; ./conf</code></strong>
Building in /usr/local/aolserver
with the following modules:
AOLserver
nscache
nsrewrite
nssha1
nsxml
pgdriver
==================================================================
Starting Build Sat Mar  8 10:28:26 PST 2003
Running gmake in aolserver/; output in log/aolserver.log
<span class="emphasis"><em>(several minute delay here)</em></span>
Running gmake in nscache/; output in log/nscache.log
Running gmake in nsrewrite/; output in log/nsrewrite.log
Running gmake in nssha1/; output in log/nssha1.log
Running gmake in nsxml/; output in log/nsxml.log
Running gmake in nspostgres/; output in log/nspostgres.log
Creating  ...
==================================================================
Done Building Sat Mar  8 10:31:35 PST 2003
[root aolserver]# 
</pre><p>This takes about 5 minutes. It builds aolserver, several
modules, and the database driver. (Upgraders, note that the
postgres database driver has changed from postgres.so to
nspostgres.so). All of the results are logged to files in
<code class="computeroutput">/usr/local/src/aolserver/log</code>.
If you run into problems running AOLserver, check these files for
build errors.</p>
</li><li class="listitem">
<a name="aolserver-db-wrapper" id="aolserver-db-wrapper"></a><p>
<strong>Add a database-specific wrapper
script. </strong>This script sets database environment
variables before starting AOLserver; this allows the AOLserver
instance can communicate with the database. There is one script
each for Oracle and PostgreSQL. They don&#39;t conflict, so if you
plan to use both databases, install both.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>Oracle</p><pre class="screen">
[root aolserver]# <strong class="userinput"><code>cd /usr/local/aolserver/bin</code></strong>
[root bin]# <strong class="userinput"><code>cp /var/tmp/openacs-5.9.0/packages/acs-core-docs/www/files/nsd-oracle.txt ./nsd-oracle</code></strong>
[root bin]# <strong class="userinput"><code>chmod 750 nsd-oracle</code></strong>
[root bin]#
<span class="action"><span class="action">cd /usr/local/aolserver/bin
cp /var/tmp/openacs-5.9.0/packages/acs-core-docs/www/files/nsd-oracle.txt ./nsd-oracle
chmod 750 nsd-oracle</span></span>
</pre>
</li><li class="listitem">
<p>PostgreSQL</p><pre class="screen">
[root aolserver]# <strong class="userinput"><code>cd /usr/local/aolserver/bin</code></strong>
[root bin]# <strong class="userinput"><code>cp /var/tmp/openacs-5.9.0/packages/acs-core-docs/www/files/nsd-postgres.txt ./nsd-postgres</code></strong>
[root bin]# <strong class="userinput"><code>chmod 755 nsd-postgres</code></strong>
[root bin]#
<span class="action"><span class="action">cd /usr/local/aolserver/bin
cp /var/tmp/openacs-5.9.0/packages/acs-core-docs/www/files/nsd-postgres.txt ./nsd-postgres
chmod 755 nsd-postgres</span></span>
</pre>
</li>
</ul></div>
</li><li class="listitem">
<a name="install-tdom" id="install-tdom"></a><p>
<strong>Install tDOM. </strong>Download the
<a class="link" href="individual-programs">tDOM
tarball</a>, unpack it, adjust the configuration file to match our
patched distribution of aolserver, and compile it.</p><pre class="screen">
[root root]# <strong class="userinput"><code>cd /usr/local/src</code></strong>
[root src]# <strong class="userinput"><code>wget --passive http://www.tdom.org/tDOM-0.7.8.tar.gz</code></strong>
--16:40:58--  http://www.tdom.org/tDOM-0.7.8.tar.gz
           =&gt; `tDOM-0.7.8.tar.gz'
Resolving www.tdom.org... done.
Connecting to www.tdom.org[212.14.81.4]:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 826,613 [application/x-compressed]

100%[====================================&gt;] 826,613      138.06K/s    ETA 00:00

16:41:04 (138.06 KB/s) - `tDOM-0.7.8.tar.gz' saved [826613/826613]

[root src]# <strong class="userinput"><code>tar xzf tDOM-0.7.8.tar.gz</code></strong>
[root src]# <strong class="userinput"><code>cd tDOM-0.7.8/unix</code></strong>
[root unix]#
<span class="action"><span class="action">cd /usr/local/src
wget --passive http://www.tdom.org/tDOM-0.7.8.tar.gz
tar xzf tDOM-0.7.8.tar.gz
cd tDOM-0.7.8/unix</span></span>
</pre><p>Edit the file CONFIG and change this section:</p><pre class="programlisting">
# ----------------------------------------------------
# aolsrc="/usr/src/aolserver-3.4"
# ../configure --enable-threads --disable-tdomalloc \
#   --with-aolserver=$aolsrc \
#   --with-tcl=$aolsrc/tcl8.3.4/unix 
</pre><p>to</p><pre class="programlisting">
# ----------------------------------------------------
aolsrc="/usr/local/src/aolserver/aolserver"
../configure --enable-threads --disable-tdomalloc \
  --with-aolserver=$aolsrc \
  --with-tcl=$aolsrc/tcl8.3.2/unix
</pre><p>And configure and compile:</p><pre class="screen">
[root unix]# <strong class="userinput"><code>sh CONFIG</code></strong>
creating cache ./config.cache
checking for memmove... yes
  <span class="emphasis"><em>(many lines omitted)</em></span>
creating Makefile
creating tdomConfig.sh
[root unix]# <strong class="userinput"><code>make</code></strong>
gcc -pipe -DHAVE_UNISTD_H=1 -DHAVE_LIMITS_H=1 -DTCL_THREADS=1
-DHAVE_GETCWD=1 -DHAVE_OPENDIR=1 -DHAVE_STRSTR=1 -DHAVE_STRTOL=1 
  <span class="emphasis"><em>(many lines omitted)</em></span>
          -Wl,-rpath,/usr/local/lib -o tcldomsh;\
fi
[root unix]# <strong class="userinput"><code>cp libtdom0.7.8.so /usr/local/aolserver/bin/</code></strong>
[root unix]# <strong class="userinput"><code>cd /usr/local/aolserver/bin/</code></strong>
[root bin]# <strong class="userinput"><code>ln -s libtdom0.7.8.so libtdom.so</code></strong>
[root bin]#

<span class="action"><span class="action">sh CONFIG
make
cp libtdom0.7.8.so /usr/local/aolserver/bin/
cd /usr/local/aolserver/bin
ln -s libtdom0.7.8.so libtdom.so</span></span>
</pre>
</li><li class="listitem"><p>
<a class="link" href="install-nsopenssl" title="Install nsopenssl">Install nsopenssl</a> (OPTIONAL)</p></li><li class="listitem"><p>
<a class="link" href="install-full-text-search-openfts" title="Install OpenFTS module">Install Full Text Search with OpenFTS</a>
(OPTIONAL)</p></li><li class="listitem"><p>
<a class="link" href="install-nspam" title="Install nspam">Install nspam</a> (OPTIONAL)</p></li><li class="listitem">
<a name="install-aolserver-permissions" id="install-aolserver-permissions"></a><p>
<strong>Test AOLserver. </strong>In order to test
AOLserver, we&#39;ll run it using the sample-config.tcl file
provided in the AOLserver distribution, under the nobody user and
<code class="computeroutput">web</code> group. The
sample-config.tcl configuration writes to the default log
locations, so we need to give it permission to do so or it will
fail. Grant the <code class="computeroutput">web</code> group
permission to write to <code class="computeroutput">/usr/local/aolserver/log</code> and <code class="computeroutput">/usr/local/aolserver/servers</code>.</p><pre class="screen">
[root root]# <strong class="userinput"><code>cd /usr/local/aolserver</code></strong>
[root aolserver]# <strong class="userinput"><code>chown -R root.web log servers</code></strong>
[root aolserver]# <strong class="userinput"><code>chmod -R g+w log servers</code></strong>
[root aolserver]# <strong class="userinput"><code>ls -l</code></strong>
total 32
drwxr-sr-x    2 root     root         4096 Mar  8 12:57 bin
drwxr-xr-x    3 root     root         4096 Mar  8 10:34 include
drwxr-sr-x    3 root     root         4096 Mar  8 10:34 lib
drwxrwsr-x    2 root     web          4096 Mar  8 10:31 log
drwxr-sr-x    3 root     root         4096 Mar  8 10:31 modules
-rw-r--r--    1 root     root         7320 Mar 31  2001 sample-config.tcl
drwxrwsr-x    3 root     web          4096 Mar  8 10:31 servers
[root aolserver]#
<span class="action"><span class="action">
cd /usr/local/aolserver
chown -R root.web log servers
chmod -R g+w log servers
ls -l</span></span>
</pre><p>Note: AOLserver4.x does not include a default start page, so we
create one for this test. Type <strong class="userinput"><code>echo
"Welcome to AOLserver" &gt;
/usr/local/aolserver40r8/servers/server1/pages/index.html</code></strong>
</p><p>Now, we&#39;ll run a quick test to ensure AOLserver is running
correctly. We&#39;ll use the sample config file provided with
AOLserver. This file will attempt to guess your IP address and
hostname. It will then start up the server at port 8000 of that IP
address.</p><pre class="screen">
[root aolserver]# <strong class="userinput"><code>./bin/nsd -t sample-config.tcl -u nobody -g web</code></strong>
[root aolserver]# [08/Mar/2003:15:07:18][31175.8192][-main-] Notice: config.tcl: starting to read config file...
[08/Mar/2003:15:07:18][31175.8192][-main-] Warning: config.tcl: nsssl not loaded -- key/cert files do not exist.
[08/Mar/2003:15:07:18][31175.8192][-main-] Warning: config.tcl: nscp not loaded
-- user/password is not set.
[08/Mar/2003:15:07:18][31175.8192][-main-] Notice: config.tcl: finished reading
config file.
</pre><p>The first warning, about nsssl, can be ignored. We won&#39;t be
using nsssl; we&#39;ll be using nsopenssl instead, and we
haven&#39;t fully configured it yet. The nscp warning refers to the
fact that, without a user and password in the config file, the
administrative panel of AOLserver won&#39;t load. We don&#39;t plan
to use it and can ignore that error as well. Any other warning or
error is unexpected and probably a problem.</p><p>Test to see if AOLserver is working by starting <code class="computeroutput">Mozilla</code> or <code class="computeroutput">Lynx</code><span class="emphasis"><em>on the same
computer</em></span> and surfing over to your web page. If you
browse from another computer and the sample config file didn&#39;t
guess your hostname or ip correctly, you&#39;ll get a false
negative test.</p><pre class="screen">
[root aolserver]# <strong class="userinput"><code>lynx localhost:8000</code></strong>
</pre><p>You should see a "Welcome to AOLserver" page. If this
doesn&#39;t work, try going to <code class="computeroutput">http://127.0.0.1:8000/</code>. If this still
doesn&#39;t work, check out the <a class="xref" href="aolserver">Troubleshooting
AOLserver</a> section below. Note that you will not be able to
browse to the web page from another machine, because AOLserver is
only listening to the local address.</p><p>Shutdown the test server:</p><pre class="screen">
[root aolserver]# <strong class="userinput"><code>killall nsd</code></strong>
[root aolserver]#
</pre><p>The <code class="computeroutput">killall</code> command will
kill all processes with the name <code class="computeroutput">nsd</code>, but clearly this is not a good tool to
use for managing your services in general. We cover this topic in
the <a class="xref" href="install-openacs-keepalive" title="Starting and Stopping an OpenACS instance.">Keep AOLserver
alive</a> section.</p>
</li><li class="listitem">
<a name="install-aolserver-troubleshooting" id="install-aolserver-troubleshooting"></a><p>
<strong>Troubleshooting. </strong>If you can&#39;t
view the welcome page, it&#39;s likely there&#39;s a problem with
your server configuration. Start by viewing your AOLserver log,
which is in <code class="computeroutput">/usr/local/aolserver/log/server.log</code>. You
should also try to find lines of the form:</p><pre class="screen">
[01/Jun/2000:12:11:20][5914.4051][-nssock-] Notice: nssock: listening on http://localhost.localdomain:8000 (127.0.0.1:8000)
[01/Jun/2000:12:11:20][5914.4051][-nssock-] Notice: accepting connections
</pre><p>If you can find these lines, try entering the URL the server is
listening on. If you cannot find these lines, there must be an
error somewhere in the file. Search for lines beginning with the
word <code class="computeroutput">Error</code> instead of
<code class="computeroutput">Notice</code>.</p><p>The <code class="computeroutput">sample-config.tcl</code> file
grabs your address and hostname from your OS settings.</p><pre class="screen">
set hostname        [ns_info hostname]
set address         [ns_info address]
</pre><p>If you get an error that nssock can&#39;t get the requested
address, you can set these manually. If you type 0.0.0.0, AOLserver
will try to listen on all available addresses. <span class="emphasis"><em>Note</em></span>: <code class="computeroutput">ns_info address</code> doesn&#39;t appear to be
supported in current versions of AOLserver.</p><pre class="screen">
set hostname        [ns_info hostname]
#set address         [ns_info address]
set address 0.0.0.0
</pre>
</li><li class="listitem"><p>
<a class="link" href="analog-install" title="Install Analog web file analyzer">Install Analog</a> web file
analyzer. (OPTIONAL)</p></li>
</ol></div><div class="cvstag">($&zwnj;Id: aolserver.xml,v 1.22.14.2 2017/04/22
17:18:48 gustafn Exp $)</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="install-ldap-radius" leftLabel="Prev" leftTitle="Install LDAP for use as external
authentication"
		    rightLink="credits" rightLabel="Next" rightTitle="
Appendix C. Credits"
		    homeLink="index" homeLabel="Home" 
		    upLink="install-more-software" upLabel="Up"> 
		