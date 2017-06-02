
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {Request Processor Design}</property>
<property name="doc(title)">Request Processor Design</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
		    leftLink="rp-requirements" leftLabel="Prev"
		    title="
Chapter 15. Kernel Documentation"
		    rightLink="tcl-doc" rightLabel="Next">
		<div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="rp-design" id="rp-design"></a>Request Processor Design</h2></div></div></div><div class="authorblurb">
<p>By <a class="ulink" href="http://planitia.org" target="_top">Rafael H. Schloming</a>
</p>
OpenACS docs are written by the named authors, and may be edited by
OpenACS documentation staff.</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="rp-design-essentials" id="rp-design-essentials"></a>Essentials</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p><a class="xref" href="rp-requirements" title="Request Processor Requirements">OpenACS 4 Request Processor
Requirements</a></p></li><li class="listitem"><p><a class="ulink" href="request-processor" target="_top">Request
Processor Stages and API</a></p></li><li class="listitem"><p><a class="ulink" href="/api-doc/procs-file-view?path=packages/acs-tcl/tcl/request-processor-procs.tcl" target="_top">/packages/acs-tcl/tcl/request-processor-procs.tcl</a></p></li><li class="listitem"><p><a class="ulink" href="/api-doc/procs-file-view?path=packages/acs-tcl/tcl/request-processor-init.tcl" target="_top">/packages/acs-tcl/tcl/request-processor-init.tcl</a></p></li><li class="listitem"><p><a class="ulink" href="/api-doc/procs-file-view?path=packages/acs-tcl/tcl/site-nodes-procs.tcl" target="_top">/packages/acs-tcl/tcl/site-nodes-procs.tcl</a></p></li><li class="listitem"><p><a class="ulink" href="/api-doc/procs-file-view?path=packages/acs-tcl/tcl/site-nodes-init.tcl" target="_top">/packages/acs-tcl/tcl/site-nodes-init.tcl</a></p></li><li class="listitem"><p><a class="ulink" href="/doc/sql/display-sql?package_key=acs-kernel&amp;url=site-nodes-create.sql" target="_top">/packages/acs-kernel/sql/site-nodes-create.sql</a></p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="rp-design-intro" id="rp-design-intro"></a>Introduction</h3></div></div></div><p>The request processor is the set of procs that responds to every
HTTP request made to the OpenACS. The request processor must
authenticate the connecting user, and make sure that he is
authorized to perform the given request. If these steps succeed,
then the request processor must locate the file that is associated
with the specified URL, and serve the content it provides to the
browser.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="rp-design-related-systems" id="rp-design-related-systems"></a>Related Systems</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;"><li class="listitem"><p><a class="xref" href="apm-design" title="Package Manager Design">Package Manager Design</a></p></li></ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="rp-design-terminology" id="rp-design-terminology"></a>Terminology</h3></div></div></div><div class="itemizedlist"><ul class="itemizedlist" style="list-style-type: disc;">
<li class="listitem"><p>
<span class="strong"><strong>pageroot</strong></span> -- Any
directory that contains scripts and/or static files intended to be
served in response to HTTP requests. A typical OpenACS installation
is required to serve files from multiple pageroots.</p></li><li class="listitem"><p>
<span class="strong"><strong>global pageroot</strong></span>
(<span class="strong"><strong>/var/lib/aolserver/<span class="emphasis"><em>servicename</em></span>/www</strong></span>) --
Files appearing under this pageroot will be served directly off the
base url http://www.<span class="emphasis"><em>servicename</em></span>.com/</p></li><li class="listitem"><p>
<span class="strong"><strong>package root</strong></span>
(<span class="strong"><strong>/var/lib/aolserver/<span class="emphasis"><em>servicename</em></span>/packages</strong></span>) --
Each subdirectory of the package root is a package. A typical
OpenACS installation will have several packages.</p></li><li class="listitem"><p>
<span class="strong"><strong>package pageroot</strong></span>
(<span class="strong"><strong>/var/lib/aolserver/<span class="emphasis"><em>servicename</em></span>/packages/<span class="emphasis"><em>package_key</em></span>/www</strong></span>) -- This
is the pageroot for the <span class="emphasis"><em>package_key</em></span> package.</p></li><li class="listitem"><p>
<span class="strong"><strong>request environment</strong></span>
(<span class="strong"><strong>ad_conn</strong></span>) -- This is a
global namespace containing variables associated with the current
request.</p></li><li class="listitem"><p>
<span class="strong"><strong>abstract URL</strong></span> -- A
URL with no extension that doesn&#39;t directly correspond to a
file in the filesystem.</p></li><li class="listitem"><p>
<span class="strong"><strong>abstract file</strong></span> or
<span class="strong"><strong>abstract path</strong></span> -- A URL
that has been translated into a file system path (probably by
prepending the appropriate pageroot), but still doesn&#39;t have
any extension and so does not directly correspond to a file in the
filesystem.</p></li><li class="listitem"><p>
<span class="strong"><strong>concrete file</strong></span> or
<span class="strong"><strong>concrete path</strong></span> -- A
file or path that actually references something in the
filesystem.</p></li>
</ul></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="rp-design-system-overview" id="rp-design-system-overview"></a>System Overview</h3></div></div></div><p><span class="strong"><strong>Package Lookup</strong></span></p><p>One of the first things the request processor must do is to
determine which package instance a given request references, and
based on this information, which pageroot to use when searching for
a file to serve. During this process the request processor divides
the URL into two pieces. The first portion identifies the package
instance. The rest identifies the path into the package pageroot.
For example if the news package is mounted on
/offices/boston/announcements/, then a request for
/offices/boston/announcements/index would be split into the
<span class="strong"><strong>package_url</strong></span>
(/offices/boston/announcements/), and the abstract (no extension
info) file path (index). The request processor must be able to
figure out which <span class="strong"><strong>package_id</strong></span> is associated with a
given package_url, and package mountings must be persistent across
server restarts and users must be able to manipulate the mountings
on a live site, therefore this mapping is stored in the
database.</p><p><span class="strong"><strong>Authentication and
Authorization</strong></span></p><p>Once the request processor has located both the package_id and
concrete file associated with the request, authentication is
performed by the <a class="ulink" href="security-design" target="_top">session</a> security system. After authentication has
been performed the user is authorized to have read access for the
given package by the <a class="xref" href="permissions-design" title="Permissions Design">OpenACS 4 Permissions Design</a>. If
authorization succeeds then the request is served, otherwise it is
aborted.</p><p><span class="strong"><strong>Concrete File
Search</strong></span></p><p>To actually serve a file, the request processor generates an
ordered list of abstract paths and searches each path for a
concrete file. The first path searched is composed of the package
pageroot with the extra portion of the URL appended. The second
abstract path consists of the global pageroot with the full URL
appended. This means that if an instance of the news package is
mounted on /offices/boston/announcements/, then any requests that
are not matched by something in the news package pageroot could be
matched by something under the global pageroot in the
/offices/boston/announcements/ directory. Files take precedence
over directory listings, so an index file in the global pageroot
will be served instead of a directory listing in the package
pageroot, even though the global pageroot is searched later. If a
file is found at any of the searched locations then it is
served.</p><p><span class="strong"><strong>Virtual URL
Handlers</strong></span></p><p>If no file is found during the concrete file search, then the
request processor searches the filesystem for a <span class="strong"><strong>virtual url handler</strong></span> (<span class="strong"><strong>.vuh</strong></span>) file. This file contains
normal Tcl code, and is in fact handled by the same extension
handling procedure that handles .tcl files. The only way this file
is treated differently is in how the request processor searches for
it. When a lookup fails, the request processor generates each valid
prefix of all the abstract paths considered in the concrete file
search, and searches these prefixes in order from most specific to
least specific for a matching .vuh file. If a file is found then
the ad_conn variable <span class="strong"><strong>path_info</strong></span> is set to the portion of
the url <span class="emphasis"><em>not</em></span> matched by the
.vuh script, and the script is sourced. This facility is intended
to replace the concept of registered procs, since no special
distinction is required between sitewide procs and package specific
procs when using this facility. It is also much less prone to
overlap and confusion than the use of registered procs, especially
in an environment with many packages installed.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="rp-design-site-nodes" id="rp-design-site-nodes"></a>Site Nodes</h3></div></div></div><p>The request processor manages the mappings from URL patterns to
package instances with the site_nodes data model. Every row in the
site_nodes table represents a fully qualified URL. A package can be
mounted on any node in this data model. When the request processor
performs a URL lookup, it determines which node matches the longest
possible prefix of the request URI. In order to make this lookup
operation as fast as possible, the rows in the site_nodes table are
pulled out of the database at server startup, and stored in
memory.</p><p>The memory structure used to store the site_nodes mapping is a
hash table that maps from the fully qualified URL of the node, to
the package_id and package_key of the package instance mounted on
the node. A lookup is performed by starting with the full request
URI and successively stripping off the rightmost path components
until a match is reached. This way the time required to lookup a
URL is proportional to the length of the URL, not to the number of
entries in the mapping.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="rp-design-req-env" id="rp-design-req-env"></a>Request Environment</h3></div></div></div><p>The request environment is managed by the procedure <span class="strong"><strong>ad_conn</strong></span>. Variables can be set and
retrieved through use of the ad_conn procedure. The following
variables are available for public use. If the ad_conn procedure
doesn&#39;t recognize a variable being passed to it for a lookup,
it tries to get a value using ns_conn. This guarantees that ad_conn
subsumes the functionality of ns_conn.</p><div class="informaltable"><table class="informaltable" cellspacing="0" border="0">
<colgroup>
<col class="c1"><col class="c2">
</colgroup><tbody>
<tr><td colspan="2"><span class="strong"><strong>Request
processor</strong></span></td></tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
urlv]</code></td><td valign="top">A list containing each element of the URL</td>
</tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
url]</code></td><td valign="top">The URL associated with the request.</td>
</tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
query]</code></td><td valign="top">The portion of the URL from the ? on (i.e. GET
variables) associated with the request.</td>
</tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
file]</code></td><td valign="top">The filepath including filename of the file being
served</td>
</tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
request]</code></td><td valign="top">The number of requests since the server was last
started</td>
</tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
start_clicks]</code></td><td valign="top">The system time when the RP starts handling the
request</td>
</tr><tr><td colspan="2"></td></tr><tr><td colspan="2">
<span class="strong"><strong>Session System
Variables</strong></span>: set in sec_handler, check security with
ad_validate_security_info</td></tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
session_id]</code></td><td valign="top">The unique session_id coming from the sequence
<code class="computeroutput">sec_id_seq</code>
</td>
</tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
user_id]</code></td><td valign="top">User_id of a person if the person is logged in.
Otherwise, it is blank</td>
</tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
sec_validated]</code></td><td valign="top">This becomes "secure" when the
connection uses SSL</td>
</tr><tr><td colspan="2"></td></tr><tr><td colspan="2"><span class="strong"><strong>Database
API</strong></span></td></tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
db,handles]</code></td><td valign="top">What are the list of handles available to
AOL?</td>
</tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
db,n_handles_used]</code></td><td valign="top">How many database handles are currently used?</td>
</tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
db,last_used]</code></td><td valign="top">Which database handle did we use last?</td>
</tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
db,transaction_level,$db]</code></td><td valign="top">Specifies what transaction level we are in</td>
</tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
db,db_abort_p,$dbh]</code></td><td valign="top">Whether the transaction is aborted</td>
</tr><tr><td colspan="2"></td></tr><tr><td colspan="2"><span class="strong"><strong>APM</strong></span></td></tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
xml_loaded_p]</code></td><td valign="top">Checks whether the XML parser is loaded so that it
only gets loaded once. Set in apm_load_xml_packages</td>
</tr><tr><td colspan="2"></td></tr><tr><td colspan="2"><span class="strong"><strong>Packages</strong></span></td></tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
package_id]</code></td><td valign="top">The package_id of the package associated with the
URL.</td>
</tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
package_url]</code></td><td valign="top">The URL on which the package is mounted.</td>
</tr><tr><td colspan="2"></td></tr><tr><td colspan="2"><span class="strong"><strong>Miscellaneous</strong></span></td></tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
system_p]</code></td><td valign="top">If true then the request has been made to one of
the special directories specified in the config file (somewhere),
and no authentication or authorization has been performed.</td>
</tr><tr><td colspan="2"></td></tr><tr><td colspan="2"><span class="strong"><strong>Documentation</strong></span></td></tr><tr>
<td valign="top"><code class="computeroutput">[ad_conn
api_page_documentation_mode_p]</code></td><td valign="top"> </td>
</tr>
</tbody>
</table></div>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
		    leftLink="rp-requirements" leftLabel="Prev" leftTitle="Request Processor Requirements"
		    rightLink="tcl-doc" rightLabel="Next" rightTitle="Documenting Tcl Files: Page Contracts
and Libraries"
		    homeLink="index" homeLabel="Home" 
		    upLink="kernel-doc" upLabel="Up"> 
		