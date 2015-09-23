
<property name="context">{/doc/acs-core-docs {Documentation}} {Install PostgreSQL}</property>
<property name="doc(title)">Install PostgreSQL</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="oracle" leftLabel="Prev"
		    title="
Chapter 3. Complete Installation"
		    rightLink="aolserver4" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="postgres" id="postgres"></a>Install PostgreSQL</h2></div></div></div><div class="authorblurb">
<p>by <a class="ulink" href="mailto:vinod\@kurup.com" target="_top">Vinod Kurup</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>Skip this section if you will run only Oracle.</p><p>OpenACS 5.7.0 will run with <a class="link" href="individual-programs" title="PostgreSQL 7.4.x (Either this or Oracle is REQUIRED)">PostgreSQL</a>
7.3.2, 7.3.3, and 7.3.4 and 7.4.x. 7.4.7 is the recommended version
of PostgreSQL.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<a name="install-postgres-mac" id="install-postgres-mac"></a><b>Special notes for Mac OS
X. </b>If you are running Mac OS X prior to 10.3, you
should be able to install and use PostGreSQL 7.3.x. Mac OS X 10.3
requires PostGreSQL 7.4.</p></li><li class="listitem">
<p>
<a name="install-postgres-debian" id="install-postgres-debian"></a><b>Special Notes for
Debian. </b>
</p><p>Debian stable user should install PostGreSQL from source as
detailed below, or they should use the www.backports.org backport
for Postgres to get a more current version. Debian unstable users:
the following process has been known to work (but you should
double-check that the version of PostGreSQL is 7.3 or above):</p><p>For Debian stable users, you can use backports, by adding this
line to the /etc/apt/sources.list</p><pre class="screen"><strong class="userinput"><code>deb http://www.backports.org/debian stable bison postgresql openssl openssh tcl8.4 courier debconf spamassassin tla diff patch neon chkrootkit
        </code></strong></pre><pre class="screen"><strong class="userinput"><code>apt-get install postgresql postgresql-dev postgresql-doc
ln -s /usr/include/postgresql/ /usr/include/pgsql
ln -s /var/lib/postgres /usr/local/pgsql
ln -s /usr/include/pgsql /usr/local/pgsql/include
su postgres -c "/usr/lib/postgresql/bin/createlang plpgsql template1"</code></strong></pre><p>and proceed to <a class="xref" href="postgres" title="Tune postgres. (OPTIONAL)">Tune postgres. (OPTIONAL)</a> or to the
next section.</p>
</li><li class="listitem">
<p>
<a name="install-postgres-rpm" id="install-postgres-rpm"></a><b>Special Notes for Red
Hat. </b>Red Hat users: If you install PostgreSQL 7.3.2
from the Red Hat 9 RPM, you can skip a few steps. These shell
commands add some links for compatibility with the directories from
a source-based install; start the service; create a new group for
web service users, and modify the postgres user's environment
(<a class="link" href="postgres">more
information</a>):</p><pre class="screen">
[root root]# <strong class="userinput"><code>ln -s /usr/lib/pgsql/ /var/lib/pgsql/lib</code></strong>
[root root]# <strong class="userinput"><code>ln -s /var/lib/pgsql /usr/local/pgsql</code></strong>
[root root]# <strong class="userinput"><code>ln -s /etc/init.d/postgresql /etc/init.d/postgres</code></strong>
[root root]# <strong class="userinput"><code>ln -s /usr/bin /usr/local/pgsql/bin</code></strong>
[root root]# <strong class="userinput"><code>service postgresql start</code></strong>
Initializing database:
                                                           [  OK  ]
Starting postgresql service:                               [  OK  ]
[root root]# <strong class="userinput"><code>echo "export LD_LIBRARY_PATH=/usr/local/pgsql/lib" &gt;&gt; ~postgres/.bash_profile</code></strong>
[root root]# <strong class="userinput"><code>echo "export PATH=$PATH:/usr/local/pgsql/bin" &gt;&gt; ~postgres/.bash_profile</code></strong>
[root root]# <strong class="userinput"><code>groupadd web</code></strong>
[root root]# <strong class="userinput"><code>su - postgres</code></strong>
-bash-2.05b$
<span class="action"><span class="action">
ln -s /usr/lib/pgsql/ /var/lib/pgsql/lib
ln -s /var/lib/pgsql /usr/local/pgsql
ln -s /usr/bin /usr/local/pgsql/bin
service postgresql start
echo "export LD_LIBRARY_PATH=/usr/local/pgsql/lib" &gt;&gt; ~postgres/.bash_profile
echo "export PATH=$PATH:/usr/local/pgsql/bin" &gt;&gt; ~postgres/.bash_profile
groupadd web
su - postgres</span></span>
</pre><p>... and then skip to <a class="xref" href="postgres">8</a>. Something similar may work
for other binary packages as well.</p>
</li><li class="listitem">
<p>Safe approach: install from source</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>
<b>Unpack PostgreSQL 7.4.7. </b>If you have not
downloaded the postgresql tarball to <code class="computeroutput">/var/tmp/postgresql-7.4.7.tar.gz</code>, <a class="link" href="individual-programs" title="PostgreSQL 7.4.x (Either this or Oracle is REQUIRED)">get
it</a>.</p><pre class="screen">
[root root]# <strong class="userinput"><code>cd /usr/local/src</code></strong>
[root src]# <strong class="userinput"><code>tar xzf /var/tmp/postgresql-7.4.7.tar.gz</code></strong>
[root src]# 
<span class="action"><span class="action">cd /usr/local/src
tar xzf /var/tmp/postgresql-7.4.7.tar.gz</span></span>
</pre>
</li><li class="listitem">
<p>
<b>ALTERNATIVE: Unpack PostgreSQL 7.4.7. </b>If you
have not downloaded the postgresql tarball to <code class="computeroutput">/var/tmp/postgresql-7.4.7.tar.bz2</code>,
<a class="link" href="individual-programs" title="PostgreSQL 7.4.x (Either this or Oracle is REQUIRED)">get
it</a>.</p><pre class="screen">
[root root]# <strong class="userinput"><code>cd /usr/local/src</code></strong>
[root src]# <strong class="userinput"><code>tar xfj /var/tmp/postgresql-7.4.7.tar.bz2</code></strong>
[root src]# 
<span class="action"><span class="action">cd /usr/local/src
tar xfj /var/tmp/postgresql-7.4.7.tar.bz2</span></span>
</pre>
</li><li class="listitem">
<p>
<b>Install Bison. </b>Only do this if <strong class="userinput"><code>bison --version</code></strong> is smaller than
1.875 and you install PostgreSQL 7.4 from cvs instead of
tarball.</p><pre class="screen">
[root root]# <strong class="userinput"><code>cd /usr/local/src</code></strong>
[root src]# <strong class="userinput"><code>wget http://ftp.gnu.org/gnu/bison/bison-1.875.tar.gz</code></strong>
[root src]# <strong class="userinput"><code>tar xfz bison-1.875.tar.gz</code></strong>
[root src]# <strong class="userinput"><code>cd bison-1.875</code></strong>
[root src]# <strong class="userinput"><code>./configure</code></strong>
[root src]# <strong class="userinput"><code>make install</code></strong>
</pre>
</li><li class="listitem">
<p>
<b>Create the Postgres user. </b> Create a user and
group (if you haven't done so before) for PostgreSQL. This is the
account that PostgreSQL will run as since it will not run as root.
Since nobody will log in directly as that user, we'll leave the
password blank.</p><p>Debian users should probably use adduser instead of useradd.
Type <code class="computeroutput">man adduser</code>
</p><pre class="screen">
[root src]# <strong class="userinput"><code>groupadd web</code></strong>
[root src]# <strong class="userinput"><code>useradd -g web -d /usr/local/pgsql postgres</code></strong>
[root src]# <strong class="userinput"><code>mkdir -p /usr/local/pgsql</code></strong>
[root src]# <strong class="userinput"><code>chown -R postgres.web /usr/local/pgsql /usr/local/src/postgresql-7.4.7</code></strong>
[root src]# <strong class="userinput"><code>chmod 750 /usr/local/pgsql</code></strong>
[root src]#
<span class="action"><span class="action">groupadd web
useradd -g web -d /usr/local/pgsql postgres
mkdir -p /usr/local/pgsql
chown -R postgres.web /usr/local/pgsql /usr/local/src/postgresql-7.4.7
chmod 750 /usr/local/pgsql</span></span>
</pre><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>
<b>Mac OS X: Do instead: </b>First make sure the
gids and uids below are available (change them if they are not).To
list taken uids and gids:</p><pre class="screen"><strong class="userinput"><code>nireport / /groups name gid | grep "[0123456789][0123456789]"
nireport / /users name uid | grep "[0123456789][0123456789]"</code></strong></pre><p>Now you can install the users</p><pre class="screen"><strong class="userinput"><code>sudo niutil -create / /groups/web
sudo niutil -createprop / /groups/web gid <span class="replaceable"><span class="replaceable">201</span></span>
sudo niutil -create / /users/postgres
sudo niutil -createprop / /users/postgres gid <span class="replaceable"><span class="replaceable">201</span></span>
sudo niutil -createprop / /users/postgres uid <span class="replaceable"><span class="replaceable">502</span></span>
sudo niutil -createprop / /users/postgres home /usr/local/pgsql
sudo niutil -create / /users/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
sudo niutil -createprop / /users/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> gid  <span class="replaceable"><span class="replaceable">201</span></span>
sudo niutil -createprop / /users/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> uid <span class="replaceable"><span class="replaceable">201</span></span>
mkdir -p /usr/local/pgsql
chown -R postgres:web /usr/local/pgsql /usr/local/src/postgresql-7.4.7
chmod 750 /usr/local/pgsql</code></strong></pre>
</li><li class="listitem">
<p>
<b>FreeBSD users: </b> need to add more
parameters.</p><pre class="screen">
[root src]# <strong class="userinput"><code>mkdir -p /usr/local/pgsql</code></strong>
[root src]# <strong class="userinput"><code>pw groupadd -n web</code></strong>
[root src]# <strong class="userinput"><code>pw useradd -n postgres -g web -d /usr/local/pgsql -s /bin/bash</code></strong>
[root src]# <strong class="userinput"><code>chown -R postgres:web /usr/local/pgsql /usr/local/src/postgresql-7.4.7</code></strong>
[root src]# <strong class="userinput"><code>chmod -R 750 /usr/local/pgsql</code></strong>
[root src]#
<span class="action"><span class="action">mkdir -p /usr/local/pgsql
pw groupadd -n web
pw useradd -n postgres -g web -d /usr/local/pgsql -s /bin/bash
chown -R postgres:web /usr/local/pgsql /usr/local/src/postgresql-7.4.7
chmod -R 750 /usr/local/pgsql</span></span>
</pre>
</li>
</ul></div>
</li><li class="listitem">
<a name="install-postgres-env" id="install-postgres-env"></a><p>
<b>Set up postgres's environment variables. </b>They
are necessary for the executable to find its supporting libraries.
Put the following lines into the postgres user's environment.</p><pre class="screen">
[root src]# <strong class="userinput"><code>su - postgres</code></strong>
[postgres ~] <strong class="userinput"><code>emacs ~postgres/.bashrc</code></strong>
</pre><p>Paste this line into <code class="computeroutput">.bash_profile</code>:</p><pre class="programlisting">
source $HOME/.bashrc
</pre><p>Paste these lines into <code class="computeroutput">.bashrc</code>:</p><pre class="programlisting">
export PATH=/usr/local/bin/:$PATH:/usr/local/pgsql/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/pgsql/lib
</pre><p>Test this by logging in as <code class="computeroutput">postgres</code> and checking the paths; you should
see <code class="computeroutput">/usr/local/pgsql/bin</code>
somewhere in the output (the total output is system-dependent so
yours may vary)</p><pre class="screen">
[root src]# <strong class="userinput"><code>su - postgres</code></strong>
[postgres pgsql]$ <strong class="userinput"><code>env | grep PATH</code></strong>
LD_LIBRARY_PATH=:/usr/local/pgsql/lib
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin/X11:/usr/X11R6/bin:/root/bin:/usr/local/pgsql/bin:/usr/local/pgsql/bin
[postgres pgsql]$ <strong class="userinput"><code>exit</code></strong>
</pre><p>Don't continue unless you see correct output from <code class="computeroutput">env | grep PATH</code>
</p>
</li><li class="listitem">
<a name="install-postgres-compile" id="install-postgres-compile"></a><p>
<b>Compile and install PostgreSQL. </b> Change to
the postgres user and run <code class="computeroutput">./configure</code> to set the compilation options
automatically. This is the point at which you can configure
PostgreSQL in various ways. For example, if you are installing on
"OS X" add the flags <code class="computeroutput">--with-includes=/sw/include/
--with-libraries=/sw/lib</code>. If you want to see what the other
possibilities are, run <code class="computeroutput">./configure
--help</code>.</p><p>On debian woody (stable, 3.0), do <code class="computeroutput">./configure --without-readline
--without-zlib</code>.</p><pre class="screen">
[root src]# <strong class="userinput"><code>su - postgres</code></strong>
[postgres pgsql]$<strong class="userinput"><code> cd /usr/local/src/postgresql-7.4.7</code></strong>
[postgres postgresql-7.4.7]$ <strong class="userinput"><code>./configure</code></strong>
creating cache ./config.cache
checking host system type... i686-pc-linux-gnu
(many lines omitted&gt;
linking ./src/makefiles/Makefile.linux to src/Makefile.port
linking ./src/backend/port/tas/dummy.s to src/backend/port/tas.s
[postgres postgresql-7.4.7]$ <strong class="userinput"><code>make all</code></strong>
make -C doc all
make[1]: Entering directory `/usr/local/src/postgresql-7.4.7/doc'
(many lines omitted)
make[1]: Leaving directory `/usr/local/src/postgresql-7.4.7/src'
All of PostgreSQL successfully made. Ready to install.
[postgres postgresql-7.4.7]$ <strong class="userinput"><code>make install</code></strong>
make -C doc install
make[1]: Entering directory `/usr/local/src/postgresql-7.4.7/doc'
(many lines omitted)
Thank you for choosing PostgreSQL, the most advanced open source database
engine.
<span class="action"><span class="action">su - postgres
cd /usr/local/src/postgresql-7.4.7
./configure 
make all
make install</span></span>
</pre>
</li><li class="listitem">
<a name="install-postgres-startup" id="install-postgres-startup"></a><p>
<b>Start PostgreSQL. </b> The <code class="computeroutput">initdb</code> command initializes the database.
<code class="computeroutput">pg_ctl</code> is used to start up
PostgreSQL. If PostgreSQL is unable to allocate enough memory, see
section 11 Tuning PostgreSQL (below).</p><pre class="screen">
[postgres postgresql-7.4.7]$ <strong class="userinput"><code>/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data</code></strong>
The files belonging to this database system will be owned by user "postgres".
This user must also own the server process.
(17 lines omitted)
or
    /usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data -l logfile start
[postgres postgresql-7.4.7]$ <strong class="userinput"><code>/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data -l /usr/local/pgsql/data/server.log start</code></strong>
postmaster successfully started
[postgres postgresql-7.4.7]$
<span class="action"><span class="action">/usr/local/pgsql/bin/initdb -D /usr/local/pgsql/data
/usr/local/pgsql/bin/pg_ctl -D /usr/local/pgsql/data -l /usr/local/pgsql/data/server.log start</span></span>
</pre><p>PostgreSQL errors will be logged in <code class="computeroutput">/usr/local/pgsql/data/server.log</code>
</p>
</li><li class="listitem">
<a name="install-plpgsql" id="install-plpgsql"></a><p>
<b>Install Pl/pgSQL. </b>Set up plpgsq and allow
your user to have access. Plpgsql is a PL/SQL-like language. We add
it to template1, which is the template from which all new databases
are created. We can verify that it was created with the createlang
command in list mode.</p><pre class="screen">
[postgres postgresql-7.4.7]$ <strong class="userinput"><code>createlang plpgsql template1</code></strong>
[postgres pgsql]$ <strong class="userinput"><code>createlang -l template1</code></strong>
Procedural languages
  Name   | Trusted?
---------+----------
 plpgsql | t
(1 row)

[postgres pgsql-7.4.7]$
<span class="action"><span class="action">createlang plpgsql template1
createlang -l template1</span></span>
</pre>
</li><li class="listitem">
<a name="install-postgres-test" id="install-postgres-test"></a><p>
<b>Test PostgreSQL (OPTIONAL). </b>Create a database
and try some simple commands. The output should be as shown.</p><pre class="screen">
[postgres pgsql]$ <strong class="userinput"><code>createdb mytestdb</code></strong>
CREATE DATABASE
[postgres pgsql]$ <strong class="userinput"><code>psql mytestdb</code></strong>
Welcome to psql, the PostgreSQL interactive terminal.

Type:  \copyright for distribution terms
       \h for help with SQL commands
       \? for help on internal slash commands
       \g or terminate with semicolon to execute query
       \q to quit

mytestdb=# <strong class="userinput"><code>select current_timestamp;</code></strong>
          timestamptz
-------------------------------
 2003-03-07 22:18:29.185413-08
(1 row)

mytestdb=# <strong class="userinput"><code>create function test1() returns integer as 'begin return 1; end;' language 'plpgsql';</code></strong>
CREATE
mytestdb=#<strong class="userinput"><code> select test1();</code></strong>
 test1
-------
     1
(1 row)

mytestdb=# <strong class="userinput"><code>\q</code></strong>
[postgres pgsql]$<strong class="userinput"><code> dropdb mytestdb</code></strong>
DROP DATABASE
[postgres pgsql]$ <strong class="userinput"><code>exit</code></strong>
logout

[root src]#
</pre>
</li><li class="listitem">
<p>
<a name="install-postgres-startonboot" id="install-postgres-startonboot"></a>Set PostgreSQL to start on boot.
First, we copy the postgresql.txt init script, which automates
startup and shutdown, to the distribution-specific init.d
directory. Then we verify that it works. Then we automate it by
setting up a bunch of symlinks that ensure that, when the operating
system changes runlevels, postgresql goes to the appropriate state.
Red Hat and Debian and SuSE each work a little differently. If you
haven't <a class="link" href="openacs" title="Installation Option 2: Install from tarball">untarred the
OpenACS tarball</a>, you will need to do so now to access the
postgresql.txt file.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>Red Hat RPM:</p><p>The init script is already installed; just turn it on for the
appropriate run levels.</p><pre class="screen">
[root root]# <strong class="userinput"><code>chkconfig --level 345 postgresql on</code></strong>
[root root]# 
</pre>
</li><li class="listitem">
<p>Red Hat from source:</p><pre class="screen">
[root src]# <strong class="userinput"><code>cp /var/tmp/openacs-5.7.0/packages/acs-core-docs/www/files/postgresql.txt /etc/init.d/postgresql</code></strong>
[root src]# <strong class="userinput"><code>chown root.root /etc/rc.d/init.d/postgresql</code></strong>
[root src]# <strong class="userinput"><code>chmod 755 /etc/rc.d/init.d/postgresql</code></strong>
[root src]# 
<span class="action"><span class="action">cp /var/tmp/openacs-5.7.0/packages/acs-core-docs/www/files/postgresql.txt /etc/init.d/postgresql
chown root.root /etc/rc.d/init.d/postgresql
chmod 755 /etc/rc.d/init.d/postgresql</span></span>
</pre><p>Test the script.</p><pre class="screen">
[root root]# <strong class="userinput"><code>service postgresql stop</code></strong>
Stopping PostgreSQL: ok
[root root]# 
</pre><p>If PostgreSQL successfully stopped, then use the following
command to make sure that the script is run appropriately at boot
and shutdown. And turn it back on because we'll use it later.</p><pre class="screen">
[root root]# <strong class="userinput"><code>chkconfig --add postgresql</code></strong>
[root root]# <strong class="userinput"><code>chkconfig --level 345 postgresql on</code></strong>
[root root]# <strong class="userinput"><code>chkconfig --list postgresql</code></strong>
postgresql      0:off   1:off   2:on    3:on    4:on    5:on    6:off
[root root]# <strong class="userinput"><code>service postgresql start</code></strong>
Starting PostgreSQL: ok
[root root]#
<span class="action"><span class="action">chkconfig --add postgresql
chkconfig --level 345 postgresql on
chkconfig --list postgresql
service postgresql start</span></span>
</pre>
</li><li class="listitem">
<p>Debian:</p><pre class="screen">
[root ~]# <strong class="userinput"><code>cp /var/tmp/packages/acs-core-docs/www/files/postgresql.txt /etc/init.d/postgresql</code></strong>
[root ~]# <strong class="userinput"><code>chown root.root /etc/init.d/postgresql</code></strong>
[root ~]# <strong class="userinput"><code>chmod 755 /etc/init.d/postgresql</code></strong>
[root ~]# <span class="action"><span class="action">
cp /var/tmp/openacs-5.7.0/packages/acs-core-docs/www/files/postgresql.txt /etc/init.d/postgresql
chown root.root /etc/init.d/postgresql
chmod 755 /etc/init.d/postgresql</span></span>
</pre><p>Test the script</p><pre class="screen">
[root ~]# <strong class="userinput"><code>/etc/init.d/postgresql stop</code></strong>
Stopping PostgreSQL: ok
[root ~]# 
</pre><p>If PostgreSQL successfully stopped, then use the following
command to make sure that the script is run appropriately at boot
and shutdown.</p><pre class="screen">
[root ~]# <strong class="userinput"><code>update-rc.d postgresql defaults</code></strong>
 Adding system startup for /etc/init.d/postgresql ...
   /etc/rc0.d/K20postgresql -&gt; ../init.d/postgresql
   /etc/rc1.d/K20postgresql -&gt; ../init.d/postgresql
   /etc/rc6.d/K20postgresql -&gt; ../init.d/postgresql
   /etc/rc2.d/S20postgresql -&gt; ../init.d/postgresql
   /etc/rc3.d/S20postgresql -&gt; ../init.d/postgresql
   /etc/rc4.d/S20postgresql -&gt; ../init.d/postgresql
   /etc/rc5.d/S20postgresql -&gt; ../init.d/postgresql
[root ~]# <strong class="userinput"><code>/etc/init.d/postgresql start</code></strong>
Starting PostgreSQL: ok
[root ~]#
</pre>
</li><li class="listitem">
<p>FreeBSD:</p><pre class="screen">
[root ~]# <strong class="userinput"><code>cp /tmp/openacs-5.7.0/packages/acs-core-docs/www/files/postgresql.txt /usr/local/etc/rc.d/postgresql.sh</code></strong>
[root ~]# <strong class="userinput"><code>chown root:wheel /usr/local/etc/rc.d/postgresql.sh</code></strong>
[root ~]# <strong class="userinput"><code>chmod 755 /usr/local/etc/rc.d/postgresql.sh</code></strong>
[root ~]# <span class="action"><span class="action">
cp /tmp/openacs-5.7.0/packages/acs-core-docs/www/files/postgresql.txt /usr/local/etc/rc.d/postgresql.sh
chown root:wheel /usr/local/etc/rc.d/postgresql.sh
chmod 755 /usr/local/etc/rc.d/postgresql.sh</span></span>
</pre><p>Test the script</p><pre class="screen">
[root ~]# <strong class="userinput"><code>/usr/local/etc/rc.d/postgresql.sh stop</code></strong>
Stopping PostgreSQL: ok
[root ~]# 
</pre><p>If PostgreSQL successfully stopped, then turn it back on because
we'll use it later.</p><pre class="screen">
[root root]# <strong class="userinput"><code>/usr/local/etc/rc.d/postgresql.sh start</code></strong>
Starting PostgreSQL: ok
[root root]#
<span class="action"><span class="action">/usr/local/etc/rc.d/postgresql.sh start</span></span>
</pre>
</li><li class="listitem">
<p>SuSE:</p><div class="note" style="margin-left: 0.5in; margin-right: 0.5in;">
<h3 class="title">Note</h3><p>I have received reports that SuSE 8.0 is different from previous
versions. Instead of installing the boot scripts in <code class="computeroutput">/etc/rc.d/init.d/</code>, they should be placed in
<code class="computeroutput">/etc/init.d/</code>. If you're using
SuSE 8.0, delete the <code class="computeroutput">rc.d/</code> part
in each of the following commands.</p>
</div><pre class="screen">
[root ~]# <strong class="userinput"><code>cp /var/tmp/openacs-5.7.0/packages/acs-core-docs/www/files/postgresql.txt /etc/rc.d/init.d/postgresql</code></strong>
[root ~]# <strong class="userinput"><code>chown root.root /etc/rc.d/init.d/postgresql</code></strong>
[root ~]# <strong class="userinput"><code>chmod 755 /etc/rc.d/init.d/postgresql</code></strong>
</pre><p>Test the script.</p><pre class="screen">
[root ~]# <strong class="userinput"><code>/etc/rc.d/init.d/postgresql stop</code></strong>
Stopping PostgreSQL: ok
</pre><p>If PostgreSQL successfully stopped, then use the following
command to make sure that the script is run appropriately at boot
and shutdown.</p><pre class="screen">
[root ~]# <strong class="userinput"><code>cd /etc/rc.d/init.d</code></strong>
root:/etc/rc.d/init.d# <strong class="userinput"><code>ln -s /etc/rc.d/init.d/postgresql K20postgresql</code></strong>
root:/etc/rc.d/init.d# <strong class="userinput"><code>ln -s /etc/rc.d/init.d/postgresql S20postgresql  </code></strong>
root:/etc/rc.d/init.d# <strong class="userinput"><code>cp K20postgresql rc2.d</code></strong>
root:/etc/rc.d/init.d# <strong class="userinput"><code>cp S20postgresql rc2.d</code></strong>
root:/etc/rc.d/init.d# <strong class="userinput"><code>cp K20postgresql rc3.d</code></strong>
root:/etc/rc.d/init.d# <strong class="userinput"><code>cp S20postgresql rc3.d</code></strong>
root:/etc/rc.d/init.d# <strong class="userinput"><code>cp K20postgresql rc4.d</code></strong>
root:/etc/rc.d/init.d# <strong class="userinput"><code>cp S20postgresql rc4.d </code></strong>
root:/etc/rc.d/init.d# <strong class="userinput"><code>cp K20postgresql rc5.d</code></strong>
root:/etc/rc.d/init.d# <strong class="userinput"><code>cp S20postgresql rc5.d</code></strong>
root:/etc/rc.d/init.d# <strong class="userinput"><code>rm K20postgresql</code></strong>
root:/etc/rc.d/init.d# <strong class="userinput"><code>rm S20postgresql</code></strong>
root:/etc/rc.d/init.d# 
</pre><p>Test configuration.</p><pre class="screen">
root:/etc/rc.d/init.d # <strong class="userinput"><code>cd</code></strong>
root:~ # <strong class="userinput"><code>/etc/rc.d/init.d/rc2.d/S20postgresql start</code></strong>
Starting PostgreSQL: ok
root:~ # 
</pre>
</li><li class="listitem">
<p>Mac OS X 10.3:</p><div class="orderedlist"><ol class="orderedlist" type="a"><li class="listitem">
<p>Install the startup script:</p><pre class="screen">
<strong class="userinput"><code>cd /System/Library/StartupItems/</code></strong><strong class="userinput"><code>tar xfz /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/acs-core-docs/www/files/osx-postgres-startup-item.tgz</code></strong>
</pre>
</li></ol></div>
</li><li class="listitem">
<p>Mac OS X 10.4 can use Launchd:</p><div class="orderedlist"><ol class="orderedlist" type="a"><li class="listitem">
<p>Install the startup script:</p><pre class="screen">
<strong class="userinput"><code>cd /Library/LaunchDaemons</code></strong><strong class="userinput"><code>cp
/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/packages/acs-core-docs/www/files/osx-postgres-launchd-item.txt
org.postgresql.PostgreSQL.plist</code></strong>
</pre><p>If postgres does not start automatically on reboot, see what
error you get when manually starting it with:</p><pre class="screen">
$ <strong class="userinput"><code>sudo launchctl load /Library/LaunchDaemons/org.postgresql.PostgreSQL.plist</code></strong>
$ <strong class="userinput"><code>sudo launchctl start org.postgresql.PostgreSQL</code></strong>
</pre>
</li></ol></div>
</li>
</ul></div><p>From now on, PostgreSQL should start automatically each time you
boot up and it should shutdown gracefully each time you shut down.
(Note: Debian defaults to starting all services on runlevels 2-5.
Red Hat defaults to starting services on 3-5. So, on Red Hat,
PostgreSQL won't start on runlevel 2 unless you alter the above
commands a little. This usually isn't a problem as Red Hat defaults
to runlevel 3)</p>
</li><li class="listitem">
<p>
<a name="postgres-tune" id="postgres-tune"></a><b>Tune postgres.
(OPTIONAL). </b>The default values for PostgreSQL are
very conservative; we can safely change some of them and improve
performance.</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem">
<p>Change the kernel parameter for maximum shared memory segment
size to 128Mb:</p><pre class="screen">
[root root]# <strong class="userinput"><code>echo 134217728 &gt;/proc/sys/kernel/shmmax</code></strong>
[root root]#
</pre><p>Make that change permanent by editing <code class="computeroutput">/etc/sysctl.conf</code> to add these lines at the
end:</p><pre class="programlisting">
# increase shared memory limit for postgres
kernel.shmmax = 134217728
</pre>
</li><li class="listitem">
<p>Edit the PostgreSQL config file, <code class="computeroutput">/usr/local/pgsql/data/postgresql.conf</code>, to
use more memory. These values should improve performance in most
cases. (<a class="ulink" href="http://openacs.org/forums/message-view?message_id=94071" target="_top">more information</a>)</p><pre class="programlisting">
#       Shared Memory Size
#
shared_buffers = 15200      # 2*max_connections, min 16

#       Non-shared Memory Sizes
#
sort_mem = 32168            # min 32


#       Write-ahead log (WAL)
#
checkpoint_segments = 3     # in logfile segments (16MB each), min 1
</pre><p>Restart postgres (<code class="computeroutput">service
postgresql restart</code>) or (<code class="computeroutput">/etc/init.d/postgres restart</code>) so that the
changes take effect.</p>
</li>
</ol></div><p>FreeBSD users: See <strong class="userinput"><code>man
syctl</code></strong>, <strong class="userinput"><code>man 5
sysctl</code></strong> and <strong class="userinput"><code>man 5
loader.conf</code></strong>.</p><p>Performance tuning resources:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>
<a class="ulink" href="http://www.postgresql.org/docs/7.4/interactive/kernel-resources.html" target="_top">Managing Kernel Resources</a> about PostgreSQL shared
memory and semaphores with specific operating system notes.</p></li><li class="listitem"><p>
<a class="ulink" href="http://developer.postgresql.org/docs/postgres/kernel-resources.html" target="_top">Managing Kernel Resources (development version)</a>
This information may be experimental.</p></li><li class="listitem"><p><a class="ulink" href="http://www.varlena.com/varlena/GeneralBits/Tidbits/perf.html" target="_top">Tuning PostgreSQL for performance</a></p></li>
</ul></div>
</li>
</ol></div>
</li>
</ul></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-postgres-moreinfo" id="install-postgres-moreinfo"></a>more information about
PostgreSQL</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p><a class="ulink" href="http://www.postgresql.org/idocs/" target="_top">Official PostgreSQL Docs</a></p></li><li class="listitem"><p><a class="ulink" href="http://pascal.scheffers.net/openacs/pgupdate/" target="_top">Migrating from 7.0 to 7.1</a></p></li><li class="listitem"><p><a class="ulink" href="http://techdocs.postgresql.org" target="_top">techdocs.postgresql.org</a></p></li><li class="listitem"><p><a class="ulink" href="http://www.linuxjournal.com/article.php?sid=4791" target="_top">PostgreSQL Performance Tuning</a></p></li>
</ul></div><div class="cvstag">($Id: postgres.xml,v 1.35 2006/07/17 05:38:38
torbenb Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="oracle" leftLabel="Prev" leftTitle="Install Oracle 8.1.7"
		    rightLink="aolserver4" rightLabel="Next" rightTitle="Install AOLserver 4"
		    homeLink="index" homeLabel="Home" 
		    upLink="complete-install" upLabel="Up"> 
		