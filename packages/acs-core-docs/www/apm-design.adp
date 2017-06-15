
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Package Manager Design}</property>
<property name="doc(title)">Package Manager Design</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="apm-requirements" leftLabel="Prev"
		    title="
Chapter 15. Kernel Documentation"
		    rightLink="db-api-detailed" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="apm-design" id="apm-design"></a>Package Manager Design</h2></div></div></div><div class="authorblurb">
<p>By Bryan Quinn</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-design-essentials" id="apm-design-essentials"></a>Essentials</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p><a class="ulink" href="/acs-admin/apm" target="_top">OpenACS
Administrator directory</a></p></li><li class="listitem"><p><a class="xref" href="apm-requirements" title="Package Manager Requirements">Package Manager Requirements</a></p></li><li class="listitem"><p><a class="xref" href="packages" title="OpenACS Packages">Packages</a></p></li><li class="listitem"><p><a class="ulink" href="../images/apm.pdf" target="_top">ER
diagram</a></p></li><li class="listitem">
<p>Tcl API</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p><a class="ulink" href="/api-doc/procs-file-view?path=packages%2facs%2dtcl%2ftcl%2fapm%2dprocs%2etcl" target="_top">apm-procs.tcl</a></p></li><li class="listitem"><p>
<a class="ulink" href="/api-doc/procs-file-view?path=packages%2facs%2dtcl%2ftcl%2fapm%2dinstall%2dprocs%2etcl" target="_top">apm-install-procs.tcl</a> (Supports installation of
packages)</p></li><li class="listitem"><p>
<a class="ulink" href="/api-doc/procs-file-view?path=packages%2facs%2dbootstrap%2dinstaller%2ftcl%2f30%2dapm%2dload%2dprocs%2etcl" target="_top">30-apm-load-procs.tcl</a> (Bootstraps APM for server
startup)</p></li><li class="listitem"><p>
<a class="ulink" href="/api-doc/procs-file-view?path=packages%2facs%2dadmin%2ftcl%2fapm%2dadmin%2dprocs%2etcl" target="_top">apm-admin-procs.tcl</a> (Supports APM UI)</p></li>
</ul></div>
</li><li class="listitem">
<p>PL/SQL file</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem"><p><a class="ulink" href="/doc/sql/display-sql?url=apm-create.sql&amp;package_key=acs-kernel" target="_top">apm-create.sql</a></p></li></ul></div>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-design-intro" id="apm-design-intro"></a>Introduction</h3></div></div></div><p>In general terms, a <span class="strong"><strong>package</strong></span> is a unit of software that
serves a single well-defined purpose. That purpose may be to
provide a service directly to one or more classes of end-user,
(e.g., discussion forums and file storage for community members,
user profiling tools for the site publisher), or it may be to act
as a building block for other packages (e.g., an application
programming interface (API) for storing and querying access control
rules, or an API for scheduling email alerts). Thus, packages fall
into one of two categories:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<span class="strong"><strong>OpenACS
Applications:</strong></span> a "program or group of programs
designed for end users" (the <a class="ulink" href="http://www.pcwebopaedia.com/TERM/a/application.html" target="_top">Webopedia definition</a>); also known as <span class="emphasis"><em>modules</em></span>, for historical reasons.
Examples of applications include <a class="ulink" href="/doc/forums" target="_top">Forums</a> and <a class="ulink" href="/doc/news" target="_top">News</a>.</p></li><li class="listitem"><p>
<span class="strong"><strong>OpenACS Services:</strong></span>
the aforementioned building blocks. Examples of services include
the <a class="ulink" href="/doc/acs-content-repository" target="_top">OpenACS Content Repository</a>, the <a class="ulink" href="/doc/acs-templating" target="_top">OpenACS Templating System</a>,
and the <a class="link" href="kernel-doc" title="Chapter 15. Kernel Documentation">OpenACS
Kernel</a>, which includes APM.</p></li>
</ul></div><p>An installation of the OpenACS includes the OpenACS Kernel, some
services that extend the kernel&#39;s functionality, and some
applications intended for end-users. Packages function as
individual pieces of <a class="link" href="subsites-design" title="Subsites Design Document">subsites</a>. A subsite can
contain multiple application and service instances that provide the
end-user with capabilities and content customized to the particular
subsite.</p><p>This architecture supports the growth of collaborative commerce.
For example, Jane User starts a forum focusing on the merits of
View Cameras by creating an instance of the Forum application for
her personal subsite on an OpenACS Installation. Jack User
discovers Jane&#39;s forum and includes a link to it in his
subsite. As interest in Jane&#39;s forum grows, she creates a
subsite specializing in providing information about View cameras.
This subsite now includes several package instances beyond Forum;
it could potentially include its own Ecommerce capabilities (ala
<a class="ulink" href="http://shopping.yahoo.com" target="_top">Yahoo! Shopping</a>). This could include a knowledge
management application that allows users to spread expertise about
view cameras and a portal application that links to reliable camera
models and resellers. Any subsite enabled package that is added to
the OpenACS installation through APM is another potential package
instance that can become part of Jane&#39;s View Camera
subsite.</p><p>The APM provides an architecture for packaging software, making
instances of that software available to subsites, specifying
configuration parameters for each instance, and managing the
creation and release of new packages.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-design-hist-considerations" id="apm-design-hist-considerations"></a>Historical Considerations</h3></div></div></div><p>Prior to ACS 3.3, all packages were lumped together into one
monolithic distribution without explicit boundaries; the only way
to ascertain what comprised a given package was to look at the top
of the corresponding documentation page, where, by convention, the
package developer would specify where to find:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>the data model</p></li><li class="listitem"><p>the Tcl procedures</p></li><li class="listitem"><p>the user-accessible pages</p></li><li class="listitem"><p>the administration pages</p></li>
</ul></div><p>Experience has shown us that this lack of explicit boundaries
causes a number of maintainability problems for pre-3.3
installations:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem">
<p>Package interfaces were not guaranteed to be stable in any
formal way, so a change in the interface of one package would often
break dependent packages (which we would only discover through
manual regression testing). In this context, any of the following
could constitute an interface change:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>renaming a file or directory that appears in a URL</p></li><li class="listitem"><p>changing what form variables are expected as input by a page</p></li><li class="listitem"><p>changing a procedural abstraction, e.g., a PL/SQL or Java stored
procedure or a Tcl procedure</p></li><li class="listitem"><p>changing a functional abstraction, e.g., a database view or a
PL/SQL or Java stored function</p></li><li class="listitem"><p>changing the data model</p></li>
</ul></div><p>This last point is especially important. In most cases, changing
the data model should <span class="emphasis"><em>not</em></span>
affect dependent packages. Rather, the package interface should
provide a level of abstraction above the data model (as well as the
rest of the package implementation). Then, users of the package can
take advantage of implementation improvements that don&#39;t affect
the interface (e.g., faster performance from intelligent
denormalization of the data model), without having to worry that
code outside the package will now break.</p>
</li><li class="listitem"><p>A typical ACS-backed site only uses a few of the modules
included in the distribution, yet there was no well-understood way
to pick only what you needed when installing the ACS, or even to
uninstall what you didn&#39;t need, post-installation. Unwanted
code had to be removed manually.</p></li><li class="listitem"><p>Releasing a new version of the ACS was complicated, owing again
to the monolithic nature of the software. Since we released
everything in the ACS together, all threads of ACS development had
to converge on a single deadline, after which we would undertake a
focused QA effort whose scale increased in direct proportion to the
expansion of the ACS codebase.</p></li><li class="listitem"><p>There was no standard way for developers outside of ArsDigita to
extend the ACS with their own packages. Along the same lines,
ArsDigita programmers working on client projects had no standard
way to keep custom development cleanly separated from ACS code.
Consequently, upgrading an already installed ACS was an error-prone
and time-consuming process.</p></li>
</ol></div><p>Consistent use of the APM format and tools will go a long way
toward solving the maintainability problems listed above. Moreover,
APM is the substrate that will enable us to establish a central
package repository, where developers will be able publish their
packages for other OpenACS users to download and install.</p><p>For a simple illustration of the difference between ACS without
APM (pre-3.3) and ACS with APM (3.3 and beyond), consider a
hypothetical ACS installation that uses only two of the thirty-odd
modules available circa ACS 3.2 (say, bboard and e-commerce):</p><div class="mediaobject" align="center"><img src="images/acs-without-apm-vs-with-apm.png" align="middle"></div><p>APM itself is part of a package, the <span class="strong"><strong>OpenACS Kernel</strong></span>, an OpenACS service
that is the only mandatory component of an OpenACS
installation.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-design-competitors" id="apm-design-competitors"></a>Competitive Analysis</h3></div></div></div><p>The OpenACS is a platform for web-based application software,
and any software platform has the potential to develop problems
like those described above. Fortunately, there are many precedents
for systematic solutions, including:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<a class="ulink" href="http://www.debian.org/" target="_top">Debian GNU/Linux</a> and the <a class="ulink" href="https://www.debian.org/doc/manuals/maint-guide/" target="_top">Debian Packaging manual</a>
</p></li><li class="listitem"><p>
<a class="ulink" href="http://www.freebsd.org/" target="_top">FreeBSD</a> has <a class="ulink" href="http://www.freebsd.org/handbook/ports.html" target="_top">the
Ports collection</a>
</p></li><li class="listitem"><p>
<a class="ulink" href="http://www.redhat.com/" target="_top">Red
Hat Linux</a> has <a class="ulink" href="https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/5/html/Deployment_Guide/ch-rpm.html" target="_top">the Red Hat Package Manager (RPM)</a>
</p></li>
</ul></div><p>Borrowing from all of the above, OpenACS 3.3 introduces its own
package management system, the OpenACS Package Manager (APM), which
consists of:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>
<span class="strong"><strong>a standard format for APM
packages</strong></span> (also called "OpenACS
packages"), including:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>version numbering, independent of any other package and the
OpenACS as a whole</p></li><li class="listitem"><p>specification of the package interface</p></li><li class="listitem"><p>specification of dependencies on other packages (if any)</p></li><li class="listitem"><p>attribution (who wrote it) and ownership (who maintains it)</p></li>
</ul></div>
</li><li class="listitem">
<p><span class="strong"><strong>web-based tools for package
management:</strong></span></p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>obtaining packages from a remote distribution point</p></li><li class="listitem">
<p>installing packages, if and only if:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>all prerequisite packages are installed</p></li><li class="listitem"><p>no conflicts will be created by the installation</p></li>
</ol></div>
</li><li class="listitem"><p>configuring packages (obsoleting the monolithic OpenACS
configuration file)</p></li><li class="listitem"><p>upgrading packages, without clobbering local modifications</p></li><li class="listitem"><p>uninstalling unwanted packages</p></li>
</ul></div>
</li><li class="listitem"><p>
<span class="strong"><strong>a registry of installed
packages</strong></span>, database-backed and integrated with
filesystem-based version control</p></li><li class="listitem">
<p><span class="strong"><strong>web-based tools for package
development:</strong></span></p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>creating new packages locally</p></li><li class="listitem"><p>releasing new versions of locally-created packages</p></li>
</ul></div>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-design-design-tradeoffs" id="apm-design-design-tradeoffs"></a>Design Tradeoffs</h3></div></div></div><p>The design chosen for APM was meant to satisfy the following
constraints:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>The process of authoring a package must be as simple as
possible.</p></li><li class="listitem"><p>Strict conventions must be established that provide a set of
canonical locations and names for files and patterns, for OpenACS
application development.</p></li><li class="listitem"><p>The processes of installing, upgrading, and using packages must
be straightforward and accessible through a web-based UI.</p></li><li class="listitem"><p>Package instances must be able to have subsite-specific content
available at an easily configurable URL.</p></li>
</ul></div><p>All of these requirements were met, but at the cost of
development simplicity. As <a class="xref" href="packages" title="OpenACS Packages">Packages</a> demonstrates, a set of strict
directory conventions are required in order for a package to use
APM. This contrasts with the apparent simplicity available to
developers of the OpenACS 3.3 system. However, while the system has
become more complex for developers to build packages, this
complexity is easily managed and is compensated for by additional
capabilities.</p><p>For example, to make a new application available to the system,
a developer must:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>Create the necessary files to support the data model, Tcl API,
and UI pages.</p></li><li class="listitem"><p>Put the files in the correct locations for APM to be aware of
them.</p></li><li class="listitem"><p>Use APM to create a new package and enable it.</p></li><li class="listitem"><p>Use the Site Map facility to create an instance of the package,
mount it on an appropriate URL, and set parameters for that
particular instance.</p></li>
</ol></div><p>While this is complex, especially to a new OpenACS developer,
the documentation walks the developer through each of these steps.
Moreover, from following these steps, the package can be subsite
specific, available to subsites across the system, and be available
for distribution to other OpenACS installations without doing a
monolithic upgrade or reinstall.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-design-api" id="apm-design-api"></a>API</h3></div></div></div><p>The APM is composed of systems for accomplishing a set of
package-related tasks. Each of these tasks comprise a feature area
that has an API, data model, and a UI:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Authoring a Package</p></li><li class="listitem"><p>Maintaining Multiple Versions of a Package</p></li><li class="listitem"><p>Creating Instances of the Package</p></li><li class="listitem"><p>Specifying Configuration Parameters for each Instance</p></li>
</ul></div><p><span class="strong"><strong>Authoring a
Package</strong></span></p><p>Full instructions on how to prepare an OpenACS package are
available in <a class="xref" href="packages" title="OpenACS Packages">Packages</a>. The API here can be invoked
manually by a package&#39;s data model creation script, but need
not to be used. This API is part of the <a class="ulink" href="/api-doc/plsql-subprogram-one?type=PACKAGE&amp;name=APM" target="_top">APM PL/SQL package</a>.</p><pre class="programlisting">

-- Informs the APM that this application is available for use.
procedure register_application (
    package_key         in apm_package_types.package_key%TYPE,
    pretty_name         in apm_package_types.pretty_name%TYPE,
    pretty_plural       in apm_package_types.pretty_plural%TYPE,
    package_uri         in apm_package_types.package_uri%TYPE,
    singleton_p         in apm_package_types.singleton_p%TYPE
                                default 'f',
    spec_file_path      in apm_package_types.spec_file_path%TYPE
                                default null,
    spec_file_mtime     in apm_package_types.spec_file_mtime%TYPE
                                default null
);

</pre><p>The procedure above registers an OpenACS application in the APM.
It creates a new OpenACS object and stores information about the
package, such as its name, in the APM data model. There is an
analogous procedure for OpenACS services, called <code class="computeroutput">apm.register_service</code>.</p><p>To remove an application from the system, there are the calls
<code class="computeroutput">apm.unregister_application</code> and
<code class="computeroutput">apm.unregister_service</code>.</p><pre class="programlisting">

-- Remove the application from the system.  
procedure unregister_application (
    package_key     in apm_package_types.package_key%TYPE,
    -- Delete all objects associated with this application.
    cascade_p       in char default 'f'  
);

</pre><p>Use the <code class="computeroutput">cascade_p</code> only if
you want to completely remove the package from the OpenACS.</p><p>In order to determine if a particular package exists in the
system, use the <code class="computeroutput">register_p</code>
predicate. It returns 1 if the specified <code class="computeroutput">package_key</code> exists in the system, 0
otherwise.</p><pre class="programlisting">

function register_p (
    package_key     in apm_package_types.package_key%TYPE
) return integer;

</pre><p><span class="strong"><strong>Maintaining Multiple Versions of a
Package</strong></span></p><p>While the package authoring API provides a means for registering
a package, some information about a package is version dependent.
For example, between versions, the owner of a package, its vendor,
its URI, and its dependency information may change. The API for
package versions allows this information to be specified. All of
these APIs are part of the <a class="ulink" href="/api-doc/plsql-subprogram-one?type=PACKAGE&amp;name=APM%5fPACKAGE%5fVERSION" target="_top">
<code class="computeroutput">apm_package_version</code> PL/SQL package</a>.</p><p>To create a new package version, use the <code class="computeroutput">apm_package_version.new</code> constructor
function.</p><pre class="programlisting">

function new (
    version_id          in apm_package_versions.version_id%TYPE
                default null,
    package_key         in apm_package_versions.package_key%TYPE,
    version_name        in apm_package_versions.version_name%TYPE
                                default null,
    version_uri         in apm_package_versions.version_uri%TYPE,
    summary         in apm_package_versions.summary%TYPE,
    description_format      in apm_package_versions.description_format%TYPE,
    description         in apm_package_versions.description%TYPE,
    release_date        in apm_package_versions.release_date%TYPE,
    vendor          in apm_package_versions.vendor%TYPE,
    vendor_uri          in apm_package_versions.vendor_uri%TYPE,
    installed_p         in apm_package_versions.installed_p%TYPE
                                default 'f',
    data_model_loaded_p     in apm_package_versions.data_model_loaded_p%TYPE
                        default 'f'
) return apm_package_versions.version_id%TYPE;

</pre><p>In order to use this function, an existing <code class="computeroutput">package_key</code> must be specified. The
<code class="computeroutput">version_name</code> parameter must
follow a strict convention:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>A major version number</p></li><li class="listitem"><p>at least one minor version number. Although any number of minor
version numbers may be included, three minor version numbers is
sufficient and is the convention of software developers.</p></li><li class="listitem">
<p>One of the following:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>The letter <code class="computeroutput">d</code>, indicating a
development-only version</p></li><li class="listitem"><p>The letter <code class="computeroutput">a</code>, indicating an
alpha release</p></li><li class="listitem"><p>The letter <code class="computeroutput">b</code>, indicating a
beta release</p></li><li class="listitem"><p>No letter at all, indicating a final production release</p></li>
</ul></div>
</li>
</ol></div><p>In addition, the letters <code class="computeroutput">d</code>,
<code class="computeroutput">a</code>, and <code class="computeroutput">b</code> may be followed by another integer,
indicating a version within the release.</p><p>For those who like regular expressions:</p><pre class="programlisting">

version_number := ^[0-9]+((\.[0-9]+)+((d|a|b|)[0-9]?)?)$

</pre><p>So the following is a valid progression for version numbers:</p><div class="blockquote"><blockquote class="blockquote"><p><code class="computeroutput">0.9d, 0.9d1, 0.9a1, 0.9b1, 0.9b2,
0.9, 1.0, 1.0.1, 1.1b1, 1.1</code></p></blockquote></div><p>To delete a given version of a package, use the <code class="computeroutput">apm_package_version.delete</code> procedure:</p><pre class="programlisting">

procedure delete (
    package_id      in apm_packages.package_id%TYPE  
);

</pre><p>After creating a version, it is possible to edit the information
associated with it using <code class="computeroutput">apm_package_version.edit</code>.</p><pre class="programlisting">

function edit (
      new_version_id        in apm_package_versions.version_id%TYPE
                default null,
      version_id        in apm_package_versions.version_id%TYPE,
      version_name      in apm_package_versions.version_name%TYPE
                default null,
      version_uri       in apm_package_versions.version_uri%TYPE,
      summary           in apm_package_versions.summary%TYPE,
      description_format    in apm_package_versions.description_format%TYPE,
      description       in apm_package_versions.description%TYPE,
      release_date      in apm_package_versions.release_date%TYPE,
      vendor            in apm_package_versions.vendor%TYPE,
      vendor_uri        in apm_package_versions.vendor_uri%TYPE,
      installed_p       in apm_package_versions.installed_p%TYPE
                default 'f',
      data_model_loaded_p   in apm_package_versions.data_model_loaded_p%TYPE
                default 'f'
) return apm_package_versions.version_id%TYPE;

</pre><p>Versions can be enabled or disabled. Enabling a version
instructs APM to source the package&#39;s libraries on startup and
to make the package available to the OpenACS.</p><pre class="programlisting">

procedure enable (
    version_id          in apm_package_versions.version_id%TYPE
);

procedure disable (
    version_id          in apm_package_versions.version_id%TYPE  
);

</pre><p>Files associated with a version can be added and removed. The
path is relative to the <span class="strong"><strong>package-root</strong></span> which is <code class="computeroutput">acs-server-root/packages/package-key</code>.</p><pre class="programlisting">
-- Add a file to the indicated version. 
function add_file(
    file_id             in apm_package_files.file_id%TYPE 
                        default null, 
    version_id in       apm_package_versions.version_id%TYPE, 
    path                in apm_package_files.path%TYPE,
    file_type           in apm_package_file_types.file_type_key%TYPE 
) return apm_package_files.file_id%TYPE; 

-- Remove a file from the indicated version.
procedure remove_file( 
    version_id          in apm_package_versions.version_id%TYPE,
    path                in apm_package_files.path%TYPE 
);
</pre><p>Package versions need to indicate that they provide interfaces
for other software. An interface is an API that other packages can
access and utilize. Interfaces are identified as a URI and a
version name, that comply with the specification of a version name
for package URIs.</p><pre class="programlisting">

-- Add an interface provided by this version.
function add_interface(
    interface_id        in apm_package_dependencies.dependency_id%TYPE
                    default null,
    version_id          in apm_package_versions.version_id%TYPE,
    interface_uri       in apm_package_dependencies.service_uri%TYPE,
    interface_version       in apm_package_dependencies.service_version%TYPE
) return apm_package_dependencies.dependency_id%TYPE;

procedure remove_interface(
    interface_id        in apm_package_dependencies.dependency_id%TYPE,
    version_id          in apm_package_versions.version_id%TYPE
);

procedure remove_interface(
    interface_uri       in apm_package_dependencies.service_uri%TYPE,
    interface_version       in apm_package_dependencies.service_version%TYPE,
    version_id          in apm_package_versions.version_id%TYPE
);

</pre><p>The primary use of interfaces is for other packages to specify
required interfaces, known as dependencies. A package cannot be
correctly installed unless all of its dependencies have been
satisfied.</p><pre class="programlisting">

-- Add a requirement for this version.  A requirement is some interface that this
-- version depends on.
function add_dependency(
    requirement_id      in apm_package_dependencies.dependency_id%TYPE
                    default null,
    version_id          in apm_package_versions.version_id%TYPE,
    requirement_uri     in apm_package_dependencies.service_uri%TYPE,
    requirement_version     in apm_package_dependencies.service_version%TYPE
) return apm_package_dependencies.dependency_id%TYPE;

procedure remove_dependency(
    requirement_id      in apm_package_dependencies.dependency_id%TYPE,
    version_id          in apm_package_versions.version_id%TYPE
);

procedure remove_dependency(
    requirement_uri     in apm_package_dependencies.service_uri%TYPE,
    requirement_version     in apm_package_dependencies.service_version%TYPE,
    version_id          in apm_package_versions.version_id%TYPE
);

</pre><p>As new versions of packages are created, it is necessary to
compare their version names. These two functions assist in that
task.</p><pre class="programlisting">

-- Given a version_name (e.g. 3.2a), return
-- something that can be lexicographically sorted.
function sortable_version_name (
    version_name        in apm_package_versions.version_name%TYPE
) return varchar;

-- Given two version names, return 1 if one &gt; two, -1 if two &gt; one, 0 otherwise. 
-- Deprecate?
function compare(
    version_name_one        in apm_package_versions.version_name%TYPE,
    version_name_two        in apm_package_versions.version_name%TYPE
) return integer;

</pre><p><span class="strong"><strong>Creating Instances of a
Package</strong></span></p><p>Once a package is registered in the system, it is possible to
create instances of it. Each instance can maintain its own content
and parameters.</p><pre class="programlisting">

create or replace package apm_application
as

function new (
    application_id  in acs_objects.object_id%TYPE default null,
    instance_name   in apm_packages.instance_name%TYPE
            default null,
    package_key     in apm_package_types.package_key%TYPE,
    object_type     in acs_objects.object_type%TYPE
               default 'apm_application',
    creation_date   in acs_objects.creation_date%TYPE default sysdate,
    creation_user   in acs_objects.creation_user%TYPE default null,
    creation_ip     in acs_objects.creation_ip%TYPE default null,
    context_id      in acs_objects.context_id%TYPE default null
) return acs_objects.object_id%TYPE;

procedure delete (
    application_id      in acs_objects.object_id%TYPE
);
end apm_application;

</pre><p>Just creating a package instance is not sufficient for it to be
served from the web server. A corresponding site node must be
created for it. As an example, here is how the <a class="ulink" href="/api-doc" target="_top">OpenACS API Documentation</a> service
makes itself available on the OpenACS main site:</p><pre class="programlisting">

declare
    api_doc_id integer;
begin
    api_doc_id := apm_service.new (
      instance_name =&gt; 'OpenACS API Browser',
      package_key =&gt; 'acs-api-browser',
      context_id =&gt; main_site_id
    );

    apm_package.enable(api_doc_id);

    api_doc_id := site_node.new (
      parent_id =&gt; site_node.node_id('/'),
      name =&gt; 'api-doc',
      directory_p =&gt; 't',
      pattern_p =&gt; 't',
      object_id =&gt; api_doc_id
    );

    commit;
end;
/
show errors


</pre><p><span class="strong"><strong>Specifying Configuration Parameters
for each Instance</strong></span></p><p>A parameter is a setting that can be changed on a package
instance basis. Parameters are registered on each <code class="computeroutput">package_key</code>, and the values are associated
with each instance. Parameters can have default values and can be
of type 'string' or 'number.' There is support with
this API for setting a number of minimum and maximum values for
each parameter, but for most instances, the minimum and maximum
should be 1. It is useful to allow or require multiple values for
packages that need to store multiple pieces of information under
one parameter. Default values are automatically set when instances
are created, but can be changed for each instance.</p><p>All of the functions below are in the <a class="ulink" href="/api-doc/plsql-subprogram-one?type=PACKAGE&amp;name=APM" target="_top">APM PL/SQL package</a>.</p><pre class="programlisting">

-- Indicate to APM that a parameter is available to the system.
function register_parameter (
    parameter_id        in apm_parameters.parameter_id%TYPE 
                default null,
    parameter_name      in apm_parameters.parameter_name%TYPE,
    description         in apm_parameters.description%TYPE
                default null,
    package_key         in apm_parameters.package_key%TYPE,
    datatype            in apm_parameters.datatype%TYPE 
                default 'string',
    default_value       in apm_parameters.default_value%TYPE 
                default null,
    section_name        in apm_parameters.section_name%TYPE
                default null,
    min_n_values        in apm_parameters.min_n_values%TYPE 
                default 1,
    max_n_values        in apm_parameters.max_n_values%TYPE 
                default 1
) return apm_parameters.parameter_id%TYPE;

function update_parameter (
    parameter_id        in apm_parameters.parameter_id%TYPE,
    parameter_name      in apm_parameters.parameter_name%TYPE,
    description         in apm_parameters.description%TYPE
                default null,
    package_key         in apm_parameters.package_key%TYPE,
    datatype            in apm_parameters.datatype%TYPE 
                default 'string',
    default_value       in apm_parameters.default_value%TYPE 
                default null,
    section_name        in apm_parameters.section_name%TYPE
                default null,
    min_n_values        in apm_parameters.min_n_values%TYPE 
                default 1,
    max_n_values        in apm_parameters.max_n_values%TYPE 
                default 1
) return apm_parameters.parameter_name%TYPE;

-- Remove any uses of this parameter.
procedure unregister_parameter (
    parameter_id        in apm_parameters.parameter_id%TYPE 
                default null
);

</pre><p>The following functions are used to associate values with
parameters and instances:</p><pre class="programlisting">

-- Return the value of this parameter for a specific package and parameter.
function get_value (
    parameter_id        in apm_parameter_values.parameter_id%TYPE,
    package_id          in apm_packages.package_id%TYPE         
) return apm_parameter_values.attr_value%TYPE;

function get_value (
    package_id          in apm_packages.package_id%TYPE,
    parameter_name      in apm_parameters.parameter_name%TYPE
) return apm_parameter_values.attr_value%TYPE;

-- Sets a value for a parameter for a package instance.
procedure set_value (
    parameter_id        in apm_parameter_values.parameter_id%TYPE,
    package_id          in apm_packages.package_id%TYPE,        
    attr_value          in apm_parameter_values.attr_value%TYPE
);

procedure set_value (
    package_id          in apm_packages.package_id%TYPE,
    parameter_name      in apm_parameters.parameter_name%TYPE,
    attr_value          in apm_parameter_values.attr_value%TYPE
);  

</pre>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-design-data-model" id="apm-design-data-model"></a>Data Model Discussion</h3></div></div></div><p>The central piece of the data model is the <code class="computeroutput">apm_package_types</code> table where each package
is registered. When a new application or service is installed on an
OpenACS instance, a corresponding row in this table is inserted
with information about the type of package, e.g. if the <a class="ulink" href="/doc/forum" target="_top">forum package</a> is
installed on your OpenACS server, a row in <code class="computeroutput">apm_package_types</code> will be created, noting
that it&#39;s an application package type.</p><p>The <code class="computeroutput">apm_packages</code> table is
used to contain information about the <span class="emphasis"><em>instances</em></span> of packages currently created
in the system. The <code class="computeroutput">package_key</code>
column references the <code class="computeroutput">apm_package_types</code> table to ensure that no
package instance can be created for a type that does not exist.</p><p>The <code class="computeroutput">apm_package_versions</code>
table contains information specific to a particular version of a
package. Several tables reference this one to provide further
information about the particular version:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<code class="computeroutput">apm_package_owners</code> Stores
information about the owners of a particular version of a
package.</p></li><li class="listitem"><p>
<code class="computeroutput">apm_package_files</code> Stores
information about the files that are part of a version.</p></li><li class="listitem"><p>
<code class="computeroutput">apm_package_dependencies</code>
Stores information about what interfaces the package provides and
requires.</p></li>
</ul></div><p>Parameter information is maintained through two tables:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<code class="computeroutput">apm_parameters</code> This table
contains the definition of each of the parameters for a
package.</p></li><li class="listitem"><p>
<code class="computeroutput">apm_parameter_values</code> This
table holds all of the values of parameters for specific package
instances.</p></li>
</ul></div><p>A number of views are available for obtaining information about
packages registered in the APM.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<code class="computeroutput">apm_package_version_info</code>
Provides information about all of the versions in the system with
information available from the <code class="computeroutput">apm_package_types</code> table.</p></li><li class="listitem"><p>
<code class="computeroutput">apm_enabled_package_versions</code>
A view (subset) of the above table with only enabled versions.</p></li><li class="listitem"><p>
<code class="computeroutput">apm_file_info</code> Provides a
public interface for querying file information.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-design-ui" id="apm-design-ui"></a>User Interface</h3></div></div></div><p>The <a class="ulink" href="/acs-admin/apm" target="_top">APM&#39;s user interface</a> is part of the <a class="ulink" href="/acs-admin" target="_top">OpenACS Administration Service</a>.
The UI is the primary point of contact with APM by developers and
administrators. It is part of OpenACS Administration, because only
the site-wide administrator should be able to access it. Thus in
order to develop a package, the developer must be granted site-wide
administration.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-design-config" id="apm-design-config"></a>Configuration/Parameters</h3></div></div></div><p>APM has two parameters for configuring how it interacts with the
UNIX filesystem, accessible via the <a class="ulink" href="/admin/site-map/" target="_top">Site Map admin</a> page. These
parameters need not be changed under most circumstances, but may
need to be tweaked for Windows compatibility.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<span class="strong"><strong>GzipExecutableDirectory</strong></span> This
directory points to where the <code class="computeroutput">gunzip</code> program can be found for
uncompressing <code class="computeroutput">gzip</code> archives.
This is needed for the installation of <code class="computeroutput">.apm</code> files which are simply <code class="computeroutput">gzip</code>ed tarballs. Default is <code class="computeroutput">/usr/local/bin</code>
</p></li><li class="listitem"><p>
<span class="strong"><strong>InfoFilePermissionsMode</strong></span> This sets
the default UNIX permissions used when creating files using the
APM. Default is 775.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-design-future" id="apm-design-future"></a>Future Improvements/Areas of Likely
Change</h3></div></div></div><p>APM has been in production since OpenACS 3.3, and as of version
4.0 offers a stable set of features. One major feature planned is
integration with the OpenACS Package Repository for automatic
dependency satisfaction. When a user tries to install a package
that depends on other packages, the APM will contact the package
repository, determine what packages depend on it, and offer the
user a chance to download and install them all. This improvement
offers value to end users by facilitating the extension of their
OpenACS systems.</p><p>Architecturally, minor improvements to the data model and the
specification file are planned to increase modularity. The current
implementation puts all package specification information in a
single file. This approach has certain advantages, such as
centralization, but splitting this information into several files
allows for flexible extensions to the APM architecture over
time.</p><p>APM packages currently lack provisions to verify security
information. There are plans to add MD5 time stamps and PGP
signatures to packages to enable secure authentication of packages.
These steps are necessary for APM to be usable as a scalable method
to distribute packages on multiple repositories worldwide.</p><p>Another anticipated change is to split the APM UI into separate
systems for authoring, maintaining, and installing packages. The
current UI presents all of this functionality in one interface and
it can be confusing from a usability perspective.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-design-authors" id="apm-design-authors"></a>Authors</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>System creator: Bryan Quinn, Jon Salz, Michael Yoon, Lars Pind,
Todd Nightingale.</p></li><li class="listitem"><p>System owner: Bryan Quinn</p></li><li class="listitem"><p>Documentation author: Bryan Quinn, building from earlier
versions by Jon Salz, Michael Yoon, and Lars Pind.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-design-rev-history" id="apm-design-rev-history"></a>Revision History</h3></div></div></div><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><tbody>
<tr>
<td><span class="strong"><strong>Document Revision
#</strong></span></td><td><span class="strong"><strong>Action Taken,
Notes</strong></span></td><td><span class="strong"><strong>When?</strong></span></td><td><span class="strong"><strong>By Whom?</strong></span></td>
</tr><tr>
<td>0.1</td><td>Creation</td><td>9/25/2000</td><td>Bryan Quinn</td>
</tr><tr>
<td>0.8</td><td>Ready for QA</td><td>9/29/2000</td><td>Bryan Quinn</td>
</tr><tr>
<td>0.9</td><td>Edited for ACS 4 Beta release</td><td>10/02/2000</td><td>Kai Wu</td>
</tr><tr>
<td>1.0</td><td>Edited for OpenACS 4.5 Beta release</td><td>03/02/2002</td><td>Roberto Mello</td>
</tr>
</tbody>
</table></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="apm-requirements" leftLabel="Prev" leftTitle="Package Manager Requirements"
		    rightLink="db-api-detailed" rightLabel="Next" rightTitle="Database Access API"
		    homeLink="index" homeLabel="Home" 
		    upLink="kernel-doc" upLabel="Up"> 
		