
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Bootstrapping OpenACS}</property>
<property name="doc(title)">Bootstrapping OpenACS</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="tcl-doc" leftLabel="Prev"
		    title="
Chapter 15. Kernel Documentation"
		    rightLink="ext-auth-requirements" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="bootstrap-acs" id="bootstrap-acs"></a>Bootstrapping OpenACS</h2></div></div></div><div class="authorblurb">
<p>By <a class="ulink" href="mailto:jsalz\@mit.edu" target="_top">Jon Salz</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem"><p>Tcl code: /tcl/0-acs-init.tcl and
/packages/acs-kernel/bootstrap.tcl</p></li></ul></div><p>This document describes the startup (bootstrapping) process for
an AOLserver running OpenACS.</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="bootstrap-acs-bigpicture" id="bootstrap-acs-bigpicture"></a>The Big Picture</h3></div></div></div><p>Before OpenACS 3.3, the OpenACS startup process was extremely
simple: after AOLserver performed its internal initialization
(reading the configuration file, loading shared libraries and
module code, etc.) it scanned through the Tcl library directory
(generally <code class="computeroutput">/var/lib/aolserver/</code><span class="emphasis"><em><code class="computeroutput">yourservername</code></em></span><code class="computeroutput">/tcl</code>), sourcing each file in sequence.</p><p>While this overall structure for initialization is still intact,
package management has thrown a wrench into the works - there are a
few extra things to do during initialization, most notably:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Examine the OpenACS file tree for files that should not be
present in OpenACS (i.e., that were once part of the OpenACS
distribution but have since been removed).</p></li><li class="listitem"><p>Scan the <code class="computeroutput">/packages</code> directory
for new packages.</p></li><li class="listitem"><p>Initialize enabled packages by sourcing their <code class="computeroutput">*-procs.tcl</code> and <code class="computeroutput">*-init.tcl</code> files.</p></li>
</ul></div><p>This document examines in detail each of the steps involved in
AOLserver/OpenACS startup.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="bootstrap-acs-startup-process" id="bootstrap-acs-startup-process"></a>The Startup Process</h3></div></div></div><p>As soon as the <code class="computeroutput">nsd</code> daemon is
executed by the <code class="computeroutput">init</code> process
(or otherwise), AOLserver reads its configuration file and
<code class="computeroutput">chroot</code>s itself if necessary. It
then loads shared libraries indicated in the <code class="computeroutput">.ini</code> file (e.g., the Oracle driver and
<code class="computeroutput">nssock</code>), and sources Tcl module
files (generally in <code class="computeroutput">/home/aol30/modules/tcl</code>). This step is, and
has always been, the same for all AOLservers, regardless of whether
they are running OpenACS.</p><p>Next AOLserver sources, in lexicographical order, each file in
the <code class="computeroutput">/tcl</code> directory. The first
such file is <code class="computeroutput">0-acs-init.tcl</code>,
which doesn&#39;t do much directly except to determine the OpenACS
path root (e.g., <code class="computeroutput">/var/lib/aolserver/</code><span class="emphasis"><em><code class="computeroutput">yourservername</code></em></span>) by trimming the
final component from the path to the Tcl library directory
(<code class="computeroutput">/var/lib/aolserver/</code><span class="emphasis"><em><code class="computeroutput">yourservername</code></em></span><code class="computeroutput">/tcl</code>).
But <code class="computeroutput">0-acs-init.tcl</code>'s has an
important function, namely sourcing <code class="computeroutput">/packages/acs-core/bootstrap.tcl</code>, which
does the following:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>
<span class="strong"><strong>Initialize some NSVs used by the
core</strong></span>. These NSVs are documented in <code class="computeroutput">/packages/acs-core/apm-procs.tcl</code> - no need
to worry about them unless you&#39;re an OpenACS core hacker.</p></li><li class="listitem"><p>
<span class="strong"><strong>Verify the deletion of obsolete
OpenACS files</strong></span>. The <code class="computeroutput">/tcl</code> directory has evolved quite a bit over
the months and years, and a few files have come and gone. The
<code class="computeroutput">/www/doc/removed-files.txt</code> file
contains a list of files which <span class="emphasis"><em>must be
deleted</em></span> from the AOLserver installation, at the risk of
causing weird conflicts, e.g., having several security filters
registered. <code class="computeroutput">bootstrap.tcl</code> scans
through this list, logging error messages to the log if any of
these files exist.</p></li><li class="listitem"><p>
<span class="strong"><strong>Source <code class="computeroutput">*-procs.tcl</code> files in the OpenACS
core</strong></span>. We source each file matching the <code class="computeroutput">*-procs.tcl</code> glob in the <code class="computeroutput">/packages/acs-kernel</code> directory, in
lexicographical order. These procedure are needed to perform any of
the following steps.</p></li><li class="listitem"><p>
<span class="strong"><strong>Ensure that the database is
available</strong></span> by grabbing and releasing a handle. If we
can&#39;t obtain a handle, we terminate initialization (since
OpenACS couldn&#39;t possibly start up the server without access to
the database).</p></li><li class="listitem"><p>
<span class="strong"><strong>Register any new packages in the
<code class="computeroutput">/packages</code>
directory</strong></span>. In each directory inside <code class="computeroutput">/packages</code>, we look for a <code class="computeroutput">.info</code> file; if we find a package that
hasn&#39;t yet been registered with the package manager (i.e.,
it&#39;s been copied there manually), we insert information about
it into the database. (The first time OpenACS starts up,
<span class="emphasis"><em>no</em></span> packages will have been
registered in the database yet, so this step will registers every
single package in the <code class="computeroutput">/packages</code>
directory.) Note that packages discovered here are initially
disabled; they must be manually enabled in the package manager
before they can be used.</p></li><li class="listitem"><p>
<span class="strong"><strong>Ensure that the <code class="computeroutput">acs-kernel</code> package is
enabled</strong></span>. If the OpenACS core isn&#39;t initialized,
the server couldn&#39;t possibly be operational, so if there&#39;s
no enabled version of the OpenACS core we simply mark the latest
installed one as enabled.</p></li><li class="listitem"><p>
<span class="strong"><strong>Load <code class="computeroutput">*-procs.tcl</code> files for enabled
packages</strong></span>, activating their APIs.</p></li><li class="listitem"><p>
<span class="strong"><strong>Load <code class="computeroutput">*-init.tcl</code> files for enabled
packages</strong></span>, giving packages a chance to register
filters and procedures, initialize data structures, etc.</p></li><li class="listitem"><p>
<span class="strong"><strong>Verify that the core has been
properly initialized</strong></span> by checking for the existence
of an NSV created by the request processor initialization code. If
it&#39;s not present, the server won&#39;t be operational, so we
log an error.</p></li>
</ol></div><p>At this point, <code class="computeroutput">bootstrap.tcl</code>
is done executing. AOLserver proceeds to source the remaining files
in the <code class="computeroutput">/tcl</code> directory (i.e.,
unpackaged libraries) and begins listening for connections.</p><div class="cvstag">($&zwnj;Id: bootstrap-acs.xml,v 1.7 2006/07/17
05:38:38 torbenb Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="tcl-doc" leftLabel="Prev" leftTitle="Documenting Tcl Files: Page Contracts
and Libraries"
		    rightLink="ext-auth-requirements" rightLabel="Next" rightTitle="External Authentication
Requirements"
		    homeLink="index" homeLabel="Home" 
		    upLink="kernel-doc" upLabel="Up"> 
		