
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {OpenACS Packages}</property>
<property name="doc(title)">OpenACS Packages</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="dev-guide" leftLabel="Prev"
		    title="
Chapter 11. Development Reference"
		    rightLink="objects" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="packages" id="packages"></a>OpenACS Packages</h2></div></div></div><div class="authorblurb">
<p>By Pete Su and Bryan Quinn</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="packages-overview" id="packages-overview"></a>Overview</h3></div></div></div><p>This document is a guide on how to write a software package for
OpenACS. OpenACS packages are installed and maintained with the
OpenACS Package Manager (APM) which is part of the acs-admin
package. This document presents reasons for packaging software,
conventions for the file system and naming that must be followed,
and step by step instructions for creating a new package for the
"Notes" example package.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="server-file-layout" id="server-file-layout"></a>Server file layout</h3></div></div></div><p>Here is how an OpenACS 5 server is laid out starting from the
Server root (ROOT):</p><div class="figure">
<a name="idp140592107056328" id="idp140592107056328"></a><p class="title"><strong>Figure 11.1. Server file layout
diagram</strong></p><div class="figure-contents"><pre class="programlisting">
ROOT/
    bin/
        Various executables and scripts for server maintanence.
    content-repository-content-files/
        content repository content stored in the filesystem.
    etc/
        Installation scripts and configuration files.
    packages/
        acs-admin/
        acs-api-browser/
        ... many many more...
        workflow/
    log/
        Server error and access logs
    tcl/
        bootstrap code
    www/
        Pages not in packages (static content, customized pages)
</pre></div>
</div><br class="figure-break">
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="packages-looks" id="packages-looks"></a>What a Package Looks Like</h3></div></div></div><p>Each package encapsulates all of its data model, library code,
logic, administration pages and user pages in a single part of the
file tree. This means developers can track down <span class="emphasis"><em>everything</em></span> that is related to a
particular package without hunting all over the file system.
Encapsulating everything about a package in one place also makes it
much easier to distribute packages independently from the OpenACS
Core.</p><p>In order to make this work, we need a system that keeps track of
the packages that have been installed in the server, where those
packages have been installed, and a standard way to map URLs that a
client sends to our server to the right page in the appropriate
package. While we&#39;re at it, this tool should also automate
package installation, dependency checking, upgrades, and package
removal. In OpenACS 5, this tool is called the <a class="link" href="packages" title="The APM">APM</a>.</p><p>
<a class="indexterm" name="baby" id="baby"></a> To illustrate
the general structure of a package, let&#39;s see what the package
for the "notes" application should look like.</p><div class="figure">
<a name="idp140592107063624" id="idp140592107063624"></a><p class="title"><strong>Figure 11.2. Package file layout
diagram</strong></p><div class="figure-contents"><pre class="programlisting">
ROOT/
  +-- packages/    APM Root
        |
        +-- notes/  Package Root 
        |     |
        |     +-- notes.info                              Package Specification File
        |     +-- sql/
        |     |     |
        |     |     +-- oracle/
        |     |     |        |
        |     |     |        +-- notes-create.sql         Data Model Creation Script for Oracle
        |     |     |        +-- notes-drop.sql           Data Model Drop Script
        |     |     |        +-- *.sql                    Data Model Files
        |     |     |        +-- upgrade/
        |     |     |            +-- upgrade-4.1-4.5.sql  Data Model Upgrade Scripts
        |     |     +-- postgresql/
        |     |     |        |
        |     |     |        +-- notes-create.sql         Data Model Creation Script for PostgreSQL      
        |     |     |        +-- notes-drop.sql           Data Model Drop Script
        |     |     |        +-- *.sql                    Data Model Files
        |     |     |        +-- upgrade/
        |     |     |            +-- upgrade-4.1-4.5.sql  Data Model Upgrade Scripts
        |     +-- tcl/
        |     |     |
        |     |     +-- notes-procs.tcl                   Tcl Library
        |     |     +-- notes-procs.xql                   SQL92 Queries for notes-procs.tcl
        |     |     +-- notes-procs-oracle.xql            Oracle-specific queries for notes-procs.tcl
        |     |     +-- notes-procs-postgresql.xql        PostgreSQL-specific Queries for notes-procs.tcl
        |     |     +-- notes-init.tcl                    Tcl Initialization
        |     |     +-- notes-init.xql                    Queries for notes-init.tcl (work in all DBs)      
        |     |     +-- *.tcl                             Tcl Library Files
        |     +-- lib/
        |     |     |
        |     |     +-- *.tcl                             Includable page logic
        |     |     +-- *.adp                             Includable page templates
        |     +-- www/
        |     |     |
        |     |     +-- admin/                            Administration UI
        |     |     |     +-- tests/                      Regression Tests
        |     |     |     |     +-- index.tcl             Regression Test Index Page
        |     |     |     |     +-- ...                   Regression Tests
        |     |     |     +-- index.tcl                   Administration UI Index Page
        |     |     |     +-- ...                         Administration UI Pages
        |     |     |
        |     |     +-- doc/                              Documentation
        |     |     |     +-- index.html                  Documentation Index Page
        |     |     |     +-- ...                         Administration Pages
        |     |     +-- resources/                        Static Content
        |     |     |     +-- ...                         Static Content files
        |     |     +-- index.tcl                         UI Index Page
        |     |     +-- index.adp                         UI Index Template
        |     |     +-- index.xql                         Queries for UI Index page      
        |     |     +-- *.tcl                             UI Logic Scripts
        |     |     +-- *.adp                             UI Templates
        |     |     +-- *-oracle.xql                      Oracle-specific Queries
        |     |     +-- *-postgresql.xql                  PostgreSQL-specific Queries
        +-- Other package directories.
</pre></div>
</div><br class="figure-break"><p>All file locations are relative to the package root, which in
this case is <code class="computeroutput">ROOT/packages/notes</code>. The following table
describes in detail what each of the files up in the diagram
contain.</p><p>A special note on the <code class="computeroutput">
<span class="replaceable"><span class="replaceable">PACKAGE-KEY</span></span>/www/resources</code>
directory. Files in this directory are available at <code class="computeroutput">http://<span class="replaceable"><span class="replaceable">yourserver</span></span>/resources/<span class="replaceable"><span class="replaceable">PACKAGE-KEY</span></span>/...</code> and are returned
without any permissions checking or even checks that the package is
installed or mounted. Files are returned directly, so .tcl or .adp
files are not sourced in these directories. This makes it suitable
for storing icons, css files, javascript, and other static content
which can be treated this way.</p><div class="table">
<a name="idp140592107069416" id="idp140592107069416"></a><p class="title"><strong>Table 11.1. Package
files</strong></p><div class="table-contents"><table class="table" summary="Package files" cellspacing="0" border="1">
<colgroup>
<col><col><col>
</colgroup><thead><tr>
<th>File Type</th><th>Its Use</th><th>Naming Convention</th>
</tr></thead><tbody>
<tr>
<td>Package Specification File</td><td>The package specification file is an XML file generated and
maintained by the OpenACS Package Manager (APM). It specifies
information about the package including its parameters and its
files.</td><td><code class="computeroutput">notes.info</code></td>
</tr><tr>
<td>Data Model Creation Script</td><td>Contains the SQL that creates the necessary data model and
PL/SQL packages (or PL/pgSQL or whatever) to support the package.
The name must match the convention below or the package will not be
installed correctly. Notice that the script must be under the
appropriate directory for the database you are developing your
package for (hopefully all OpenACS-supported databases :-))</td><td><code class="computeroutput">sql/&lt;database&gt;/notes-create.sql</code></td>
</tr><tr>
<td>Data Model Drop Script</td><td>Contains the SQL that removes the data model and PL/SQL
packages generated by the creation script. The name must match the
convention below or the package will not be installed
correctly.</td><td><code class="computeroutput">sql/&lt;database&gt;/notes-drop.sql</code></td>
</tr><tr>
<td>Data Model File</td><td>Any .sql file that does not match the naming convention above
is recognized as a data model file. It is useful to separate the
SQL in the creation and drop scripts into several files and then
have the scripts source the other data model files. In Oracle this
can be done by including <span class="emphasis"><em>\@\@
filename</em></span> in the creation or drop scripts. See the
<a class="ulink" href="http://www.orafaq.com/wiki/Scripts" target="_top">Oracle FAQ</a> for examples. In PostgreSQL the same is
accomplished by including <span class="emphasis"><em>\i
filename</em></span>.</td><td><code class="computeroutput">sql/&lt;database&gt;/*.sql</code></td>
</tr><tr>
<td>Data Model Upgrade Scripts</td><td>Contain changes to the data model between versions. The APM can
automatically load the appropriate upgrade scripts when upgrading
to a new version of a package.</td><td><code class="computeroutput">sql/&lt;database&gt;/upgrade/upgrade-&lt;old&gt;-&lt;new&gt;.sql</code></td>
</tr><tr>
<td>SQL92 Query Files</td><td>Files with queries that are supported by all databases. These
are usually SQL92 queries. Notice that the .xql filename must match
the name of the .tcl file that uses those queries.</td><td><code class="computeroutput">*.xql</code></td>
</tr><tr>
<td>Oracle-specific Query Files</td><td>Files with queries that are Oracle-specific. Notice that the
.xql filename must match the name of the .tcl file that uses those
queries.</td><td><code class="computeroutput">*-oracle.xql</code></td>
</tr><tr>
<td>PostgreSQL-specific Query Files</td><td>Files with queries that are PostgreSQL-specific. Notice that
the .xql filename must match the name of the .tcl file that uses
those queries.</td><td><code class="computeroutput">*-postgresql.xql</code></td>
</tr><tr>
<td>Tcl Library Files</td><td>The Tcl library files include a set of procedures that provide
an application programming interface (API) for the package to
utilize.</td><td><code class="computeroutput">tcl/notes-procs.tcl</code></td>
</tr><tr>
<td>Tcl Initialization</td><td>The initialization files are used to run Tcl procedures that
should only be sourced once on startup. Examples of statements to
put here are registered filters or procedures. Tcl initialization
files are sourced once on server startup after all of the Tcl
library files are sourced.</td><td><code class="computeroutput">tcl/notes-init.tcl</code></td>
</tr><tr>
<td>Administration UI</td><td>The administration UI is used to administer the instances of
the package. For example, the forums administration UI is used to
create new forums, moderate postings, and create new categories for
forums postings.</td><td><code class="computeroutput">www/admin/*</code></td>
</tr><tr>
<td>Administration UI Index Page</td><td>Every package administration UI must have an index page. In
most cases, this is <code class="computeroutput">index.tcl</code>
but it can be any file with the name <code class="computeroutput">index</code>, such as index.html or
index.adp.</td><td><code class="computeroutput">www/admin/index.tcl</code></td>
</tr><tr>
<td>Regression Tests</td><td>Every package should have a set of regression tests that verify
that it is in working operation. These tests should be able to be
run at any time after the package has been installed and report
helpful error messages when there is a fault in the system.</td><td><code class="computeroutput">www/admin/tests/</code></td>
</tr><tr>
<td>Regression Test Index Page</td><td>The regression test directory must have an index page that
displays all of the tests available and provides information on how
to run them. This file can have any extension, as long as its name
is <code class="computeroutput">index</code>.</td><td><code class="computeroutput">www/admin/tests/index.html</code></td>
</tr><tr>
<td>Documentation</td><td>Every package must include a full set of documentation that
includes requirements and design documents, and user-level and
developer-level documentation where appropriate.</td><td><code class="computeroutput">www/doc/</code></td>
</tr><tr>
<td>Documentation Index Page</td><td>The documentation directory must include a static HTML file
with the name of <code class="computeroutput">index.html</code>.</td><td><code class="computeroutput">www/doc/index.html</code></td>
</tr><tr>
<td>UI Logic Scripts</td><td>Packages provide a UI for users to access the system. The UI is
split into Logic and Templates. The logic scripts perform database
queries and prepare variables for presentation by the associated
templates.</td><td><code class="computeroutput">www/*.tcl</code></td>
</tr><tr>
<td>UI Templates</td><td>Templates are used to control the presentation of the UI.
Templates receive a set of data sources from the logic scripts and
prepare them for display to the browser.</td><td><code class="computeroutput">www/*.adp</code></td>
</tr><tr>
<td>UI Index Page</td><td>The UI must have an index page composed of a logic script
called <code class="computeroutput">index.tcl</code> and a template
called <code class="computeroutput">index.adp</code>.</td><td><code class="computeroutput">www/index.tcl</code></td>
</tr>
</tbody>
</table></div>
</div><br class="table-break">
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="packages-apm" id="packages-apm"></a>The
APM</h3></div></div></div><p>The APM is used to create, maintain, and install packages. It
takes care of copying all of the files and registering the package
in the system. The APM is responsible for:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Package registration</p></li><li class="listitem"><p>Automatic installation of packages: loading data models, code
libraries, and so on.</p></li><li class="listitem"><p>Checking what packages depend on what other packages.</p></li><li class="listitem"><p>Storing information on the package including ownership and a
file list.</p></li>
</ol></div><p>In addition for packages that are applications, the APM is
responsible for keeping track of where in the site a user must go
in order to use the application. To do this, the APM defines a set
of objects that we call <span class="emphasis"><em>package
instances</em></span>. Once a package is loaded, the administrator
can create as many instances of the package as she likes, and map
these instances to any URL in the site that she wants. If packages
are analogous to executable programs in an operating system, then
package instances are analgous to multiple running copies of a
single program. Each instance can be independently administered and
each instance maintains its own set of application parameters and
options.</p><p>The following sections will show you how to make a package for
the Notes application. In addition, they will discuss some site
management features in OpenACS 5 that take advantage of the
APM&#39;s package instance model. The two most important of these
are <span class="emphasis"><em>subsites</em></span>, and the
<span class="emphasis"><em>site map</em></span> tool, which can be
used to map applications to one or more arbitrary URLs in a running
site.</p><p>We will also discuss how to organize your files and queries so
they work with the OpenACS Query Dispatcher.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="packages-making-a-package" id="packages-making-a-package"></a>Making a Package</h3></div></div></div><p>Here is how you make a package.</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Login as a site-wide administrator on your web service.</p></li><li class="listitem"><p>Go to the package manager on your server. The URL is <a class="ulink" href="/acs-admin/apm" target="_top">/acs-admin/apm</a>.</p></li><li class="listitem"><p>Click on the link <a class="ulink" href="/acs-admin/apm/package-add" target="_top">/acs-admin/apm/package-add</a>.</p></li><li class="listitem">
<p>Fill out the form for adding a new package. The form explains
what everything means, but we&#39;ll repeat the important bits here
for easy reference:</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term">Package Key</span></dt><dd><p>This is a short text string that should uniquely name your
package to distinguish it from all the others. It is used as a
database key to keep track of the package and as the name of the
directory in the file system where all the files related to your
package will live. Example package keys in the current system
include: <code class="computeroutput">forums</code>, <code class="computeroutput">acs-kernel</code> and so on. For the example
application, we will use the package key <code class="computeroutput">notes</code>.</p></dd><dt><span class="term">Package Name</span></dt><dd><p>This is a short human readable name for your package. For our
example, we will use the name "Notes".</p></dd><dt><span class="term">Package Plural</span></dt><dd><p>If your package name is a nice singular noun, this should be the
plural form of it. I assume the plural form is used when multiple
instances of the package are used by a single service. We&#39;ll
talk more about package instances later. Our example apllication
doesn&#39;t really have a good plural name. So just make it also be
"Notes".</p></dd><dt><span class="term">Package Type</span></dt><dd><p>Generally we think of packages as either being <span class="emphasis"><em>applications</em></span>, meaning that the package
is meant primarily for use by end-users, or <span class="emphasis"><em>services</em></span> meaning that the package is
meant to be a reusable library of code, to be used by other
packages. <code class="computeroutput">forums</code> is a good
example of an application, while <code class="computeroutput">acs-templating</code> is a good example of a
service. Our example is an application, so pick that.</p></dd><dt><span class="term">Package URL</span></dt><dd><p>The URL from which people will download your package when it is
done. Just use the default for this, you can change it later.</p></dd><dt><span class="term">Initial Version</span></dt><dd><p>Just use the default here, which by convention is 0.1d.</p></dd><dt><span class="term">Version URL</span></dt><dd><p>Just use the default here.</p></dd><dt><span class="term">Summary and Description</span></dt><dd><p>Enter a short summary and longer description of what the Notes
application will do. That is, something like "this application
keeps short textual notes in the database", and so on.</p></dd>
</dl></div>
</li><li class="listitem"><p>Click the button "Create Package".</p></li><li class="listitem"><p>At this point, APM will create a directory called <code class="computeroutput">ROOT/packages/notes</code>.</p></li><li class="listitem">
<p>The directory that APM created will be empty except for the
<code class="computeroutput">notes.info</code> file. Create a file
called <code class="computeroutput">ROOT/packages/notes/sql/oracle/notes-create.sql</code>.
We&#39;ll fill this file with our <a class="link" href="objects" title="OpenACS Data Models and the Object System">data model</a> very
soon. Create a file called <code class="computeroutput">ROOT/packages/notes/sql/oracle/notes-drop.sql</code>.
This will contain the instructions to drop the data model. To be
complete, you would also create the PostgreSQL versions of these
files as well in <code class="computeroutput">ROOT/packages/notes/sql/postgresql/notes-create.sql</code>
and <code class="computeroutput">ROOT/packages/notes/sql/postgresql/notes-drop.sql</code>.</p><p>After you do this, go back to the main APM page. From there,
click the link called "notes" to go to the management
page for the new package. Now click the link called "Manage
file information", then the "Scan the <code class="computeroutput">packages/notes</code> directory for additional
files in this package" link on that page to scan the file
system for new files. This will bring you do a page that lists all
the files you just added and lets you add them to the <code class="computeroutput">notes</code> package.</p><p>Note that while the <code class="computeroutput">.sql</code>
files have been added to the packge, they <span class="emphasis"><em>have not</em></span> been loaded into the database.
For the purposes of development, you have to load the data model by
hand, because while OpenACS has automatic mechanisms for loading
and reloading <code class="computeroutput">.tcl</code> files for
code, it does not do the same thing for data model files.</p>
</li><li class="listitem"><p>Now go back to the main management page for the <code class="computeroutput">notes</code> If your package has parameters,
create them using the "Manage Parameter Information"
link. Define package callbacks via the "Tcl Callbacks
(install, instantiate, mount)" link.</p></li><li class="listitem">
<p>The new package has been created and installed in the server. At
this point, you should add your package files to your CVS
repository. I&#39;ll assume that you have set up your development
repository according to the standards described in <a class="link" href="cvs-tips" title="Add the Service to CVS - OPTIONAL">this appendix</a>. If so, then
you just do this:</p><pre class="programlisting">
% cd ROOT/packages
% cvs add notes
% cd notes
% cvs add notes.info
% cvs add sql
% cd sql
% cvs add *.sql
% cd ROOT/packages/notes
% cvs commit -m "add new package for notes"
    
</pre>
</li><li class="listitem"><p>Now you can start developing the package. In addition to writing
code, you should also consider the tasks outlined in the <a class="link" href="tutorial-newpackage" title="Creating an Application Package">package development
tutorial</a>.</p></li>
</ol></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="packages-subsites" id="packages-subsites"></a>The Site Map and Package Instances</h3></div></div></div><p>At this point, you are probably excited to see your new package
in action. But, we haven&#39;t added any user visible pages yet. By
convention, user visible pages go in the <code class="computeroutput">ROOT/packages/notes/www</code> directory. So go
there and add a file called <code class="computeroutput">hello.html</code> with some text in it. Now we
have to make the user pages visible in the site. Since we
didn&#39;t put the pages underneath <code class="computeroutput">ROOT/www</code> they will not appear on their own.
What we have to do is <span class="emphasis"><em>mount</em></span>
the application into the site map. That is, we have to define the
URL from which the application will serve its pages.</p><p>In OpenACS 5, administrators can define an arbitrary mapping
between the URLs the user types and the actual file in the file
system that is served. This mapping is called the <span class="emphasis"><em>site map</em></span> and entries in the site map are
called <span class="emphasis"><em>site nodes</em></span>. Each site
node maps a URL to an OpenACS object. Since package instances are
objects, the site map allows us to easily map package instances to
URLs. As we said before, each instance of an application has its
own set of parameters and runs from its own URL within the site.
What this means is that even though all the code for the
<code class="computeroutput">notes</code> application lives in
<code class="computeroutput">ROOT/packages/notes</code>, the
application itself can run from any number of locations in the
site. This allows developers and administrators to build sites that
look to the user like a collection of many indedendent applications
that actually run on a single shared code base. The <a class="link" href="request-processor" title="The Request Processor">request-processor</a> document shows you
how OpenACS figures out which instance of your application was
requested by the user at any given time. The <a class="link" href="subsites" title="Writing OpenACS Application Pages">page
development</a> tutorial shows you how to use this information in
your user interface.</p><p>In order to make the new <code class="computeroutput">notes</code> application visible to users, we have
to mount it in the site map. You do this by going to the <a class="ulink" href="/admin/site-map" target="_top">Site Map</a> page,
which is by default available at <code class="computeroutput">/acs-admin/site-map</code>. Use the interface here
to add a new sub-folder called <code class="computeroutput">notes</code> to the root of the site, then click
"new application" to mount a new instance of the
<code class="computeroutput">notes</code> application to the site.
Name the new instance <code class="computeroutput">notes-1</code>.</p><p>Then type this URL into your browser: <code class="computeroutput">http://<span class="replaceable"><span class="replaceable">yourserver</span></span>/notes/hello.html</code>
</p><p>Now you should see the contents of the page that you added. What
has happened is that all URLs that start with <code class="computeroutput">/notes</code> have been mapped in such a way as to
serve content from the directory <code class="computeroutput">ROOT/packages/notes/www</code>. At this point, you
can experiment with the site map by mounting multiple instances of
the not yet written Notes application at various places in the
site. In a later document, we&#39;ll see how to write your
application so that the code can detect from what URL it was
invoked. This is the key to supporting <a class="link" href="subsites" title="Writing OpenACS Application Pages">subsites</a>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="packages-summary" id="packages-summary"></a>Summary</h3></div></div></div><p>The APM performs the following tasks in an OpenACS site:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Manages creation, installation, and removal of packages from the
server. Also keeps track of what files belong to which
packages.</p></li><li class="listitem"><p>Manages package upgrades.</p></li><li class="listitem"><p>Manages information on all package <span class="emphasis"><em>instances</em></span> in a site. For correctly
written application packages, this allows the site administrator to
map multiple instances of a package to URLs within a site.</p></li><li class="listitem"><p>Writes out package distribution files for other people to
download and install. We&#39;ll cover this later.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="packages-add-reading" id="packages-add-reading"></a>Additional Reading</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p><a class="xref" href="apm-design" title="Package Manager Design">Package Manager Design</a></p></li><li class="listitem"><p><a class="xref" href="apm-requirements" title="Package Manager Requirements">Package Manager Requirements</a></p></li><li class="listitem"><p><a class="link" href="tutorial-newpackage" title="Creating an Application Package">package development
tutorial</a></p></li>
</ul></div><div class="cvstag">($&zwnj;Id: packages.xml,v 1.9.14.4 2017/06/16
17:19:52 gustafn Exp $)</div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="dev-guide" leftLabel="Prev" leftTitle="
Chapter 11. Development Reference"
		    rightLink="objects" rightLabel="Next" rightTitle="OpenACS Data Models and the Object
System"
		    homeLink="index" homeLabel="Home" 
		    upLink="dev-guide" upLabel="Up"> 
		