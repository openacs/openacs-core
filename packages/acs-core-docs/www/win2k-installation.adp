
<property name="context">{/doc/acs-core-docs {Documentation}} {OpenACS Installation Guide for Windows2000}</property>
<property name="doc(title)">OpenACS Installation Guide for Windows2000</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="openacs" leftLabel="Prev"
		    title="
Chapter 3. Complete Installation"
		    rightLink="mac-installation" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="win2k-installation" id="win2k-installation"></a>OpenACS Installation Guide for
Windows2000</h2></div></div></div><div class="authorblurb">
<p>by Matthew Burke and Curtis Galloway</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><p>
<span class="strong"><strong>NOTE:</strong></span> These
instructions were valid for ACS v4, but have not been tested with
OpenACS and the ArsDigita binary distributions are no longer
available. Currently (10/2003), the best option to get OpenACS
5.7.0 running on Windows is to use <a class="ulink" href="http://vmware.com" target="_top">VMware</a> and John Sequeira's
<a class="ulink" href="http://www.pobox.com/~johnseq/projects/oasisvm/" target="_top">Oasis VM distribution</a>
</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Source: <a class="ulink" href="http://openacs.org/projects/openacs/download/" target="_top">http://openacs.org/projects/openacs/download</a>
</p></li><li class="listitem"><p>Bug reports: <a class="ulink" href="http://openacs.org/bugtracker/openacs/" target="_top">http://openacs.org/bugtracker/openacs</a>
</p></li><li class="listitem"><p>Philosophy: <a class="ulink" href="http://photo.net/wtr/thebook/community/" target="_top">http://photo.net/wtr/thebook/community</a> (the community
chapter of <span class="emphasis"><em>Philip and Alex's Guide to
Web Publishing</em></span>)</p></li><li class="listitem"><p>Technical background: <a class="ulink" href="http://photo.net/wtr/thebook/" target="_top">http://photo.net/wtr/thebook/</a>
</p></li>
</ul></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="win2kinstall-overview" id="win2kinstall-overview"></a>Overview</h3></div></div></div><p>With the recent release of a win32 version of AOLserver, it is
now possible to run the OpenACS on Windows2000 and Windows98. This
document explains the steps necessary to get the OpenACS installed
and running on your machine.</p><div>Note:</div><p>We do not recommend running a production server on Windows98.
But the platform is more than sufficient for working the <a class="ulink" href="http://photo.net/teaching/one-term-web" target="_top">problem sets</a> and for getting a feel for the OpenACS.</p><p>You'll need to use the ArsDigita binary distribution of
AOLserver for the Win32 platform, which contains patches for
several problems we have come across in the default AOLserver
binary distribution. See <a class="ulink" href="/aol3" target="_top">the ArsDigita AOLserver 3 distribution page</a> for
details.</p><p>You can download the binary distribution from <a class="ulink" href="http://arsdigita.com/download" target="_top">the ArsDigita
download page</a> under "ArsDigita AOLserver 3 Binary Distribution
for Win32." Please read the release notes in the distribution for
configuration notes specific to the version you are
downloading.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="win2kinstall-prerequisites" id="win2kinstall-prerequisites"></a>Prerequisites</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Windows 2000 or Windows 98</p></li><li class="listitem"><p>
<a class="ulink" href="http://www.winzip.com" target="_top">WinZip</a> or any tool that can extract gzipped/tarred
archives.</p></li><li class="listitem"><p>
<a class="ulink" href="ftp://ftp.blarg.net/users/amol/zsh" target="_top">zsh</a> (free; included in the binary distribution).
If this link is broken try <a class="ulink" href="http://www.zsh.org" target="_top">http://www.zsh.org</a>.</p></li><li class="listitem"><p>
<a class="ulink" href="http://www.oracle.com" target="_top">Oracle 8</a> relational database management system</p></li><li class="listitem"><p>
<a class="ulink" href="http://www.aolserver.com" target="_top">AOLserver</a> (free)</p></li><li class="listitem"><p>
<a class="ulink" href="http://prdownloads.sourceforge.net/aolserver/nsoracle-2.6.tar.gz?download" target="_top">Oracle driver for AOLserver</a> (free)</p></li>
</ul></div><p>It is helpful if you have Oracle interMedia Text for full-text
searches. We're also trying to make our system work with the PLS
System, available free from <a class="ulink" href="http://www.pls.com" target="_top">http://www.pls.com</a>.</p><p>Although the <code class="computeroutput">zsh</code> shell is
the only command-line tool required to install the OpenACS, if you
are a UNIX person used to typing <code class="computeroutput">ls</code> instead of <code class="computeroutput">dir</code> you'll get along much better with the
Cygwin toolkit from RedHat (available at <a class="ulink" href="http://sourceware.cygnus.com/cygwin" target="_top">http://sourceware.cygnus.com/cygwin</a>). This is a
development library and set of tools that gives you a very
UNIX-like environment under Windows. In particular, it includes
<code class="computeroutput">bash</code>, <code class="computeroutput">gzip</code> and <code class="computeroutput">tar</code>, which you can use to perform the
OpenACS installation instead of WinZip and zsh.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="win2kinstall-oracle" id="win2kinstall-oracle"></a>Your Oracle installation</h3></div></div></div><p>When you install Oracle, a good rule of thumb is "every default
setting is wrong." We will not discuss Oracle configuration here
except to mention that the OpenACS requires Oracle's
NLS_DATE_FORMAT parameter be set to 'YYYY-MM-DD'. Fixing this
depends on whether Oracle Administration Assistant for Windows NT
(<span class="emphasis"><em>yes, that's Windows</em></span>
</p><div><span class="emphasis"><em>NT</em></span></div><span class="emphasis"><em>)</em></span> will run on your machine
or not (in some cases, it will complain about Microsoft Managment
Console not being installed).
<p>If it runs on your machine, proceed as follows:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Run Oracle Administration Assistant for Windows NT</p></li><li class="listitem"><p>Navigate using the Explorer-style control in the left panel and
select the Oracle Home for the database you wish to use.</p></li><li class="listitem"><p>Bring up its properties dialog and add a parameter
NLS_DATE_FORMAT with value 'YYYY-MM-DD' (<span class="emphasis"><em>without the quotes</em></span>)</p></li><li class="listitem"><p>Verify the date format by logging into the database using SQL
Plus and run the following query: <code class="computeroutput">select sysdate from dual;</code>
</p></li>
</ol></div><p>Otherwise you will need to perform a little registry surgery as
follows:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Run <code class="computeroutput">regedit</code> and navigate
down the registry keys to <code class="computeroutput">HKEY_LOCAL_MACHINE\Software\ORACLE</code>.</p></li><li class="listitem">
<p>Choose the appropriate subtree; this will be <code class="computeroutput">HOME0</code> if you only have on einstallation of
Oracle.</p><div class="blockquote"><blockquote class="blockquote"><p>If you are an Oracle achiever and have more than one Oracle
installation on your machine, you will see <code class="computeroutput">HOME0, HOME1, HOME2</code>, etc. Choose the
subtree that corresponds to the Oracle installtion you wish to use
with the OpenACS.</p></blockquote></div>
</li><li class="listitem"><p>If the <code class="computeroutput">NLS_DATE_FORMAT</code> key
is already present, double-click on its value and change it to
'YYYY-MM-DD' (<span class="emphasis"><em>without the
quotes</em></span>). If the key does not exist, choose <code class="computeroutput">Edit-&gt;New-&gt;String Value</code> from the menu
and type <code class="computeroutput">NLS_DATE_FORMAT</code> for
the name of the new value to create it. Then double-click on the
empty value to change it.</p></li><li class="listitem"><p>Verify the date format by logging into the database using SQL
Plus and run the following query: <code class="computeroutput">select sysdate from dual;</code>
</p></li>
</ol></div><p>For more information on Oracle configuration look at <a class="ulink" href="http://photo.net/wtr/oracle-tips" target="_top">http://photo.net/wtr/oracle-tips</a> or search the <a class="ulink" href="http://openacs.org/forums/" target="_top">OpenACS
forums</a>. One other note: the "nuke a user" admin page and
Intermedia won't run unless you set <code class="computeroutput">open_cursors = 500</code> for your database.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="win2kinstall-acs-binary" id="win2kinstall-acs-binary"></a>The ArsDigita binary
installation</h3></div></div></div><p>Extract the ArsDigita AOLserver distribution onto the
<code class="computeroutput">C:</code> drive into the default
<code class="computeroutput">aol30</code> directory. You can
install it on any drive, but it will make your life easier if you
keep the AOLserver binary and your OpenACS instance on the same
drive. For the rest of these instructions, we'll assume that you
used drive <code class="computeroutput">C:</code>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="win2kinstall-untar-acs" id="win2kinstall-untar-acs"></a>Untar the OpenACS</h3></div></div></div><p>We recommend rooting webserver content in <code class="computeroutput">c:\web</code>. Since most servers these days are
expected to run multiple services from multiple IP addresses, each
server gets a subdirectory from <code class="computeroutput">c:\web</code>. For example, <code class="computeroutput">http://scorecard.org</code> would be rooted at
<code class="computeroutput">c:\web\scorecard</code> on one of our
machines and if <code class="computeroutput">http://jobdirect.com</code> were on the same box
then it would be at <code class="computeroutput">c:\web\jobdirect</code>.</p><p>For the sake of argument, we're going to assume that your
service is called "yourdomain", is going to be at <code class="computeroutput">http://yourdomain.com</code> and is rooted at
<code class="computeroutput">c:\web\yourdomain</code> in the
Windows 2000 file system. Note that you'll find our definitions
files starting out with "yourdomain.com".</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>download the OpenACS (see <a class="ulink" href="#source" target="_top">above</a>) into <code class="computeroutput">c:\temp\acs.tar.gz</code>
</p></li><li class="listitem"><p>use WinZip (or equivalent) to extract the files to <code class="computeroutput">c:\web\yourdomain</code>
</p></li>
</ul></div><p>You'll now find that <code class="computeroutput">c:\web\yourdomain\www</code> contains the document
root and <code class="computeroutput">c:\web\yourdomain\tcl</code>
contains Tcl scripts that are loaded when the AOLserver starts
up.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="win2kinstall-data-model" id="win2kinstall-data-model"></a>Feeding Oracle the Data Model</h3></div></div></div><p>The entire server will behave in an unhappy manner if it
connects to Oracle and finds that, for example, the users table
does not exist. Thus you need to connect to Oracle as whatever user
the AOLserver will connect as, and feed Oracle the table
definitions.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>load the <code class="computeroutput">states</code>,
<code class="computeroutput">country_codes</code> and <code class="computeroutput">counties</code> tables using the <code class="computeroutput">load-geo-tables</code> shell script in the
<code class="computeroutput">c:\web\yourdomain\www\install</code>
directory. You will need to open a console window and run</p><pre class="programlisting">
zsh load-geo-tables foo/foopassword
</pre><p>You most likely will see a slew of "Commit point reached . . . "
messages. This does not indicate a problem.</p>
</li><li class="listitem">
<p>cd to <code class="computeroutput">c:\web\yourdomain\www\doc\sql</code> and feed
Oracle the .sql files that you find there. There is a meta-loader
file, load-data-model.sql, that includes the other files in the
proper order. To use it, open a console window and run</p><pre class="programlisting">
sqlplus foo/foopassword &lt; load-data-model.sql
</pre>
</li><li class="listitem">
<p>If you have interMedia installed, while still in <code class="computeroutput">c:\web\yourdomain\www\doc\sql</code>, run</p><pre class="programlisting">
zsh load-site-wide-search foo foopassword ctxsys-password
</pre><p>Note that there's no slash between <code class="computeroutput">foo</code> and <code class="computeroutput">foopassword</code> here. The third argument,
<code class="computeroutput">ctxsys-password</code>, is the
password for interMedia Text's special ctxsys user.</p>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="win2kinstall-aolserver" id="win2kinstall-aolserver"></a>Configuring AOLserver</h3></div></div></div><p>You will need two configuration files. The first is a Tcl file
with configuration information for AOLserver. This should be called
<code class="computeroutput">yourdomain</code> and should be
located in <code class="computeroutput">c:\aolserve3_0</code>. The
second is an .ini file that configures the OpenACS and is discussed
<a class="ulink" href="#ini" target="_top">below</a>. Note that
pathnames in <code class="computeroutput">yourdomain</code> must
use forward slashes rather than the Windows back slashes. This is
also true for the .ini file.</p><p>The following items must be defined in <code class="computeroutput">yourdomain</code>:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>three database pools: main, subquery, and log. They must be
named as such. The default pool will be "main".</p></li><li class="listitem"><p>the auxconfig directory which contains the .ini file:
<code class="computeroutput">c:\web\yourdomain\parameters</code>
</p></li><li class="listitem"><p>the pageroot: <code class="computeroutput">c:\web\yourdomain\www</code>
</p></li><li class="listitem"><p>the directory containing the TclLibrary: <code class="computeroutput">c:\web\yourdomain\tcl</code>
</p></li>
</ul></div><p>You can use <a class="ulink" href="/doc/files/winnsd.txt" target="_top">our template file</a> as a starting point
(<span class="emphasis"><em>you'll need to save this file with a
rather than .txt extension</em></span>).</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="wint2install-configure-acs" id="wint2install-configure-acs"></a>Configuring OpenACS itself</h3></div></div></div><p>If you want a system that works, go to <code class="computeroutput">c:\web\yourdomain\parameters</code> and copy
<code class="computeroutput">ad.ini</code> to <code class="computeroutput">yourdomain.ini</code> (<span class="emphasis"><em>or any other name different from <code class="computeroutput">ad.ini</code>
</em></span>). You don't actually
have to delete <code class="computeroutput">ad.ini</code>.</p><p>Each section of <code class="computeroutput">yourdomain.ini</code> has a hardcoded
"yourservername" in the name (e.g. <code class="computeroutput">[ns/server/yourservername/acs]</code>). This means
that the OpenACS will ignore your configuration settings unless
your AOLserver name happens to be "yourservername". Therefore you
must go through <code class="computeroutput">yourdomain.ini</code>
and change "yourservername" to whatever you're calling this
particular AOLserver (<span class="emphasis"><em>look at the server
name in the <code class="computeroutput">nsd</code> file for a
reference</em></span>).</p><p>Unless you want pages that advertise a community called
"Yourdomain Network" owned by "webmaster\@yourdomain.com", you'll
probably want to edit the text of <code class="computeroutput">yourdomain.ini</code> to change system-wide
parameters. If you want to see how some of these are used, a good
place to look is <code class="computeroutput">c:\web\yourdomain\tcl\ad-defs</code>. The Tcl
function, <code class="computeroutput">ad_parameter</code>, is used
to grab parameter values from the .ini file.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="wi2kinstall-starting-service" id="wi2kinstall-starting-service"></a>Starting the Service</h3></div></div></div><p>Now you're ready to start things up. Before installing as a
Windows service, you might want to test the setup for configuration
errors. Open up a console window and go to <code class="computeroutput">c:\aol30</code>. Then run</p><pre class="programlisting">
bin\nsd -ft yourdomain.tcl
</pre><p>This will print all the AOLserver messages to the console so you
can see them.</p><p>Try to connect to your new server with a web browser. If you see
the message "Error in serving group pages", you probably forgot to
copy the ad.ini file in <code class="computeroutput">c:\web\yourdomain\parameters</code> If everything
seems ok, you can kill the server with Control-c and then issue the
following command to install as a Windows service:</p><pre class="programlisting">
bin\nsd -I -s yourdomain -t yourdomain.tcl
</pre><p>You can now configure error recovery and other Windows aspects
of the service from the Services control panel. If you make further
changes to <code class="computeroutput">yourdomain</code> or
<code class="computeroutput">yourdomain.ini</code> you should stop
and start the service from the Services control panel.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="win2kinstall-configure-permissions" id="win2kinstall-configure-permissions"></a>Configuring
Permissions</h3></div></div></div><p>Now, you need to protect the proper administration directories
of the OpenACS. You decide the policy although we recommend
requiring the admin directories be accessible only via an SSL
connection. Here are the directories to consider protecting:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>/doc (or at least /doc/sql/ since some AOLserver configurations
will allow a user to execute SQL files)</p></li><li class="listitem"><p>/admin</p></li><li class="listitem"><p>any private admin dirs for a module you might have written that
are not underneath the /admin directory</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="win2kinstall-add-yourself" id="win2kinstall-add-yourself"></a>Adding Yourself as a User and
Making Yourself a Sysadmin</h3></div></div></div><p>OpenACS will define two users: system and anonymous. It will
also define a user group of system administrators. You'll want to
add yourself as a user (at /register/ ) and then add yourself as as
member of the site-wide administration group. Start by logging out
as yourself and logging in as the system user (email of "system").
Change the system user's password. Visit the <code class="computeroutput">https://yourservername.com/admin/ug/</code>
directory and add your personal user as a site-wide administrator.
Now you're bootstrapped!</p><p>If you do not know what the system user's password is connect to
Oracle using SQL Plus and run the following query:</p><pre class="programlisting">
select password from users where last_name = 'system';
</pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="win2kinstall-closing-down-access" id="win2kinstall-closing-down-access"></a>Closing Down Access</h3></div></div></div><p>The OpenACS ships with a user named "anonymous" (email
"anonymous") to serve as a content owner. If you're operating a
restricted-access site, make sure to change the anonymous user's
password. In recent versions of the OpenACS you cannot log into
"anonymous" because the account does not have a valid user state.
Log in as a sysadmin and change the anonymous user's password from
<code class="computeroutput">https://yourservername/admin/users</code>. You
should read the documentation for <a class="ulink" href="user-registration" target="_top">user registration and access
control</a> and decide what the appropriate user state is for
anonymous on your site.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="win2kinstall-where-is-what" id="win2kinstall-where-is-what"></a>Where to Find What</h3></div></div></div><p>A few pointers:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>the /register directory contains the login and registration
scripts. You can easily redirect someone to /register/index to have
them login or register.</p></li><li class="listitem"><p>the /pvt directory is for user-specific pages. They can only be
accessed by people who have logged in.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="win2kinstall-make-sure-it-works" id="win2kinstall-make-sure-it-works"></a>Making sure that it
works</h3></div></div></div><p>Run the acceptance tests in <a class="ulink" href="/doc/acceptance-test" target="_top">/doc/acceptance-test</a>
</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="win2kinstall-multiple-acs" id="win2kinstall-multiple-acs"></a>Running Multiple Instances of the
OpenACS</h3></div></div></div><p>You can run multiple instances of the OpenACS on a physical
machine but they must each be set up as a separate Windows service.
Each instance of the OpenACS must have its own:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Oracle tablespace and a user account with the appropriate
permissions on that tablespace. Each of these tablespaces must have
the OpenACS data model loaded.</p></li><li class="listitem"><p>file with the appropriate settings including server name,
auxconfig, ipaddress, and port.</p></li><li class="listitem"><p>Copy of the acs files in an appropriate directory under
<code class="computeroutput">c:\web</code>.</p></li>
</ul></div><p>Suppose you wish to run two services: <code class="computeroutput">lintcollectors.com</code> and <code class="computeroutput">iguanasdirect.com</code>. You would need the
following:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>an Oracle tablespace, <code class="computeroutput">lintcollectors</code> with a user <code class="computeroutput">lintcollectors</code> and password <code class="computeroutput">secretlint</code>
</p></li><li class="listitem"><p>an Oracle tablespace, <code class="computeroutput">iguanasdirect</code> with a user <code class="computeroutput">iguanasdirect</code> and password <code class="computeroutput">secretiguanas</code>
</p></li>
</ul></div><p>For each of these tablespaces/users you would load the OpenACS
data model as described <a class="ulink" href="#data" target="_top">above</a>. Then in <code class="computeroutput">c:\aolserver3_0</code> create files for each
service, i.e. <code class="computeroutput">lintcollectors</code>
and <code class="computeroutput">iguanasdirect</code>. These files
would point to their respective pageroots, <code class="computeroutput">c:\web\lintcollectors\www</code> and <code class="computeroutput">c:\web\iguanasdirect\www</code>; their respective
auxconfigdirs, <code class="computeroutput">c:\web\lintcollectors\parameters</code> and
<code class="computeroutput">c:\web\iguanasdirect\parameters</code>; etc. In
the respective auxconfigdirs would be the files <code class="computeroutput">lintcollectors.ini</code> and <code class="computeroutput">iguanasdirect.ini</code>.</p><p>Now open a console window and go to <code class="computeroutput">c:\aol30</code>. You'll start up the two services
as follows:</p><pre class="programlisting">
bin\nsd -I -s lintcollectors -t lintcollectors.tcl
bin\nsd -I -s iguanasdirect -t iguanasdirect.tcl
</pre><p>In the services control panel you should see two services:
<code class="computeroutput">AOLserver-lintcollectors</code> and
<code class="computeroutput">AOLserver-iguanasdirect</code>.</p><div class="cvstag">($Id: win2k-installation.html,v 1.49.2.1
2015/09/23 11:55:07 gustafn Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="openacs" leftLabel="Prev" leftTitle="Install OpenACS 5.7.0"
		    rightLink="mac-installation" rightLabel="Next" rightTitle="OpenACS Installation Guide for Mac OS
X"
		    homeLink="index" homeLabel="Home" 
		    upLink="complete-install" upLabel="Up"> 
		