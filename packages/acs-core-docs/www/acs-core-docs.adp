
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {OpenACS Core Documentation}</property>
<property name="doc(title)">OpenACS Core Documentation</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="" leftLabel=""
		    title=""
		    rightLink="for-everyone" rightLabel="Next">
		<div class="book">
<div class="titlepage">
<div><div><h1 class="title">
<a name="idp140198977745328" id="idp140198977745328"></a>OpenACS Core Documentation</h1></div></div><hr>
</div><div class="toc">
<p><strong>Table of Contents</strong></p><dl class="toc">
<dt><span class="part"><a href="for-everyone">I. OpenACS For
Everyone</a></span></dt><dd><dl>
<dt><span class="chapter"><a href="general-documents">1. High
level information: What is OpenACS?</a></span></dt><dd><dl>
<dt><span class="sect1"><a href="openacs-overview">Overview</a></span></dt><dt><span class="sect1"><a href="release-notes">OpenACS
Release Notes</a></span></dt>
</dl></dd>
</dl></dd><dt><span class="part"><a href="acs-admin">II.
Administrator&#39;s Guide</a></span></dt><dd><dl>
<dt><span class="chapter"><a href="install-overview">2.
Installation Overview</a></span></dt><dd><dl>
<dt><span class="sect1"><a href="install-steps">Basic
Steps</a></span></dt><dt><span class="sect1"><a href="individual-programs">Prerequisite Software</a></span></dt>
</dl></dd><dt><span class="chapter"><a href="complete-install">3.
Complete Installation</a></span></dt><dd><dl>
<dt><span class="sect1"><a href="unix-installation">Install a
Unix-like system and supporting software</a></span></dt><dt><span class="sect1"><a href="oracle">Install Oracle
8.1.7</a></span></dt><dt><span class="sect1"><a href="postgres">Install
PostgreSQL</a></span></dt><dt><span class="sect1"><a href="aolserver4">Install AOLserver
4</a></span></dt><dt><span class="sect1"><a href="openacs">Install OpenACS
5.9.0</a></span></dt><dt><span class="sect1"><a href="win2k-installation">OpenACS
Installation Guide for Windows</a></span></dt><dt><span class="sect1"><a href="mac-installation">OpenACS
Installation Guide for Mac OS X</a></span></dt>
</dl></dd><dt><span class="chapter"><a href="configuring-new-site">4.
Configuring a new OpenACS Site</a></span></dt><dd><dl>
<dt><span class="sect1"><a href="configuring-install-packages">Installing OpenACS
packages</a></span></dt><dt><span class="sect1"><a href="configuring-mounting-packages">Mounting OpenACS
packages</a></span></dt><dt><span class="sect1"><a href="configuring-configuring-packages">Configuring an OpenACS
package</a></span></dt><dt><span class="sect1"><a href="configuring-configuring-permissions">Setting Permissions on
an OpenACS package</a></span></dt><dt><span class="sect1"><a href="how-do-I">How Do
I?</a></span></dt>
</dl></dd><dt><span class="chapter"><a href="upgrade">5.
Upgrading</a></span></dt><dd><dl>
<dt><span class="sect1"><a href="upgrade-overview">Overview</a></span></dt><dt><span class="sect1"><a href="upgrade-4.5-to-4.6">Upgrading
4.5 or higher to 4.6.3</a></span></dt><dt><span class="sect1"><a href="upgrade-4.6.3-to-5">Upgrading
OpenACS 4.6.3 to 5.0</a></span></dt><dt><span class="sect1"><a href="upgrade-5-0-dot">Upgrading an
OpenACS 5.0.0 or greater installation</a></span></dt><dt><span class="sect1"><a href="upgrade-openacs-files">Upgrading the OpenACS
files</a></span></dt><dt><span class="sect1"><a href="upgrade-supporting">Upgrading
Platform components</a></span></dt>
</dl></dd><dt><span class="chapter"><a href="maintenance-web">6.
Production Environments</a></span></dt><dd><dl>
<dt><span class="sect1"><a href="install-openacs-keepalive">Starting and Stopping an OpenACS
instance.</a></span></dt><dt><span class="sect1"><a href="install-openacs-inittab">AOLserver keepalive with
inittab</a></span></dt><dt><span class="sect1"><a href="install-next-add-server">Running multiple services on one
machine</a></span></dt><dt><span class="sect1"><a href="high-avail">High
Availability/High Performance Configurations</a></span></dt><dt><span class="sect1"><a href="maintenance-deploy">Staged
Deployment for Production Networks</a></span></dt><dt><span class="sect1"><a href="install-ssl">Installing SSL
Support for an OpenACS service</a></span></dt><dt><span class="sect1"><a href="analog-setup">Set up Log
Analysis Reports</a></span></dt><dt><span class="sect1"><a href="uptime">External uptime
validation</a></span></dt><dt><span class="sect1"><a href="maint-performance">Diagnosing
Performance Problems</a></span></dt>
</dl></dd><dt><span class="chapter"><a href="database-management">7.
Database Management</a></span></dt><dd><dl>
<dt><span class="sect1"><a href="remote-postgres">Running a
PostgreSQL database on another server</a></span></dt><dt><span class="sect1"><a href="install-openacs-delete-tablespace">Deleting a
tablespace</a></span></dt><dt><span class="sect1"><a href="install-next-nightly-vacuum">Vacuum Postgres
nightly</a></span></dt>
</dl></dd><dt><span class="chapter"><a href="backup-recovery">8. Backup
and Recovery</a></span></dt><dd><dl>
<dt><span class="sect1"><a href="install-next-backups">Backup
Strategy</a></span></dt><dt><span class="sect1"><a href="snapshot-backup">Manual
backup and recovery</a></span></dt><dt><span class="sect1"><a href="automated-backup">Automated
Backup</a></span></dt><dt><span class="sect1"><a href="backups-with-cvs">Using CVS
for backup-recovery</a></span></dt>
</dl></dd><dt><span class="appendix"><a href="install-redhat">A. Install
Red Hat 8/9</a></span></dt><dt><span class="appendix"><a href="install-more-software">B.
Install additional supporting software</a></span></dt><dd><dl>
<dt><span class="sect1"><a href="openacs-unpack">Unpack the
OpenACS tarball</a></span></dt><dt><span class="sect1"><a href="install-cvs">Initialize CVS
(OPTIONAL)</a></span></dt><dt><span class="sect1"><a href="psgml-for-emacs">Add PSGML
commands to emacs init file (OPTIONAL)</a></span></dt><dt><span class="sect1"><a href="install-daemontools">Install
Daemontools (OPTIONAL)</a></span></dt><dt><span class="sect1"><a href="install-qmail">Install qmail
(OPTIONAL)</a></span></dt><dt><span class="sect1"><a href="analog-install">Install
Analog web file analyzer</a></span></dt><dt><span class="sect1"><a href="install-nspam">Install
nspam</a></span></dt><dt><span class="sect1"><a href="install-full-text-search-tsearch2">Install Full Text Search
using Tsearch2</a></span></dt><dt><span class="sect1"><a href="install-full-text-search-openfts">Install Full Text Search
using OpenFTS (deprecated see tsearch2)</a></span></dt><dt><span class="sect1"><a href="install-nsopenssl">Install
nsopenssl</a></span></dt><dt><span class="sect1"><a href="install-tclwebtest">Install
tclwebtest.</a></span></dt><dt><span class="sect1"><a href="install-php">Install PHP for
use in AOLserver</a></span></dt><dt><span class="sect1"><a href="install-squirrelmail">Install
Squirrelmail for use as a webmail system for
OpenACS</a></span></dt><dt><span class="sect1"><a href="install-pam-radius">Install
PAM Radius for use as external authentication</a></span></dt><dt><span class="sect1"><a href="install-ldap-radius">Install
LDAP for use as external authentication</a></span></dt><dt><span class="sect1"><a href="aolserver">Install AOLserver
3.3oacs1</a></span></dt>
</dl></dd><dt><span class="appendix"><a href="credits">C.
Credits</a></span></dt><dd><dl>
<dt><span class="section"><a href="install-origins">Where did
this document come from?</a></span></dt><dt><span class="section"><a href="os-install">Linux Install
Guides</a></span></dt><dt><span class="section"><a href="os-security">Security
Information</a></span></dt><dt><span class="section"><a href="install-resources">Resources</a></span></dt>
</dl></dd>
</dl></dd><dt><span class="part"><a href="acs-package-dev">III. For
OpenACS Package Developers</a></span></dt><dd><dl>
<dt><span class="chapter"><a href="tutorial">9. Development
Tutorial</a></span></dt><dd><dl>
<dt><span class="sect1"><a href="tutorial-newpackage">Creating
an Application Package</a></span></dt><dt><span class="sect1"><a href="tutorial-database">Setting Up
Database Objects</a></span></dt><dt><span class="sect1"><a href="tutorial-pages">Creating Web
Pages</a></span></dt><dt><span class="sect1"><a href="tutorial-debug">Debugging and
Automated Testing</a></span></dt>
</dl></dd><dt><span class="chapter"><a href="tutorial-advanced">10.
Advanced Topics</a></span></dt><dd><dl>
<dt><span class="sect1"><a href="tutorial-specs">Write the
Requirements and Design Specs</a></span></dt><dt><span class="sect1"><a href="tutorial-cvs">Add the new
package to CVS</a></span></dt><dt><span class="sect1"><a href="tutorial-etp-templates">OpenACS Edit This Page
Templates</a></span></dt><dt><span class="sect1"><a href="tutorial-comments">Adding
Comments</a></span></dt><dt><span class="sect1"><a href="tutorial-admin-pages">Admin
Pages</a></span></dt><dt><span class="sect1"><a href="tutorial-categories">Categories</a></span></dt><dt><span class="sect1"><a href="profile-code">Profile your
code</a></span></dt><dt><span class="sect1"><a href="tutorial-distribute">Prepare
the package for distribution.</a></span></dt><dt><span class="sect1"><a href="tutorial-upgrades">Distributing upgrades of your
package</a></span></dt><dt><span class="sect1"><a href="tutorial-notifications">Notifications</a></span></dt><dt><span class="sect1"><a href="tutorial-hierarchical">Hierarchical data</a></span></dt><dt><span class="sect1"><a href="tutorial-vuh">Using .vuh
files for pretty urls</a></span></dt><dt><span class="sect1"><a href="tutorial-css-layout">Laying
out a page with CSS instead of tables</a></span></dt><dt><span class="sect1"><a href="tutorial-html-email">Sending
HTML email from your application</a></span></dt><dt><span class="sect1"><a href="tutorial-caching">Basic
Caching</a></span></dt><dt><span class="sect1"><a href="tutorial-schedule-procs">Scheduled Procedures</a></span></dt><dt><span class="sect1"><a href="tutorial-wysiwyg-editor">Enabling WYSIWYG</a></span></dt><dt><span class="sect1"><a href="tutorial-parameters">Adding
in parameters for your package</a></span></dt><dt><span class="sect1"><a href="tutorial-upgrade-scripts">Writing upgrade
scripts</a></span></dt><dt><span class="sect1"><a href="tutorial-second-database">Connect to a second
database</a></span></dt><dt><span class="sect1"><a href="tutorial-future-topics">Future Topics</a></span></dt>
</dl></dd><dt><span class="chapter"><a href="dev-guide">11. Development
Reference</a></span></dt><dd><dl>
<dt><span class="sect1"><a href="packages">OpenACS
Packages</a></span></dt><dt><span class="sect1"><a href="objects">OpenACS Data Models
and the Object System</a></span></dt><dt><span class="sect1"><a href="request-processor">The
Request Processor</a></span></dt><dt><span class="sect1"><a href="db-api">The OpenACS Database
Access API</a></span></dt><dt><span class="sect1"><a href="templates">Using Templates in
OpenACS</a></span></dt><dt><span class="sect1"><a href="permissions">Groups, Context,
Permissions</a></span></dt><dt><span class="sect1"><a href="subsites">Writing OpenACS
Application Pages</a></span></dt><dt><span class="sect1"><a href="parties">Parties in
OpenACS</a></span></dt><dt><span class="sect1"><a href="permissions-tediously-explained">OpenACS Permissions
Tediously Explained</a></span></dt><dt><span class="sect1"><a href="object-identity">Object
Identity</a></span></dt><dt><span class="sect1"><a href="programming-with-aolserver">Programming with
AOLserver</a></span></dt><dt><span class="sect1"><a href="form-builder">Using Form
Builder: building html forms dynamically</a></span></dt>
</dl></dd><dt><span class="chapter"><a href="eng-standards">12.
Engineering Standards</a></span></dt><dd><dl>
<dt><span class="sect1"><a href="style-guide">OpenACS Style
Guide</a></span></dt><dt><span class="sect1"><a href="cvs-guidelines">CVS
Guidelines</a></span></dt><dt><span class="sect1"><a href="eng-standards-versioning">Release Version
Numbering</a></span></dt><dt><span class="sect1"><a href="eng-standards-constraint-naming">Constraint naming
standard</a></span></dt><dt><span class="sect1"><a href="eng-standards-filenaming">ACS
File Naming and Formatting Standards</a></span></dt><dt><span class="sect1"><a href="eng-standards-plsql">PL/SQL
Standards</a></span></dt><dt><span class="sect1"><a href="variables">Variables</a></span></dt><dt><span class="sect1"><a href="automated-testing-best-practices">Automated
Testing</a></span></dt>
</dl></dd><dt><span class="chapter"><a href="doc-standards">13.
Documentation Standards</a></span></dt><dd><dl>
<dt><span class="sect1"><a href="docbook-primer">OpenACS
Documentation Guide</a></span></dt><dt><span class="sect1"><a href="psgml-mode">Using PSGML mode
in Emacs</a></span></dt><dt><span class="sect1"><a href="nxml-mode">Using nXML mode in
Emacs</a></span></dt><dt><span class="sect1"><a href="filename">Detailed Design
Documentation Template</a></span></dt><dt><span class="sect1"><a href="requirements-template">System/Application Requirements
Template</a></span></dt>
</dl></dd><dt><span class="chapter"><a href="i18n">14.
Internationalization</a></span></dt><dd><dl>
<dt><span class="sect1"><a href="i18n-overview">Internationalization and Localization
Overview</a></span></dt><dt><span class="sect1"><a href="i18n-introduction">How
Internationalization/Localization works in OpenACS</a></span></dt><dt><span class="sect1"><a href="i18n-convert">How to
Internationalize a Package</a></span></dt><dt><span class="sect1"><a href="i18n-design">Design
Notes</a></span></dt><dt><span class="sect1"><a href="i18n-translators">Translator&#39;s Guide</a></span></dt>
</dl></dd><dt><span class="appendix"><a href="cvs-tips">D. Using CVS
with an OpenACS Site</a></span></dt>
</dl></dd><dt><span class="part"><a href="acs-plat-dev">IV. For OpenACS
Platform Developers</a></span></dt><dd><dl>
<dt><span class="chapter"><a href="kernel-doc">15. Kernel
Documentation</a></span></dt><dd><dl>
<dt><span class="sect1"><a href="kernel-overview">Overview</a></span></dt><dt><span class="sect1"><a href="object-system-requirements">Object Model
Requirements</a></span></dt><dt><span class="sect1"><a href="object-system-design">Object
Model Design</a></span></dt><dt><span class="sect1"><a href="permissions-requirements">Permissions
Requirements</a></span></dt><dt><span class="sect1"><a href="permissions-design">Permissions Design</a></span></dt><dt><span class="sect1"><a href="groups-requirements">Groups
Requirements</a></span></dt><dt><span class="sect1"><a href="groups-design">Groups
Design</a></span></dt><dt><span class="sect1"><a href="subsites-requirements">Subsites Requirements</a></span></dt><dt><span class="sect1"><a href="subsites-design">Subsites
Design Document</a></span></dt><dt><span class="sect1"><a href="apm-requirements">Package
Manager Requirements</a></span></dt><dt><span class="sect1"><a href="apm-design">Package Manager
Design</a></span></dt><dt><span class="sect1"><a href="db-api-detailed">Database
Access API</a></span></dt><dt><span class="sect1"><a href="i18n-requirements">OpenACS
Internationalization Requirements</a></span></dt><dt><span class="sect1"><a href="security-requirements">Security Requirements</a></span></dt><dt><span class="sect1"><a href="security-design">Security
Design</a></span></dt><dt><span class="sect1"><a href="security-notes">Security
Notes</a></span></dt><dt><span class="sect1"><a href="rp-requirements">Request
Processor Requirements</a></span></dt><dt><span class="sect1"><a href="rp-design">Request Processor
Design</a></span></dt><dt><span class="sect1"><a href="tcl-doc">Documenting Tcl
Files: Page Contracts and Libraries</a></span></dt><dt><span class="sect1"><a href="bootstrap-acs">Bootstrapping
OpenACS</a></span></dt><dt><span class="sect1"><a href="ext-auth-requirements">External Authentication
Requirements</a></span></dt>
</dl></dd><dt><span class="chapter"><a href="releasing-openacs">16.
Releasing OpenACS</a></span></dt><dd><dl>
<dt><span class="section"><a href="releasing-openacs-core">OpenACS Core and .LRN</a></span></dt><dt><span class="section"><a href="update-repository">How to
Update the OpenACS.org repository</a></span></dt><dt><span class="section"><a href="releasing-package">How to
package and release an OpenACS Package</a></span></dt><dt><span class="section"><a href="update-translations">How to
Update the translations</a></span></dt>
</dl></dd>
</dl></dd><dt><span class="index"><a href="ix01">Index</a></span></dt>
</dl>
</div><div class="list-of-figures">
<p><strong>List of Figures</strong></p><dl>
<dt>4.1. <a href="how-do-I">Site
Templates</a>
</dt><dt>4.2. <a href="how-do-I">Granting
Permissions</a>
</dt><dt>4.3. <a href="how-do-I">Granting
Permissions in 5.0</a>
</dt><dt>5.1. <a href="upgrade-overview">Upgrading with the
APM</a>
</dt><dt>5.2. <a href="upgrade-openacs-files">Upgrading a local
CVS repository</a>
</dt><dt>6.1. <a href="high-avail">Multiple-server
configuration</a>
</dt><dt>6.2. <a href="maintenance-deploy">Simple A/B Deployment
- Step 1</a>
</dt><dt>6.3. <a href="maintenance-deploy">Simple A/B Deployment
- Step 2</a>
</dt><dt>6.4. <a href="maintenance-deploy">Simple A/B Deployment
- Step 3</a>
</dt><dt>6.5. <a href="maintenance-deploy">Complex A/B Deployment
- Step 1</a>
</dt><dt>6.6. <a href="maintenance-deploy">Complex A/B Deployment
- Step 2</a>
</dt><dt>6.7. <a href="maintenance-deploy">Complex A/B Deployment
- Step 3</a>
</dt><dt>6.8. <a href="maint-performance">Query
Analysis example</a>
</dt><dt>8.1. <a href="backup-recovery">Backup
and Recovery Strategy</a>
</dt><dt>9.1. <a href="tutorial-newpackage">Assumptions in this
section</a>
</dt><dt>9.2. <a href="tutorial-database">Tutorial Data
Model</a>
</dt><dt>9.3. <a href="tutorial-database">The
Database Creation Script</a>
</dt><dt>9.4. <a href="tutorial-database">Database Deletion
Script</a>
</dt><dt>9.5. <a href="tutorial-pages">Page
Map</a>
</dt><dt>10.1. <a href="tutorial-cvs">Upgrading
a local CVS repository</a>
</dt><dt>11.1. <a href="packages">Server file
layout diagram</a>
</dt><dt>11.2. <a href="packages">Package file
layout diagram</a>
</dt>
</dl>
</div><div class="list-of-tables">
<p><strong>List of Tables</strong></p><dl>
<dt>2.1. <a href="install-steps">Default
directories for a standard install</a>
</dt><dt>2.2. <a href="individual-programs">Version
Compatibility Matrix</a>
</dt><dt>5.1. <a href="upgrade-overview">Assumptions in this
section</a>
</dt><dt>6.1. <a href="install-openacs-keepalive">How it
Works</a>
</dt><dt>10.1. <a href="tutorial-etp-templates">table showing ETP
layout</a>
</dt><dt>11.1. <a href="packages">Package
files</a>
</dt><dt>11.2. <a href="permissions-tediously-explained">Context
Hierarchy Example</a>
</dt><dt>11.3. <a href="permissions-tediously-explained">acs_objects
example data</a>
</dt><dt>14.1. <a href="i18n-overview">Internationalization and
Localization Overview</a>
</dt>
</dl>
</div><div class="list-of-examples">
<p><strong>List of Examples</strong></p><dl><dt>12.1. <a href="variables">Getting
datetime from the database ANSI-style</a>
</dt></dl>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="" leftLabel="" leftTitle=""
		    rightLink="for-everyone" rightLabel="Next" rightTitle="
Part I. OpenACS For Everyone"
		    homeLink="" homeLabel="" 
		    upLink="" upLabel=""> 
		