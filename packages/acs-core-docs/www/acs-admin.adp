
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Part II. Administrator&#39;s
Guide}</property>
<property name="doc(title)">Part II. Administrator&#39;s
Guide</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="release-notes" leftLabel="Prev"
		    title=""
		    rightLink="install-overview" rightLabel="Next">
		<div class="part">
<div class="titlepage"><div><div><h1 class="title">
<a name="acs-admin" id="acs-admin"></a>Part II. Administrator&#39;s
Guide</h1></div></div></div><div class="toc">
<p><strong>Table of Contents</strong></p><dl class="toc">
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
</dl>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="release-notes" leftLabel="Prev" leftTitle="OpenACS Release Notes"
		    rightLink="install-overview" rightLabel="Next" rightTitle="
Chapter 2. Installation Overview"
		    homeLink="index" homeLabel="Home" 
		    upLink="index" upLabel="Up"> 
		