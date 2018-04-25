
<property name="context">{/doc/acs-core-docs {ACS Core Documentation}} {The Request Processor}</property>
<property name="doc(title)">The Request Processor</property>
<master>
<include src="/packages/acs-core-docs/lib/navheader"
			leftLink="objects" leftLabel="Prev"
			title="Chapter 11. Development
Reference"
			rightLink="db-api" rightLabel="Next">
		    <div class="sect1">
<div class="titlepage"><div><div><h2 class="title" style="clear: both">
<a name="request-processor" id="request-processor"></a>The Request Processor</h2></div></div></div><span style="color: red">&lt;authorblurb&gt;</span><p><span style="color: red">By Pete Su</span></p><span style="color: red">&lt;/authorblurb&gt;</span><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="rp-overview" id="rp-overview"></a>Overview</h3></div></div></div><p>This document is a brief introduction to the OpenACS 5.9.0
Request Processor; more details can be found in the <a class="xref" href="rp-design" title="Request Processor Design">OpenACS 4
Request Processor Design</a>. Here we cover the high level concepts
behind the system, and implications and usage for the application
developer.</p>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="rp-thenewway" id="rp-thenewway"></a>Request Processor</h3></div></div></div><p>The 5.9.0 Request Processor is a global filter and set of Tcl
procs that respond to every incoming URL reaching the server. The
following diagram summarizes the stages of the request processor
assuming a URL request like <code class="computeroutput">http://someserver.com/notes/somepage.adp</code>.</p><div class="mediaobject" align="center"><img src="images/rp-flow.gif" align="middle"></div><div class="variablelist"><dl class="variablelist">
<dt><span class="term">Stage 1: Search Site Map</span></dt><dd>
<p>The first thing the RP does is to map the given URL to the
appropriate physical directory in the filesystem, from which to
serve content. We do this by searching the site map data model
(touched on in the <a class="xref" href="packages" title="OpenACS Packages">Packages</a>, and further discussed in <a class="xref" href="subsites" title="Writing OpenACS Application Pages">Writing OpenACS Application
Pages</a>). This data model maps URLs to objects representing
content, and these objects are typically package instances.</p><p>After looking up the appropriate object, the RP stores the URL,
the ID of the object it found, and the package and package instance
the object belongs to into the environment of the connection. This
environment can be queried using the <code class="computeroutput">ad_conn</code> procedure, which is described in
detail in <a class="xref" href="rp-design" title="Request Processor Design">OpenACS 4 Request Processor Design</a>.
The <a class="link" href="subsites" title="Writing OpenACS Application Pages">page development</a> tutorial
shows you how to use this interface to make your pages aware of
which instance was requested.</p>
</dd><dt><span class="term">Stage 2: Authentication</span></dt><dd><p>Next, the Request Processor examines the request for session
information. Session information is generally sent from the client
(the user&#39;s browser) to the server via cookies. The <a class="link" href="security-notes" title="Security Notes">security/session handler</a> is described in
detail in its own document. It examines the client request and
either extracts or sets up new session tokens for the user.</p></dd><dt><span class="term">Stage 3: Authorization</span></dt><dd><p>Next, the Request Processor checks if the user has appropriate
access privileges to the requested part of the site. In OpenACS
5.9.0, access control is dictated by the <a class="ulink" href="permissions" target="_top">permissions system</a>. In this case,
the RP checks if the user has "read" privileges on the
object in the site map specified by the URL. This object is
typically a package instance, but it could easily be something more
granular, such as whehter the user can view a particular piece of
content within a package instance. This automatic check makes it
easy to set up sites with areas that are only accessible to
specific groups of users.</p></dd><dt><span class="term">Stage 4: URL Processing, File
Search</span></dt><dd>
<p>Finally, the Request Processor finds the file we intend to
serve, searching the filesystem to locate the actual file that
corresponds to an abstract URL. It searches for files with
predefined "magic" extensions, i.e. files that end with:
<code class="computeroutput">.html</code>, <code class="computeroutput">.tcl</code> and <code class="computeroutput">.adp</code>.</p><p>If the RP can&#39;t find any matching files with the expected
extensions, it will look for virtual-url-handler files, or
<code class="computeroutput">.vuh</code> files. A <code class="computeroutput">.vuh</code> file will be executed as if it were a
Tcl file, but with the tail end of the URL removed. This allows the
code in the <code class="computeroutput">.vuh</code> file to act
like a registered procedure for an entire subtree of the URL
namespace. Thus a <code class="computeroutput">.vuh</code> file can
be thought of as a replacement for filters and registered procs,
except that they integrate cleanly and correctly with the RP&#39;s
URL mapping mechanisms. The details of how to use these files are
described in <a class="xref" href="rp-design" title="Request Processor Design">OpenACS 4 Request Processor
Design</a>.</p><p>Once the appropriate file is found, it is either served directly
if it&#39;s static content, or sent to the template system or the
standard Tcl interpreter if it&#39;s a dynamic page.</p>
</dd>
</dl></div>
</div><div class="sect2">
<div class="titlepage"><div><div><h3 class="title">
<a name="rp-basicapi" id="rp-basicapi"></a>Basic
API</h3></div></div></div><p>Once the flow of control reaches a dynamic page, the Request
Processor has populated the environment of the request with several
pieces of useful information. The RP&#39;s environment is
accessible through the <code class="computeroutput">ad_conn</code>
interface, and the following calls should be useful to you when
developing dynamic pages:</p><div class="variablelist"><dl class="variablelist">
<dt><span class="term"><code class="computeroutput">[ad_conn
user_id]</code></span></dt><dd><p>The ID of the user associated with this request. By convention
this is zero if there is no user.</p></dd><dt><span class="term"><code class="computeroutput">[ad_conn
session_id]</code></span></dt><dd><p>The ID of the session associated with this request.</p></dd><dt><span class="term"><code class="computeroutput">[ad_conn
url]</code></span></dt><dd><p>The URL associated with the request.</p></dd><dt><span class="term"><code class="computeroutput">[ad_conn
urlv]</code></span></dt><dd><p>The URL associated with the request, represented as a list
instead of a single string.</p></dd><dt><span class="term"><code class="computeroutput">[ad_conn
file]</code></span></dt><dd><p>The actual local filesystem path of the file that is being
served.</p></dd><dt><span class="term"><code class="computeroutput">[ad_conn
object_url]</code></span></dt><dd><p>If the URL refers to a site map object, this is the URL to the
root of the tree where the object is mounted.</p></dd><dt><span class="term"><code class="computeroutput">[ad_conn
package_url]</code></span></dt><dd><p>If the URL refers to a package instance, this is the URL to the
root of the tree where the package is mounted.</p></dd><dt><span class="term"><code class="computeroutput">[ad_conn
extra_url]</code></span></dt><dd><p>If we found the URL in the site map, this is the tail of the URL
following the part that matched a site map entry.</p></dd><dt><span class="term"><code class="computeroutput">[ad_conn
object_id]</code></span></dt><dd><p>If the URL refers to a site map object, this is the ID of that
object.</p></dd><dt><span class="term"><code class="computeroutput">[ad_conn
package_id]</code></span></dt><dd><p>If the URL refers to a package instance, this is the ID of that
package instance.</p></dd><dt><span class="term"><code class="computeroutput">[ad_conn
package_key]</code></span></dt><dd><p>If the URL refers to a package instance, this is the unique key
name of the package.</p></dd><dt><span class="term"><code class="computeroutput">[ad_conn
path_info]</code></span></dt><dd><p>In a .vuh file, path_info is the trailing part of the URL not
matched by the .vuh file.</p></dd>
</dl></div><p><span class="cvstag">($&zwnj;Id: rp.xml,v 1.13 2017/08/07 23:47:54
gustafn Exp $)</span></p>
</div>
</div>
<include src="/packages/acs-core-docs/lib/navfooter"
			leftLink="objects" leftLabel="Prev" leftTitle="OpenACS Data Models and the Object
System"
			rightLink="db-api" rightLabel="Next" rightTitle="The OpenACS Database Access API"
			homeLink="index" homeLabel="Home" 
			upLink="dev-guide" upLabel="Up"> 
		    