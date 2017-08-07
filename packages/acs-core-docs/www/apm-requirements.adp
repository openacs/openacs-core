
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Package Manager Requirements}</property>
<property name="doc(title)">Package Manager Requirements</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="subsites-design" leftLabel="Prev"
		    title="
Chapter 15. Kernel Documentation"
		    rightLink="apm-design" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="apm-requirements" id="apm-requirements"></a>Package Manager Requirements</h2></div></div></div><div class="authorblurb">
<p>By Bryan Quinn and Todd Nightingale</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-requirements-intro" id="apm-requirements-intro"></a>Introduction</h3></div></div></div><p>The following is a requirements document for the OpenACS Package
Manager (APM), version 4.0 (APM4). APM4 offers a superset of APM
v3.3 functionality with the following specific enhancements:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>A public procedural API. (v 3.3 only has web-based UI)</p></li><li class="listitem"><p>Support for dependency checking.</p></li><li class="listitem"><p>Support for compound packages (to support installation
chaining).</p></li><li class="listitem"><p>Support for on-line parameter setting.</p></li><li class="listitem"><p>Support for sub-site level configuration (requires revised
parameter and /admin pages at sub-site level; deprecation of
site-wide parameter file).</p></li>
</ul></div><p>To differentiate these new requirements from the requirements of
version 3.3, all requirements new in v4 are prefaced with the
number <span class="strong"><strong>4</strong></span>.</p><p>We gratefully acknowledge the authors of APM 3 for their
original design documentation which suggested these features, as
well as the influence of the design and open-source implementation
of the Red Hat Package manager, the Debian packaging system, and
PERL&#39;s CPAN in the development of the ideas behind this
document.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-requirements-vision" id="apm-requirements-vision"></a>Vision Statement</h3></div></div></div><p>A typical website will tend to offer its users a number of
web-based services or applications, e.g. a bulletin board,
calendaring, classified ads, etc. A website may also have
underlying subsystems, such as a permissions system, content
management system, etc. For such applications and subsystem
components, modularity - or the degree to which a component can be
encapsulated and decoupled from the rest of the system - is of
great value. Thus the OpenACS Package Manager (APM) was created to
allow website components, or packages, to be added, removed, and
upgraded easily, with minimum disturbance to the rest of the
system. This allows site owners to steadily offer users new and
improved services, and also allows programmers to quickly and
easily distribute their OpenACS components in a standardized manner
to other OpenACS sites.</p><p>In general terms, a package is a unit of software that serves a
single well-defined purpose. The OpenACS Package Manager (APM)
provides a mechanism for packaging, installing, and configuring
OpenACS software in a consistent, user-friendly, and subsite-aware
manner.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-requirements-system-overview" id="apm-requirements-system-overview"></a>System Overview</h3></div></div></div><p>The OpenACS Package Manager (APM) consists of:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>
<span class="strong"><strong>A standard format for APM
packages</strong></span> including:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Version numbering, independent of any other package and the
OpenACS as a whole</p></li><li class="listitem"><p>Specification of the package interface</p></li><li class="listitem"><p>Specification of dependencies on other packages (if any)</p></li><li class="listitem"><p>Attribution (who wrote it) and ownership (who maintains it)</p></li>
</ul></div>
</li><li class="listitem">
<p><span class="strong"><strong>Web-based tools for package
management:</strong></span></p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Obtaining packages from a remote distribution point</p></li><li class="listitem">
<p>Installing packages, if and only if:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>All prerequisite packages are installed</p></li><li class="listitem"><p>No conflicts will be created by the installation</p></li>
</ol></div>
</li><li class="listitem"><p>Configuring packages (obsoleting the monolithic OpenACS
configuration file)</p></li><li class="listitem"><p>Upgrading packages, without clobbering local modifications</p></li><li class="listitem"><p>Uninstalling unwanted packages</p></li>
</ul></div>
</li><li class="listitem"><p>
<span class="strong"><strong>A registry of installed
packages</strong></span>, database-backed and integrated with file
system-based version control</p></li><li class="listitem">
<p><span class="strong"><strong>Web-based tools for package
development:</strong></span></p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Creating new packages locally</p></li><li class="listitem"><p>Releasing new versions of locally-created packages</p></li><li class="listitem"><p>Uploading packages to a global package repository on the web</p></li><li class="listitem"><p>Use of these tools should be safe, i.e. installing or removing a
package should never break an OpenACS installation</p></li>
</ul></div>
</li><li class="listitem">
<p><span class="strong"><strong>Web-based tools for package
configuration:</strong></span></p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>The ability to change package parameter values on-line through a
simple web interface.</p></li><li class="listitem"><p>A new ad_parameter which does not require a monolithic site-wide
parameter&#39;s file or server restarts for changes to take
effect.</p></li><li class="listitem"><p>The ability to manage multiple package instances at the sub-site
level.</p></li>
</ul></div>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-requirements-use-cases" id="apm-requirements-use-cases"></a>Use-cases and User-scenarios</h3></div></div></div><p>The APM is intended for the following classes of users, which
may or may not overlap:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>
<span class="strong"><strong>Developers</strong></span>
(referred to as 'the developer') use the APM to create a
software package for distribution and use the procedural API for
direct control of the APM system.</p></li><li class="listitem"><p>
<span class="strong"><strong>Site-wide
administrators</strong></span> (referred to as 'the
administrator') use the APM to install packages for their
OpenACS instance, and optionally make them available to
sub-sites.</p></li><li class="listitem"><p>
<span class="strong"><strong>Sub-site
administrators</strong></span> (referred to as 'the
sub-admin') use an administration interface to configure and
enable packages for their sub-site.</p></li>
</ol></div><p><span class="strong"><strong>Initial Package
Development</strong></span></p><p>
<span class="strong"><strong>David Developer</strong></span>
writes a piece of software used to do knowledge management (km) for
the OpenACS. He distributes his data model, procedure code, UI
pages, and his documentation according to the APM specification. He
splits the documentation and the code into sub-packages, and
creates a KM installation-chain to install both with the APM
developer UI. Noting that his software was built with <span class="strong"><strong>Patricia Programmer</strong></span>'s Super
Widget toolkit, he specifies that as a dependency. Moreover, since
this package is capable of being used at the sub-site level, David
configures this option in the package. When the package development
is complete, David uses the APM developer UI to construct a
distribution file. He assigns it a version number, 1.0, and makes
the package available for download at the OpenACS package
repository.</p><p><span class="strong"><strong>Initial Package
Installation</strong></span></p><p>
<span class="strong"><strong>Annie Admin</strong></span> learns
of David&#39;s KM system by browsing the OpenACS package
repository. Annie Admin uses the APM administrator UI on her
system. She selects to install a package from a URL and types the
URL displayed on the system. The APM automatically downloads the
package. The dependency checker notices that Patricia&#39;s Super
Widget toolkit is required, so it warns Annie of this. Annie
selects an option to find a package that satisfies the dependency
at the OpenACS APM repository. The APM informs Annie that it can
download and install Jim&#39;s Super Widget toolkit. Annie confirms
this option. After successfully installing Jim&#39;s toolkit, Annie
proceeds to install David&#39;s KM system. The data model is loaded
and all of the files necessary for the software are installed.
Because installation was successful, the package is available for
use.</p><p>Since the package is available for use, its initialization
routines are set to run automatically on server startup. Annie is
warned that since there are initialization routines, she must
restart the server for the package to be ready for use. Annie
restarts the server.</p><p><span class="strong"><strong>Initial Subsite Use of
Package</strong></span></p><p>Annie Admin decides to make the KM module available only to a
particular sub-site type on her OpenACS system, and not others. She
specifies this option using the Sub-site type UI (not part of
APM).</p><p>Annie Admin notifies <span class="strong"><strong>Sally
SubAdmin</strong></span> by e-mail that a new package is now
available for use. Sally goes to her sub-site /admin page and sees
that a new entry, KM, is available. Sally clicks on it and finds
links to the installed KM documentation and to the web based
configuration utility. Then, Sally configures the package using an
automatically generated web interface and enables KM for use on her
sub-site. After some initial use of the package, Sally decides to
change some parameters using the SubAdmin UI. These changes take
effect immediately, without any server restarts.</p><p><span class="strong"><strong>Upgrade Process</strong></span></p><p>Sally SubAdmin finds a bug in the KM system and sends a report
to David Developer. David reads the bug report and verifies that
the bugs are present in the current version. Because the bugs are
present in the shared procedure file, David assigns a watch to the
file. David makes the necessary modifications to the source code
and saves the file. Because a watch was assigned to the file, the
APM automatically reloads the updated code. David tests the program
and confirms that the bug is fixed. He increments the minor version
number and makes km v 1.1 available for download at the
repository.</p><p>Sally SubAdmin asks Annie Administrator to upgrade the package
using the APM UI. This upgrade supersedes the old version of KM at
the site-wide level. Once Annie upgrades the package, the new
version starts working immediately in Sally&#39;s sub-site.</p><p><span class="strong"><strong>Procedural API</strong></span></p><p>
<span class="strong"><strong>Danielle Developer</strong></span>
wants her software to perform different actions depending on what
version of another package is installed. She uses the APM
procedural API to check if KM version 1.0 is installed or version
1.1. Based on the results of this procedural call, the software
exhibits different behavior.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-requirements-links" id="apm-requirements-links"></a>Related Links</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p><a class="ulink" href="apm-design" target="_top">APM 3.3 Design
document</a></p></li><li class="listitem"><p><a class="ulink" href="packages" target="_top">Five minute guide
to packaging a module</a></p></li><li class="listitem"><p><a class="ulink" href="subsites-requirements" target="_top">Sub-sites</a></p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-requirements-data-model" id="apm-requirements-data-model"></a>Requirements: Data Model</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>
<span class="strong"><strong>4.500.0 Package
Identification</strong></span> (All of these items are entered by
the developer using the developer UI.)</p><p>
<span class="strong"><strong>4.500.1</strong></span> A human
readable package key that is guaranteed to be unique to the local
OpenACS site must be maintained by the APM. For example,
"apm."</p><p>
<span class="strong"><strong>4.500.5</strong></span> A package
id (primary key) that is guaranteed to be unique to the local site
must be maintained by the APM. For example, "25."</p><p>
<span class="strong"><strong>4.500.10</strong></span> A package
URL that is guaranteed to be unique across all sites must be
maintained by the APM. The package URL should point to a server
that allows download of the latest version of the package. For
example, "http://openacs.org/software."</p>
</li><li class="listitem">
<p>
<span class="strong"><strong>4.505.0 Version
Identification</strong></span> (All of these items are entered by
the developer using the developer UI.)</p><p>
<span class="strong"><strong>4.505.1</strong></span> A version
id (primary key) that is guaranteed to be unique to the local site
must be maintained by the APM.</p><p>
<span class="strong"><strong>4.505.5</strong></span> A version
URL that is guaranteed to be unique across all sites must be
maintained by the APM. The version URL should point to a server
that allows download of a specific version of the package.</p>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-requirements-api" id="apm-requirements-api"></a>Requirements: API</h3></div></div></div><p>The API for APM v3 is explicitly a private API. However, it
would be useful to obtain information from the APM through a
procedural API. Implementing the API specified below is quite easy
given that there are pages that already do all of the below in raw
SQL.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p><span class="strong"><strong>4.400.0 Packages Status
Predicates</strong></span></p><p>
<span class="strong"><strong>4.400.1</strong></span> Given
defining information such as a package URL, the APM API can return
the status of the package on the local OpenACS instance.</p>
</li><li class="listitem">
<p><span class="strong"><strong>4.405.0 Package Information
Procedures</strong></span></p><p>
<span class="strong"><strong>4.405.1</strong></span> The APM API
can return information for any locally installed packages,
including the version number, paths and files, and package key.</p>
</li><li class="listitem">
<p><span class="strong"><strong>4.410.0 Sub-site
Procedures</strong></span></p><p>
<span class="strong"><strong>4.410.1</strong></span> After a
package has been installed at the site-wide level, the system API
will provide means to check for package presence, creation,
enabling, disabling, and destruction on a subsite.</p>
</li><li class="listitem">
<p><span class="strong"><strong>4.415.0 Parameter Values (replaces
ad_parameter)</strong></span></p><p>
<span class="strong"><strong>4.415.1</strong></span> The system
API shall allow subsite parameters for an installed package to be
set by either site-wide administrators or sub-site admins. The
subsite parameter can be set to be non-persistent (but default is
to survive server restarts). The subsite parameter can also be set
to only take effect after a server restart (default is
immediate).</p><p>
<span class="strong"><strong>4.415.5</strong></span> Parameters
for a given subsite and package can be returned by the system
API.</p>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-requirements-security" id="apm-requirements-security"></a>Requirements: Security</h3></div></div></div><p>Provisions will be made to assure that packages are securely
identified.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<span class="strong"><strong>4.600.1</strong></span> Each
package will have a PGP signature and there will be MD5 time stamps
for each file within the package.</p></li><li class="listitem"><p>
<span class="strong"><strong>4.600.5</strong></span> The APM
will provide a facility to validate both the PGP signature and MD5
stamps information before a package install.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-requirements-ui" id="apm-requirements-ui"></a>Requirements: The User Interface</h3></div></div></div><p>The user interface is a set of HTML pages that are used to drive
the underlying API. It is restricted to site-wide administrators
because the actions taken here can dramatically affect the state of
the running OpenACS.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-requirements-dev-interface" id="apm-requirements-dev-interface"></a>Requirements: The
Developer&#39;s Interface</h3></div></div></div><p>The intent of the developer&#39;s interface is to enable the
developer to construct and maintain APM packages. It will be
possible to disable the developer&#39;s interface for production
sites to help reduce the chance of site failure; much of the
functionality here can have cascading effects throughout the
OpenACS and should not be used on a production site.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p><span class="strong"><strong>10.0 Define a
package.</strong></span></p><p>The developer must be able to create a new package by specifying
some identifying information for the package. This includes a
package name, a package key, version information, owner
information, and a canonical URL.</p><p>
<span class="strong"><strong>10.1</strong></span> The APM must
maintain the state of all locally generated packages.</p><p>
<span class="strong"><strong>10.50</strong></span> If the
developer fails to provide the required information, the package
cannot be created.</p><p>
<span class="strong"><strong>10.55</strong></span> All of the
package information should be editable after creation, except for
the package key.</p><p>
<span class="strong"><strong>4.10.60</strong></span> The package
creator must specify whether the package is capable of being used
in sub-sites, or if only a single, global instance of the package
is permitted.</p><p>
<span class="strong"><strong>4.10.65</strong></span> If the
developer fails to provide unique information for unique fields
specified in the data model requirements, the package cannot be
created.</p>
</li><li class="listitem">
<p><span class="strong"><strong>20.0 Add files to a
package</strong></span></p><p>
<span class="strong"><strong>20.1</strong></span> The developer
must be able to add files to the package. This is done by copying
the files into the package directory in the host OS&#39;s file
system. Files can be added at any point after package creation.</p><p>
<span class="strong"><strong>20.3</strong></span> Once a package
has been versioned and distributed, no new files should be added to
the package without incrementing the version number.</p><p>
<span class="strong"><strong>20.5</strong></span> The APM&#39;s
UI should facilitate the process of adding new files, by scanning
the file system for new files automatically, and allowing the
developer to confirm adding them.</p><p>
<span class="strong"><strong>20.10</strong></span> The developer
cannot add files to a given package via the UI that do not exist in
the file system already.</p><p>
<span class="strong"><strong>20.15</strong></span> Package file
structure must follow a specified convention. Please see the
<a class="link" href="apm-design" title="Package Manager Design">design document</a> for what we do
currently.</p>
</li><li class="listitem">
<p><span class="strong"><strong>30.0 Remove files from a
package</strong></span></p><p>The developer must be able to remove files from a package. This
can be done in two ways.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>
<span class="strong"><strong>30.1</strong></span> Access the APM
UI, browse the file list, and remove files.</p><p>
<span class="strong"><strong>30.1.1</strong></span>If a file is
removed from the package list, but not from the file system, an
error should be generated at package load time.</p>
</li><li class="listitem">
<p>
<span class="strong"><strong>30.5</strong></span> Remove the
file from file system.</p><p>
<span class="strong"><strong>30.5.1</strong></span> The APM UI
should take note of the fact that the file is gone and offer the
developer an option to confirm the file&#39;s deletion.</p>
</li>
</ul></div>
</li><li class="listitem">
<p>
<span class="strong"><strong>40.0 Modify files in a
package</strong></span>.</p><p>
<span class="strong"><strong>40.1</strong></span> The developer
should be able to modify files in the file system. The APM UI
should not interfere with this.</p><p>
<span class="strong"><strong>40.5</strong></span> However, if
the developer modifies files containing procedural definitions, APM
UI should allow a means to <span class="strong"><strong>watch</strong></span> those files and
automatically reload them if changed. See requirement 50.0 for more
detail.</p><p>
<span class="strong"><strong>40.10</strong></span> Also,
although a change in files implies that the package distribution
file is out of date, it is the developer&#39;s responsibility to
update it.</p>
</li><li class="listitem">
<p>
<span class="strong"><strong>4.45.0 Manage Package Dependency
Information</strong></span>.</p><p>
<span class="strong"><strong>4.45.1</strong></span> The
developer should be able to specify which interfaces the package
requires.</p><p>
<span class="strong"><strong>4.45.5</strong></span> The
developer should be able to specify which interfaces the package
provides.</p><p>
<span class="strong"><strong>4.45.10</strong></span> Circular
dependencies are not allowed.</p>
</li><li class="listitem">
<p><span class="strong"><strong>50.0 Watch a
file</strong></span></p><p>
<span class="strong"><strong>4.50.1</strong></span> The
developer should be able to assign a watch to any Tcl procedure
file, whether in /packages or /tcl.</p><p>
<span class="strong"><strong>50.5</strong></span> If a watched
file is locally modified, then it will be automatically reloaded,
thus allowing for any changes made to take affect immediately.</p><p>
<span class="strong"><strong>4.50.10</strong></span> The setting
of a watch should be persistent across server restarts.</p>
</li><li class="listitem">
<p><span class="strong"><strong>60.0 Display an XML package
specification</strong></span></p><p>
<span class="strong"><strong>60.1</strong></span> The developer
should be able to view the XML package specification that encodes
all package information.</p>
</li><li class="listitem">
<p><span class="strong"><strong>70.0 Write an XML package
specification to the file system</strong></span></p><p>
<span class="strong"><strong>70.1</strong></span> The developer
should be able to write an up-to-date XML specification to
disk.</p><p>
<span class="strong"><strong>70.5</strong></span> The developer
should be able to request the current XML specification for all
installed, locally generated packages.</p>
</li><li class="listitem">
<p><span class="strong"><strong>130.0 Distribution file
generation</strong></span></p><p>
<span class="strong"><strong>130.1</strong></span> The developer
should be able to generate a .APM distribution file for the package
with just one click.</p><p>
<span class="strong"><strong>130.5</strong></span> Generating a
distribution file implies doing an "up-to-date" check on
all of the files. If any of the files have changed since package
installation, then a new version of the package is created.</p>
</li><li class="listitem">
<p><span class="strong"><strong>140.0 Access CVS
information</strong></span></p><p>
<span class="strong"><strong>140.1</strong></span> The developer
should be able to determine the CVS status of a package, or all
packages, with a single click.</p>
</li><li class="listitem">
<p><span class="strong"><strong>4.400.0 Compound Package
Construction</strong></span></p><p>
<span class="strong"><strong>4.400.1</strong></span> The
developer can include .APM packages (sub-packages) within a package
(the compound package) like any other file.</p><p>
<span class="strong"><strong>4.400.5</strong></span> The
recommended usage for this feature is to allow for separation of
optional and required components from the installation as well as
better organization of files once installed. For example, all
documentation for the community-core can be packages as
<code class="computeroutput">community-core-doc.apm</code>. It is
legal to include sub-packages with dependencies that are not
satisfied by the packages in the compound package, but this is
discouraged. In such a case, the sub-package should really be a
separate package that is required by the compound package.</p><p>
<span class="strong"><strong>4.400.10</strong></span> If a
sub-package is required for the installation of the compound
package, the compound package should have a registered dependency
on the sub-package.</p>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-requirements-admin-interface" id="apm-requirements-admin-interface"></a>Requirements: The Site-Wide
Administrator&#39;s Interface</h3></div></div></div><p>The requirement of the administrator&#39;s interface is to
enable the administrator to install, enable, upgrade, disable,
deinstall, and delete packages.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p><span class="strong"><strong>80.0 Package
Enable/Disable</strong></span></p><p>
<span class="strong"><strong>4.80.1</strong></span> The
administrator should be able mark an installed package as enabled.
This means that the package is activated and its functionality is
delivered through the Request Processor. As of OpenACS 4, this is
done through the sub-site system.</p><p>
<span class="strong"><strong>4.80.5</strong></span> Moreover,
the administrator must be able to disable a package, thereby
removing the functionality provided to a sub-site. As of OpenACS 4,
this is done through the sub-site system.</p>
</li><li class="listitem">
<p><span class="strong"><strong>90.0 Package
Install</strong></span></p><p>
<span class="strong"><strong>90.1</strong></span> The
administrator must be able to install new packages either from
locally maintained .APM files or from URLs.</p><p>
<span class="strong"><strong>90.5</strong></span> In the case of
an URL, the APM transparently downloads the APM file off the web,
proceeds with a file based installation, and then optionally
removes the .APM file just downloaded.</p><p>
<span class="strong"><strong>90.10.1</strong></span> If .APM
files are present in a package, then it is considered a compound
package (use 4.410.0).</p><p>
<span class="strong"><strong>90.15.0</strong></span>
Installation requires these steps:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>
<span class="strong"><strong>90.15.1</strong></span>The package
dependencies are scanned. If some dependencies are not present, the
system warns the administrator that installation cannot proceed
until those packages are installed.</p></li><li class="listitem"><p>
<span class="strong"><strong>90.15.2</strong></span> Assuming
all dependencies are present, APM extracts the contents of the APM
file into the /packages directory.</p></li><li class="listitem"><p>
<span class="strong"><strong>90.15.3</strong></span> The
administrator is offered the option of importing directly into
CVS.</p></li><li class="listitem"><p>
<span class="strong"><strong>90.15.4</strong></span> The
administrator is given a list of data model scripts found in the
package and can select which ones to be executed.</p></li><li class="listitem"><p>
<span class="strong"><strong>90.15.5</strong></span> If no
errors are recorded during this process, the package is
enabled.</p></li>
</ol></div>
</li><li class="listitem">
<p><span class="strong"><strong>4.410.0 Compound package
Install</strong></span></p><p>
<span class="strong"><strong>4.410.1</strong></span> If .APM
files are present in a package, then it is considered a compound
package.</p><p>
<span class="strong"><strong>4.410.5.0</strong></span>
Installation of a compound package proceeds according to the
following sequence:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>
<span class="strong"><strong>4.410.5.1</strong></span> Identify
the set of all sub-packages within the compound package by scanning
for all files with .APM.</p></li><li class="listitem"><p>
<span class="strong"><strong>4.410.5.2</strong></span> Identify
which sub-packages are required by checking the dependencies of the
compound package. If there dependencies not satisfied by the
current system or the packages included with the compound package,
halt installation and inform user to install these packages
first.</p></li><li class="listitem"><p>
<span class="strong"><strong>4.410.5.3</strong></span> Present
Administrator with the ability to choose which sub-packages to
install. Required sub-packages must be installed.</p></li><li class="listitem"><p>
<span class="strong"><strong>4.410.5.4</strong></span> Proceed
with the installation of each sub-package, starting with required
packages. If the sub-package is already installed, then do nothing.
Else, If the sub-package is a normal package, proceed according to
<span class="strong"><strong>90.15.0</strong></span>, otherwise if
it is a compound package, proceed according to <span class="strong"><strong>4.410.5.0</strong></span>.</p></li><li class="listitem"><p>
<span class="strong"><strong>4.410.5.5</strong></span> If all
required sub-packages are installed, proceed to install
non-required sub-packages. If there was a failure during the
installation of a required sub-package, then the installation of
the compound package is also a failure.</p></li><li class="listitem"><p>
<span class="strong"><strong>4.410.5.6</strong></span> Any
attempt to install a compound package in the future involves a
choice presented to the admin of installing any uninstalled
sub-packages.</p></li>
</ol></div>
</li><li class="listitem">
<p><span class="strong"><strong>4.420.0 Recovering from failed
package installation</strong></span></p><p>
<span class="strong"><strong>4.420.1</strong></span> If any
error is generated during package installation, the package is not
considered installed. To recover from this failure, the package
should be selected for installation again.</p>
</li><li class="listitem">
<p><span class="strong"><strong>100.0 Version
Upgrade</strong></span></p><p>
<span class="strong"><strong>100.1</strong></span> The
administrator can upgrade to a new version of a package. This
entails</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>
<span class="strong"><strong>100.1.1</strong></span> Running any
necessary and included upgrade scripts.</p></li><li class="listitem"><p>
<span class="strong"><strong>100.1.5</strong></span> Replacing
any old files with new versions.</p></li><li class="listitem"><p>
<span class="strong"><strong>100.1.10</strong></span> Marking
the old version of the package as 'superseded' and
disabling it.</p></li><li class="listitem"><p>
<span class="strong"><strong>100.1.15</strong></span> Assuming
no errors from above, the new package is enabled.</p></li>
</ol></div>
</li><li class="listitem">
<p><span class="strong"><strong>110.0 Package
Deinstall</strong></span></p><p>
<span class="strong"><strong>110.1</strong></span> The
administrator must be able to deinstall a package that has already
been installed. Deinstallation entails:</p><div class="orderedlist"><ol class="orderedlist" type="1">
<li class="listitem"><p>
<span class="strong"><strong>110.1.1</strong></span> Running any
data model scripts necessary to drop the package.</p></li><li class="listitem"><p>
<span class="strong"><strong>110.1.5</strong></span> Moving all
of the files into a separate location in the file system from the
installed packages.</p></li><li class="listitem"><p>
<span class="strong"><strong>4.110.1.10</strong></span> If the
package is a compound package, then the administrator must confirm
removing all sub-packages. Optionally, some sub-packages can be
kept.</p></li>
</ol></div><p>
<span class="strong"><strong>110.5</strong></span> Deinstalled
packages can be re-installed at a later date.</p><p>
<span class="strong"><strong>4.110.10</strong></span> If
deinstalling a package or any of its sub-packages breaks a
dependency, then deinstallation cannot proceed until the package
registering the dependency is removed.</p>
</li><li class="listitem">
<p><span class="strong"><strong>120.0 Package
Deletion</strong></span></p><p>
<span class="strong"><strong>120.1</strong></span> The
administrator should be able to completely erase all records of the
package. This involves removing all instances of the package, all
related database tables and content.</p><p>
<span class="strong"><strong>120.5</strong></span> This option
can only be used if all package instances are deleted or marked as
disabled. This is purposefully cumbersome because deleting all
instances of a package can have far-sweeping consequences
throughout a site and should almost never be done.</p>
</li><li class="listitem">
<p><span class="strong"><strong>150.0 Scan for new or modified
packages</strong></span></p><p>
<span class="strong"><strong>150.1</strong></span> The
administrator should be able to scan the file system for any
changes made in any of the installed package files.</p><p>
<span class="strong"><strong>150.5</strong></span> The
administrator should be able to scan the file system for any newly
installed packages.</p>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-requirements-sub-admin-intf" id="apm-requirements-sub-admin-intf"></a>Requirements: The Sub-Site
Administrator&#39;s Interface</h3></div></div></div><p>If the developer is in charge of creating packages and the
administrator for installing them, then the sub-site administrator
is responsible for configuring and enabling packages. In order for
a package to be available for a sub-site it must be associated with
the sub-site&#39;s type specification. This interface is part of
the sub-site /admin interface.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>
<span class="strong"><strong>4.300</strong></span> Creating a
package instance.</p><p>
<span class="strong"><strong>4.300.1</strong></span> From the
sub-site /admin interface, there should be an option to view all
packages available in the system as well as an option to add a
package to the subsite.</p><p>
<span class="strong"><strong>4.300.5</strong></span> From the
"add" option, the sub-admin can select from a list of
packages registered as available in the sub-site type to which the
sub-site belongs.</p><p>
<span class="strong"><strong>4.300.19</strong></span> Once a
package instance is added, it is available on the list of the
subsite&#39;s available packages.</p>
</li><li class="listitem">
<p>
<span class="strong"><strong>4.305</strong></span> Configuring a
package instance.</p><p>
<span class="strong"><strong>4.305.1</strong></span> An
automatic web interface that lists all parameters with current
values must be available.</p><p>
<span class="strong"><strong>4.305.5</strong></span> Changing
the values for the parameters is accomplished simply by submitting
an HTML form.</p>
</li><li class="listitem">
<p>
<span class="strong"><strong>4.310</strong></span> Enabling a
package instance.</p><p>
<span class="strong"><strong>4.310.1</strong></span> The
sub-admin should be able to enable a package with a single click.
Enabling a package means that the OpenACS will serve its URLs
properly.</p>
</li><li class="listitem">
<p>
<span class="strong"><strong>4.315</strong></span> Disabling a
package instance.</p><p>
<span class="strong"><strong>4.315.1</strong></span> The
sub-admin should be able to disable a package with a single click.
Disabling a package means that the OpenACS will no longer serve
those URLs.</p>
</li><li class="listitem">
<p>
<span class="strong"><strong>4.320</strong></span> Deleting a
package instance.</p><p>
<span class="strong"><strong>4.320.1</strong></span> Deleting a
package instance involves deleting not only the package instance,
but any and all content associated with it. It is questionable
whether this option should even be available due to its drastic
consequences. Reviewer comments appreciated.</p>
</li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-requirements-implementation" id="apm-requirements-implementation"></a>Implementation notes</h3></div></div></div><p>Despite the fact that requirements are meant to be
design/implementation neutral, the following thoughts were in our
head when specifying these requirements. You must be familiar with
the new object design for this to be comprehensible.</p><p>When a package is installed system-wide, a corresponding
acs_object_type is created for it. All parameters registered for
the package are registered for that acs_object_type.</p><p>When a package instance is created, it is an acs_object. Its
parameters are set using the acs_attribute_values table. The
automatic web interface for setting package parameters should be
one and the same with the interface for setting acs object
attribute values. Consequently, the implementation of these
features should be quite straightforward.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="apm-requirements-rev-history" id="apm-requirements-rev-history"></a>Revision History</h3></div></div></div><div class="informaltable"><table class="informaltable" cellspacing="0" border="1">
<colgroup>
<col><col><col><col>
</colgroup><tbody>
<tr>
<td><span class="strong"><strong>Document Revision
#</strong></span></td><td><span class="strong"><strong>Action Taken,
Notes</strong></span></td><td><span class="strong"><strong>When?</strong></span></td><td><span class="strong"><strong>By Whom?</strong></span></td>
</tr><tr>
<td>0.1</td><td>Creation</td><td>8/10/2000</td><td>Bryan Quinn, Todd Nightingale</td>
</tr><tr>
<td></td><td>Reviewed</td><td>8/11/2000</td><td>John Prevost, Mark Thomas, and Pete Su</td>
</tr><tr>
<td>0.2</td><td>Revised and updated</td><td>8/12/2000</td><td>Bryan Quinn</td>
</tr><tr>
<td>0.3</td><td>Reviewed, revised, and updated - conforms to requirements
template.</td><td>8/18/2000</td><td>Kai Wu</td>
</tr><tr>
<td>0.4</td><td>Minor edits before ACS 4 Beta.</td><td>9/30/2000</td><td>Kai Wu</td>
</tr>
</tbody>
</table></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="subsites-design" leftLabel="Prev" leftTitle="Subsites Design Document"
		    rightLink="apm-design" rightLabel="Next" rightTitle="Package Manager Design"
		    homeLink="index" homeLabel="Home" 
		    upLink="kernel-doc" upLabel="Up"> 
		