
<property name="context">{/doc/acs-core-docs/ {ACS Core Documentation}} {OpenACS Release Notes}</property>
<property name="doc(title)">OpenACS Release Notes</property>
<master>
<style>
div.sect2 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 16px;}
div.sect3 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 6px;}
</style>              
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="openacs-overview" leftLabel="Prev"
			title="Chapter 1. High level
information: What is OpenACS?"
			rightLink="acs-admin" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="release-notes" id="release-notes"></a>OpenACS Release Notes</h2></div></div></div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-10-1" id="release-notes-5-10-1"></a>Release 5.10.1</h3></div></div></div><p>The release of OpenACS 5.10.1 contains the 94 packages of the
oacs-5-10 branch. These packages include the OpenACS core packages,
the major application packages (e.g., most of the ones used on
OpenACS.org), and DotLRN 2.10.1. The release is probably the most
secure and with the most tested code since ever.</p><p>Altogether, OpenACS 5.10.1 differs from OpenACS 5.10.0 by the
following statistics</p><pre class="programlisting">
        3038 files changed, 1291141 insertions(+), 354533 deletions(-)</pre><p>These changes were contributed by 8 committers (Antonio Pisano,
Gustaf Neumann, Günter Ernst, Héctor Romojaro, Michael Aram, Raúl
Rodríguez, Sebastian Scheder, and Thomas Renner) and additional 8
patch/bugfix providers (Felix Mödritscher, Frank Bergmann, Franz
Penz, Josue Cardona, Keith Paskett, Markus Moser, Marty Israelsen,
and Monika Andergassen) - all sorted by the first names.</p><p>In terms of changes, the release contains the largest amount of
changes of the releases in the last 10 years. The packages with the
most changes are <code class="literal">acs-tcl</code>, <code class="literal">acs-templating</code>, <code class="literal">xowiki</code>, <code class="literal">xowf</code>,
<code class="literal">acs-automated-testing</code>, <code class="literal">acs-admin</code>, and <code class="literal">xotcl-core</code>.</p><p>Below is a summary of the most important changes, often together
with the commit references in Git. The summary was made on
subjective criteria. For all details, consult the <a class="ulink" href="http://openacs.org/changelogs/ChangeLog-5.10.1" target="_top">raw ChangeLog</a>.</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="changes-in-the-acs-core-packages-between-openacs-5.10.0-and-5.10.1" id="changes-in-the-acs-core-packages-between-openacs-5.10.0-and-5.10.1"></a>Changes in the acs-core packages between OpenACS 5.10.0 and
5.10.1</h3></div></div></div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="new-features" id="new-features"></a>New
Features</h4></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>
<span class="strong"><strong>Security and Privacy Posture
Overview</strong></span>: As expressed as a wish from OpenACS users
at the last OpenACS conference, a <span class="quote">“<span class="quote">Security and Privacy Posture Overview</span>”</span> was
added that offers a quick overview of the state of the system and
eases access to the parameters scattered over different packages in
the system. The page offers:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Quick overview</li><li class="listitem">Check of security and privacy relevant package
parameters</li><li class="listitem">Permission and accessibility check of mounted
packages</li><li class="listitem">Response header check</li><li class="listitem">External library check (CDN vs local usage,
vulnerable or outdated libraries) The page is linked from the
site-wide-admin page (<code class="literal">/acs-admin</code>).</li>
</ul></div>
</li><li class="listitem"><p>
<span class="strong"><strong>Stronger Password Hashes for
OpenACS</strong></span> (commit fe2bdb547, 8eee6a932, 52d2c997e,
62d969c85): Introduction of new password hash functions alongside
the pre-existing <span class="quote">“<span class="quote">salted-sha1</span>”</span>. The new algorithms are named
<span class="quote">“<span class="quote">scram-sha-256</span>”</span>, <span class="quote">“<span class="quote">scrypt-16384-8-1</span>”</span>,
<span class="quote">“<span class="quote">argon2-argon2-12288-3-1</span>”</span>, <span class="quote">“<span class="quote">argon2-rfc9106-high-mem</span>”</span>, and <span class="quote">“<span class="quote">argon2-rfc9106-low-mem</span>”</span>.
These algorithms can be specified via the kernel package parameter
<span class="quote">“<span class="quote">PasswordHashAlgorithm</span>”</span>. The algorithms
require a recent version of NaviServer and a recent version of
OpenSSL, which serves as a crypto library. This feature enhances
security against brute-force attacks on password hashes (when db is
compromised). Preferences of the password hash algorithms can be
set via kernel package parameter <span class="quote">“<span class="quote">PasswordHashAlgorithm</span>”</span>, the first available
algorithm is taken from the preference list, hash re-coding happens
automatically at the next login.</p></li><li class="listitem"><p>
<span class="strong"><strong>Setting of CSP rules based on MIME
types</strong></span> (commit 6bc253f1e, commit 94b8513ae). This is
necessary to mitigate certain attacks on static SVG files uploaded
to, e.g., the content repository. For example, set the following to
the <code class="literal">ns/server/$server/acs</code> section of
your NaviServer configuration file:</p></li>
</ul></div><pre class="programlisting">
        ns_param StaticCSP {
            image/svg+xml "script-src 'none'"
        }
</pre><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>
<span class="strong"><strong>Support for generic icon
names</strong></span> Support for generic icon names, which can be
mapped differently depending on the installed packages and themes.
The support provides a mapping from a set of generic names to the
names provided by different libraries sich as Glyph Icons,
Bootstrap Icons, Font-Awsome. The provided support can be inspected
on the site-wide page of <code class="literal">acs-templating</code>.</p><p>The generic names can be used via the special tag <code class="computeroutput">&lt;adp:icon name="NAME"
title=....&gt;</code> in .adp-files. By using this feature, one can
use font-based icons (like e.g. glyphicons of Bootstrap5,
bootstrap-icons, fa-icons, ...) instead of the old-style .gif and
.png images. This makes the appearance more uniform, has better
resizing behavior, and works more efficiently (fewer requests for
embedded resources). Most of the occurrences of the old-style
images in standard core and non-core packages in oacs-5-10 are
already replaced. (commit c129c89ec, 996740672, e9cae22dc,
c7705c68b, a85ea7301, 58ad43055, 737da5514, a05813ec7, 110b2f5d6,
7011c8fd9, 286fd9e58, 927d9d5ef)</p>
</li><li class="listitem"><p>
<span class="strong"><strong>Better Automated Site
Configurability</strong></span>: Support for installing themes from
<code class="literal">install.xml</code> (commit 2f9761160).</p></li><li class="listitem"><p>
<span class="strong"><strong>Dynamic Cluster Nodes and Cluster
Infrastructure</strong></span> (commit 5738761db, 7cbc3e63c,
1a7a7656c, 3faceddc4, 5fba13c0f, 7cbc3e63c, 3faceddc4, 1a7a7656c):
Added support for dynamically adding and removal of nodes in an
OpenACS cluster. In contrast to static cluster nodes, the IP
addresses of dynamic cluster nodes do not have to be provided at
startup time. The changes introduce new admin pages and further
configuration options.</p></li><li class="listitem"><p>
<span class="strong"><strong>Optional Caching
Deactivation</strong></span> (commit 75c3f2b25): It is possible to
deactivate caching via the <code class="literal">ns_cache</code>
infrastructure when the NaviServer configuration variable
<code class="literal">cachingmode</code> is set to <code class="literal">none</code>. The change modifies <code class="literal">per_thread_cache</code> to behave like a <code class="literal">per_connection_cache</code>. This option is useful for
cluster configurations, when legacy components do not handle cache
coherency (e.g. via <code class="literal">acs::clusterwide</code>)</p></li><li class="listitem"><p>
<span class="strong"><strong>Support for Cloud Identity
Providers</strong></span> (commit e506dee05, fd7af8d17, 06954d83b).
Additional Identity providers can be added as secondary registries
(e.g., MS Azure via oauth2), to support e.g. logins via the
classical <code class="literal">register</code> page and via a
cloud registry (requires package xooauth for full
functionality)</p></li><li class="listitem"><p>
<span class="strong"><strong>Client-side double click
prevention</strong></span>: This change makes it possible to
provide a double click prevention for HTML elements via the CSS
class <span class="quote">“<span class="quote">prevent-double-click</span>”</span>. The double click
prevention deactivates a button or an anchor element after clicking
for a short time (per default for 1s) and ignores in this time
window further clicks. The time window can be specified via the
data element oacs-timeout. (commit 5f2edeec2a9a831,
916d365aa11f2d)</p></li><li class="listitem"><p>
<span class="strong"><strong>Cookie Namespaces</strong></span>
(commit ce1573ed8): Important, when multiple OpenACS instances are
served from the same domain name, but different cookies have to be
used.</p></li>
</ul></div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="reforms" id="reforms"></a>Reforms</h4></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<code class="literal">lc_time_tz_convert</code>: Enforce ISO format for dates
and other changes (commit 9a5b5cd97).</li><li class="listitem">
<code class="literal">template::element</code>
validation reform to improve validation on fields (commit
87919f923).</li><li class="listitem">Provide timeouts for caching operations to
improve liveliness also when certain calls are hanging (commit
22cd530d4).</li><li class="listitem">Form widget attributes reform consolidating
logics for merging tag attributes (commit 3a7fc6a8e).</li><li class="listitem"><p>Streamlined resource_info handling by adding versioning and
better management of external library dependencies. External
libraries can be used from CDN or downloaded, the versions are
checked for vulnerabilities, which are reported via posture
overview and package-specific site-wide admin pages.</p></li>
</ul></div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="configuration-changes" id="configuration-changes"></a>Configuration Changes</h4></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Set the (default) theme package on the subsite
upon installation (commit 0ff7101b3).</li><li class="listitem">Improved clusterwide operations with new
configuration parameters (commit 5738761db).</li><li class="listitem">New configuration options <code class="literal">CSSToolkit</code> and <code class="literal">IconSet</code> for <code class="literal">acs-subsite</code> (commit fc56a275b).</li><li class="listitem">Support specification of allowed
tags/attributes/protocols via global package parameters (commit
657cef99a,fc46466e3).</li><li class="listitem">Made <code class="literal">ad_html_security_check</code> configurable (commit
bc63ee424).</li><li class="listitem">Support for memory units as default cache
sizes (commit 68c853abd).</li>
</ul></div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="bug-fixes" id="bug-fixes"></a>Bug
Fixes</h4></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Fixed missing <code class="literal">update_content-lob.set_content</code> (commit a3effac23,
4ce8e9fae).</li><li class="listitem">Fixed incorrect HTTP status code on result
page (commit 636226cb2).</li><li class="listitem">Fixed signature of service contract
implementation (commit b9f0c541c).</li><li class="listitem">Fixed implementation of <code class="literal">ad_acs_admin_node</code> (commit 34a823c51).</li><li class="listitem">Fixed reference in doc (commit
e596b46f8).</li><li class="listitem">Fixed <code class="literal">ad_approval_system_inuse_p</code> implementation (commit
bd8afdeeb).</li><li class="listitem">Fixed self-inflicted bug in form variable
specification (commit 79e6df943).</li><li class="listitem">Fixed a bug in <code class="literal">db_multirow_group_last_row_p</code> (commit
aafd1db58).</li><li class="listitem">Fixed issue with <code class="literal">ns_parseurl</code> in <code class="literal">util::split_location</code> (commit aee571ad1).</li><li class="listitem">Various fixes for Oracle 19c compatibility
issues (numerous commits).</li><li class="listitem">Fixed broken function_args definition and
other issues (commit 83e45f9b5, d166927d2, etc.).</li><li class="listitem">Fixed a bug in <code class="literal">db_driverkey</code> when OpenACS connects to multiple
databases, involving the removal of per-thread caching (commit
18e656b00).</li><li class="listitem">Fixed and generalized <code class="literal">version_dir</code> handling for download of external
resources (commit 8e9a6a5c8).</li><li class="listitem">Fixed selector for click all list callback in
core.js (commit 00b9db614).</li><li class="listitem">Fixed a bug in <code class="literal">db_foreach</code> with <code class="literal">-column_set</code> flag (commit 95e8970d7).</li><li class="listitem">Handle null dates in core.js (commit
1dd928238).</li><li class="listitem">Fixed issues in SQL function calling to avoid
incorrect function selection due to typecasting issues (commit
bc33e9938).</li><li class="listitem">Corrected problems with session handling in
cluster mode and fixed cache coherency issues in clustered
environments (commit c0a1cf7b9).</li>
</ul></div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="improvements" id="improvements"></a>Improvements</h4></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<span class="strong"><strong>Security
Improvements</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">In addition to the new security features
mentioned above, the new release was tested several times by
different vulnerability scanners, which triggered a large number of
changes as for example strengthening the input tests in page
contracts, consequent use of bind variables and permission
checks.</li><li class="listitem">New API <code class="literal">ad_mktmpdir</code> and <code class="literal">ad_opentmpfile</code> (commit a10b55d3d).</li><li class="listitem">Added support for elliptic curve certificates
(ecdsa) when the lets-encrypt module from NaviServer is used
(commit 2c40f1d9d).</li><li class="listitem">Hardened page contracts, added many
constraints to address potential SQI and XQL etc. attacks (many
commits, e.g. 8eee6a932, d4846d106)</li><li class="listitem">Warn warning when <code class="literal">parametersecret</code> is not set (commit
0ec8f0183).</li><li class="listitem">Safe creation of temporary directories (commit
d25ff6593).</li><li class="listitem">Upgraded internal use of JavaScript and HTML
standards to improve security and performance (commit
e68a73c92).</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Performance
Improvements</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">New partial index for a common query in
acs-tcl (commit aaaf86adb).</li><li class="listitem">Implemented <code class="literal">ad_html_security_check</code> based on <code class="literal">ns_parsehtml</code> (commit 387f3de3e).</li><li class="listitem">Added support for NaviServer built-in
<code class="literal">ns_trim -prefix</code> (commit
500099e0).</li><li class="listitem">Change in storing and displaying util user
messages (commit bb0702bf3).</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Additional
Filters for Page Contracts</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Introduced <code class="literal">ad_page_contract</code> filter object type (commit
2f9d127a0).</li><li class="listitem">Introduced a new <code class="literal">clock</code> page contract filter (commit
5544faffc).</li><li class="listitem">Introduced new <code class="literal">tmpfile</code> page contract filter (commit
1a179e9bc).</li><li class="listitem">Allow more characters in argument specs
(commit f952d9d5e).</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Code
Refactoring</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Added a new procedure <code class="literal">ad_log_deprecated</code> for unified logging of
deprecated usages (commit 0e03b3358).</li><li class="listitem">Improved configurability of LockfreeCache
(commit 9bc412576).</li><li class="listitem">Reform of site-nodes-procs for improved
clarity and ease of maintenance, esp. Oracle (commit
3fe93032e).</li><li class="listitem">Update of SQL function calls via API, made it
callable during initial bootstrap (commit ad97aa747).</li><li class="listitem">Modernization of idioms and cleanup of
deprecated code (e.g., commit a5c537515, e68a73c92,
1d1ff8c4e).</li><li class="listitem">Improved documentation, localization updates,
and typo fixes (e.g., commit 5c23325a3, f3590415f, 7a97e0ea0).</li><li class="listitem">Phased out outdated procedures and functions
that were superseded by more efficient and secure implementations
(e.g., commit 6272226b6).</li><li class="listitem">Deprecated old APIs that no longer align with
modern security practices or performance standards (commit
cd0af7373).</li><li class="listitem">Removed legacy support for certain outdated
browser features and replaced them with modern alternatives (commit
a1a7c22a7).</li><li class="listitem">Further reduced divergence between Oracle and
Postgres SQL. Target version of Oracle could be 12.*, as Extended
support ends in 2022 (see <a class="ulink" href="https://www.oracle.com/us/support/library/lifetime-support-technology-069183.pdf" target="_top">https://www.oracle.com/us/support/library/lifetime-support-technology-069183.pdf</a>).
This change implies:
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">change <span class="quote">“<span class="quote">limit ... rownum ...</span>”</span> to standard
<span class="quote">“<span class="quote">fetch first
...</span>”</span>
</li><li class="listitem">use Postgres schemas where available for
stored procedures so that they can be invoked with the same Oracle
idiom</li>
</ul></div>
</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Miscellaneous</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Message keys for content repository (commit
2f89a971a).</li><li class="listitem">Make <code class="literal">util::join_location</code> usable for UDP and SMTP
(commit 01b5c0d61).</li><li class="listitem">Zero-dependency implementations of Modal and
Tooltip using CSS and JavaScript (commit db0f52664,
02bfffbb2).</li><li class="listitem">Deprecation of specific functions and APIs in
favor of modern replacements (e.g., commit 4493f07b9, 6db041083,
94c505b01).</li><li class="listitem">Extended API: Introduced new API functions
like <code class="literal">ad_unless_script_abort</code>,
<code class="literal">aa_silence_log_entries</code>, and
<code class="literal">util::json2dict</code> to enhance error
handling and logging cleanliness (commit aeb027aeb, f455d60c6,
e9298cf02).</li><li class="listitem">Expanded timezone data and improved
internationalization features, including better locale management
and updated localization data (commit 828ab0bd4, 47d478bcf).</li><li class="listitem">Added Support for listing registered URNs (per
package on the site-wide admin page of a package, full set on the
adm page of acs-templating)</li><li class="listitem">Added support for relative redirects (commit
867d9441e).</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Regression
Test</strong></span>:
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">The regression test was substantially extended
and in part overworked</li><li class="listitem">The test includes now checks for resource
leaks (tDOM documents and nodes, temporary objects, etc.) and
leaves less garbage in the /tmp directory</li><li class="listitem">For the major packages (core and application
packages), the tests run without reporting errors.</li><li class="listitem">For the tests of the majro packages, the
system.log is now free of error messages (e.g., when handling cases
in the test that are supposed to fail)</li>
</ul></div>
</li>
</ul></div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="version-requirements" id="version-requirements"></a>Version requirements</h4></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Require NaviServer (i.e. drop AOLserver
support). Rationale: AOLserver cannot be compiled with the required
modules with recent Tcl versions. Trying to backport NaviServer
compatibility functions seems to be an overkill for the OpenACS
project.</li><li class="listitem">Bootstrap 3 reached EOL in 2019, Bootstrap 4
had EOL 2022, so we should migrate to Bootstrap 5 (details:
<a class="ulink" href="https://github.com/twbs/release" target="_top">https://github.com/twbs/release</a>)</li><li class="listitem">Require Tcl 8.6.2, XOTcl 2.1, PostgreSQL 12
(PostgreSQL 11 EOL: November 23), tdom 0.9</li><li class="listitem">Support for fresh installations on Oracle 19c
(for details, see: <a class="ulink" href="https://openacs.org/xowiki/oacs-5-10-on-oracle-19c" target="_top">oacs-5-10-on-oracle-19c</a>)</li>
</ul></div>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="application-packages" id="application-packages"></a>Changes in OpenACS Application
Packages</h3></div></div></div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="new-packages" id="new-packages"></a>New
Packages in OpenACS 5.10.1</h4></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">bootstrap-icons</li><li class="listitem">caldav</li><li class="listitem">captcha</li><li class="listitem">fa-icons</li><li class="listitem">highcharts</li><li class="listitem">openacs-bootstrap5-theme</li><li class="listitem"><p>For a description of all packages, see: <a class="ulink" href="https://openacs.org/repository/5-10/" target="_top">https://openacs.org/repository/5-10/</a>
</p></li>
</ul></div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="changes-in-package-attachments" id="changes-in-package-attachments"></a>Changes in package
"attachments"</h4></div></div></div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="improvements-1" id="improvements-1"></a>Improvements</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<span class="strong"><strong>Security
Improvements</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem">Strengthen page contracts (3b9068ad)</li></ul></div>
</li><li class="listitem">
<span class="strong"><strong>Code
Refactoring</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Replace handcrafted HTML icons with new
adp:icon adp tag (f45e6406)</li><li class="listitem">Replace deprecated <code class="literal">util_commify_number,</code> with <code class="literal">lc_numeric</code> (518e1b34)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Miscellaneous</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Document public API (fd5b5e1c)</li><li class="listitem">Improve test suite and cover 100% of public
api (3446f91c, c933a64e)</li>
</ul></div>
</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="deprecations" id="deprecations"></a>Deprecations</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">
<code class="literal">attachments::root_folder_map_p</code> -&gt; duplicates
functionalities of <code class="literal">attachments::root_folder_p</code> (cc3177d1)</li></ul></div>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="changes-in-package-calendar" id="changes-in-package-calendar"></a>Changes in package
"calendar"</h4></div></div></div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="new-features-1" id="new-features-1"></a>New Features</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">
<span class="strong"><strong>Inclusion of
multiple calendars</strong></span> (77f4db84): name calendar forms
in a way that multiple calendars can be embedded on the same page
(relevant in the context of .LRN portlets)</li></ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="bug-fixes-1" id="bug-fixes-1"></a>Bug
Fixes</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Javascript fixes (b1d49bc1)</li><li class="listitem">Fix retrieval of a calendar item when a
connection context is not available (772449b4, a049d806)</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="improvements-2" id="improvements-2"></a>Improvements</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<span class="strong"><strong>Security
Improvements</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Improve/harden input validation (many
commits)</li><li class="listitem">Don’t expose immutable values as hidden
formfields (03e3f2e7, 31955520)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Code
Refactoring</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Replace deprecated API (8e6d01a0,
9cfbf8a1)</li><li class="listitem">Streamline idioms (50c5c2d3)</li><li class="listitem">Replace handcrafted HTML icons with new
adp:icon adp tag (054c46cc, 8bb2cd6f)</li><li class="listitem">Replace custom calendar widget implementation
with native HTML5 form fields and streamline input validation
(6bd30d58, f5118fb4)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Miscellaneous</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Improve spelling in catalog files
(258edac5)</li><li class="listitem">Pass properties to master template as literal
according to best practices (9598e88e)</li><li class="listitem">Improve API documentation (d924a307)</li><li class="listitem">Cleanup vestigial features/dead code (various
commits)</li><li class="listitem">Port of downstream localization
(90dbfa96)</li><li class="listitem">Various typos and formatting improvements</li><li class="listitem">Increase test suite of functionalities and
cover 100% of public api (various commits)</li>
</ul></div>
</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="deprecations-1" id="deprecations-1"></a>Deprecations</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<code class="literal">calendar::adjust_date</code> -&gt; inlined the one
occurrence (fbd97314)</li><li class="listitem">
<code class="literal">calendar::from_sql_datetime</code>, <code class="literal">calendar::make_datetime</code> -&gt; not used upstream,
superseded by modern clock idioms and HTML5 features (bccd1c3a,
7264a2fe)</li><li class="listitem">
<code class="literal">cal_outlook_gmt_sql</code> -&gt; last usage in the
codebase 2002 (1ee22f96)</li><li class="listitem">
<code class="literal">calendar::item::assign_permission</code>. <code class="literal">calendar::assign_permissions</code> -&gt; trivial
wrappers over the permission api (a1ddaed5, f174fd12)</li>
</ul></div>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="changes-in-package-captcha" id="changes-in-package-captcha"></a>Changes in package
"captcha"</h4></div></div></div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="features" id="features"></a>Features</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<span class="strong"><strong>Bot protection
for your form</strong></span> implements template::widget::captcha.
This can be used in forms exposed to the public to hinder automated
bots. Based on the implementation at https://fossil-scm.org/</li><li class="listitem">
<span class="strong"><strong>Scalable</strong></span> a new captcha is
generated fast, from scratch and on the fly</li><li class="listitem">
<span class="strong"><strong>No external
dependencies</strong></span> this package does not require any
external commands or libraries</li>
</ul></div>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="changes-in-package-categories" id="changes-in-package-categories"></a>Changes in package
"categories"</h4></div></div></div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="reforms-1" id="reforms-1"></a>Reforms</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">Mark service contract implementations as
private (efd3b8e5, 886068d3)</li></ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="improvements-3" id="improvements-3"></a>Improvements</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<span class="strong"><strong>Performance
Improvements</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem">Create indices on FK constraints
(e935a857)</li></ul></div>
</li><li class="listitem">
<span class="strong"><strong>Security
Improvements</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Add include contracts where missing (40b5bdc3,
667d9cdf, 5d3fb337)</li><li class="listitem">Strengthen page contracts (1ad80ea6)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Code
Refactoring</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Replace deprecated <code class="literal">template::util::is_true</code> with inline string idiom
(f2604994)</li><li class="listitem">Replace handcrafted HTML icons with new
adp:icon adp tag (035bd73b)</li><li class="listitem">Better qualify command invocation
(a693a8be)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Miscellaneous</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Cleanup and formatting changes (various
commits)</li><li class="listitem">Increase test suite of functionalities and
reach 80.82% coverage of public api (various commits)</li><li class="listitem">Improved documentation of library file and
public API (8da391b1)</li>
</ul></div>
</li>
</ul></div>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="changes-in-package-chat" id="changes-in-package-chat"></a>Changes in package
"chat"</h4></div></div></div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="new-features-2" id="new-features-2"></a>New Features</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<span class="strong"><strong>Anonymous chat
participants</strong></span> (3a73986c, 214684f3): use newly
introduced support for anonymous users built in xowiki to support
not logged-in users</li><li class="listitem">
<span class="strong"><strong>Chat
include</strong></span> (c2ab5967) : Move the main chat rendering
in an include to allow reuse in other contexts</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="bug-fixes-2" id="bug-fixes-2"></a>Bug
Fixes</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Fix typo in datamodel code affecting new
installations (98d26cfa)</li><li class="listitem">Improve/fix Oracle compatibility (d3e0d69b,
cb2e52d0, 04e229f2)</li><li class="listitem">Allow for arbitrary arguments to be passed
when extending inherited methods (95ca0c0e)</li><li class="listitem">Allow to persist chat messages also in the
chat sweeper (4bf7bd59)</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="improvements-4" id="improvements-4"></a>Improvements</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<span class="strong"><strong>Performance
Improvements</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem">(Postgres only) Improve performances when
fetching the available chat rooms using recursive permission api
(56d47b31, 0b2cff50)</li></ul></div>
</li><li class="listitem">
<span class="strong"><strong>Security
Improvements</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Improve SQL quoting (e2146673)</li><li class="listitem">Harden page contracts and use new contract
features from the core (43955d16, 148be6f4, 7f6b5c92)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Code
Refactoring</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Replace :xo::clusterwide -&gt;
::acs::clusterwide for cluster-aware chaching (76fbfe1f)</li><li class="listitem">Replace ::xo::db::sql -&gt; ::acs::dc as tcl
abstraction for db stored procedures (76fbfe1f)</li><li class="listitem">Replace deprecated api (928793ce,
cb2e52d0)</li><li class="listitem">Replace handcrafted HTML icons with new
adp:icon adp tag (054c46cc)</li><li class="listitem">Reduce layers of redirection when accessing a
chat room (4f57e272)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Miscellaneous</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Prefer message keys from core packages
(943daaa3)</li><li class="listitem">Cleanup vestigial features/dead code
(23fe7d3a, b8d5da6d, d7434cae)</li><li class="listitem">Pass properties to master template as literal
according to best practices (98a2b1ec)</li><li class="listitem">Extend test suite to 100% public API coverage
(117c66e3, 210e3f16, b2abc81c, fe60e3d1)</li><li class="listitem">Improve configurability and styling of the
chat includelet (54bb236f, 289ddee6)</li><li class="listitem">Streamline idioms (2b0bd209)</li><li class="listitem">Replace legacy message keys (a465cf76)</li><li class="listitem">Improve localization (0252ed50)</li>
</ul></div>
</li>
</ul></div>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="changes-in-package-dotlrn" id="changes-in-package-dotlrn"></a>Changes in package
"dotlrn" and associated packages</h4></div></div></div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="reforms-2" id="reforms-2"></a>Reforms</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<span class="strong"><strong>dotlrn</strong></span>:
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Deactivate obsolete SQL function in creation
script (sql/postgresql/dotlrn-create.sql). This complements commit
3a280c7e in acs-kernel (commit 1b845ba0).</li><li class="listitem">Use dotlrn-bootstrap3-theme as default theme
(commit c6547eb8).</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>theme-zen</strong></span>: Adapt to commit
3a280c7e (acs-kernel) and c6547eb8 (dotlrn) (commit 6d50cb9b).</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="improvements-5" id="improvements-5"></a>Improvements</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<span class="strong"><strong>Performance
Improvements</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<span class="strong"><strong>dotlrn</strong></span>: Prefer APIs returning
cached values before querying the DB using <code class="literal">site_node::</code> (commit 4d025e63)</li><li class="listitem">
<span class="strong"><strong>dotlrn-fs</strong></span>: Prefer APIs returning
cached values before querying the DB using <code class="literal">site_node::</code> (39bcaf3f)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Security
Improvements</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem">
<span class="strong"><strong>dotlrn</strong></span>: Mitigating potential XSS
attacks using NaviServer own <code class="literal">ns_quotehtml</code> (commit 4476e815)</li></ul></div>
</li><li class="listitem">
<span class="strong"><strong>Code
Refactoring</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<span class="strong"><strong>dotlrn</strong></span>:
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">Replace deprecated <code class="literal">notification::get_interval_id</code> with <code class="literal">notification::interval::get_id_from_name</code> (commit
871dd502)</li><li class="listitem">Replace deprecated <code class="literal">notification::get_delivery_method_id</code> with
<code class="literal">notification::delivery::get_id</code> (commit
a9760fc4)</li><li class="listitem">Replace deprecated <code class="literal">template::util::is_true</code> with <code class="literal">[string is true -strict $value]</code> (commit
38981891)</li><li class="listitem">Replace deprecated <code class="literal">util_commify_number</code> with <code class="literal">lc_numeric</code> (commit 7c14688e)</li><li class="listitem">Replace deprecated <code class="literal">twt::user::create</code> and <code class="literal">twt::user::delete</code> with the respective <code class="literal">acs::test::user::</code> counterparts (commit
dea8673e)</li><li class="listitem">Cleanup usage of deprecated API <code class="literal">template::util::nvl</code> (commit 0775f434,
73b52fba)</li><li class="listitem">Cleanup usage of deprecated API <code class="literal">acs_privacy::</code> (commit d31c3b6f, 9ae5aa4a)</li><li class="listitem">Replace deprecated <code class="literal">bulk_mail::parameter</code> with <code class="literal">parameter::get</code> (commit b10c5f26)</li><li class="listitem">Replace deprecated <code class="literal">forum::new_questions_deny</code> and <code class="literal">forum::new_questions_allow</code> with <code class="literal">permission::grant</code> (commit 4880f884)</li><li class="listitem">Replace custom calendar widget implementation
with native HTML5 fields (commit 113b1cb4)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>dotlrn-bm</strong></span>: Replace deprecated
<code class="literal">bulk_mail::pretty_name</code> with
<code class="literal">parameter::get</code> (commit b6b7aec1)</li><li class="listitem">
<span class="strong"><strong>dotlrn-calendar</strong></span>: Reform handling
of admin permissions (commit ce9e27d4, 6a9ada80)</li><li class="listitem">
<span class="strong"><strong>dotlrn-forums</strong></span>:
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">Replace deprecated <code class="literal">notification::get_interval_id</code> with <code class="literal">notification::interval::get_id_from_name</code> (commit
d77b24b7)</li><li class="listitem">Replace deprecated <code class="literal">notification::get_delivery_method_id</code> with
<code class="literal">notification::delivery::get_id</code> (commit
075b8adc)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>dotlrn-fs</strong></span>: Replace Naviserver
<code class="literal">ns_mktemp</code> with <code class="literal">ad_tmpnam</code> (commit f5fd2c96)</li><li class="listitem">
<span class="strong"><strong>dotlrn-homework</strong></span>:
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">Alter reference to db-error file in
acs-subsite (commit d47e5f2c)</li><li class="listitem">Replace deprecated <code class="literal">util_commify_number</code> with <code class="literal">lc_numeric</code> (commit 990b0b0a)</li><li class="listitem">Replace handcrafted HTML icons with adp:icon
adp tag (commit 3f1557c2)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>dotlrn-news</strong></span>:
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">Replace deprecated <code class="literal">notification::get_interval_id</code> with <code class="literal">notification::interval::get_id_from_name</code> (commit
586cc6ae)</li><li class="listitem">Replace deprecated <code class="literal">notification::get_delivery_method_id</code> with
<code class="literal">notification::delivery::get_id</code>
(28661484)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>dotlrn-static</strong></span>: Fix applet mount
point (commit 233e0c6c)</li><li class="listitem">
<span class="strong"><strong>new-portal</strong></span>:
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">Replace <code class="literal">export_ns_set_vars</code> with <code class="literal">export_vars</code> (commit e8ab835d)</li><li class="listitem">Prefer adp:icon adp tag over handcrafted HTML
icons (commit 7afadf3b)</li>
</ul></div>
</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Miscellaneous</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem">
<span class="strong"><strong>All
packages</strong></span>:
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">Cleanup and formatting (various commits)</li><li class="listitem">Strengthen page contracts (various
commits)</li><li class="listitem">Document public API, e.g., in new-portal,
dotlrn-dotlrn (e.g., commit 75656f6f, 05540825)</li><li class="listitem">Improve test coverage, e.g., in <code class="literal">dotlrn-portlet</code> (e.g., commit dcfe916b, 712e8793,
59ec97b0)</li>
</ul></div>
</li></ul></div>
</li>
</ul></div>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="changes-in-package-faq" id="changes-in-package-faq"></a>Changes in package
"faq"</h4></div></div></div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="new-features-3" id="new-features-3"></a>New Features</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">
<span class="strong"><strong>faq::new
API</strong></span> (1fc77330): an API to create an FAQ, also
useful for testing</li></ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="bug-fixes-3" id="bug-fixes-3"></a>Bug
Fixes</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">Fixes for Oracle compatibility (3e5418a3)</li></ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="reforms-3" id="reforms-3"></a>Reforms</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Mark service contract implementations as
private (987ef426)</li><li class="listitem">Mark apm callbacks as private (6861af77)</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="improvements-6" id="improvements-6"></a>Improvements</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<span class="strong"><strong>Security
Improvements</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem">Harden page contract validation (a2904377,
87d05896, a4c9fc52)</li></ul></div>
</li><li class="listitem">
<span class="strong"><strong>Code
Refactoring</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Replace deprecated <code class="literal">twt::user::create</code> and <code class="literal">twt::user::delete</code> with their acs::test::user::
counterpart (27286797)</li><li class="listitem">Replace handcrafted HTML icons with new
adp:icon adp tag (17acc438, 5a7ce6b6)</li><li class="listitem">Replace <code class="literal">rp_form_put</code> with plain ns_set idioms
(d7deda66)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Miscellaneous</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Cleanup and formatting changes (various
commits)</li><li class="listitem">Increase test suite of functionalities and
cover 100% of public api (various commits)</li>
</ul></div>
</li>
</ul></div>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="changes-in-package-file-storage" id="changes-in-package-file-storage"></a>Changes in package
"file-storage"</h4></div></div></div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="bug-fixes-4" id="bug-fixes-4"></a>Bug
Fixes</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Make <code class="literal">fs::get_file_package_id</code> more robust to cases where
the package_id is not set on the object itself (bbbbf93b)</li><li class="listitem">Fixes for Oracle compatibility (9a5b9cf4,
0d4331cb, de75d648)</li><li class="listitem">Fix regression when the files list is rendered
in <span class="quote">“<span class="quote">list</span>”</span>
format (d0eecbe4)</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="reforms-4" id="reforms-4"></a>Reforms</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Make oacs-dav an optional, uninstallable
dependency (c8e3b5f8)</li><li class="listitem">Make Service Contract implementation private
and use the abstract api instead (81ef9be7, 6eee7dbd, 846b226b,
f56b331a)</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="improvements-7" id="improvements-7"></a>Improvements</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<span class="strong"><strong>Performance
Improvements</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem">(Postgres only) Improve performances when
fetching folder files using recursive permission api
(02f64379)</li></ul></div>
</li><li class="listitem">
<span class="strong"><strong>Security
Improvements</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem">Improve server and client-side input
validation (various commits)</li></ul></div>
</li><li class="listitem">
<span class="strong"><strong>Code
Refactoring</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Reduce divergency between Oracle and Postgres
codebase (55e70c4f, 2cf7bbf5)</li><li class="listitem">Replace deprecated <code class="literal">template::util::tcl_to_sql_list</code> with NaviServer
own <code class="literal">ns_dbquotelist</code> (8b1a62d0)</li><li class="listitem">Replace deprecated <code class="literal">twt::user::create</code> and <code class="literal">twt::user::delete</code> with their acs::test::user::
counterpart (cbc632d0)</li><li class="listitem">Cleanup obsolete error catching
(d99eccfb)</li><li class="listitem">Replace handcrafted HTML icons with new
adp:icon adp tag (602c473d, 651ab668, 53b1248d)</li><li class="listitem">Replace <code class="literal">ad_tmpnam</code>
with <code class="literal">ad_opentmpfile</code> and <code class="literal">ad_mktmpdir</code>, safer from race conditions (576d51a1,
8a9ac2b9)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Miscellaneous</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Cleanup and formatting (various commits)</li><li class="listitem">Improve test suite and cover 100% of public
api (various commits)</li>
</ul></div>
</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="deprecations-2" id="deprecations-2"></a>Deprecations</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<code class="literal">fs::add_created_version</code> -&gt; behavior specific to
this proc was to <code class="literal">fs::add_version</code>,
largely similar (815cbaae)</li><li class="listitem">
<code class="literal">fs::torrent::get_hashsum</code> -&gt; superseded by
NaviServer <code class="literal">ns_md</code> command
(aaf2751d)</li><li class="listitem">
<code class="literal">fs::item_editable_p</code>, <code class="literal">fs::item_editable_info</code> -&gt; Unused, unclear
usefulness (86cd3917)</li><li class="listitem">
<code class="literal">fs::get_archive_extension</code> -&gt; trivial wrapper
over the parameter api (aa63e153)</li><li class="listitem">
<code class="literal">fs::get_folder_contents</code> -&gt; Not used in the
codebase, same result can be achieved with other api
(72e444b8)</li>
</ul></div>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="changes-in-package-forums" id="changes-in-package-forums"></a>Changes in package
"forums"</h4></div></div></div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="bug-fixes-5" id="bug-fixes-5"></a>Bug
Fixes</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Fix broken message key (74cadd4f)</li><li class="listitem">Fixes for Oracle compatibility (f5db030e)</li><li class="listitem">Rely less on values provided by the connection
(f85185af)</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="reforms-5" id="reforms-5"></a>Reforms</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Adapt template::element calls after replacing
<code class="literal">template::util::get_opts</code>
(16b22e9e)</li><li class="listitem">Mark service contract implementations as
private (bb6e3b3b)</li><li class="listitem">Use UTF-8 emojis instead of actual images to
render supported smileys in forum posts (335f1ede)</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="improvements-8" id="improvements-8"></a>Improvements</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<span class="strong"><strong>Performance
Improvements</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Avoid transaction when unnecessary
(aeb4e876)</li><li class="listitem">Use cached api when detecting if attachments
are supported (83b9a2e8)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Security
Improvements</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Improve server response in error situations
(b2e833ab)</li><li class="listitem">Harden page contract validation (c92794b8,
22c992f2, 655eea7b, 619b2580, c403e313, 189442f8, 0a4c5d1d)</li><li class="listitem">Increase permission checking (6ddf512d)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Code
Refactoring</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Pass properties in adp consistently with
\@….;literal\@ best practice (dc2b6f8f, 44d3483e)</li><li class="listitem">Replace deprecated <code class="literal">template::util::is_true</code> with inline string idiom
(88c779b5)</li><li class="listitem">Replace handcrafted HTML icons with new
adp:icon adp tag (1b6adbcb, 0cf9dfe4)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Miscellaneous</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Cleanup and formatting changes (various
commits)</li><li class="listitem">Increase test suite of functionalities and
cover 100% of public api (various commits)</li>
</ul></div>
</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="deprecations-3" id="deprecations-3"></a>Deprecations</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<code class="literal">forum::new_questions_allowed_p</code> -&gt; Trivial
shotrhand to forum::get (5e7c3e01)</li><li class="listitem">
<code class="literal">forum::new_questions_allow</code> and <code class="literal">forum::new_questions_deny</code> -&gt; Trivial shorthands
to forum::edit</li><li class="listitem">
<code class="literal">forum::message::get_attachments</code> -&gt; Unused and
repleaceable by other API</li>
</ul></div>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="changes-in-package-general-comments" id="changes-in-package-general-comments"></a>Changes in package
"general-comments"</h4></div></div></div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="bug-fixes-6" id="bug-fixes-6"></a>Bug
Fixes</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">Fixes for Oracle compatibility (e6fdab8b)</li></ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="reforms-6" id="reforms-6"></a>Reforms</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">Reimplement add/edit UI to use ad_form and
reduce duplication (0842ac32)</li></ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="improvements-9" id="improvements-9"></a>Improvements</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<span class="strong"><strong>Security
Improvements</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem">Harden page contract validation (a17a883b,
438b62a5, 150c40c4, c08961bd, 993e67b1, 026075fc, b041c11b,
b6e063dc, dc08e85c, c34e943b)</li></ul></div>
</li><li class="listitem">
<span class="strong"><strong>Code
Refactoring</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Replace deprecated <code class="literal">export_ns_set_vars</code> with alternative idioms
(4892cc8d)</li><li class="listitem">Replace deprecated <code class="literal">ad_convert_to_html</code> with <code class="literal">ad_html_text_convert</code> (e48e5624)</li>
</ul></div>
</li>
</ul></div>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="changes-in-package-proctoring-support" id="changes-in-package-proctoring-support"></a>Changes in package
"proctoring-support"</h4></div></div></div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="new-features-4" id="new-features-4"></a>New Features</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<span class="strong"><strong>Support for mock
exams</strong></span> (commit 114d489e): introduce parameter
record_p in the main proctoring include allowing to turn off
artifacts collection. Useful FOR mock exams.</li><li class="listitem">
<span class="strong"><strong>Artifacts data
model</strong></span> (commit 9acb6bc8, f9206d9e): proctoring
artifacts are now stored in actual database tables and not only on
the filesystem.</li><li class="listitem">
<span class="strong"><strong>Test
pages</strong></span> (commit 30ea5f4b): the default proctoring
installation provides a fully-functional test environment of the
admin and regular user functionalities.</li><li class="listitem">
<span class="strong"><strong>Push updates for
new artifacts</strong></span> (commit 337d8cb6): the proctoring
display UI now uses websockets to receive push updates from the
server when new artifacts are available.</li><li class="listitem">
<span class="strong"><strong>Artifacts review
UI</strong></span> (commit 99cdda4a and various others): the
proctoring display UI now enables admin users to review proctoring
artifacts via comments or flagging.</li><li class="listitem">
<span class="strong"><strong>Red
border</strong></span> (commit d20cb434): allow one to display an
additional border around the proctored window. Useful to increase
the visibility of the proctored session in a classroom.</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="reforms-7" id="reforms-7"></a>Reforms</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Proctoring enforcing: captive-portal the
proctoring session using a callback mechanism, rather than via
includes in the master template (commit 9acb6bc8).</li><li class="listitem">Stop the proctoring session from the client
side when no artifacts are sent for too long (commit
0b87b9e0).</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="bug-fixes-7" id="bug-fixes-7"></a>Bug
Fixes</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Be more robust in case of client-side error
conditions (commit 64d4dde9, 2c7ff02a, 7dc4239a)</li><li class="listitem">Use PiP to circumvent browser powersaving that
would shut down MediaStreams when a browser is out of focus.
(commit 0b87b9e0, c0d97c91)</li><li class="listitem">Relax enforcing of duplicated images for
proctored desktops (commit c72ddbb3)</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="improvements-10" id="improvements-10"></a>Improvements</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<span class="strong"><strong>Code
Refactoring</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Replace deprecated api (various commits)</li><li class="listitem">Modernize javascript idioms (various
commits)</li><li class="listitem">Maintain an adequate look and feel using both
Bootstrap5 and Bootstrap3 (70a0f52c, f07dfc06, e913ee2b, 54d4f3cc
and others)</li><li class="listitem">Drop custom implementation of <span class="quote">“<span class="quote">lazy loading</span>”</span> for the
proctoring display UI and rely on modern native browser features
instead (commit 90d2404c)</li>
</ul></div>
</li><li class="listitem">
<span class="strong"><strong>Usability</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem">Improve usability of the proctoring display UI
on mobile and when using a keyboard (various commits)</li></ul></div>
</li><li class="listitem">
<span class="strong"><strong>Miscellaneous</strong></span><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Improve integration with master template
(9acb6bc8, 44729649)</li><li class="listitem">Streamline idioms (various commits)</li><li class="listitem">Improved documentation</li><li class="listitem">Increase test suite of functionalities and
cover 100% of public api (various commits)</li><li class="listitem">Extend package localization. Currently
English, German, Italian and Spanish are supported.</li>
</ul></div>
</li>
</ul></div>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="changes-in-package-xotcl-core" id="changes-in-package-xotcl-core"></a>Changes in package
"xotcl-core"</h4></div></div></div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="new-features-5" id="new-features-5"></a>New Features</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Added value checker <code class="literal">signed</code> (commit 1ce581a)</li><li class="listitem">Added value checker <code class="literal">oneof</code> (commits 58bc938, 2dbadad, 65575bf,
58bc938).</li><li class="listitem">Added value checker <code class="literal">cr_item_of_package</code> (commit 6fc46f3)</li><li class="listitem">Provided consistent sorting for Database and
Tcl sorts (commit 6effe16)</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="bug-fixes-8" id="bug-fixes-8"></a>Bug
Fixes</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Avoiding double quoting (commit 08386db).</li><li class="listitem">Fixed potential memory leaks
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Free explicitly answer <code class="literal">ns_set</code> in database <span class="quote">“<span class="quote">sets</span>”</span> method (commit
158a831)</li><li class="listitem">Free <code class="literal">ns_set</code>
storage more eager (when e.g. large queries are used in longer
loops) (commit 3d6b05a)</li>
</ul></div>
</li><li class="listitem">Compatibility Fixes for Oracle 19c (commit
de4a9a5, 88f8521, 1408e2b)</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="improvements-11" id="improvements-11"></a>Improvements</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Security improvements:
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Support for <code class="literal">form_parameter</code> specs with value checkers added
(commit 64bb847).</li><li class="listitem">harden page contracts (commit b0c282d)</li>
</ul></div>
</li><li class="listitem">Performance improvements:
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Improved prepared-statement handling (commit
fac52ce)</li><li class="listitem">Various other changes such as
e.g. d22121d</li>
</ul></div>
</li><li class="listitem">Unified package parameter handing between xo*
and oacs-core (commit 66ee181)</li><li class="listitem">Reduced verbosity of logging for streamlined
output (commit 0553811).</li><li class="listitem">Stop sending messages to other (potentially
stopped) thread to avoid log messages (commit 0aa8c98).</li>
</ul></div>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="changes-in-package-xowiki" id="changes-in-package-xowiki"></a>Changes in package
"xowiki"</h4></div></div></div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="new-features-6" id="new-features-6"></a>New Features</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">GUI improvements
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">New abstraction xowiki::CSS to provide
portability between different frameworks and version of frameworks
(commit 99e3331c)</li><li class="listitem">Added <code class="literal">xowiki::bootstrap::card</code> for increased
configurability (commits 97685004, 4e09efa9, 136edcc5).</li><li class="listitem">Use adp:icon for better cross framework
compatibility (commits 562e9e48, 19407b34, 71606059)</li><li class="listitem">Support for Bootstrap5 (commits 97685004,
ddae6214, 701612b7, a073060e, de6f0f48, 694c61b5, 48efaa9e,
57a7e91a, b71aacc0, 07be172b and several more)</li><li class="listitem">Added native CSS classes for Tree renderer and
made TreeRenderer more configurable, reduce YUI (commit
83eafdcf).</li><li class="listitem">Beautify display of CSS tree renderer for
deeper trees (commit ab624faa).</li>
</ul></div>
</li><li class="listitem">Chat improvements
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Reduce server-side guessing of browser
capabilities and minimize mode-specific JavaScript code (commit
8d98e9bf).</li><li class="listitem">Support for anonymous users in chat class,
allowing mixed participation of authenticated and non-authenticated
users (commit d929ec45).</li>
</ul></div>
</li><li class="listitem">Drag and Drop improvements
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Support for drag &amp; drop for reordering
items for mobile devices (commit 4489907b).</li><li class="listitem">Extended functionality of the DropZone widget
(commit d65bd411).</li>
</ul></div>
</li><li class="listitem">Added support for archiving of items (commit
4d17aa0e).</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="reforms-8" id="reforms-8"></a>Reforms</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">Generalized handling of error pages in
disconnected stage (commit b3b677d4).</li></ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="configuration-changes-1" id="configuration-changes-1"></a>Configuration Changes</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Update CDN sources where necessary (commit
d4d0d85e).</li><li class="listitem">Updates of external libraries and CDN
providers (commits d4d0d85e, f71db88b, 2986f329, f22f9b0b,
e3b9f244, c63f61c9)</li><li class="listitem">Improved Parameterization *Ability to
parameterize <code class="literal">www-delete</code> and
<code class="literal">www-toggle-publish-status</code> with
<code class="literal">return_url</code> for workflow-specific
behavior (commit abba6cd1).
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">New package parameter: <code class="literal">PackageInitParameter</code> for instance-specific package
behavior (commit cc5b9959).</li><li class="listitem">Added support for passing parameter specs of
the form <code class="literal">parameter_name:value_constraint</code> to <code class="literal">xowiki::Package.get_parameter</code> (commit
9df95cb3).</li>
</ul></div>
</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="bug-fixes-9" id="bug-fixes-9"></a>Bug
Fixes:</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Test reproducing a bug in <code class="literal">acs::test::xpath::get_form_values</code> proc (commit
f495cac3).</li><li class="listitem">Fixed test case returned violation on plain
instance (commit 78ec506d).</li><li class="listitem">Fixed xowiki <code class="literal">create_form_with_form_instance</code> automated test
(commit a9a37dcc).</li><li class="listitem">Handle more gracefully the case of missing
files on the filesystem (commit 72c1aeeb).</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="improvements-12" id="improvements-12"></a>Improvements:</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Improved autosave support (commit
b373091c).</li><li class="listitem">Added support to check the file types of
uploaded content (commit 80756c4b).</li><li class="listitem">Improved portability
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Added missing Oracle support for Oracle 19c
(commit 777eadbc).</li><li class="listitem">Fix for Oracle 19c issues (commit
777eadbc).</li>
</ul></div>
</li><li class="listitem">Improved error handling
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Improved handling of pages with <code class="literal">parent_id</code> == 0 (commit 7637ff52).</li><li class="listitem">Improved error message clarity and handling
(multiple commits).</li><li class="listitem">Improved warning message (commit
80c69179).</li><li class="listitem">Various small improvements in handling form
pages and error messages (commit 1c11ce20).</li>
</ul></div>
</li><li class="listitem">Various API improvements:
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem">Updated interface for <code class="literal">Page.create_form_page_instance</code> (commit
c0ee21d6).</li></ul></div>
</li><li class="listitem">Security improvements:
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Enhanced form and query variable validation
(commit d405042d).</li><li class="listitem">Improved safety of SQL queries (commit
be15be72).</li>
</ul></div>
</li><li class="listitem">Code Maintenance:
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Cleanup and modernization of code, removal of
obsolete and commented code (multiple commits).</li><li class="listitem">Extended regression test (commit
8daa654b).</li><li class="listitem">Improved comments (commit 9e9a99f5).</li><li class="listitem">Improved documentation and cleanup (commit
27609be3).</li>
</ul></div>
</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="deprecations-4" id="deprecations-4"></a>Deprecations:</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Cleanup of deprecated API references and
methods (commit b0a9b875, commit fc1e48d1, commit 2c490318).</li><li class="listitem">Logging of deprecated usages unified under
<code class="literal">ad_log_deprecated</code> (commit
56d4b9d5).</li><li class="listitem">Removal of features and scripts no longer in
use (commit 726cc0dd, commit c8100365).</li><li class="listitem">Added <span class="quote">“<span class="quote">\@see</span>”</span> to deprecated proc (commit
bb2fa23a).</li><li class="listitem">Got rid of legacy message key <code class="literal">menu-Clipboard-Copy</code> (commit ba901036).</li>
</ul></div>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="changes-in-package-xowf" id="changes-in-package-xowf"></a>Changes in package
"xowf"</h4></div></div></div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="new-features-7" id="new-features-7"></a>New Features</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">Improved Support E-Learning applications
(mostly inclass exam)
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Support for restricting access to exams based
on IP addresses (7fc8473).</li><li class="listitem">Drag and Drop interface for feedback files
(fd68c22).</li><li class="listitem">Support for pool questions in the test-item
family (No specific commit hash related to this feature was found
in the provided content).</li><li class="listitem">Improved support for viewing and downloading
exam results (250d5a4).</li><li class="listitem">Added Support for viewing/altering all
configuration options for inclass exams via modal dialogs
(39d5063).</li><li class="listitem">Added Parameter to allow/disallow page
translation and spell checker for exams (commits 97e383e,
20a2d49).</li>
</ul></div>
</li></ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="configuration-changes-2" id="configuration-changes-2"></a>Configuration Changes</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">Turn off production mode by default
(363c839).</li></ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="bug-fixes-10" id="bug-fixes-10"></a>Bug
Fixes</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Fixed achieved points in exam statistics per
question (f05631f).</li><li class="listitem">Fix for potential loss of statistics for
auto-graded exams (fc03d5f).</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="improvements-13" id="improvements-13"></a>Improvements</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Improved Maintainability: Added Site-wide
admin pages for xowf (cbb3bc8).</li><li class="listitem">Improved Performance: Added support for shared
workflow definitions (2628b6f).</li><li class="listitem">Improved GUI:
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Improved support for Bootstrap5
(e.g. commits 8623ebd and a5e1f6c).</li><li class="listitem">Enhanced usability and styling for inclass
exams and workflows (3d33b2a).</li>
</ul></div>
</li>
</ul></div>
</div>
</div><div class="sect3">
<div class="titlepage"><div><div><h4 class="title">
<a name="changes-in-package-xotcl-request-monitor" id="changes-in-package-xotcl-request-monitor"></a>Changes in package
"xotcl-request-monitor"</h4></div></div></div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="new-features-8" id="new-features-8"></a>New Features</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">Ability to order by time values in long-calls
listing (Commit 031ee35).</li><li class="listitem">Support for ordering long-calls by start time
or by end time in long-calls listing (Commit 7c9ffe9).</li>
</ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="configuration-changes-3" id="configuration-changes-3"></a>Configuration Changes</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">Added configurability to watchdog with
parameters like <span class="quote">“<span class="quote">-maxWaiting</span>”</span> and <span class="quote">“<span class="quote">-maxRunning</span>”</span> (Commit
60ba4e3).</li></ul></div>
</div><div class="sect4">
<div class="titlepage"><div><div><h5 class="title">
<a name="improvements-14" id="improvements-14"></a>Improvements</h5></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">Security Improvements
<div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">Protect query-parameters against exceptions
with empty values (Commit 176a32b).</li><li class="listitem">Added safety measures for potential DOS
attacks and improved request blocking (Commit ef39b79).</li><li class="listitem">Improved strictness of tests (Commit
ceb4a88).</li><li class="listitem">Improved description of package parameters
(Commit ff8c44d)</li><li class="listitem">Enhanced the initial population of
request-monitor counters for robustness (Commit 622d8f2).</li><li class="listitem">Switch from <code class="literal">xo::db::sql</code> to <code class="literal">acs::dc</code> interface (Commit a2d4688).</li>
</ul></div>
</li></ul></div>
</div>
</div>
</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-10-0" id="release-notes-5-10-0"></a>Release 5.10.0</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>The release of OpenACS 5.10.0 contains the 93 packages of the
oacs-5-10 branch. These packages include the OpenACS core packages,
the major application packages (e.g. most the ones used on
OpenACS.org), and DotLRN 2.10.0.</p></li><li class="listitem">
<p>Functional improvements</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>Features:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">
<p>Support for range types in .xql files:</p><p>PostgreSQL supports range types since 9.5. When using range
types, square braces have to be used in SQL statements. Since
OpenACS uses always Tcl substitution in .xql files, and OpenACS
does NOT allow backslash substitution in these files, square
brackets could not be escaped and therefore not be used in .xql
files so far. This change allows now a developer to deactivate the
substitution by passing e.g. <code class="computeroutput">-subst
none</code> to the db_* command using the .xql file. Valid values
for <code class="computeroutput">-subst</code> are <code class="computeroutput">all</code>, <code class="computeroutput">none</code>, <code class="computeroutput">vars</code>, and <code class="computeroutput">commands</code>, default is <code class="computeroutput">all</code> which is exactly the behavior of
previous releases. Therefore, this change is fully backward
compatible.</p>
</li><li class="listitem">
<p>Registry for .js and .css libraries: allow besides classical
URLs symbolic names for loading external resources (e.g. jquery),
this makes it easier to upgrade libraries in multiple packages
(without running into problems with duplicate versions) and
supports switching between CDN and local pathsURN. The existing
implementation is based on URNs and extends the existing
template-head API to support registration for URNs. A URN provides
an abstraction and a single place for e.g. updating references to
external resources when switching between a CDN and a locally
stored resource, or when a resource should be updated. Instead of
adding e.g. a CDN URL via template::head::add_script, one can add
an URN and control its content from a single place. Use common
namespaces for OpenACS such as <code class="computeroutput">urn:ad:css:*</code> and <code class="computeroutput">urn:ad:js:*</code>.</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>Register URNs:</p><p>Example provider (e.g. in some theme):</p><pre class="programlisting">
   template::register_urn \ 
       -urn urn:ad:js:jquery \ 
       -resource /resources/xowiki/jquery/jquery.min.js
</pre>
</li><li class="listitem">
<p>The registered URN can be used like classical URL after
registration.</p><p>Example consumer:</p><pre class="programlisting">
   template::head::add_javascript -src urn:ad:js:jquery</pre>
</li><li class="listitem">
<p>Declare composite files: Provide an interface to define that a
.js file or a .css file contains multiple other .js/.css files in
order to reduce the number of requests.</p><pre class="programlisting">
   template::head::includes -container urn:js::style.js -parts {urn:ad:js:jquery ...}</pre>
</li>
</ul></div>
</li><li class="listitem"><p>Improved API browser: Visualization for code dependencies (which
procs calls what, from where is a proc being called) and
test-coverage</p></li><li class="listitem"><p>Warn site administrators about expiring certificates</p></li><li class="listitem"><p>Added text/markdown to the accepted text formats or rich-text
widget</p></li><li class="listitem">
<p>Additional input types (and widgets) for <code class="computeroutput">ad_form</code>:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>checkbox_text</p></li><li class="listitem"><p>color</p></li><li class="listitem"><p>email</p></li><li class="listitem"><p>tel</p></li><li class="listitem"><p>url</p></li><li class="listitem"><p>number</p></li><li class="listitem"><p>file (multiple)</p></li><li class="listitem"><p>h5date and h5time: date and time fields using native HTML5
visualization and input normalization</p></li>
</ul></div>
</li><li class="listitem"><p>Added additional page_contract filter: oneof(red|green|blue)</p></li><li class="listitem"><p>
<code class="computeroutput">template::add_event_listener</code>
and <code class="computeroutput">template::add_confirm_handler</code> now can
target elements by CSS selector</p></li><li class="listitem"><p>Improved support for streaming HTML: The new API function
<code class="computeroutput">template::collect_body_scripts</code>
can be used to get the content of template::script or CSP calls
(<code class="computeroutput">template::add_body_script</code>,
<code class="computeroutput">template::add_event_listener</code>,
<code class="computeroutput">template::add_body_handler</code>,
<code class="computeroutput">template::add_script</code>) when
streaming HTML (incremental HTML) is used. Before, these call could
bot be used for streaming HTML.</p></li>
</ul></div>
</li><li class="listitem">
<p>Reforms:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">
<p>Login:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem"><p>Get rid of bugging "login page expired" messages. The
17 years old construct was replaced by newer means to avoid caching
of form values from the login form. Admins of existing sites should
set the kernel parameter <code class="computeroutput">LoginPageExpirationTime</code> to 0</p></li></ul></div>
</li><li class="listitem">
<p>Forums:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Removed hard-coded dependency with registered_users group when
checking forum permissions</p></li><li class="listitem"><p>Don&#39;t rely so heavily on acs_permissions to model forum
configuration, as this can have unexpected consequences in
convoluted multi-group/multi-subsite scenarios. Prefer simpler
table attributes instead</p></li><li class="listitem"><p>New style of attachments to the forums, allowing multiple
attachments to a single message directly from the message post
page, using the multiple file input widget. Retain compatibility
with old style attachments, using the new 'AttachmentStyle'
package instance parameter. Currently, this supports two values:
'simple' (new behavior) and 'complex' previous
behavior.</p></li>
</ul></div>
</li><li class="listitem">
<p>Chat:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Revamping of the GUI</p></li><li class="listitem"><p>Responsiveness</p></li><li class="listitem"><p>Full screen mode</p></li><li class="listitem"><p>Skins support (minimal, classic and bubbles, included): Skins
are located in the new /packages/xowiki/www/resources/chat-skins/
directory. New skins can be created by just adding the css and js
files in the skins directory, and naming them accordingly
(chat-$SKIN_NAME.{js|css}).</p></li><li class="listitem"><p>Avatars (can be enabled per room)</p></li><li class="listitem"><p>Number of active users in chat</p></li><li class="listitem"><p>Tab notifications of new messages</p></li><li class="listitem">
<p>Web Notifications:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>https://www.w3.org/TR/notifications/</p></li><li class="listitem"><p>
https://developer.mozilla.org/en-US/docs/Web/API/Notifications_API/Using_the_Notifications_API</p></li>
</ul></div>
</li>
</ul></div>
</li><li class="listitem">
<p>acs-lang:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>admin pages:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Added the option to unregister (delete permanently the message
key from all locales) a message key that has been already marked as
deleted. Useful for cleaning up old message keys.</p></li><li class="listitem"><p>Added the option to undelete, using the new ::message::undelete
proc.</p></li><li class="listitem"><p>Made number and category (untranslated/deleted/...) of messages
coherent in all pages.</p></li><li class="listitem"><p>Added the columns 'total' and 'deleted' to the
index page.</p></li>
</ul></div>
</li><li class="listitem"><p>object_id reference: it is now possible to associate a message
key to an object_id in a way that e.g. when the object is deleted,
so is the message key. This addresses cases such as the message
keys generated by group creation or by the new XoWiki localized
fields</p></li>
</ul></div>
</li><li class="listitem">
<p>Notifications:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Improved scalability for notifications: One of the most
expensive operations in large site is the cleanup for
notification_requests in situations, where the user has lost
permissions on an object, on which the user wanted to receive
notifications. This check was performed previously in <code class="computeroutput">notification::sweep::cleanup_notifications</code>
via a permission check over all notification requests, which can be
very costly on large sites. This change moves this cleanup into the
actual notification sending, where the permissions have to be sent
anyhow.</p></li><li class="listitem"><p>When sending a notification on behalf of a person, if the system
is not configured to process replies to notification, do not set
the reply-to address to anything different than the sender</p></li><li class="listitem"><p>Notifications: proper cleanup of acs_objects resulting from the
deletion of dynamic notification requests</p></li>
</ul></div>
</li><li class="listitem"><p>User/Person/Party API: rework and rationalize caching of all
party, person and user API, create separate caches for each of
these types, make the API and return dicts. acs_user::get will not
fail anymore with non-existing user.</p></li><li class="listitem"><p>User Portrait: created API to retrieve and create, store and
delete the user&#39;s portrait. Also address leftover child
relationships from the past and delete them properly.</p></li>
</ul></div>
</li>
</ul></div>
</li><li class="listitem">
<p>Non-functional Changes</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>Improved automated regression test infrastructure and test
coverage</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>All packages in the <code class="computeroutput">oacs-5-10</code> branch pass regression test</p></li><li class="listitem"><p>Web testing was separated from non-maintained tcltest and was
built on the standard OpenACS infrastructure</p></li><li class="listitem"><p>Include web testing per default in standard regression
testing</p></li><li class="listitem"><p>Introduced new test authentication authority, allowing to run
many user administration tests outside the context of a "real
authority": in cases where the real authority depends on
external services to proof identity, (e.g. Kerberos), those tests
would just fail.</p></li><li class="listitem"><p>Introduce the display of warnings in the UI of automated
testing</p></li><li class="listitem"><p>Added test coverage information in the automated testing pages,
using the new proc-coverage API and providing test coverage
information for packages and system wide.</p></li><li class="listitem"><p>Increased overall coverage of public API</p></li><li class="listitem"><p>New tests checking various data-model properties and smells</p></li>
</ul></div>
</li><li class="listitem">
<p>Improved scalability:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>Provided lock-free implementation of <code class="computeroutput">ad_page_contract_filters</code> and <code class="computeroutput">ad_page_contract_filter_rules</code>. This change
improves parallel processing of requests and is primarily
interesting for sites with a few mio page views per days. These
locks were among the most frequent nsv locks</p></li><li class="listitem"><p>Reduced locks on util_memoize_cache my more invariants values
into per-thread caching (<code class="computeroutput">acs_lookup_magic_object</code>, <code class="computeroutput">ad_acs_version</code>, .... ) and by avoiding
specialized calls, which can be realized by already optimized ones
(<code class="computeroutput">apm_package_installed_p_not_cached
ref-timezones</code> was most frequently used util_memoize_cache
entry). These changes are necessary to avoid full still-stand on
the unfortunate long-time locks on util_memoize_cache stemming from
permission and user management with wild-card flush operations,
which require to iterate over all cache entries (which might be on
a busy server several hundred thousands)</p></li><li class="listitem"><p>Added new interface for cache partitioning to reduce lock
latencies on high load websites</p></li><li class="listitem"><p>Added new interface for lock-free per-thread and per-request
caching to avoid scattered ad-hoc implementations</p></li><li class="listitem"><p>Better reuse of DB handles (reduced expiring/reopen/etc.),
faster access to handles</p></li>
</ul></div>
</li><li class="listitem">
<p>Improved startup time:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>When the package acs-automated-testing is disabled, startup time
is reduced by avoiding loading of support functions and tests; the
size of the blueprint is reduced</p></li><li class="listitem"><p>xowf: loading of at-jobs is significantly improved.</p></li>
</ul></div>
</li><li class="listitem">
<p>Security improvements:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>Strengthened page contracts</p></li><li class="listitem"><p>CSP support for application packages</p></li><li class="listitem"><p>CSP fine tuning  </p></li>
</ul></div>
</li><li class="listitem">
<p>Better exception handling based on Tcl 8.6 exception handlers
(<code class="computeroutput">try</code> and <code class="computeroutput">throw</code>, also available in Tcl 8.5)</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>Provided a new <code class="computeroutput">ad_try</code>
implementation based on Tcl&#39;s <code class="computeroutput">try</code> replaces now the old <code class="computeroutput">ad_try</code>, <code class="computeroutput">with_catch</code> and <code class="computeroutput">with_finally</code>, which are marked as
deprecated</p></li><li class="listitem"><p>The new <code class="computeroutput">ad_try</code> is in essence
Tcl&#39;s <code class="computeroutput">try</code> but with
predefined handling of <code class="computeroutput">ad_script_abort</code> and should be also used
instead of <code class="computeroutput">catch</code>, when the
OpenACS API is used (which might use script aborts)</p></li><li class="listitem"><p>All core packages use the new <code class="computeroutput">ad_try</code> instead of the deprecated
versions.</p></li>
</ul></div>
</li><li class="listitem">
<p>Connection close reform:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>NaviServer/AOLserver continue after connection closing commands
to execute a script. This is in many situations not desired,
especially, when for the page as well a .adp file exists, which
will try to deliver this on the already closed connection. This can
lead to errors in the error.log file, which are sometimes hard to
analyze</p></li><li class="listitem"><p>Due to this cleanup, developers should use in most such cases
cases <code class="computeroutput">ad_script_abort</code>
</p></li><li class="listitem"><p>Connection closing commands are e.g. <code class="computeroutput">ad_returnredirect</code>, <code class="computeroutput">ad_redirect_for_registration</code>, <code class="computeroutput">cr_write_content</code>, <code class="computeroutput">ad_page_contract_handle_datasource_error</code>,
<code class="computeroutput">ad_return_string_as_file</code>,
<code class="computeroutput">ad_return_complaint</code>,
<code class="computeroutput">ad_return_error</code>, <code class="computeroutput">ad_return_forbidden</code>, <code class="computeroutput">ad_return_warning</code>, <code class="computeroutput">ad_return_exception_page</code>, <code class="computeroutput">ns_returnredirect</code>, <code class="computeroutput">ns_return</code>, <code class="computeroutput">ns_returnerror</code>
</p></li><li class="listitem"><p>The new version has made on most occasions explicit, when the
script should abort.</p></li>
</ul></div>
</li><li class="listitem">
<p>API changes (new and extended API calls):</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>New API call <code class="computeroutput">category::get</code>
to obtain category description for a category_id and locale</p></li><li class="listitem"><p>New utility <code class="computeroutput">ad_pad</code> emulating
both lpad and rpad typically available in DBMSs</p></li><li class="listitem"><p>New proc lc_content_size_pretty, prettify data size given in
bytes. It supports three different standards (SI base-10, IEC
base-2 and the old JEDEC base-2), default is SI base-10.</p></li><li class="listitem"><p>New flag <code class="computeroutput">-export</code> for
<code class="computeroutput">ad_form</code>: this flag uses
<code class="computeroutput">export_vars</code> under the hood and
supports all of this API&#39;s features (e.g. :multiple, :sign,
:array). This addresses a long standing TODO</p></li><li class="listitem"><p>
<code class="computeroutput">util::pdfinfo</code>: simple
poppler-utils wrapper to extract pdf information</p></li><li class="listitem"><p>util::http: leverage new ns_http features such as request file
spooling. Native implementation will now be used only on NaviServer
&gt;= 4.99.15.</p></li><li class="listitem">
<p>Database API:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<code class="computeroutput">db_foreach</code>: queries executed
inside of a db_foreach will not be issued using a different handle
and will therefore be safe to use in a transaction</p></li><li class="listitem"><p>
<code class="computeroutput">db_list_of_lists</code>: new
<code class="computeroutput">-with_headers</code> flag, which will
make the first element of the returned list to be the column names
as defined in the query</p></li>
</ul></div>
</li><li class="listitem">
<p>Groups API:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Logics to delete a group type have now been included in the
API</p></li><li class="listitem"><p>Allow to filter group members by member_state in the API</p></li>
</ul></div>
</li>
</ul></div>
</li><li class="listitem">
<p>Deprecated commands:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>Many deprecated API calls were included in the code (and
sometimes still in use) sometimes more than 10 years after these
calls have been deprecated. In case a site modification still uses
deprecated code, the user is warned about this. The OpenACS 5.10
code base does not depend on deprecated code.</p></li><li class="listitem"><p>Move deprecated code into separate files</p></li><li class="listitem"><p>Made loading of deprecated code optional (can be controlled via
parameter "WithDeprecatedCode" in section
"ns_section ns/server/${server}/acs" of the config file.
By default, deprecated procs are still loaded</p></li><li class="listitem">
<p>When deprecated code is not loaded, the blueprint of the
interpreter is smaller. The following number of lines of code can
be omitted when loading without the deprecated procs:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>acs-tcl: 3178</p></li><li class="listitem"><p>acs-templating: 450</p></li><li class="listitem"><p>xotcl-core http-client-procs: 830</p></li><li class="listitem"><p>acs-content-repository: 1717 (including .xql files)</p></li>
</ul></div>
</li>
</ul></div>
</li><li class="listitem">
<p>Bugfix and Code Maintenance:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>Made sure all party emails are stored as lowercase through the
API</p></li><li class="listitem"><p>Fixed long standing regression in template::list: we were
looping through the list "elements", rather than the
"display_elements". This prevents specifying different
sets of columns to be returned depending on the <code class="computeroutput">-formats</code> and <code class="computeroutput">-selected_format</code> options in
template::list::create.</p></li><li class="listitem"><p>acs-content-repository: New HEIC and HEIF mimetypes</p></li><li class="listitem"><p>acs-mail-lite: handle <code class="computeroutput">to_addr</code> specified as "DisplayName
&lt;email&gt;" without errors</p></li><li class="listitem"><p>Fixed invalidating of all existing user logins, (aka)
"Logout from everywhere" feature, useful e.g. to make
sure no device still holds a valid login when we change our
password on a device</p></li><li class="listitem"><p>Don&#39;t lose the return URL when one tries to join a subsite
before being logged in</p></li><li class="listitem"><p>Added <code class="computeroutput">doc(base_href)</code> and
<code class="computeroutput">doc(base_target)</code> for setting
&lt;base&gt; element via blank-baster (see issue #3435)</p></li><li class="listitem">
<p>Groups:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>When a new group is created, flush all the group::get_id caches
with the same name so that the new group can be fetched correctly
in case it replaces a previously deleted one</p></li><li class="listitem"><p>Cleanup message keys coming from groups in acs-translations when
a group is deleted</p></li>
</ul></div>
</li><li class="listitem">
<p>acs-lang:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<code class="computeroutput">lang::util::convert_to_i18n</code>:
do not always register a en_US translation, which would be always
overridden. Instead, let <code class="computeroutput">lang::message::register</code> make sure that a
en_US message exists and create one only as a fallback.</p></li><li class="listitem"><p>
<code class="computeroutput">lc_time_fmt</code>: leverage Tcl
clock to address shortcomings such as handling of dates in
Julian/Gregorian calendar and impossible dates such as 1999-02-29,
implement missing formats, support previously undocumented formats
explicitly</p></li>
</ul></div>
</li><li class="listitem"><p>search: make sure objects in the search indexer queue still
exist by the time they are swept by the indexer (e.g. items deleted
before the indexer could sweep them)</p></li><li class="listitem"><p>
<code class="computeroutput">attribute::delete</code>: fix proc
so it leverages stored procedure capability of dropping the
database table as well</p></li><li class="listitem"><p>
<code class="computeroutput">util::http</code>: fix UTF-8
encoding issues for some cornercases</p></li><li class="listitem"><p>Localization: Complete Italian and Spanish localization for the
whole .LRN set of packages (including themes). Message keys for new
and previously localized packages have also been updated</p></li>
</ul></div>
</li><li class="listitem">
<p>General cleanup/maintenance</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>Improved handling of server implementation-specific code:
server-specific code can be optionally loaded via specifying the
server family in the filename. Provided <code class="computeroutput">*-procs-aolserver.tcl</code> and <code class="computeroutput">*-procs-naviserver.tcl</code> similar to
*.postgresql.xql and *.oracle.xql where appropriate</p></li><li class="listitem"><p>Modernization of Tcl idioms.</p></li><li class="listitem"><p>Compliance of files, proc names, ... to the naming
conventions.</p></li><li class="listitem"><p>White space cleanup, indentation changes.</p></li><li class="listitem"><p>Improvement of public API documentation</p></li><li class="listitem"><p>Adjustment of proc protection levels (public, private)</p></li><li class="listitem"><p>Adjustment of log severity</p></li><li class="listitem"><p>Cleanup of obsolete files</p></li><li class="listitem"><p>Replacement of handcrafted forms by ad_form</p></li><li class="listitem"><p>Typo fixing</p></li><li class="listitem"><p>Editor hints</p></li><li class="listitem"><p>Replacement of deprecated calls</p></li><li class="listitem"><p>Addition of missing contracts</p></li><li class="listitem"><p>...</p></li>
</ul></div>
</li><li class="listitem">
<p>SQL cleanup:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">
<p>Cleanup of obsolete nonportable SQL constructs in a way Oracle
and PostgreSQL code base divergency is reduced:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>"nvl" -&gt; "coalesce"</p></li><li class="listitem"><p>"sysdate" / "now()" -&gt; standard
"current_date" or "current_timestamp"</p></li><li class="listitem"><p>Use standard-compliant "dual" table where appropriate
(required by Oracle, supported by PostgreSQL)</p></li><li class="listitem"><p>Use non-dialectal cast idioms when appropriate</p></li><li class="listitem"><p>Adopt CTE idioms in Oracle codebase as well (e.g. connect -&gt;
with recursive)</p></li><li class="listitem"><p>... (reference Oracle version will be 11gr2 as is oldest version
officially supported by Oracle (See <a class="ulink" href="http://www.oracle.com/us/support/library/lifetime-support-technology-069183.pdf" target="_top">here</a> and <a class="ulink" href="https://n4stack.io/oracle-11g-end-of-life/" target="_top">here</a>)</p></li>
</ul></div>
</li><li class="listitem">
<p>Reduced superfluous .xql queries</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>acs-subsite: delete 21 files with un-referenced .xql queries</p></li><li class="listitem"><p>acs-tcl: delete 4 files</p></li><li class="listitem"><p>news: 3 files</p></li><li class="listitem"><p>file-storage: 1 file</p></li><li class="listitem"><p>dotlrn: 9 files</p></li>
</ul></div>
</li>
</ul></div>
</li><li class="listitem">
<p>New Packages:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>cookie-consent: alerting users about the use of cookies on a
website</p></li><li class="listitem"><p>boomerang: performance of your website from your end user’s
point of view</p></li><li class="listitem"><p>xooauth: OAuth implementation, including LTI (Learning Tools
Interoperability)</p></li><li class="listitem"><p>dotlrn-bootstrap3-theme: Bootstrap 3 theme for DotLRN</p></li><li class="listitem"><p>xowf-monaco-plugin: Integration of Monaco editor with for code
exercise types in xowf</p></li><li class="listitem"><p>proctoring-support: utilities and user interfaces to implement
proctoring of the user session, mainly intended in the context of
distance education and online exams. The main proctoring feature
relies only on web technologies and does not require any plugin or
additional software. Optional support for the Safe Exam Browser has
also been introduced. The package is currently at the core of WU
Online Exam infrastructure and is integrated in the inclass exam
implementation for xowf</p></li>
</ul></div>
</li>
</ul></div>
</li><li class="listitem"><p>Require Tcl 8.6, XOTcl 2.1, PostgreSQL 9.6 (PostgreSQL 9.5 EOL:
<a class="ulink" href="https://www.postgresql.org/support/versioning/" target="_top">February 2021</a>), tdom 0.9</p></li>
</ul></div><p>Altogether, OpenACS 5.10.0 differs from OpenACS 5.9.1 by the
following statistics</p><pre class="programlisting">
 3445 files changed, 215464 insertions(+), 193642 deletions(-) 
</pre><p>contributed by 7 committers (Antonio Pisano, Gustaf Neumann,
Günter Ernst, Hector Romojaro, Michael Aram, Stefan Sobernig,
Thomas Renner) and additional 13 patch/bugfix providers (Felix
Mödritscher, Florian Mosböck, Frank Bergmann, Franz Penz, Hanifa
Hasan, Keith Paskett, Markus Moser, Maurizio Martignano, Monika
Andergassen, Nathan Coulter, Rainer Bachleitner, Stephan
Adelsberger, Tony Kirkham). All packages of the release were tested
with PostgreSQL 13.* and Tcl 8.6.*.</p><p>For more details, consult the <a class="ulink" href="http://openacs.org/changelogs/ChangeLog-5.10.0" target="_top">raw
ChangeLog</a>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-9-1" id="release-notes-5-9-1"></a>Release 5.9.1</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>The release of OpenACS 5.9.1 contains the 88 packages of the
oacs-5-9 branch. These packages include the OpenACS core packages,
the major application packages (e.g. most the ones used on
OpenACS.org), and DotLRN 2.9.1.</p></li><li class="listitem">
<p>Summary of changes:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>Refactoring of rich-text editor integration</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>Driving force: Debian packaging (e.g. js minified code is not
allowed)</p></li><li class="listitem"><p>Moved out code from acs-templating, provided interfaces to add
many different richtext editors as separate packages</p></li><li class="listitem">
<p>New OpenACS packages:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>richtext-xinha</p></li><li class="listitem"><p>richtext-tinymce</p></li><li class="listitem"><p>richtext-ckeditor4 (has ability to choose between CDN and local
installation via web interface)</p></li>
</ul></div>
</li>
</ul></div>
</li><li class="listitem">
<p>Improving admin interface</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">
<p>New theme manager:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>Goals:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Make it easier to keep track of themes with local
modifications</p></li><li class="listitem"><p>Make it easier to create local modification a new themes and to
update these</p></li><li class="listitem"><p>Show differences between default theme parameter (in DB) and
actual settings (in subsite parameters)</p></li><li class="listitem"><p>Allow to delete unused themes</p></li><li class="listitem"><p>Give site admin hints, which theme is used at which subsite</p></li><li class="listitem"><p>Ease theme switching</p></li>
</ul></div>
</li><li class="listitem"><p>Added a subsite::theme_changed callback to be able to handle
theme changes in custom themes (was also necessary for proper
integration with DotLRN theming)</p></li><li class="listitem"><p>Added support for these features under subsite admin
(/admin/)</p></li><li class="listitem"><p>Improved support for themed templates via
[template::themed_template]</p></li>
</ul></div>
</li><li class="listitem"><p>Improved (broken) interface to define/manage groups over web
interface</p></li><li class="listitem"><p>Allow to send as well mail, when membership was rejected</p></li><li class="listitem"><p>New functions [membership_rel::get_user_id],
[membership_rel::get] and [membership_rel::get_group_id] to avoid
code duplication</p></li><li class="listitem"><p>Added support to let user include %forgotten_password_url% in
self-registration emails (e.g. in message key
acs-subsite.email_body_Registration_password)</p></li><li class="listitem">
<p>Improved subsite/www/members</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Make it possible to manage members of arbitrary groups</p></li><li class="listitem"><p>Improved performance for large groups</p></li><li class="listitem"><p>Improved configurability: when ShowMembersListTo is set to
"3", show list to members only, when this is not the
whole subsite</p></li>
</ul></div>
</li><li class="listitem"><p>Improved user interface for /admin/applications for large number
of applications</p></li><li class="listitem"><p>Various fixes for sitewide-admin pages (under /acs-admin)</p></li><li class="listitem"><p>Update blueprint in "install from repository"
(currently just working in NaviServer)</p></li>
</ul></div>
</li><li class="listitem">
<p>SQL</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">
<p>Further cleanup of .xql files (like what as done for acs-subsite
in OpenACS 5.9.0):</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>36 files deleted</p></li><li class="listitem"><p>Removed more than 100 obsolete named queries</p></li><li class="listitem"><p>Stripped misleading SQL statements</p></li>
</ul></div>
</li><li class="listitem"><p>Marked redundant / uncalled SQL functions as deprecated</p></li><li class="listitem"><p>Replaced usages of obsolete view
"all_object_party_privilege_map" by
"acs_object_party_privilege_map"</p></li><li class="listitem">
<p>Removed type discrepancy introduced in 2002:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>acs_object_types.object_type has type varchar(1000), while</p></li><li class="listitem"><p>acs_object_types.supertype has type varchar(100)</p></li><li class="listitem"><p>... several more data types are involved, using
acs_object_types.object_type as foreign key</p></li>
</ul></div>
</li><li class="listitem">
<p>Simplified core SQL functions by using defaults:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Number of functions reduced by a factor of 2 compared to OpenACS
5.9.0 (while providing compatibility for clients using old
versions),</p></li><li class="listitem"><p>Reduced code redundancy</p></li><li class="listitem">
<p>Affected functions:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Reduced content_item__new from 12 versions to 6,</p></li><li class="listitem"><p>Reduce content_revision__new from 7 to 4</p></li><li class="listitem"><p>Similar in image__new, image__new_revision, content_item__copy,
content_item__get_title, content_item__move</p></li>
</ul></div>
</li><li class="listitem"><p>PostgreSQL 9.5 supports named parameter in the same syntax as in
Oracle. Further reduction of variants will be possible, once
OpenACS requires at least PostgreSQL 9.5</p></li>
</ul></div>
</li><li class="listitem"><p>Reduced usage of deprecated versions of SQL functions (mostly
content repository calls)</p></li><li class="listitem"><p>Reduced generation of dead tuples by combining multiple DML
statements to one (reduces costs of checkpoint cleanups in
PostgreSQL)</p></li><li class="listitem">
<p>Permission queries:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Improved performance</p></li><li class="listitem"><p>Support PACKAGE.FUNCTION notation for PostgreSQL to allow calls
permission queries exactly the same way as in Oracle (e.g.
"acs_permission.permission_p()"). This helps to reduce
the number of postgres specific .xql files.</p></li>
</ul></div>
</li><li class="listitem">
<p>Modernize SQL:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Use real Boolean types instead of character(1) (done for
new-portal, forums, faq, attachments, categories, dotlrn,
dotlrn-forums, evaluation)</p></li><li class="listitem"><p>Use real enumeration types rather than check constraints (done
for storage_type text/file/lob)</p></li>
</ul></div>
</li>
</ul></div>
</li><li class="listitem">
<p>CR hygienics (reduce cr bloat)</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">
<p>Provided means to avoid insert/update/delete operations in the
search queue:</p><p>OpenACS adds for every new revision often multiple entries to
the search_queue, without providing any means to prevent this. This
requires for busy sites very short intervals between queue sweeps
(otherwise too many entries pile up). Another consequence is that
this behavior keeps the PostgreSQL auto-vacuum daemons permanently
active. Many of these operations are useless in cases where the
content repository is used for content that should not be provided
via search. The changed behavior should honors a publish-date set
to the future, since it will not add any content with future
publish dates to the search-queue.</p>
</li><li class="listitem">
<p>Reduced number of insert cr_child_rels operations, just when
needed:</p><p>cr_child_rels provide only little benefit (allow one to use
roles in a child-rel), but the common operation is a well available
in cr_items via the parent_id. cr_child_rels do not help for
recursive queries either. One option would be to add an additional
argument for content_item__new to omit child-rel creation (default
is old behavior) and adapt the other cases.</p>
</li>
</ul></div>
</li><li class="listitem">
<p>Security improvements</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">
<p>Added support against <a class="ulink" href="/xowiki/CSRF" target="_top">CSRF</a> (cross site request forgery)</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>OpenACS maintains a per-request CSRF token that ensures that
form replies are coming just from sites that received the form</p></li><li class="listitem"><p>CSRF support is optional for packages where CSRF is less
dangerous, and such requests are wanted (e.g. search and
API-browser)</p></li>
</ul></div>
</li><li class="listitem">
<p>Added Support for W3C "Upgrade-Insecure-Headers" (see
https://www.w3.org/TR/upgrade-insecure-requests/):</p><p>For standard compliant upgrade for requests from HTTP to
HTTPS</p>
</li><li class="listitem"><p>Added support for W3C "Subresource Integrity" (SRI;
see https://www.w3.org/TR/SRI/)</p></li><li class="listitem">
<p>Added support for W3C "Content Security Policy"
(<a class="ulink" href="/xowiki/CSP" target="_top">CSP</a>; see
https://www.w3.org/TR/CSP/)</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Removed "javascript:*" links (all such URLs are
removed from the 90 packages in oacs-5-9, excluding js libraries
(ajaxhelper) and richtext code)</p></li><li class="listitem"><p>Removed "onclick", "onfocus",
"onblur", "onchange" handlers from all .adp and
.tcl files in the 90 packages in oacs-5-9 (excluding js libraries
(ajaxhelper) and richtext code)</p></li><li class="listitem"><p>Added optional nonces to all &lt;script&gt; elements with
literal JavaScript content</p></li>
</ul></div>
</li><li class="listitem"><p>Removed "generic downloader", which allowed to
download arbitrary content items, when item_id was known
(bug-fix)</p></li><li class="listitem"><p>Improved protection against XSS and SQL-injection (strengthen
page contracts, add validators, added page_contract_filter
"localurl", improve HTML escaping, and URI encoding)</p></li><li class="listitem"><p>Fixed for potential traversal attack
(acs-api-documentation-procs)</p></li>
</ul></div>
</li><li class="listitem">
<p>Improvements for "host-node mapped" subsites</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>Fixed links from host-node mapped subsite pages to swa-functions
(must be always on main subsite)</p></li><li class="listitem"><p>Made "util_current_directory" aware of
host-node-mapped subsites</p></li><li class="listitem"><p>Added ability to pass "-cookie_domain" to make it
possible to use the same cookie for different domains</p></li><li class="listitem"><p>Fixed result of affected commands
"util_current_location", "ad_return_url",
"ad_get_login_url" and "ad_get_logout_url" for
HTTP and HTTPS, when UseHostnameDomainforReg is 0 or 1.</p></li><li class="listitem"><p>Improved UI for host-node maps when a large number of site nodes
exists</p></li>
</ul></div>
</li><li class="listitem">
<p>Reform of acs-rels</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>Made acs-rels configurable to give the developer the option to
specify, whether these are composable or not (default fully
backward compatible). This is required to control transitivity in
rel-segments</p></li><li class="listitem">
<p>The code changes are based on a patch provided by Michael
Steigmann. For details, see:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p><a class="ulink" href="http://openacs.org/forums/message-view?message_id=4031049" target="_top">http://openacs.org/forums/message-view?message_id=4031049</a></p></li><li class="listitem"><p><a class="ulink" href="http://openacs.org/forums/message-view?message_id=5330734" target="_top">http://openacs.org/forums/message-view?message_id=5330734</a></p></li>
</ul></div>
</li>
</ul></div>
</li><li class="listitem">
<p>Improved status code handlers for AJAX scenarios</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>Don&#39;t report data source errors with status code 200 (use
422 instead)</p></li><li class="listitem"><p>Let "permission::require_permission" return forbidden
(403) in AJAX calls (determined via [ad_conn ajaxp])</p></li>
</ul></div>
</li><li class="listitem">
<p>Improved Internationalization</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">
<p>Extended language catalogs for</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Russian (thanks to v v)</p></li><li class="listitem"><p>Italian (thanks to Antonio Pisano)</p></li><li class="listitem"><p>Spanish (thanks to Hector Romojaro)</p></li><li class="listitem"><p>German (thanks to Markus Moser)</p></li>
</ul></div>
</li><li class="listitem"><p>Added (missing) message keys</p></li><li class="listitem"><p>Improved wording of entries</p></li><li class="listitem"><p>Added message keys for member_state changes, provide API via
group::get_member_state_pretty</p></li>
</ul></div>
</li><li class="listitem">
<p>Improved online documentation (/doc)</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>Fixed many broken links</p></li><li class="listitem"><p>Removed fully obsolete sections</p></li><li class="listitem"><p>Improved markup (modernize HTML)</p></li><li class="listitem"><p>Updated various sections</p></li>
</ul></div>
</li><li class="listitem">
<p>Misc code improvements:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>18 issues from the OpenACS-bug-tracker fixed</p></li><li class="listitem"><p>Made code more robust against invalid/incorrect input
(page_contracts, validators, values obtained from header fields
such as Accept-Language)</p></li><li class="listitem"><p>Fixed quoting of message keys on many places</p></li><li class="listitem"><p>Improved exception handling (often, a "catch" swallows
one too much, e.g. script_aborts), introducing
"ad_exception".</p></li><li class="listitem">
<p>Generalized handling of leading zeros:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Fixed cases where leading zeros could lead to unwanted octal
interpretations</p></li><li class="listitem"><p>Switch to use of " util::trim_leading_zeros" instead
of "template::util::leadingTrim",
"dt_trim_leading_zeros" and
"template::util::leadingTrim", marked the latter as
deprecated</p></li>
</ul></div>
</li><li class="listitem">
<p>URL encoding</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>"ad_urlencode_folder_path": new function to perform an
urlencode operation on the segments of the provided folder path</p></li><li class="listitem"><p>"export_vars": encode path always correctly, except
-no_base_encode is specified</p></li><li class="listitem"><p>Fixed encoding of the URL path in
"ad_returnredirect"</p></li>
</ul></div>
</li><li class="listitem">
<p>Improvements for "ad_conn":</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Added [ad_conn behind_proxy_p] to check, whether the request is
coming from behind a proxy server</p></li><li class="listitem"><p>Added [ad_conn behind_secure_proxy_p] to check, whether the
request is coming from behind a secure proxy server</p></li><li class="listitem"><p>Added [ad_conn ajax_p] to check, whether the request is an AJAX
requests (assumption: AJAX request sets header-field
Requested-With: XMLHttpRequest")</p></li><li class="listitem"><p>Added [ad_conn vhost_url] to obtain the url of host-node-mapped
subsites</p></li>
</ul></div>
</li><li class="listitem"><p>Added various missing upgrade scripts (missing since many years)
of changes that were implemented for new installs to reduce
differences between "new"-and "old" (upgraded)
installations</p></li><li class="listitem">
<p>Templating</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Get rid of various pesky "MISSING FORMWIDGET:
...formbutton:ok" messages</p></li><li class="listitem"><p>Improved support for JavaScript event handlers in
template::head</p></li><li class="listitem"><p>New functions "template::add_event_listener" and
"template::add_confirm_handler"</p></li><li class="listitem"><p>Fix handling, when "page_size_variable_p" is set (was
broken since ages)</p></li>
</ul></div>
</li><li class="listitem">
<p>Improved location and URL handling:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Refactored and commented "util_current_location" to
address security issues, handle IPv6 addresses, IP literal
notation, multiple drivers, "</p></li><li class="listitem"><p>Improved "security::get_secure_location" (align with
documentation)</p></li><li class="listitem">
<p>New functions:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>"util::configured_location"</p></li><li class="listitem"><p>"util::join_location",
"util::split_location"</p></li>
</ul></div><p>for working on HTTP locations to reduce scattered regexps
handling URL components</p>
</li><li class="listitem"><p>Improved IPv6 support</p></li><li class="listitem"><p>Use native "ns_parseurl" when available, provide
backward compatible version for AOLserver</p></li>
</ul></div>
</li><li class="listitem">
<p>MIME types:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Added more Open XML formats for MS-Office to allowed content
types</p></li><li class="listitem"><p>Modernized entries to IANA recommendations</p></li><li class="listitem"><p>New function "cr_check_mime_type" centralizing the
retrieval of the mime_type from uploaded content</p></li>
</ul></div>
</li><li class="listitem">
<p>Finalized cleanup of permissions (started in OpenACS 5.9.0):</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">
<p>Get rid of "acs_object_context_index " (and therefore
on "acs_object_party_privilege_map " as well) on
PostgreSQL.</p><p>Reasons:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>huge table,</p></li><li class="listitem"><p>expensive maintenance, used only in a few places,</p></li>
</ul></div>
</li></ul></div>
</li><li class="listitem">
<p>Misc new functions:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>"lang::util::message_key_regexp": factor out scattered
regexp for detecting message keys</p></li><li class="listitem"><p>"ns_md5" and "ns_parseurl": improve
compatibility between AOLserver and NaviServer</p></li><li class="listitem"><p>"ad_dom_sanitize_html": allow one to specify different
sets of tags, attributes and protocols and
"ad_dom_fix_html", which is a light weight tidy
variant.</p></li>
</ul></div>
</li><li class="listitem"><p>Improved HTML rendering (acs-api-browser), provide width and
height to speed up rendering</p></li><li class="listitem"><p>Improved ADP files (e.g. missing doc(title))</p></li><li class="listitem"><p>Added usage of "ad_include_contract" on more
occasions</p></li><li class="listitem"><p>Modernize Tcl and HTML coding</p></li><li class="listitem"><p>Reduced dependency on external programs (use Tcl functions
instead)</p></li><li class="listitem"><p>Improved robustness of "file delete" operations all
over the code</p></li><li class="listitem"><p>Improved documentation, fix demo pages</p></li><li class="listitem"><p>Aligned usages of log notification levels (distinction between
"error", "warning" and "notice") with
coding-standards</p></li><li class="listitem">
<p>Cleaned up deprecated calls:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Removed usage of deprecated API functions (e.g.
"cc_lookup_email_user", "cc_email_from_party",
"util_unlist", ...)</p></li><li class="listitem"><p>Moved more deprecated procs to acs-outdated</p></li><li class="listitem"><p>Marked remaining (and unused) "cc_*" functions as well
as deprecated.</p></li>
</ul></div>
</li><li class="listitem"><p>Improved Oracle and windows support</p></li><li class="listitem"><p>Fixed common spelling errors and standardize spelling of product
names all over the code (comments, documentation, ...)</p></li><li class="listitem"><p>Many more small bug fixes</p></li>
</ul></div>
</li><li class="listitem">
<p>Packages:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;"><li class="listitem">
<p>New Package Parameters</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem">
<p>acs-kernel:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>MaxUrlLength: remove hard-coded constant in request processor
for max accepted url paths</p></li><li class="listitem"><p>SecureSessionCookie: Let site admin determine, whether or not to
use secured session cookies (useful, when not all requests are over
HTTPS)</p></li><li class="listitem"><p>CSPEnabledP: activate/deactivate CSP</p></li>
</ul></div>
</li><li class="listitem">
<p>acs-kernel (recommended to be set via config file in section
"ns/server/${server}/&gt;acs"</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>NsShutdownWithNonZeroExitCode: tell NaviServer to return with a
nonzero return code to cause restart (important under windows)</p></li><li class="listitem"><p>LogIncludeUserId: include user_id in access log</p></li>
</ul></div>
</li><li class="listitem">
<p>acs-api-browser:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem"><p>ValidateCSRFP: make checking of CSRF optional (default 1)</p></li></ul></div>
</li><li class="listitem">
<p>acs-content-repository:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem"><p>AllowMimeTypeCreationP: Decides whether we allow unknown mime
types to be automatically registered (default: 0}</p></li></ul></div>
</li><li class="listitem">
<p>news-portlet:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem"><p>display_item_lead_p: Should we display news leads in the
portlet? (default 0)</p></li></ul></div>
</li><li class="listitem">
<p>search:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem"><p>ValidateCSRFP: make checking of CSRF optional (default 1)</p></li></ul></div>
</li><li class="listitem">
<p>xotcl-request-monitor:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;"><li class="listitem"><p>do_track_activity: turn activity monitoring on or off (default
0)</p></li></ul></div>
</li>
</ul></div>
</li></ul></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;"><li class="listitem">
<p>New OpenACS packages:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>richtext-xinha</p></li><li class="listitem"><p>richtext-tinymce</p></li><li class="listitem"><p>richtext-ckeditor4 (has ability to choose between CDN and local
installation via GUI)</p></li><li class="listitem"><p>openacs-bootstrap3-theme (as used on openacs.org)</p></li><li class="listitem"><p>dotlrn-bootstrap3-theme</p></li>
</ul></div>
</li></ul></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem">
<p>xotcl-core:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Improved XOTcl 2.0 and NX support (e.g. api-browser)</p></li><li class="listitem"><p>Added "-debug", "-deprecated" to ad_*
defined methods (such as e.g. "ad_instproc")</p></li><li class="listitem"><p>Make use of explicit "create" statements when creating
XOTcl/NX objects (makes it easier to grab intentions and to detect
typos)</p></li><li class="listitem"><p>Added parameter to "get_instance_from_db" to specify,
whether the loaded objects should be initialized</p></li><li class="listitem"><p>Added support for PostgreSQL prepared statements of SQL
interface in ::xo::dc (nsdb driver)</p></li>
</ul></div>
</li><li class="listitem">
<p>xowiki:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Named all web-callable methods www-NAME (to make it clear, what
is called, what has to be checked especially carefully)</p></li><li class="listitem"><p>Moved templates from www into xowiki/resources to avoid naming
conflicts</p></li><li class="listitem"><p>Improved ckeditor support</p></li><li class="listitem"><p>Added usage of prepared statements for common queries</p></li><li class="listitem"><p>Improved error handling</p></li><li class="listitem"><p>Better value checking for query parameter, error reporting via
ad_return_complaint</p></li><li class="listitem"><p>Added option "-path_encode" to methods
"pretty_link" and "folder_path" to allow one to
control, whether the result should be encoded or not (default
true)</p></li><li class="listitem">
<p>Form fields:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Improved repeatable form fields (esp. composite cases),
don&#39;t require preallocation (can be costly in composite
cases)</p></li><li class="listitem"><p>Added signing of form-fields</p></li><li class="listitem"><p>Added HTML5 attributes such as "multiple" (for
"file") or "autocomplete"</p></li><li class="listitem"><p>Fixed generation of "orderby" attribute based on
form-field names</p></li><li class="listitem"><p>richtext: allow one to specify "extraAllowedContent"
via options</p></li><li class="listitem"><p>Improved layout of horizontal check boxes</p></li>
</ul></div>
</li><li class="listitem">
<p>Menu bar:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Added dropzone (requires bootstrap): drag and drop file
upload</p></li><li class="listitem"><p>Added mode toggle (requires bootstrap)</p></li><li class="listitem"><p>Extended default policies for handling e.g. dropzone
(file-upload method)</p></li><li class="listitem"><p>Distinguish between "startpage"
(menu.Package.Startpage) and "table of contents"
(menu.Package.Toc)</p></li>
</ul></div>
</li><li class="listitem">
<p>Notifications:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem"><p>Added support for better tailorable notifications: introduced
method "notification_render" (similar to
"search_render")</p></li><li class="listitem"><p>Added support for tailorable subject lines (method
"notification_subject")</p></li>
</ul></div>
</li><li class="listitem"><p>Improved bootstrap support, use "bootstrap" as
PreferredCSSToolkit</p></li><li class="listitem"><p>Switched to ckeditor4 as PreferredRichtextEditor</p></li><li class="listitem"><p>Improved handling of script-abort from within the payload of
::xowiki::Object payloads</p></li><li class="listitem"><p>Added parameter to "get_all_children" to specify,
whether the child objects should be initialized</p></li>
</ul></div>
</li><li class="listitem">
<p>xowf:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Added property "payload" to
"WorkflowConstruct" in order to simplify customized
workflow "allocate" actions</p></li><li class="listitem"><p>Internationalized more menu buttons</p></li>
</ul></div>
</li><li class="listitem">
<p>xotcl-request-monitor</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Added class "BanUser" (use. e.g. ip address to
disallow requests from a user via request monitor)</p></li><li class="listitem"><p>Added support for optional user tracking in database</p></li><li class="listitem"><p>Added support for monitoring response-time for certain URLs via
munin</p></li><li class="listitem"><p>Increased usage of XOTcl 2.0 variable resolver (potentially
speed improvement 4x)</p></li><li class="listitem"><p>Performed some refactoring of response-time handling to allow
site-admin to make e.g. use of NaviServer&#39;s dynamic connection
pool management (not included in CVS)</p></li><li class="listitem"><p>Added support for partial times in long-calls.tcl to ease
interpretation of unexpected slow calls</p></li><li class="listitem"><p>last100.tcl: Don&#39;t report hrefs to URLs, except to SWAs</p></li>
</ul></div>
</li><li class="listitem">
<p>chat:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Introduced new options to set chat rooms so login and/or logout
message are not issued every time a user enters/exits a chat-room
(important for chats with huge number of participants)</p></li><li class="listitem"><p>Parameterized viewing of chat-logs</p></li><li class="listitem"><p>Fixed cases of over-/under-quoting</p></li><li class="listitem"><p>Fixed JavaScript for IE, where innerHTML can cause problems</p></li>
</ul></div>
</li><li class="listitem">
<p>file-storage:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Don&#39;t show action keys, when user has no permissions</p></li><li class="listitem"><p>Added support for copying of same-named files into a folder
(adding suffix)</p></li><li class="listitem"><p>Fixed old bugs in connection with "views" package</p></li>
</ul></div>
</li>
</ul></div>
</li>
</ul></div>
</li>
</ul></div><p>Altogether, OpenACS 5.9.1 differs from OpenACS 5.9.1 by the
following statistics</p><pre class="programlisting">
       3548 files changed, 113292 insertions(+), 90507 deletions(-)
    </pre><p>contributed by 5 committers (Michael Aram, Gustaf Neumann,
Antonio Pisano, Hector Romojaro, Thomas Renner) and 8 patch/bugfix
providers (Frank Bergmann, Günter Ernst, Brian Fenton, Felix
Mödritscher, Marcus Moser, Franz Penz, Stefan Sobernig, Michael
Steigman). All packages of the release were tested with PostgreSQL
9.6.* and Tcl 8.5.*.</p><p>For more details, consult the <a class="ulink" href="" target="_top">raw ChangeLog</a>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-9-0" id="release-notes-5-9-0"></a>Release 5.9.0</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>The release of OpenACS 5.9.0 contains the 78 packages of the
oacs-5-9 branch. These packages include the OpenACS core packages,
the major application packages (e.g. most the ones used on
OpenACS.org), and DotLRN 2.9.0.</p></li><li class="listitem">
<p>Summary of changes:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>SQL:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>Improved performance of acs-object deletion.</p></li><li class="listitem"><p>Replaced many manual referential integrity calls by built-in
handing in PostgreSQL.</p></li><li class="listitem"><p>Removed various manual bookkeeping and deletion operations in
the content repository by built-in handing in PostgreSQL.</p></li><li class="listitem"><p>Removed tree_sortkey on acs-objects to reduce its size and to
speedup operations, where the context-id is changed (could take on
large installation several minutes in earlier versions)</p></li><li class="listitem"><p>Removed several uncalled / redundant SQL statements and
functions.</p></li><li class="listitem">
<p>Cleanup of .xql files in acs-subsite:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Some cleanup of .xql files: removed misleading sql-statements
from db_* calls, which were ignored due .xql files</p></li><li class="listitem"><p>Removed bug where same query-name was used in different branches
of an if-statement for different SQL statements, but the query-name
lead to the wrong result.</p></li><li class="listitem"><p>Removed multiple entries of same query name from .xql files
(e.g. the entry
"package_create_attribute_list.select_type_info" was 7
(!) times in a single .xql file)</p></li>
</ul></div>
</li>
</ul></div>
</li><li class="listitem">
<p>Web Interface:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>Improve Performance of WebSites created with OpenACS: e.g. move
core.js to a body requests, provide kernel parameter
ResourcesExpireInterval to specify expiration times for
resources.</p></li><li class="listitem"><p>Much better protection against XSS attacks.</p></li><li class="listitem"><p>Improved HTML validity (especially for admin pages)</p></li><li class="listitem">
<p>Improved admin interface:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Placed all installation options to a single page.</p></li><li class="listitem"><p>Added pagination to /admin/applications (was unusable for large
sites)</p></li><li class="listitem"><p>New admin pages for subsites linked from site-wide-admin package
(/acs-admin).</p></li><li class="listitem"><p>Added explanatory text to several admin pages.</p></li>
</ul></div>
</li><li class="listitem"><p>Add lightweight support for ckeditor4 for templating::richtext
widget (configurable via package parameter
"RichTextEditor" of acs-templating. ckeditor4 supports
mobile devices (such as iPad, ...)</p></li>
</ul></div>
</li><li class="listitem">
<p>Templating:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>Improved theme-ability: Moved more information into theme
packages in order to create responsive designs, reduce hard-coding
of paths, HTML etc.</p></li><li class="listitem"><p>Improved include-handling: All includes are now theme-able,
interfaces of includes can be defined with
"ad_include_contract" (similar to ad_page_contract).</p></li><li class="listitem"><p>Improved them-ability for display_templates. One can now provide
a display_template_name (similar to the SQL statement name) to
refer to display templates. This enables reusability and is
theme-able.</p></li><li class="listitem"><p>Dimensional slider reform (ad_dimensional): Removed hard-coded
table layout from dimensional slider. Add backwards compatible
templates Move hard-coded styles into theme styling</p></li><li class="listitem"><p>Notification chunks are now theme-able as well (using
ad_include_contract)</p></li><li class="listitem"><p>Complete template variable suffixes (adding noi18n, addressing
bug #2692, full list is now: noquote, noi18n, literal)</p></li><li class="listitem"><p>Added timeout and configurable secrets for signed url parameters
to export_vars/page_contracts. This can be used to secure sensitive
operations such as granting permissions since a link can be set to
timeout after e.g. 60 seconds; after that, the link is invalid. A
secret (password) can be set in section ns/server/$server/acs
parameter "parametersecret". For example, one can use now
"user_id:sign(max_age=60)" in export_vars to let the
exported variable expire after 60 seconds.</p></li>
</ul></div>
</li><li class="listitem">
<p>Misc:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>Added ability to show ns_log statements of current request to
developer support output when developer support is activated
(controlled via package parameter
"TclTraceLogServerities" in the acs-tcl package
parameters)</p></li><li class="listitem"><p>Added ability to save data sent by ns_return in files on the
filesystem. This can be used to validate HTML content also for
password protected pages (controlled via package parameter
"TclTraceSaveNsReturn" in the acs-tcl package
parameters)</p></li><li class="listitem"><p>New API function "ad_log" having the same interface as
ns_log, but which logs the calling information (like URL and
call-stack) to ease tracking of errors.</p></li><li class="listitem"><p>Use per-thread caching to reduce number of mutex lock operations
and lock contention on various caches (util-memoize, xo_site_nodes,
xotcl_object_types) and nsvs (e.g. ds_properties)</p></li><li class="listitem"><p>Improved templating of OpenACS core documentation</p></li><li class="listitem"><p>Improved Russian Internationalization</p></li><li class="listitem"><p>Make pretty-names of acs-core packages more consistent</p></li><li class="listitem"><p>Mark unused functions of acs-tcl/tcl/table-display-procs.tcl as
deprecated</p></li><li class="listitem"><p>Many more bug fixes (from bug tracker and extra) and performance
improvements.</p></li><li class="listitem">
<p>Version numbers:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Require PostgreSQL 9.0 (End Of Life of PostgreSQL 8.4 was July
2014)</p></li><li class="listitem"><p>Require XOTcl 2.0 (presented at the Tcl conference in 2011).</p></li>
</ul></div>
</li>
</ul></div>
</li><li class="listitem">
<p>Changes in application packages:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;"><li class="listitem"><p>Various bug fixes and improvements for e.g. file-storage,
forums, news, notifications, xowiki.</p></li></ul></div>
</li>
</ul></div>
</li>
</ul></div><p>Altogether, OpenACS 5.9.0 differs from OpenACS 5.8.1 by the
following statistics</p><pre class="programlisting">
      3658 files changed, 120800 insertions(+), 97617 deletions(-)
    </pre><p>contributed by 4 committers (Michael Aram, Victor Guerra, Gustaf
Neumann, Antonio Pisano) and patch/bugfix providers (Frank
Bergmann, Andrew Helsley, Felix Mödritscher, Markus Moser, Franz
Penz, Thomas Renner). These are significantly more changes as the
differences in the last releases. All packages of the release were
tested with PostgreSQL 9.4.* and Tcl 8.5.*.</p><p>For more details, consult the <a class="ulink" href="" target="_top">raw ChangeLog</a>.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-8-1" id="release-notes-5-8-1"></a>Release 5.8.1</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>The release contains the 78 packages of the oacs-5-8 branch.
These packages contain the OpenACS core packages, major application
packages (e.g. most the ones used on OpenACS.org), and DotLRN.</p></li><li class="listitem">
<p>All packages have the following properties:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: circle;">
<li class="listitem">
<p>SQL:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>All packages are PostgreSQL 9.1+ compatible (tested with
PostgreSQL 9.3)</p></li><li class="listitem"><p>All SQL files with stored procedures use the recommended $$
quoting</p></li><li class="listitem"><p>All SQL-functions have regular function arguments instead of the
old-style aliases</p></li><li class="listitem"><p>The function_args() (query-able meta-data) are completed and
fixed</p></li><li class="listitem"><p>Incompatible functions (e.g. for sequences) are replaced.</p></li>
</ul></div>
</li><li class="listitem">
<p>Tcl:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>All packages were brought up Tcl 8.5, including the actual Tcl
idioms where appropriate (e.g. using the safer expand operator,
range indices, dict, lassign, etc.)</p></li><li class="listitem"><p>The code was updated to prefer byte-compiled functions instead
of legacy functions from ancient Tcl versions.</p></li><li class="listitem"><p>The code works with NaviServer and AOLserver.</p></li>
</ul></div>
</li><li class="listitem">
<p>API:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: square;">
<li class="listitem"><p>All packages are free from calls to deprecated code (157
functions are marked as deprecated and will be moved into an
"outdated" package in the 5.9 or 6.0 release)</p></li><li class="listitem"><p>General overhaul of package management</p></li><li class="listitem"><p>Install-from-local and install-from-repository can be used to
install the provided packages based on a acs-core installation.
This means that also DotLRN can be installed from repository or
from local into an existing OpenACS instance.</p></li><li class="listitem"><p>Install-from-repository offers filtering functions, allows to
install optionally from head-channel (for packages not in the base
channel of the installed instance). Install-from-repository works
more like an app-store, showing as well vendor information</p></li><li class="listitem"><p>Packages can be equipped with xml-based configuration files
(e.g. changing parameters for style packages)</p></li><li class="listitem"><p>Package developers can upload .apm packages via workflow for
review by core members and for inclusion to the repository. The
option is integrated with package management, the link is offered
for local packages. We hope to attract additional vendors
(universities, companies) to make their packages available on this
path.</p></li><li class="listitem"><p>New management-functions for package instances (list, create,
delete package instances)</p></li><li class="listitem">
<p>Substantially improved API browser:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Show just relevant parts of .xql files for a function</p></li><li class="listitem"><p>Provide syntax-highlighting for www scripts as well</p></li><li class="listitem"><p>Handle more special cases like e.g. util_memoize</p></li><li class="listitem"><p>Provide links to Tcl functions depending on the installed Tcl
version</p></li><li class="listitem"><p>Provide links to NaviServer or OpenACS functions depending on
installed version</p></li><li class="listitem"><p>Syntax highlighter uses CSS rather than hard-coded markup</p></li><li class="listitem"><p>Significant performance improvement for large installations</p></li>
</ul></div>
</li>
</ul></div>
</li>
</ul></div>
</li>
</ul></div><p>Altogether, OpenACS 5.8.1 differs from OpenACS 5.8.0 in about
100,000 modifications (6145 commits) contributed by 5
committers.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-8-0" id="release-notes-5-8-0"></a>Release 5.8.0</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Compatibility with PostgreSQL 9.2: The new version installs
without any need for special parameter settings in new PostgreSQL
versions. This makes it easier to use e.g. shared or packaged
PostgreSQL installations.</p></li><li class="listitem"><p>Compatibility with NaviServer 4.99.5 or newer</p></li><li class="listitem"><p>Performance and scalability improvements</p></li><li class="listitem"><p>Various bug fixes</p></li>
</ul></div><p>Altogether, OpenACS 5.8.0 differs from OpenACS 5.7.0 in more
than 18.000 modifications (781 commits) contributed by 7
committers.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-7-0" id="release-notes-5-7-0"></a>Release 5.7.0</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem"><p>Made changes that extend acs-kernel&#39;s create_type and
create_attribute procs, so they&#39;re optionally able to create
SQL tables and columns. Optional metadata params allow for the
automatic generation of foreign key references, check exprs,
etc.</p></li></ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-6-0" id="release-notes-5-6-0"></a>Release 5.6.0</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">
<p>Added new package dependency type, "embeds". This is a
variant of the "extends" package dependency type added in
OpenACS 5.5.0. It allows one to write embeddable packages, with
scripts made visible in client packages using URLs which include
the embedded package&#39;s package key. An example embeddable
package might be a rewritten "attachments" package. The
current implementation requires a global instance be mounted, and
client packages generate URLs to that global instance. Among other
things, this leads to the user navigating to the top-level subsite,
losing any subsite theming that might be associated with a
community. Using "embeds", a rewritten package would run
in the client package&#39;s context, maintaining theming and
automatically associating attachments with the client package.</p><p>Added global package parameters - parameters can now have scope
"local" or "global", with "local"
being the default..</p><p>Fixes for ns_proxy handling</p><p>Significant speedup for large sites</p><p>Optional support for selenium remote control
(acs-automated-tests)</p><p>New administration UI to manage mime types and extension map</p><p>Added acs-mail-lite package params for rollout support</p><p>Support for 3-chars language codes in acs-lang</p><p>Added OOXML mime types in acs-content-repository</p>
</li></ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-5-0" id="release-notes-5-5-0"></a>Release 5.5.0</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">
<p>PostgreSQL 8.3 is now fully supported, including the use of the
built-in standard version of tsearch2.</p><p>TinyMCE has been upgraded to 3.2.4.1 with language pack
support.</p><p>acs-mail-lite now correctly implements rollout support.</p><p>Added new package dependency type, "extends".
Implements a weak form of package inheritance (parameters and,
optionally, templates). Multiple inheritance is supported. For
instance, the non-core "layout-managed-subsite" extends
the "acs-subsite" and "layout-manager"
packages, resulting in a package that combines the semantics of
both.</p><p>Added new package attribute "implements-subsite-p"
(default "f"). If true, this package may be mounted as a
subsite and is expected to implement subsite semantics. Typically
used by packages which extend acs-subsite.</p><p>Added new package attribute "inherit-templates-p"
(default "t"). If true, the package inherits templates
defined in the packages it extends. This means that the package
only needs to specify templates where the UI of an extended package
is modified or extended. This greatly reduces the need to fork base
packages when one needs to customize it. Rather than modify the
package directly, use "extends" rather than
"requires" then rewrite those templates you need to
customize.</p><p>Added a simple mechanism for defining subsite themes, removing
the hard-wired choices implemented in earlier versions of OpenACS.
The default theme has been moved into a new package,
"openacs-default-theme". Simplifies the customization of
the look and feel of OpenACS sites and subsites.</p><p>The install xml facility has been enhanced to allow the calling
of arbitrary Tcl procedures and includes various other enhancements
written by Xarg. Packages can extend the facility, too. As an
example of what can be done, the configuration of .LRN communities
could be moved from a set of interacting parameters to a cleaner
XML description of how to build classes and clubs, etc.</p><p>Notifications now calls lang::util::localize on the message
subject and body before sending the message out, using the
recipient locale if set, the site-wide one if not. This will cause
message keys (entered as <span style="color: red">&lt;span&gt;#&lt;/span&gt;</span>....# strings) to be
replaced with the language text for the chosen locale.</p>
</li></ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-4-2" id="release-notes-5-4-2"></a>Release 5.4.2</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">
<p>This is a minor bugfix release.</p><p>Site node caching was removed as doesn&#39;t work correctly</p><p>Critical issues with search on oracle were fixed</p><p>More html strict work etc</p>
</li></ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-4-1" id="release-notes-5-4-1"></a>Release 5.4.1</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem"><p>This is a minor bugfix release.</p></li></ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-4-0" id="release-notes-5-4-0"></a>Release 5.4.0</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">
<p>New Templating API added to add scripts, css, etc to the HTML
HEAD and BODY sections of the generated HTML document. Please see
/packages/acs-templating/tcl/head-procs.tcl or visit the
template::head procs in the API browser for details.</p><p>Templates have been modified to comply with HTML strict</p><p>The Search package&#39;s results page has been improved</p><p>TinyMCE WYSIWYG support has been added, RTE and HTMLArea support
dropped</p><p>acs-mail-lite&#39;s send has been cleaned up to properly encode
content, to handle file attachments, etc. "complex-send"
will disappear from acs-core in a future release.</p>
</li></ul></div>
</div><p>The ChangeLogs include an annotated list of changes (<a class="xref" href="">???</a>) since the last release and in the entire
5.9 release sequence <a class="xref" href="">???</a>.</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-3-1" id="release-notes-5-3-1"></a>Release 5.3.1</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">
<p>Bug fixes.</p><p>New TIPs implemented.</p><p>All Core Automated Tests for Postgres pass.</p><p>New Site and Blank master templates and CSS compatible with the
.LRN Zen work. Compatibility master templates are provided for
existing sites.</p>
</li></ul></div>
</div><p>The ChangeLogs include an annotated list of changes (<a class="xref" href="">???</a>) since the last release and in the entire
5.9 release sequence <a class="xref" href="">???</a>.</p><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-3-0" id="release-notes-5-3-0"></a>Release 5.3.0</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">
<p>Bug fixes.</p><p>New TIPs implemented.</p><p>All Core Automated Tests for Postgres pass.</p>
</li></ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-2-0" id="release-notes-5-2-0"></a>Release 5.2.0</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">
<p>Bug fixes.</p><p>New TIPs implemented.</p><p>This release does <span class="strong"><strong>not</strong></span> include new translations.</p>
</li></ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-1-4" id="release-notes-5-1-4"></a>Release 5.1.4</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem">
<p>Bug fixes.</p><p>The missing CR Tcl API has been filled in, thanks to Rocael and
his team and Dave Bauer.</p><p>This release does <span class="strong"><strong>not</strong></span> include new translations.</p>
</li></ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-1-3" id="release-notes-5-1-3"></a>Release 5.1.3</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem"><p>Bug fixes, primarily for .LRN compatibility in support of
upcoming .LRN 2.1.0 releases. This release does <span class="strong"><strong>not</strong></span> include new translations since
5.1.2.</p></li></ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-1-2" id="release-notes-5-1-2"></a>Release 5.1.2</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Translations synchronized with the translation server. Basque
and Catalan added.</p></li><li class="listitem"><p>For a complete change list, see the Change list since 5.1.0 in
<a class="xref" href="">???</a>.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-1-1" id="release-notes-5-1-1"></a>Release 5.1.1</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>This is the first release using the newest adjustment to the
versioning convention. The OpenACS 5.1.1 tag will apply to OpenACS
core as well as to the most recent released version of every
package, including .LRN.</p></li><li class="listitem"><p>Translations synchronized with the translation server.</p></li><li class="listitem"><p>
<a class="ulink" href="http://openacs.org/bugtracker/openacs/com/acs-lang/bug?bug%5fnumber=1519" target="_top">Bug 1519</a> fixed. This involved renaming all
catalog files for ch_ZH, TH_TH, AR_EG, AR_LB, ms_my, RO_RO, FA_IR,
and HR_HR. If you work with any of those locales, you should do a
full catalog export and then import (via <a class="ulink" href="/acs-lang/admin" target="_top">/acs-lang/admin</a>) after
upgrading acs-lang. (And, of course, make a backup of both the
files and database before upgrading.)</p></li><li class="listitem"><p>Other bug fixes since 5.1.0: <a class="ulink" href="http://openacs.org/bugtracker/openacs/bug?bug_number=1785" target="_top">1785</a>, <a class="ulink" href="http://openacs.org/bugtracker/openacs/bug?bug_number=1793" target="_top">1793</a>, and over a dozen additional bug fixes.</p></li><li class="listitem"><p>For a complete change list, see the Change list since 5.0.0 in
<a class="xref" href="">???</a>.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-1-0" id="release-notes-5-1-0"></a>Release 5.1.0</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Lots of little tweaks and fixes</p></li><li class="listitem"><p>Complete Change list since 5.0.0 in Changelog</p></li><li class="listitem"><p><a class="ulink" href="http://openacs.org/bugtracker/openacs/core?filter%2efix%5ffor%5fversion=125273&amp;filter%2estatus=closed" target="_top">Many Bug fixes</a></p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-0-4" id="release-notes-5-0-4"></a>Release 5.0.4</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem"><p>New translations, including for .LRN 2.0.2.</p></li></ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-0-3" id="release-notes-5-0-3"></a>Release 5.0.3</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem"><p>Bug fixes: <a class="ulink" href="http://openacs.org/bugtracker/openacs/bug?bug%5fnumber=1560" target="_top">1560</a>, <a class="ulink" href="http://openacs.org/bugtracker/openacs/bug?bug%5fnumber=1556" target="_top">#1556. Site becomes unresponsive, requires
restart</a>
</p></li></ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-0-2" id="release-notes-5-0-2"></a>Release 5.0.2</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Bug fixes: <a class="ulink" href="http://openacs.org/bugtracker/openacs/bug?bug%5fnumber=1495" target="_top">#1495. Croatian enabled by default</a>, <a class="ulink" href="http://openacs.org/bugtracker/openacs/bug?bug%5fnumber=1496" target="_top">#1496. APM automated install fails if files have
spaces in their names</a>, <a class="ulink" href="http://openacs.org/bugtracker/openacs/bug?bug%5fnumber=1494" target="_top">#1494. automated upgrade crashes (halting the upgrade
process)</a>
</p></li><li class="listitem"><p>Complete Change list since 5.0.0 in Changelog</p></li><li class="listitem"><p>File tagging scheme in CVS changed to follow <a class="ulink" href="http://openacs.org/forums/message-view?message_id=161375" target="_top">TIP #46: (Approved) Rules for Version Numbering and
CVS tagging of Packages</a>
</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-0-1" id="release-notes-5-0-1"></a>Release 5.0.1</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>All work on the translation server from 7 Nov 2003 to 7 Feb 2004
is now included in catalogs.</p></li><li class="listitem"><p>One new function in acs-tcl, util::age_pretty</p></li><li class="listitem"><p>Complete Change list since 5.0.0 in Changelog</p></li><li class="listitem"><p>Many documentation updates and doc bug fixes</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="release-notes-5-0-0" id="release-notes-5-0-0"></a>Release 5.0.0</h3></div></div></div><p>This is OpenACS 5.0.0. This version contains no known security,
data loss, or crashing bugs, nor any bugs judged release blockers.
This version has received manual testing. It has passed current
automated testing, which is not comprehensive. This release
contains work done on the translation server
http://translate.openacs.org through 7 Nov 2003.</p><p>Please report bugs using our <a class="ulink" href="http://openacs.org/bugtracker/openacs/" target="_top">Bug
Tracker</a> at the <a class="ulink" href="http://openacs.org/" target="_top">OpenACS website</a>.</p><p>You may want to begin by reading our installation documentation
for <a class="xref" href="unix-installation" title="a Unix-like system">the section called “a Unix-like
system”</a>. Note that the Windows documentation is not current for
OpenACS 5.9.0, but an alternative is to use John Sequeira&#39;s
<a class="ulink" href="http://www.jsequeira.com/oasis/about.html" target="_top">Oasis VM project</a>.</p><p>After installation, the full documentation set can be found by
visiting <code class="filename">http://yourserver/doc</code>.</p><p>New features in this release:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>Internationalization support. A message catalog to store
translated text, localization of dates, number formatting, timezone
conversion, etc. Allows you to serve your users in their
language.</p></li><li class="listitem"><p>External authentication. Integrate with outside user databases
through e.g. LDAP, RADIUS, Kerberos, MS Active Directory. Imports
user information through IMS Enterprise 1.1 format. Easily extended
to support other authentication, password management, account
creation, and account import mechanisms. This includes improvements
to the basic cookie handling, so logins can be expired without the
user&#39;s identity being completely lost. You can set login to
expire after a certain period (e.g. 8 hours, then password must be
refreshed), or you can have all issues login cookies expired at
once, e.g. if you have left a permanent login cookie on a public
machine somewhere.</p></li><li class="listitem"><p>User interface enhancements. All pages, including site-wide and
subsite admin pages, will be templated, so they can be styled using
master template and site-wide stylesheets. We have a new
default-master template, which includes links to administration,
your workspace, and login/logout, and is rendered using CSS. And
there&#39;s a new community template
(/packages/acs-subsite/www/group-master), which provides useful
navigation to the applications and administrative UI in a subsite.
In addition, there&#39;s new, simpler UI for managing members of a
subsite, instantiating and mounting applications, setting
permissions, parameters, etc. Site-wide admin as also seen the
addition of a new simpler software install UI to replace the APM
for non-developer users, and improved access to parameters,
internationalization, automated testing, service contracts, etc.
The list builder has been added for easily generating templated
tables and lists, with features such as filtering, sorting, actions
on multiple rows with checkboxes, etc. Most of all, it&#39;s fast
to use, and results in consistently-looking, consistently-behaving,
templated tables.</p></li><li class="listitem"><p>Automated testing. The automated testing framework has been
improved significantly, and there are automated tests for a number
of packages.</p></li><li class="listitem"><p>Security enhancements. HTML quoting now happens in the
templating system, greatly minimizing the chance that users can
sneak malicious HTML into the pages of other users.</p></li><li class="listitem"><p>Oracle 9i support.</p></li><li class="listitem"><p>Who&#39;s online feature.</p></li><li class="listitem"><p>Spell checking.</p></li>
</ul></div><p>Potential incompatibilities:</p><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>With the release of OpenACS 5, PostgreSQL 7.2 is no longer
supported. Upgrades are supported from OpenACS 4.6.3 under Oracle
or PostgreSQL 7.3.</p></li><li class="listitem"><p>The undocumented special handling of ~ and +variable+ in
formtemplates, found in <code class="filename">packages/acs-templating/resources/*</code>, has been
removed in favor of using &lt;noparse&gt; and \\@variable\\@ (the
standard templating mechanisms). Locally provided formtemplate
styles still using these mechanisms will break.</p></li><li class="listitem"><p>Serving backup files and files from the CVS directories is
turned off by default via the acs-kernel parameter ExcludedFiles in
section request-processor (The variable provides a string match
glob list of files and is defaulted to "*/CVS/* *~")</p></li>
</ul></div><div class="cvstag">($&zwnj;Id: release-notes.xml,v 1.39.2.9 2024/09/02
09:31:40 gustafn Exp $)</div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="id1338" id="id1338"></a>Release
4.6.3</h3></div></div></div><p><a class="ulink" href="release-notes-4-6-3" target="_top">Release Notes for 4.6.3</a></p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="id1339" id="id1339"></a>Release
4.6.2</h3></div></div></div><p><a class="ulink" href="release-notes-4-6-2" target="_top">Release Notes for 4.6.2</a></p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="id1340" id="id1340"></a>Release 4.6</h3></div></div></div><p><a class="ulink" href="release-notes-4-6" target="_top">Release Notes for 4.6</a></p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="id1341" id="id1341"></a>Release 4.5</h3></div></div></div><p><a class="ulink" href="release-notes-4-5" target="_top">Release Notes for 4.5</a></p>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="openacs-overview" leftLabel="Prev" leftTitle="Overview"
			rightLink="acs-admin" rightLabel="Next" rightTitle="
Part II. Administrator&#39;s Guide"
			homeLink="index" homeLabel="Home" 
			upLink="general-documents" upLabel="Up"> 
		    