
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Prerequisite Software}</property>
<property name="doc(title)">Prerequisite Software</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="install-steps" leftLabel="Prev"
			title="Chapter 2. Installation
Overview"
			rightLink="complete-install" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="individual-programs" id="individual-programs"></a>Prerequisite Software</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">by <a class="ulink" href="mailto:joel\@aufrecht.org" target="_top">Joel
Aufrecht</a>
</span></p><span style="color: red">&lt;/authorblurb&gt;</span><p>OpenACS requires, at a minimum, an operating system, database,
and webserver to work. Many additional programs, such as a build
environment, Mail Transport Agent, and source control system, are
also needed for a fully effective installation.</p><div class="table">
<a name="compatibility-matrix" id="compatibility-matrix"></a><p class="title"><strong>Table 2.2. Version Compatibility
Matrix</strong></p><div class="table-contents"><table class="table" summary="Version Compatibility Matrix" cellspacing="0" border="1">
<colgroup>
<col class="c1"><col class="c2"><col class="3.2.5"><col class="4.5"><col class="4.6"><col class="4.6.1"><col class="4.6.2"><col class="4.6.3"><col class="5.0"><col class="5.1">
</colgroup><thead><tr>
<th colspan="2" align="center">OpenACS Version</th><th>3.2.5</th><th>4.5</th><th>4.6</th><th>4.6.1</th><th>4.6.2</th><th>4.6.3</th><th>5.0</th><th>5.1</th><th>5.2</th><th>5.3</th><th>5.4</th><th>5.5</th>
</tr></thead><tbody>
<tr>
<td rowspan="8">AOLserver</td><td>3</td><td bgcolor="lightgreen" align="center">Yes</td><td bgcolor="red" colspan="11" align="center">No</td>
</tr><tr>
<td>3.3+ad13</td><td bgcolor="yellow" align="center">Maybe</td><td bgcolor="lightgreen" colspan="7" align="center">Yes</td><td bgcolor="red" colspan="4" align="center">No</td>
</tr><tr>
<td>3.3oacs1</td><td bgcolor="yellow" align="center">Maybe</td><td bgcolor="lightgreen" colspan="7" align="center">Yes</td><td bgcolor="red" colspan="4" align="center">No</td>
</tr><tr>
<td>3.4.4</td><td bgcolor="red" colspan="12" align="center">No</td>
</tr><tr>
<td>3.4.4oacs1</td><td bgcolor="yellow" colspan="4" align="center">Maybe</td><td bgcolor="lightgreen" colspan="2" align="center">Yes</td><td bgcolor="red" colspan="6" align="center">No</td>
</tr><tr>
<td>3.5.5</td><td bgcolor="yellow" colspan="4" align="center">Maybe</td><td bgcolor="lightgreen" colspan="2" align="center">Yes</td><td bgcolor="red" colspan="6" align="center">No</td>
</tr><tr>
<td>4.0</td><td bgcolor="yellow" colspan="4" align="center">Maybe</td><td bgcolor="lightgreen" colspan="8" align="center">Yes</td>
</tr><tr>
<td>4.5</td><td bgcolor="red" colspan="8" align="center">No</td><td bgcolor="lightgreen" colspan="4" align="center">Yes</td>
</tr><tr>
<td rowspan="2">Tcl</td><td>8.4</td><td bgcolor="lightgreen" colspan="12" align="center">Yes</td>
</tr><tr>
<td>8.5.4 -</td><td bgcolor="yellow" colspan="12" align="center">Maybe</td>
</tr><tr>
<td rowspan="8">PostgreSQL</td><td>7.0</td><td bgcolor="lightgreen" align="center">Yes</td><td bgcolor="red" colspan="11" align="center">No</td>
</tr><tr>
<td>7.2</td><td bgcolor="yellow" align="center">Maybe</td><td bgcolor="lightgreen" colspan="5" align="center">Yes</td><td bgcolor="red" colspan="6" align="center">No</td>
</tr><tr>
<td>7.3.2 - 7.3.x</td><td bgcolor="red" colspan="5" align="center">No</td><td bgcolor="lightgreen" colspan="4" align="center">Yes</td><td bgcolor="red" colspan="3" align="center">No</td>
</tr><tr>
<td>7.4</td><td bgcolor="red" colspan="6" align="center">No</td><td bgcolor="lightgreen" colspan="3" align="center">Yes</td><td bgcolor="red" colspan="3" align="center">No</td>
</tr><tr>
<td>8.0</td><td bgcolor="red" colspan="7" align="center">No</td><td bgcolor="yellow" align="center">Maybe</td><td bgcolor="lightgreen" colspan="4" align="center">Yes</td>
</tr><tr>
<td>8.1</td><td bgcolor="red" colspan="8" align="center">No</td><td bgcolor="lightgreen" colspan="4" align="center">Yes</td>
</tr><tr>
<td>8.2</td><td bgcolor="red" colspan="8" align="center">No</td><td bgcolor="yellow" align="center">CVS version only</td><td bgcolor="lightgreen" colspan="3" align="center">Yes</td>
</tr><tr>
<td>8.3</td><td bgcolor="red" colspan="11" align="center">No</td><td bgcolor="lightgreen" align="center">Yes</td>
</tr><tr>
<td rowspan="5">Oracle</td><td>8.1.6</td><td bgcolor="yellow" align="center">Maybe</td><td bgcolor="lightgreen" colspan="8" align="center">Yes</td><td bgcolor="yellow" colspan="3" align="center">Maybe</td>
</tr><tr>
<td>8.1.7</td><td bgcolor="yellow" align="center">Maybe</td><td bgcolor="lightgreen" colspan="8" align="center">Yes</td><td bgcolor="yellow" colspan="3" align="center">Maybe</td>
</tr><tr>
<td>9i</td><td bgcolor="red" colspan="6" align="center">No</td><td bgcolor="lightgreen" colspan="6" align="center">Yes</td>
</tr><tr>
<td>10g</td><td bgcolor="red" colspan="8" align="center">No</td><td bgcolor="lightgreen" colspan="4" align="center">Yes</td>
</tr><tr>
<td>11g</td><td bgcolor="red" colspan="11" align="center">No</td><td bgcolor="yellow" align="center">Maybe</td>
</tr>
</tbody>
</table></div>
</div><br class="table-break"><p>The OpenACS installation instructions assume the operating
system and build environment are installed. The instructions
explain installation of Tcl, Tcllib, tDOM, tclwebtest, a Web
Server, a Database, a Process Controller, and Source Control
software. The following external links are for reference only.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<a name="openacs-download" id="openacs-download"></a><p>
<strong>
<a class="ulink" href="http://openacs.org/projects/openacs/download/" target="_top">OpenACS 5.9.0</a>. </strong> The OpenACS tarball
comprises the core packages and many useful additional packages.
This includes a full set of documentation. The tarball works with
both PostgreSQL and Oracle. Some scripts require bash shell.</p>
</li><li class="listitem">
<p>
<strong>Operating System. </strong> OpenACS is designed for
a Unix-like system. It is developed primarily in Linux. It can be
run on Mac OS X, and in Windows within VMWare.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>
<strong>GNU/Linux. </strong> The installation assumes a
linux kernel of 2.2.22 or newer, or 2.4.14 or newer.</p></li><li class="listitem"><p>
<strong>FreeBSD. </strong><a class="ulink" href="https://web.archive.org/web/20011204174701/http://www.orchardlabs.com:80/freebsd/" target="_top">FreeBSD guide</a>. The OpenACS Reference Platform
uses shell scripts written for bash, which is the standard Linux
shell. If you are using a different shell, you will need to
substitute your shell&#39;s conventions for setting environment
variables when appropriate, and install bash to work with the
scripts. Substitute <strong class="userinput"><code>fetch</code></strong> when the instructions
suggest you use <strong class="userinput"><code>wget</code></strong> to download software.</p></li><li class="listitem"><p>
<strong>Mac OS X. </strong><a class="xref" href="mac-installation" title="OpenACS Installation Guide for Mac OS X">the section called
“OpenACS Installation Guide for Mac OS X”</a>
</p></li><li class="listitem"><p>
<strong>Windows/VMWare. </strong><a class="xref" href="win2k-installation" title="OpenACS Installation Guide for Windows">the section called
“OpenACS Installation Guide for Windows”</a> The only way to run
OpenACS on Windows is through the VMWare emulator. (Please let me
know if you have OpenACS running directly in Windows.)</p></li>
</ul></div>
</li><li class="listitem">
<p>
<strong>Build Environment. </strong> The Reference Platform
installation compiles most programs from source code.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>
<strong>
<a class="ulink" href="http://www.gnu.org/software/libc/libc.html" target="_top">glibc</a> 2.2 or newer, REQUIRED. </strong> You need
recent versions of these libraries for Oracle to work properly. For
Unicode support, you need glibc 2.2 or newer. This should be
included in your operating system distribution.</p></li><li class="listitem"><p>
<strong>
<a class="ulink" href="http://www.gnu.org/software/make/" target="_top">GNU Make</a>
3.76.1 or newer, REQUIRED. </strong> PostgreSQL and AOLserver
require gmake to compile. Note that on most linux distributions,
GNU Make is simply named <code class="computeroutput">make</code>
and there is no <code class="computeroutput">gmake</code>, whereas
on BSD distributions, <code class="computeroutput">make</code> and
<code class="computeroutput">gmake</code> are different --use
gmake.</p></li>
</ul></div>
</li><li class="listitem">
<p><strong>
<a class="ulink" href="http://www.tcl.tk/" target="_top">Tcl</a> 8.5.x. </strong></p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>
<strong>
<a class="ulink" href="http://www.tcl.tk/" target="_top">Tcl</a> 8.5.x, REQUIRED. </strong> OpenACS is written
in Tcl, an interpreted language. A threaded version of the Tcl
interpreter must be installed for OpenACS to work. The Tcl
interpreter that is included in most standard distributions may not
be thread safe.</p></li><li class="listitem"><p>
<strong>
<a class="ulink" href="http://www.tcl.tk/" target="_top">Tcl</a> 8.5.x development headers and libraries,
OPTIONAL. </strong> The site-wide-search service, OpenFTS,
requires these to compile. (Debian users: <code class="computeroutput">apt-get install tcl8.5-dev</code>). You need this
to install OpenFTS.</p></li>
</ul></div>
</li><li class="listitem">
<a name="source-tcllib" id="source-tcllib"></a><p>
<strong>
<a class="ulink" href="http://tcllib.sourceforge.net/" target="_top">Tcllib</a>, REQUIRED. </strong> OpenACS 5.9.0
uses those Tcl extensions to send e-mail out, among others.</p>
</li><li class="listitem">
<a name="source-tdom" id="source-tdom"></a><p>
<strong>
<a class="ulink" href="http://www.tdom.org/" target="_top">tDOM</a>, REQUIRED. </strong> OpenACS 5.9.0 stores
queries in XML files, so we use an AOLserver module called tDOM to
parse these files. (This replaces libxml2, which was used prior to
4.6.4.)</p>
</li><li class="listitem">
<a name="source-tclwebtest" id="source-tclwebtest"></a><p>
<strong>
<a class="ulink" href="http://sourceforge.net/project/showfiles.php?group_id=31075" target="_top">tclwebtest</a>, OPTIONAL. </strong> tclwebtest
is a tool for testing web interfaces via Tcl scripts.</p>
</li><li class="listitem">
<p>
<strong>Web Server. </strong> The web server handles
incoming HTTP requests, provides a runtime environment for
OpenACS&#39;s Tcl code, connects to the database, sends out HTTP
responses, and logs requests and errors. OpenACS uses AOLserver;
<a class="ulink" href="http://openacs.org/forums/message-view?message_id=21461" target="_top">some people have had success running Apache with
mod_nsd</a>.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem">
<a name="source-aolserver" id="source-aolserver"></a><p>
<strong>
<a class="ulink" href="http://aolserver.com/" target="_top">AOLserver</a> 4.x, REQUIRED. </strong> Provides the
base HTTP server</p>
</li></ul></div><p>Mat Kovach is graciously maintaining an AOLserver distribution
that includes all the patches and modules needed to run OpenACS
5.9.0. These instructions will describe how to install using his
source distribution. He also has binaries for SuSE 7.3 and OpenBSD
2.8 (and perhaps more to come), currently located at <a class="ulink" href="http://uptime.openacs.org/aolserver-openacs/" target="_top">uptime.openacs.org</a>.</p><p>It&#39;s also possible to download all the pieces and patches
yourself:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>AOLserver is available at <a class="ulink" href="http://aolserver.com" target="_top">aolserver.com</a>
</p></li><li class="listitem"><p>The OpenACS PostgreSQL driver (nspostgres.so) is available from
<a class="ulink" href="http://prdownloads.sourceforge.net/aolserver/nspostgres-3.5.tar.gz?download" target="_top">SourceForge</a>. If you do decide to use
nspostgres.so, you have to remember to change the AOLserver config
file to point to nspostgres.so instead of postgres.so. This guide
uses Mat Kovach&#39;s distro (i.e. postgres.so)</p></li><li class="listitem"><p>The patch that makes <code class="computeroutput">exec</code>
work on BSD is available at <a class="ulink" href="http://sourceforge.net/tracker/index.php?func=detail&amp;aid=415475&amp;group_id=3152&amp;atid=303152" target="_top">sourceforge.net</a>
</p></li><li class="listitem"><p>The patch for AOLserver 3.x that makes <code class="computeroutput">ns_uuencode</code> work for binary files is
available at <a class="ulink" href="http://sourceforge.net/tracker/index.php?func=detail&amp;aid=474259&amp;group_id=3152&amp;atid=303152" target="_top">sourceforge.net</a>
</p></li><li class="listitem"><p>The patch that makes AOLserver 3.x respect the <code class="computeroutput">-g</code> flag is available at <a class="ulink" href="http://sourceforge.net/tracker/index.php?func=detail&amp;aid=509413&amp;group_id=3152&amp;atid=303152" target="_top">sourceforge.net</a>
</p></li>
</ul></div>
</li><li class="listitem">
<a name="nsopenssl-download" id="nsopenssl-download"></a><p>
<strong>nsopenssl, OPTIONAL. </strong> Provides SSL
capabilities for AOLserver. It requires OpenSSL. You need this if
you want users to make secure (https) connections to your
webserver. aolserver3.x requires <a class="ulink" href="http://www.scottg.net/download/nsopenssl-2.1a.tar.gz" target="_top">nsopenssl 2.1a</a>. aolserver4.x requires nsopenssl3; see
<a class="ulink" href="http://www.aolserver.com/" target="_top">aolserver.com</a> for latest release. (<a class="ulink" href="http://panoptic.com/wiki/aolserver/Nsopenssl" target="_top">home page</a>)</p>
</li><li class="listitem">
<a name="nspam-download" id="nspam-download"></a><p>
<strong>
<a class="ulink" href="http://wayback.archive.org/web/20050228071203/http://braindamage.alal.com/software/nspam.html" target="_top">ns_pam</a> 0.1 or newer, OPTIONAL. </strong>
Provides PAM capabilities for AOLserver. You need this if you want
OpenACS users to authenticate through a PAM module (such as
RADIUS).</p>
</li><li class="listitem">
<a name="pam-radius-download" id="pam-radius-download"></a><p>
<strong>
<a class="ulink" href="ftp://ftp.freeradius.org/pub/radius/pam_radius-1.3.16.tar" target="_top">pam_radius 1.3.16</a>, OPTIONAL. </strong> Provides
RADIUS capabilities for PAM. You need this if you want to use
RADIUS authentication via PAM in OpenACS.</p>
</li><li class="listitem">
<a name="nsldap-download" id="nsldap-download"></a><p>
<strong>
<a class="ulink" href="http://sourceforge.net/project/showfiles.php?group_id=3152" target="_top">ns_ldap 0.r8</a>, OPTIONAL. </strong> Provides
LDAP capabilities for AOLserver. You need this if you want to use
LDAP authentication in OpenACS.</p>
</li><li class="listitem">
<a name="openfts-download" id="openfts-download"></a><p>
<strong>
<a class="ulink" href="http://unc.dl.sourceforge.net/sourceforge/openfts/Search-OpenFTS-tcl-0.3.2.tar.gz" target="_top">OpenFTS Tcl 0.3.2</a>, OPTIONAL. </strong> Adds
full-text-search to PostgreSQL and includes a driver for AOLserver.
You need this if you want users to be able to search for any text
on your site. For postgres 7.4.x and higher, full text search is
also available via tsearch2.</p>
</li><li class="listitem"><p>
<a name="analog-download" id="analog-download"></a><strong>
<a class="ulink" href="http://www.analog.cx/" target="_top">Analog</a> 5.32 or newer, OPTIONAL. </strong> This
program examines web server request logs, looks up DNS values, and
produces a report. You need this if you want to see how much
traffic your site is getting.</p></li><li class="listitem"><p>
<a name="balance-download" id="balance-download"></a><strong>
<a class="ulink" href="http://sourceforge.net/projects/balance/" target="_top">Balance</a> 3.11 or newer, OPTIONAL. </strong>
"Balance is a simple but powerful generic tcp proxy with round
robin load balancing and failover mechanisms." You need this
or something equivalent if you are running a high-availability
production site and do not have an external load balancing
system.</p></li><li class="listitem">
<p>
<strong>Database. </strong> The data on your site (for
example, user names and passwords, calendar entries, and notes) is
stored in the database. OpenACS separates the database with an
abstraction layer, which means that several different databases all
function identically. While you can run the core OpenACS on any
supported database, not all contributed packages support all
databases.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>
<strong>Oracle 8.1.7 (Either this or PostgreSQL is
REQUIRED). </strong> You can register and download Oracle from
<a class="ulink" href="https://www.oracle.com/downloads/index.html" target="_top">Oracle TechNet</a>. You need this if you want to use
an Oracle database.</p></li><li class="listitem"><p>
<a name="source-postgresql" id="source-postgresql"></a><strong>
<a class="ulink" href="http://sourceforge.net/projects/pgsql/" target="_top">PostgreSQL</a> 7.4.x (Either this or Oracle is
REQUIRED). </strong> You need this if you want to use a
PostgreSQL database.</p></li>
</ul></div>
</li><li class="listitem">
<p>
<strong>Process Controller. </strong> This is software that
initiates other software, and restarts that software if it fails.
On Linux, we recommend using Daemontools to control AOLserver and
qmail.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem">
<a name="daemontools-download" id="daemontools-download"></a><p>
<strong>
<a class="ulink" href="http://cr.yp.to/daemontools/daemontools-0.76.tar.gz" target="_top">Daemontools 0.76</a>, OPTIONAL. </strong> You need this
if you want AOLserver and qmail to run "supervised,"
meaning that they are monitored and automatically restarted if they
fail. An alternative would be to run the services from inittab.</p>
</li></ul></div>
</li><li class="listitem">
<p>
<strong>Mail Transport Agent. </strong> A Mail Transport
Agent is a program that handles all incoming and outgoing mail. The
Reference Platform uses Qmail; any MTA that provides a sendmail
wrapper (that is, that can be invoked by calling the sendmail
program with the same variables that sendmail expects) can be
used.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>
<a name="qmail-download" id="qmail-download"></a><strong>
<a class="ulink" href="http://www.qmail.org/netqmail/" target="_top">Netqmail 1.04</a>, OPTIONAL. </strong> You need
this (or a different Mail Transport Agent) if you want your
webserver to send and receive email.</p></li><li class="listitem"><p>
<a name="ucspi-download" id="ucspi-download"></a><strong>
<a class="ulink" href="http://cr.yp.to/ucspi-tcp/ucspi-tcp-0.88.tar.gz" target="_top">ucspi-tcp 0.88</a>, OPTIONAL. </strong> This program
listens for incoming TCP connections and hands them to a program.
We use it instead of inetd, which is insecure. You need this if you
are running qmail.</p></li>
</ul></div>
</li><li class="listitem"><p>
<strong>
<a class="ulink" href="http://www.docbook.org/" target="_top">DocBook</a>, OPTIONAL. </strong> (docbook-xml v4.4,
docbook-xsl v1.56, libxslt 1.0.21, xsltproc 1.0.21). You need this
to write or edit documentation.</p></li><li class="listitem">
<p>
<strong>Source Control. </strong> A Source Control system
keeps track of all of the old versions of your files. It lets you
recover old files, compare versions of file, and identify specific
versions of files. You can use any source control system; the
Reference Platform and the OpenACS.org repository (where you can
get patched and development code in between releases) use cvs.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem"><p>
<strong>
<a class="ulink" href="https://www.cvshome.org/" target="_top">cvs</a> 1.11.18, OPTIONAL. </strong> cvs is included in
most unix distributions. You need this if you want to track old
versions of your files, do controlled deployment of code from
development to production, or get or contribute development code
from openacs.org.</p></li></ul></div>
</li>
</ul></div><p><span class="cvstag">($&zwnj;Id: software.xml,v 1.28 2018/03/24
00:14:57 hectorr Exp $)</span></p>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="install-steps" leftLabel="Prev" leftTitle="Basic Steps"
			rightLink="complete-install" rightLabel="Next" rightTitle="Chapter 3. Complete
Installation"
			homeLink="index" homeLabel="Home" 
			upLink="install-overview" upLabel="Up"> 
		    