
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Install OpenACS 5.9.0}</property>
<property name="doc(title)">Install OpenACS 5.9.0</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="aolserver4" leftLabel="Prev"
		    title="
Chapter 3. Complete Installation"
		    rightLink="win2k-installation" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="openacs" id="openacs"></a>Install OpenACS 5.9.0</h2></div></div></div><div class="authorblurb">
<p>by <a class="ulink" href="mailto:vinod\@kurup.com" target="_top">Vinod Kurup</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-aolserver-user-accounts" id="install-aolserver-user-accounts"></a>Set up a user account for
each site.</h3></div></div></div><p>AOLserver needs to be started as the root user if you want to
use port 80. Once it starts, though, it will drop the root
privileges and run as another user, which you must specify on the
command line. It&#39;s important that this user has as few
privileges as possible. Why? Because if an intruder somehow breaks
in through AOLserver, you don&#39;t want her to have any ability to
do damage to the rest of your server.</p><p>At the same time, AOLserver needs to have write access to some
files on your system in order for OpenACS to function properly. So,
we&#39;ll run AOLserver with a different user account for each
different service. A service name should be a single word,
<span class="emphasis"><em>letters and numbers only</em></span>. If
the name of your site is one word, that would be a good choice. For
example "<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>" might be
the service name for the <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>.net
community.</p><p>We&#39;ll leave the password blank, which prevents login by
password, for increased security. The only way to log in will be
with ssh certificates. The only people who should log in are
developers for that specific instance. Add this user, and put it in
the <code class="computeroutput"><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span></code> group so
that it can use database and server commands associated with that
group. (If you don&#39;t know how to do this, type <strong class="userinput"><code>man usermod</code></strong>. You can type
<strong class="userinput"><code>groups</code></strong> to find out
which groups a user is a part of)</p><pre class="screen">
[root root]# <strong class="userinput"><code>useradd <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
</pre><p>You also need to set up a group called web.</p><pre class="screen">
[root root]# <strong class="userinput"><code>groupadd web</code></strong>
</pre><p>Then change the user to be a part of this group:</p><pre class="screen">
[root root]# <strong class="userinput"><code>usermod -g web <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
</pre><p>FreeBSD creates the user this way:</p><pre class="screen">
[root root]# <strong class="userinput"><code>mkdir -p /home/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[root root]# <strong class="userinput"><code>pw useradd -n <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> -g web -d /home/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> -s /bin/bash</code></strong>
[root root]#
<span class="action"><span class="action">mkdir -p /home/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
pw useradd -n <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> -g web -d /home/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> -s /bin/bash
</span></span>
</pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="openacs-setup" id="openacs-setup"></a>Set up the file system for one or more OpenACS
Sites</h3></div></div></div><p>For Linux Standard Base compliance and ease of backup, all of
the files in each OpenACS site are stored in a subdirectory of
<code class="computeroutput">/var/lib/aolserver</code>, one
subdirectory per site. The first time you install an OpenACS site
on a server, you must create the parent directory and set its
permissions:</p><pre class="screen">
[root root]# <strong class="userinput"><code>mkdir /var/lib/aolserver</code></strong>
[root root]# <strong class="userinput"><code>chgrp web /var/lib/aolserver</code></strong>
[root root]# <strong class="userinput"><code>chmod 770 /var/lib/aolserver</code></strong>
[root root]#
<span class="action"><span class="action">mkdir /var/lib/aolserver
chgrp web /var/lib/aolserver
chmod 770 /var/lib/aolserver</span></span>
</pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-with-script" id="install-with-script"></a>Installation Option 1: Use automated
script</h3></div></div></div><p>A bash script is available to automate all of the steps for the
rest of this section. It requires <a class="link" href="install-tclwebtest" title="Install tclwebtest.">tclwebtest</a>. The automated script can
greatly accelerate the install process, but is very sensitive to
the install environment. We recommend that you run the automated
install and, if it does not work the first time, consider switching
to a <a class="link" href="openacs" title="Installation Option 2: Install from tarball">manual
installation</a>.</p><p>Get the install script from CVS. It is located within the main
cvs tree, at /etc/install. Use anonymous CVS checkout to get that
directory in the home directory of the service&#39;s dedicated
user. We put it there so that it is not overwritten when we do the
main CVS checkout to the target location.</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cvs -d :pserver:anonymous\@cvs.openacs.org:/cvsroot co -d install openacs-4/etc/install</code></strong>
cvs server: Updating install
U install/README
U install/TODO
  ... many lines omitted ...
U install/tcl/twt-procs.tcl
U install/tcl/user-procs.tcl
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cd install</code></strong>
[$OPENACS_SERVICE_NAME install]$ <strong class="userinput"><code>emacs install.tcl</code></strong>
</pre><p>Edit the installation configuration file, <code class="computeroutput">/home/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/install/install.tcl</code>
and update the site-specific values, such as the new service&#39;s
IP address and name, which will be written into the new
service&#39;s <code class="computeroutput">config.tcl</code> file.
If your system is different from the one described in the previous
sections, check the file paths as well. Set <code class="computeroutput">do_checkout=yes</code> to create a new OpenACS
site directly from a CVS checkout, or <code class="computeroutput">=no</code> if you have a fully configured site and
just want to rebuild it (drop and recreate the database and repeat
the installation). If you have followed a stock installation, the
default configuration will work without changes and will install an
OpenACS site at 127.0.0.1:8000.</p><p>Run the install script <code class="computeroutput">install.sh</code> as root:</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>exit</code></strong> 
[root root]# <strong class="userinput"><code>sh /home/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/install/install.sh</code></strong>
/home/$OPENACS_SERVICE_NAME/install/install.sh: Starting installation with config_file 
/home/$OPENACS_SERVICE_NAME/install/install.tcl. Using serverroot=/var/lib/aolserver/
$OPENACS_SERVICE_NAME, server_url=http://0.0.0.0:8000, do_checkout=yes, do_install=yes, 
dotlrn=no, and database=postgres., use_daemontools=true
  <span class="emphasis"><em>... many lines omitted ...</em></span>
Tue Jan 27 11:50:59 CET 2004: Finished (re)installing /var/lib/aolserver/$OPENACS_SERVICE_NAME.
######################################################################
  New site URL: http://127.0.0.1:8000
admin email   : admin\@yourserver.net
admin password: xxxx
######################################################################
[root root]#
</pre><p>You can proceed to <a class="xref" href="openacs" title="Next Steps">the section
called &ldquo;Next Steps&rdquo;</a>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-from-tarball" id="install-from-tarball"></a>Installation Option 2: Install from
tarball</h3></div></div></div><p>You should already have downloaded the OpenACS tarball to the
<code class="computeroutput">/var/tmp</code> directory. If not,
<a class="link" href="individual-programs">download the OpenACS
tarball</a> and save it in <code class="computeroutput">/var/tmp</code> and proceed:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>
<a name="install-openacs-download" id="install-openacs-download"></a>Unpack the OpenACS tarball and
rename it to <code class="computeroutput">$OPENACS_SERVICE_NAME</code>. Secure the directory
so that only the owner can access it. Check the permissions by
listing the directory.</p><p>FreeBSD note: Change the period in <strong class="userinput"><code>chown -R
$OPENACS_SERVICE_NAME.$OPENACS_SERVICE_NAME
$OPENACS_SERVICE_NAME</code></strong> to a colon: <strong class="userinput"><code>chown -R
$OPENACS_SERVICE_NAME:$OPENACS_SERVICE_NAME
$OPENACS_SERVICE_NAME</code></strong>
</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cd /var/lib/aolserver</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>tar xzf /var/tmp/openacs-5.9.0.tgz</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>mv openacs-5.9.0 <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>chmod -R 775 <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>chown -R <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>.<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>ls -al</code></strong>
total 3
drwxrwx---    3 root     web          1024 Mar 29 16:41 .
drwxr-xr-x   25 root     root         1024 Mar 29 16:24 ..
drwx------    7 $OPENACS_SERVICE_NAME web          1024 Jan  6 14:36 $OPENACS_SERVICE_NAME
[$OPENACS_SERVICE_NAME aolserver]$ <strong class="userinput"><code>exit</code></strong>
logout
[root root]#
<span class="action"><span class="action">su - $OPENACS_SERVICE_NAME
cd /var/lib/aolserver
tar xzf /var/tmp/openacs-5.9.0.tgz
mv openacs-5.9.0 $OPENACS_SERVICE_NAME
chmod -R 755 $OPENACS_SERVICE_NAME
chown -R $OPENACS_SERVICE_NAME.$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME
exit</span></span>
</pre>
</li><li class="listitem"><p>
<a class="link" href="cvs-tips" title="Add the Service to CVS - OPTIONAL">Add the Service to CVS</a>
(OPTIONAL)</p></li><li class="listitem">
<p>Prepare the database</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>
<a name="install-openacs-prepare-oracle" id="install-openacs-prepare-oracle"></a><strong>Prepare Oracle for
OpenACS. </strong>If you won&#39;t be using Oracle,
skip to <a class="xref" href="openacs" title="Prepare PostgreSQL for an OpenACS Service">Prepare PostgreSQL for
an OpenACS Service</a>
</p><p>You should be sure that your user account (e.g. <code class="computeroutput"><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span></code>) is in the
<code class="computeroutput">dba</code> group.</p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem">
<p>Verify membership by typing <code class="computeroutput">groups</code> when you login:</p><pre class="programlisting">
[$OPENACS_SERVICE_NAME ~]$ groups
dba web
</pre><p>If you do not see these groups, take the following action:</p><pre class="programlisting">
[$OPENACS_SERVICE_NAME ~]$ <strong class="userinput"><code>su -</code></strong>
Password: ************
[root ~]# <strong class="userinput"><code>adduser <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> dba</code></strong>
</pre><p>If you get an error about an undefined group, then add that
group manually:</p><pre class="programlisting">
[root ~]# <strong class="userinput"><code>groupadd dba</code></strong>
[root ~]# <strong class="userinput"><code>groupadd web</code></strong>
</pre><p>Make sure to logout as <code class="computeroutput">root</code>
when you are finished with this step and log back in as your
regular user.</p>
</li><li class="listitem">
<p>Connect to Oracle using <code class="computeroutput">svrmgrl</code> and login:</p><pre class="programlisting">
[$OPENACS_SERVICE_NAME ~]$ <strong class="userinput"><code>svrmgrl</code></strong>
SVRMGR&gt; <strong class="userinput"><code>connect internal</code></strong>
Connected.
</pre>
</li><li class="listitem">
<p>Determine where the system tablespaces are stored:</p><pre class="programlisting">
SVRMGR&gt; <strong class="userinput"><code>select file_name from dba_data_files;</code></strong>
</pre><p>Example results:</p><pre class="programlisting">
/ora8/m01/app/oracle/oradata/ora8/system01.dbf
/ora8/m01/app/oracle/oradata/ora8/tools01.dbf
/ora8/m01/app/oracle/oradata/ora8/rbs01.dbf
/ora8/m01/app/oracle/oradata/ora8/temp01.dbf
/ora8/m01/app/oracle/oradata/ora8/users01.dbf
/ora8/m01/app/oracle/oradata/ora8/indx01.dbf
/ora8/m01/app/oracle/oradata/ora8/drsys01.dbf
</pre>
</li><li class="listitem"><p>Using the above output, you should determine where to store your
tablespace. As a general rule, you&#39;ll want to store your
tablespace on a mount point under the <code class="computeroutput">/ora8</code> directory that is separate from the
Oracle system data files. By default, the Oracle system is on
<code class="computeroutput">m01</code>, so we will use
<code class="computeroutput">m02</code>. This enables your Oracle
system and database files to be on separate disks for optimized
performance. For more information on such a configuration, see
<a class="ulink" href="http://philip.greenspun.com/panda/databases-choosing" target="_top">Chapter 12</a> of <a class="ulink" href="http://philip.greenspun.com/panda/" target="_top">Philip&#39;s
book</a>. For this example, we&#39;ll use <code class="computeroutput">/ora8/m02/oradata/ora8/</code>.</p></li><li class="listitem">
<p>Create the directory for the datafile; to do this, exit from
<code class="computeroutput">svrmgrl</code> and login as
<code class="computeroutput">root</code> for this step:</p><pre class="programlisting">
SVRMGR&gt; <strong class="userinput"><code>exit</code></strong>
[$OPENACS_SERVICE_NAME ~]$ <strong class="userinput"><code>su -</code></strong>
Password: ************
[root ~]# <strong class="userinput"><code>mkdir -p /ora8/m02/oradata/ora8/</code></strong>
[root ~]# <strong class="userinput"><code>chown <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>:web /ora8/m02/oradata/ora8</code></strong>
[root ~]# <strong class="userinput"><code>chmod 775 /ora8/m02/oradata/ora8</code></strong>
[root ~]# <strong class="userinput"><code>exit</code></strong>
[$OPENACS_SERVICE_NAME ~]$
</pre>
</li><li class="listitem">
<p>Create a tablespace for the service. It is important that the
tablespace can <code class="computeroutput">autoextend</code>. This
allows the tablespace&#39;s storage capacity to grow as the size of
the data grows. We set the pctincrease to be a very low value so
that our extents won&#39;t grow geometrically. We do not set it to
0 at the tablespace level because this would affect Oracle&#39;s
ability to automatically coalesce free space in the tablespace.</p><pre class="programlisting">
[$OPENACS_SERVICE_NAME ~]$ <strong class="userinput"><code>svrmgrl</code></strong>
SVRMGR&gt; <strong class="userinput"><code>connect internal;</code></strong>
SVRMGR&gt; <strong class="userinput"><code>create tablespace <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
      datafile '/ora8/m02/oradata/ora8/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>01.dbf' 
      size 50M 
      autoextend on 
      next 10M
      maxsize 300M
      extent management local
      uniform size 32K;</code></strong>
</pre>
</li><li class="listitem">
<p>Create a database user for this service. Give the user access to
the tablespace and rights to connect. We&#39;ll use <code class="computeroutput"><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAMEpassword</span></span></code> as
our password.</p><p>Write down what you specify as <span class="emphasis"><em>service_name</em></span> (i.e. <code class="computeroutput"><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span></code>) and
<span class="emphasis"><em>database_password</em></span> (i.e.
<code class="computeroutput"><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAMEpassword</span></span></code>).
You will need this information for configuring exports and
AOLserver.</p><pre class="programlisting">
SVRMGR&gt; <strong class="userinput"><code>create user <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> identified by <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAMEpassword</span></span> default tablespace <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
    temporary tablespace temp quota unlimited on <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>;</code></strong>
SVRMGR&gt; <strong class="userinput"><code>grant connect, resource, ctxapp, javasyspriv, query rewrite to <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>;</code></strong>
SVRMGR&gt; <strong class="userinput"><code>revoke unlimited tablespace from <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>;</code></strong>
SVRMGR&gt; <strong class="userinput"><code>alter user <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> quota unlimited on <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>;</code></strong>
SVRMGR&gt; <strong class="userinput"><code>exit;</code></strong>
</pre><p>Your table space is now ready. In case you are trying to delete
a previous OpenACS installation, consult these commands in
<a class="xref" href="install-openacs-delete-tablespace" title="Deleting a tablespace">the section called
&ldquo;Deleting a tablespace&rdquo;</a>
below.</p>
</li><li class="listitem">
<p>Make sure that you can login to Oracle using your <span class="emphasis"><em>service_name</em></span> account:</p><pre class="programlisting">
[$OPENACS_SERVICE_NAME ~]$ <strong class="userinput"><code>sqlplus <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAMEpassword</span></span>
</code></strong>
SQL&gt; <strong class="userinput"><code>select sysdate from dual;</code></strong>
SYSDATE
----------
2001-12-20
SQL&gt; <strong class="userinput"><code>exit;</code></strong>
</pre><p>You should see today&#39;s date in a format
'YYYY-MM-DD.' If you can&#39;t login, try redoing step 1
again. If the date is in the wrong format, make sure you followed
the steps outlined in <a class="xref" href="oracle" title="Troubleshooting Oracle Dates">the section called
&ldquo;Troubleshooting Oracle
Dates&rdquo;</a>
</p>
</li>
</ol></div>
</li><li class="listitem">
<p>
<a name="install-openacs-prepare-postgres" id="install-openacs-prepare-postgres"></a><strong>Prepare PostgreSQL
for an OpenACS Service. </strong>
</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>
<a name="create-service-db-user" id="create-service-db-user"></a>PostgreSQL:</p><p>Create a user in the database matching the service name. With
default PostgreSQL authentication, a system user connecting locally
automatically authenticates as the postgres user of the same name,
if one exists. We currently use postgres "super-users"
for everything, which means that anyone with access to any of the
OpenACS system accounts on a machine has full access to all
postgresql databases on that machine.</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - postgres</code></strong>
[postgres pgsql]$ <strong class="userinput"><code>createuser -a -d <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
CREATE USER
[postgres pgsql]$ <strong class="userinput"><code>exit</code></strong>
logout
[root root]#
</pre>
</li><li class="listitem">
<p>
<a name="create-database" id="create-database"></a>Create a
database with the same name as our service name, <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>. The full
pathname for <code class="computeroutput">createdb</code> needs to
be used, since the pgsql directory has not been added to the
$OPENACS_SERVICE_NAME bash profile.</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>/usr/local/pgsql/bin/createdb -E UNICODE <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
CREATE DATABASE
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$
<span class="action"><span class="action">su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
/usr/local/pgsql/bin/createdb -E UNICODE <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</span></span>
</pre>
</li><li class="listitem">
<p>Automate daily database Vacuuming. This is a process which
cleans out discarded data from the database. A quick way to
automate vacuuming is to edit the cron file for the database user.
Recommended: <code class="computeroutput">VACUUM ANALYZE</code>
every hour and <code class="computeroutput">VACUUM FULL
ANALYZE</code> every day.</p><a class="indexterm" name="idp140592104083832" id="idp140592104083832"></a><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>export EDITOR=emacs;crontab -e</code></strong>
</pre><p>Add these lines to the file. The vacuum command cleans up
temporary structures within a PostGreSQL database, and can improve
performance. We vacuum gently every hour and completely every day.
The numbers and stars at the beginning are cron columns that
specify when the program should be run - in this case, whenever the
minute is 0 and the hour is 1, i.e., 1:00 am every day, and every
(*) day of month, month, and day of week. Type <code class="computeroutput">man 5 crontab</code> for more information.</p><pre class="programlisting">
0 1-23 * * * /usr/local/pgsql/bin/vacuumdb --analyze <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
0 0 * * * /usr/local/pgsql/bin/vacuumdb --full --analyze <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</pre><p>Depending on your distribution, you may receive email when the
crontab items are executed. If you don&#39;t want to receive email
for those crontab items, you can add <code class="computeroutput">&gt; /dev/null 2&gt;&amp;1</code> to the end of
each crontab line</p>
</li><li class="listitem"><p>
<a class="link" href="install-full-text-search-openfts" title="Install OpenFTS prerequisites in PostgreSQL instance">Add
Full Text Search Support</a> (OPTIONAL)</p></li><li class="listitem"><p>
<a name="db-setup-exit" id="db-setup-exit"></a> At this point
the database should be ready for installing OpenACS.</p></li>
</ul></div>
</li>
</ul></div>
</li><li class="listitem">
<a name="install-openacs-configure-aol" id="install-openacs-configure-aol"></a><p><strong>Configure an AOLserver Service for
OpenACS. </strong></p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem">
<p>
<a name="configure-config-tcl" id="configure-config-tcl"></a>
The AOLserver architecture lets you run an arbitrary number of
virtual servers. A virtual server is an HTTP service running on a
specific port, e.g. port 80. In order for OpenACS to work, you need
to configure a virtual server. The Reference Platform uses a
configuration file included in the OpenACS tarball, <code class="computeroutput">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/etc/config.tcl</code>.
Open it in an editor to adjust the parameters.</p><a class="indexterm" name="idp140592101013272" id="idp140592101013272"></a><pre class="screen">
[root root]# <strong class="userinput"><code>su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>cd /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/etc</code></strong>
[$OPENACS_SERVICE_NAME etc]$ <strong class="userinput"><code>emacs config.tcl</code></strong>
</pre><p>You can continue without changing any values in the file.
However, if you don&#39;t change <code class="computeroutput">address</code> to match the computer&#39;s ip
address, you won&#39;t be able to browse to your server from other
machines.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<span class="emphasis"><em>httpport</em></span> - If you want
your server on a different port, enter it here. The Reference
Platform port is 8000, which is suitable for development use. Port
80 is the standard http port - it&#39;s the port used by your
browser when you enter http://yourserver.test. So you should use
port 80 for your production site.</p></li><li class="listitem"><p>
<span class="emphasis"><em>httpsport</em></span> - This is the
port for https requests. The Reference Platform https port is 8443.
If http port is set to 80, httpsport should be 443 to match the
standard.</p></li><li class="listitem"><p>
<span class="emphasis"><em>address</em></span> - The IP address
of the server. If you are hosting multiple IPs on one computer,
this is the address specific to the web site. Each virtual server
will ignore any requests directed at other addresses.</p></li><li class="listitem"><p>
<span class="emphasis"><em>server</em></span> - This is the
keyword that, by convention, identifies the service. It is also
used as part of the path for the service root, as the name of the
user for running the service, as the name of the database, and in
various dependent places. The Reference Platform uses <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>.</p></li><li class="listitem"><p>
<span class="emphasis"><em>db_name</em></span> - In almost all
cases, this can be kept as a reference to $server. If for some
reason, the tablespace you are using is different than your
servername, then you can set it here. You should have a good reason
for doing this.</p></li><li class="listitem"><p>
<span class="emphasis"><em>servername</em></span> - This is just
a *pretty* name for your server.</p></li><li class="listitem"><p>
<span class="emphasis"><em>user_account</em></span> - The
account that will both own OpenACS files and connect to the
database (for Postgresql).</p></li><li class="listitem"><p>
<span class="emphasis"><em>debug</em></span> - Set to true for a
very verbose error log, including many lines for every page view,
success or failure.</p></li>
</ul></div>
</li><li class="listitem"><p>AOLserver is very configurable. These settings should get you
started, but for more options, read the <a class="ulink" href="http://aolserver.com/docs/admin/config.html" target="_top">AOLserver docs</a>.</p></li><li class="listitem"><p>
<a class="link" href="install-full-text-search-openfts" title="Enable OpenFTS in config.tcl">Enable OpenFTS Full Text Search</a>
(OPTIONAL)</p></li><li class="listitem"><p>
<a class="link" href="install-ssl" title="Installing SSL Support for an OpenACS service">Install nsopenssl
for SSL support.</a> (OPTIONAL)</p></li>
</ol></div>
</li><li class="listitem">
<a name="verify-aolserver-startup" id="verify-aolserver-startup"></a><p><strong>Verify AOLserver startup. </strong></p><div class="orderedlist"><ol class="orderedlist" type="a">
<li class="listitem">
<p>
<a name="start-aolserver" id="start-aolserver"></a> Kill any
current running AOLserver processes and start a new one. The
recommended way to start an AOLserver process is by running the
included script, <code class="computeroutput">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/etc/daemontools/run</code>.
If you are not using the default file paths and names, you will
need to edit <code class="computeroutput">run</code>.</p><p>If you want to use port 80, there are complications. AOLserver
must be root to use system ports such as 80, but refuses to run as
root for security reasons. So, we call the run script as root and
specify a non-root user ID and Group ID which AOLserver will switch
to after claiming the port. To do so, find the UID and GID of the
<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span> user via
<code class="computeroutput">grep <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
/etc/passwd</code> and then put those numbers into the command line
via <code class="computeroutput">-u <span class="replaceable"><span class="replaceable">501</span></span> -g
<span class="replaceable"><span class="replaceable">502</span></span>
</code>. In AOLserver 4, you must
also send a <code class="computeroutput">-b</code> flag. Do this by
editing the <code class="computeroutput">run</code> file as
indicated in the comments.</p><p>If you are root then killall will affect all OpenACS services on
the machine, so if there&#39;s more than one you&#39;ll have to do
<code class="computeroutput">ps -auxw | grep nsd</code> and
selectively kill by job number.</p><pre class="screen">
[$OPENACS_SERVICE_NAME etc]$ <strong class="userinput"><code>killall nsd</code></strong>
nsd: no process killed
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$<strong class="userinput"><code> /usr/local/aolserver/bin/nsd-postgres -t /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/etc/config.tcl</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ [08/Mar/2003:18:13:29][32131.8192][-main-] Notice: nsd.tcl: starting to read config file...
[08/Mar/2003:18:13:29][32131.8192][-main-] Notice: nsd.tcl: finished reading config file.
</pre>
</li><li class="listitem">
<p>
<a name="connect-to-aolserver" id="connect-to-aolserver"></a>
Attempt to connect to the service from a web browser. You should
specify a URL like: <code class="computeroutput">http://<span class="replaceable"><span class="replaceable">yourserver.test</span></span>:8000</code>
</p><p>You should see a page that looks like <a class="ulink" href="files/openacs-start" target="_top">this</a>. If you <a class="link" href="cvs-tips" title="Add the Service to CVS - OPTIONAL">imported your files into
cvs</a>, now that you know it worked you can erase the temp
directory with <code class="computeroutput">rm -rf
/var/lib/aolserver/$OPENACS_SERVICE_NAME.orig</code>.</p><p>If you don&#39;t see the login page, view your error log
(<code class="computeroutput">/var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/log/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>-error.log</code>)
to make sure the service is starting without any problems. The most
common errors here are trying to start a port 80 server while not
root, failing to connect because of a firewall, and AOLserver
failing to start due to permissions errors or missing files. If you
need to make changes, don&#39;t forget to kill any running servers
with <strong class="userinput"><code>killall
nsd</code></strong>.</p>
</li><li class="listitem"><p>
<a class="link" href="install-openacs-keepalive" title="Starting and Stopping an OpenACS instance.">Automate AOLserver
keepalive</a> (OPTIONAL)</p></li>
</ol></div>
</li><li class="listitem">
<a name="install-openacs-using-installer" id="install-openacs-using-installer"></a><p>
<strong>Configure a Service with the OpenACS
Installer. </strong> Now that you&#39;ve got AOLserver
up and running, let&#39;s install OpenACS 5.9.0.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>You should see a page from the webserver titled <code class="computeroutput">OpenACS Installation: Welcome</code>. You will be
warned if your version of the database driver is out of date, if
AOLserver cannot connect to the database, if any modules are
missing or out-of-date, or if there are any problems with
filesystem permissions on the server side. But if everything is
fine, you can click <code class="computeroutput">Next</code> to
proceed to load the OpenACS Kernel data model.</p></li><li class="listitem">
<p>The next page shows the results of loading the OpenACS Kernel
data model - be prepared to wait a few minutes as it works. You
should see a string of output messages from the database as the
datamodel is created. You&#39;ll see the line:</p><pre class="programlisting">
Loading package .info files ... this will take a few minutes
</pre><p>This will really take a few minutes. Have faith! Finally,
another <code class="computeroutput">Next</code> button will appear
at the bottom - click it.</p>
</li><li class="listitem"><p>The following page shows the results of loading the core package
data models. You should see positive results for each of the
previously selected packages, but watch out for any errors.
Eventually, the page will display "Generating secret
tokens" and then "Done"- click <code class="computeroutput">Next</code>.</p></li><li class="listitem"><p>You should see a page, "OpenACS Installation: Create
Administrator" with form fields to define the OpenACS site
administrator. Fill out the fields as appropriate, and click
<code class="computeroutput">Create User</code>.</p></li><li class="listitem"><p>You should see a page, "OpenACS Installation: Set System
Information" allowing you to name your service. Fill out the
fields as appropriate, and click <code class="computeroutput">Set
System Information</code>
</p></li><li class="listitem">
<p>You&#39;ll see the final Installer page, "OpenACS
Installation: Complete." It will tell you that the server is
being restarted; note that unless you already set up a way for
AOLserver to restart itself (ie. <a class="link" href="install-openacs-keepalive" title="Starting and Stopping an OpenACS instance.">inittab or
daemontools</a>), you&#39;ll need to manually restart your
service.</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>/usr/local/aolserver/bin/nsd-postgres -t /var/lib/aolserver/<span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>/config.tcl</code></strong>
</pre>
</li><li class="listitem"><p>Give the server a few minutes to start up. Then reload the final
page above. You should see the front page, with an area to login
near the upper right. Congratulations, OpenACS 5.9.0 is now up and
running!</p></li>
</ul></div>
</li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-from-cvs" id="install-from-cvs"></a>Installation Option 3: Install from CVS</h3></div></div></div><p>If you want to track fresh code developments between releases,
or you are an OpenACS core developer, you may want to install from
CVS. This is identical to Option 2 except that you get the files
from CVS instead of the tarball: <a class="ulink" href="/xowiki/Get_the_Code" target="_top">CVS Checkout Instructions</a>.
In short, instead of <code class="computeroutput"><strong class="userinput"><code>tar xzf
/var/tmp/openacs-5.9.0.tgz</code></strong></code>, use <code class="computeroutput"><strong class="userinput"><code>cvs -z3 -d
:pserver:anonymous\@openacs.org:/cvsroot co
acs-core</code></strong></code> to obtain an ACS core
installation.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="install-next-steps" id="install-next-steps"></a>Next Steps</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Use daemontools <code class="computeroutput">supervise</code>
and <code class="computeroutput">svc</code>, or <code class="computeroutput">inittab</code>, to <a class="link" href="install-openacs-inittab" title="AOLserver keepalive with inittab">automate server startup and
shutdown.</a>
</p></li><li class="listitem"><p>Install Full Text Search (OPTIONAL). If you have <a class="link" href="install-full-text-search-openfts" title="Install OpenFTS module">installed OpenFTS</a> and enabled OpenFTS,
you can now <a class="link" href="install-full-text-search-tsearch2" title="Install Full Text Search Engine Package in OpenACS">install</a>
the OpenFTS Driver package and Full Text Search Engine package in
the OpenACS service.</p></li><li class="listitem"><p>This is a good time to make a <a class="link" href="snapshot-backup" title="Manual backup and recovery">backup</a> of your service. If this is
a production site, you should set up <a class="link" href="automated-backup" title="Automated Backup">automatic nightly
backups</a>.</p></li><li class="listitem"><p>If you want traffic reports, <a class="link" href="analog-setup" title="Set up Log Analysis Reports">set up
analog</a> or another log processing program.</p></li><li class="listitem"><p>Follow the instruction on the home page to change the appearance
of your service or add more packages. (<a class="link" href="configuring-new-site" title="Chapter 4. Configuring a new OpenACS Site">more
information</a>)</p></li><li class="listitem"><p>Proceed to the <a class="link" href="tutorial" title="Chapter 9. Development Tutorial">tutorial</a>
to learn how to develop your own packages.</p></li><li class="listitem">
<p>Set up database environment variables for the site user.
Depending on how you installed Oracle or PostGreSQL, these settings
may be necessary for working with the database while logged in as
the service user. They do not directly affect the service&#39;s
run-time connection with the database, because those environmental
variables are set by the wrapper scripts nsd-postgres and
nsd-oracle.</p><pre class="screen">
[root root]# <strong class="userinput"><code>su - <span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span>
</code></strong>
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>emacs .bashrc</code></strong>
</pre><p>Put in the appropriate lines for the database you are running.
If you will use both databases, put in both sets of lines.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>PostgreSQL:</p><pre class="programlisting">
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/pgsql/lib
export PATH=$PATH:/usr/local/pgsql/bin
</pre>
</li><li class="listitem">
<p>Oracle. These environment variables are specific for a local
Oracle installation communicating via IPC. If you are connecting to
a remote Oracle installation, you&#39;ll need to adjust these
appropriately. Also, make sure that the '8.1.7' matches
your Oracle version.</p><pre class="programlisting">
export ORACLE_BASE=/ora8/m01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/<span class="replaceable"><span class="replaceable">8.1.7</span></span>
export PATH=$PATH:$ORACLE_HOME/bin
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export ORACLE_SID=ora8
export ORACLE_TERM=vt100
export ORA_NLS33=$ORACLE_HOME/ocommon/nls/admin/data
</pre>
</li>
</ul></div><p>Test this by logging out and back in as <code class="computeroutput"><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span></code> and
checking the paths.</p><pre class="screen">
[$OPENACS_SERVICE_NAME $OPENACS_SERVICE_NAME]$ <strong class="userinput"><code>exit</code></strong>
logout
[root src]# <strong class="userinput"><code>su - <strong class="userinput"><code><span class="replaceable"><span class="replaceable">$OPENACS_SERVICE_NAME</span></span></code></strong>
</code></strong>
[$OPENACS_SERVICE_NAME ~]$ <strong class="userinput"><code>env</code></strong>
</pre><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>For PostgreSQL, you should see:</p><pre class="screen">
LD_LIBRARY_PATH=:/usr/local/pgsql/lib
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin/X11:/usr/X11R6/bin:\
  /root/bin:/usr/local/pgsql/bin:/usr/local/pgsql/bin
</pre>
</li><li class="listitem">
<p>For Oracle:</p><pre class="screen">
ORACLE_BASE=/ora8/m01/app/oracle
ORACLE_HOME=/ora8/m01/app/oracle/product/8.1.7
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/bin/X11:/usr/X11R6/bin:\
  /root/bin:/ora8/m01/app/oracle/product/8.1.7/bin
LD_LIBRARY_PATH=/ora8/m01/app/oracle/product/8.1.7/lib:/lib:/usr/lib
ORACLE_SID=ora8
ORACLE_TERM=vt100
ORA_NLS33=$ORACLE_HOME/ocommon/nls/admin/data
</pre>
</li>
</ul></div>
</li><li class="listitem"><p>Test your <a class="link" href="backup-recovery" title="Chapter 8. Backup and Recovery">backup and
recovery</a> procedure.</p></li><li class="listitem"><p>Set up <a class="xref" href="uptime" title="External uptime validation">the section called
&ldquo;External uptime
validation&rdquo;</a>.</p></li>
</ul></div><div class="cvstag">($&zwnj;Id: openacs.xml,v 1.31.14.4 2017/06/11
08:42:13 gustafn Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="aolserver4" leftLabel="Prev" leftTitle="Install AOLserver 4"
		    rightLink="win2k-installation" rightLabel="Next" rightTitle="OpenACS Installation Guide for
Windows"
		    homeLink="index" homeLabel="Home" 
		    upLink="complete-install" upLabel="Up"> 
		