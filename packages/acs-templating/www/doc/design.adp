
<property name="context">{/doc/acs-templating {ACS Templating}} {Template System}</property>
<property name="doc(title)">Template System</property>
<master>
<h2>The Template System -- Design Document</h2>

by Christian Brechbühler <a href="./">Templating System</a>
 :
Design
<h3>I. Essentials</h3>
<ul>
<li>User directory -- none; <code>www</code> exists only for
documentation.</li><li>ACS administrator directory -- none.</li><li>Subsite administrator directory -- none.</li><li>
<a href="/api-doc/">Tcl script directory</a>. Almost no
procedures show up here. To minimize dependencies across packages,
in particular on <code>ad_proc</code> from <code>acs-kernel</code>,
this package uses <code>proc</code>.</li><li>PL/SQL API -- none.</li><li>Data model -- none. Templating does not depend on a database
system at all. There&#39;s the one table
<code>ad_template_sample_users</code> that some of the
demonstrations use.</li><li><a href="requirements">Requirements document</a></li><li>ER diagram -- none.</li><li>Transaction flow diagram -- none.</li>
</ul>
<h3>II. Introduction</h3>
<ul>
<li>
<em>What this package is intended to allow the user to
accomplish.</em><p>The overall goal of the templating system is to provide the
publishing team with a set of tools for simplifying the development
and maintenance of the user interface. In particular:</p><ul>
<li><p>
<strong>A common solution.</strong> Programmers and designers
should only have to learn a single system that serves as a UI
substrate for all the functionally specific modules used on a site.
The system should not make any assumptions about how pages should
look or function. Designers should be able to change the default
presentation of any module using a single methodology with minimal
exposure to code.</p></li><li><p>
<strong>Separation of code (Tcl, Java and SQL) and layout
(HTML).</strong> Programmers should be able to specify the data
sources and other properties of the template independently of the
HTML template used to present the data. HTML authors should be to
able to write templates that reference the data sources and
properties without further intervention from the programmer to
produce a finished page.</p></li><li><p>
<strong>Separation of page components.</strong> There should be
provisions so that pages can be broken into discrete components to
simplify maintenance of the HTML code and allow for reuse in
different contexts. Examples of common page components include a
navigation bar, a search box, or a section of a report or story.
Another common example is a portal page that allows the user to
choose from a palette of features to display.</p></li><li><p>
<strong>Global control over presentation.</strong> There should
be a way to define one or more standard master templates used by
most pages on a site, so that changes to the overall look and feel
of a site can be made in one place.</p></li><li><p>
<strong>Dynamic selection of presentation style.</strong> Given
that the same data may be presented in many different ways, there
should be a general mechanism for selecting a specific presentation
(including file format, layout, character set and language) for
each page request, depending on characteristics such as user
preference, location, browser type and/or device.</p></li><li><p>
<strong>Usability.</strong> Programmers should be able to
develop template specifications using their standard tools for
writing and maintaining code on the server. HTML authors should be
able to access information about template specifications and work
on templates remotely without needing shell access to the
server.</p></li>
</ul>
</li><li>
<p><em>What this package is not intended to allow users to
accomplish.</em></p><ul>
<li>Tcl "pages" that do not return anything visible to
the user. Such pages may be, e.g., the <code>action=</code> target
of a form. They typically call <code>ad_returnredirect</code> after
completing their job.</li><li>Tcl scripts that are scheduled to run in the server without a
connection to a user.</li>
</ul>
</li><li>
<em>The application domains where this package is most likely
to be of use.</em><p>User interface. Any application that delivers visible pages to a
user. Any page that returns content (HTML or other) in response to
an HTTP[S] request.</p>
</li><li>
<p><em>How the package meets its requirements.</em></p><ul>
<li>It supplies a set of <a href="tagref/index">custom markup
tags</a>.</li><li>The proc <code>ad_page_contract</code> (from the acs kernel)
should be used to specify what makes the dynamic part of the page.
There&#39;s also an API for creating forms and for creating and
manipulating multirow data sources.</li><li>The mechanism for dynamically generating pages combines data
and layout. It also allows coposition of modular pages from
reusable widgets and skins. It is not limited to HTML.</li><li>The <code>&lt;master&gt;</code> tag specifies a master
template. Its <code>src</code> attribute defaults to the site-wide
master template.</li>
</ul>
</li>
</ul>
<h3>III. Historical Considerations</h3>
<p>Karl Goldstein designed the templating system. First it was
called "Karl&#39;s Templates" or "The New Templating
System" to distinguish it from the obsolescent templates or
"Styles" by Philip Greenspun. An extended and improved
version was named "Dynamic Publishing System". It
wasn&#39;t part of the ACS yet, but client projects like iluvCAMP
used it successfully. Newcomers were consistently puzzled by the
<code>.data</code> files, which specified the datasources in an
apparently unfamiliar XML syntax. (The <code>.form</code> files
specified elements in an HTML form similarly.) To mitigate this
initial shock, Karl redesigned templates to let the programmer
specify datasources and forms in a <code>.tcl</code> script. The
system is present as packages <code>templates</code> and
<code>form-manager</code> in ACS 3.4. Both these packages are now
merged and appear as <code>acs-templating</code> starting in ACS
4.0. The architecture of the package was changed several times to
meet the emerging coding/style constraints of ACS 4.0.</p>
<h3>V. Design Tradeoffs</h3>
<p>As indicated above, the primary attribute that the page tries to
achieve is the separation of code and layout. The primary sacrifice
is simplicity; in the typical case there will be <em>two</em> files
(a .adp templage and a .tcl script) instead of a <em>single</em>
.tcl page.</p>
<p>
<strong>Management of data sources.</strong> Through the various
past versions of the package, it evolved that data sources should
be set as Tcl variables and arrays. Earlier they were kept as lists
of ns_sets, which was significantly less efficient. The datasources
are not being copied around; they reside in a specific stack frame.
Using the <code>uplevel</code> Tcl command, we make sure that the
data file (tcl part of a page) executes in the same stack frame as
the compiled template (the adp part), so the latter can make use of
the data sources prepared by the former.<br>
        Thus, we decided for
<em>performance</em>, <em>simplicity</em>, and <em>ease of use</em>
at the cost of using the (standard Tcl) commands <code>upvar</code>
and <code>uplevel</code>, which is considered <em>confusing</em>
and <em>error-prone</em> by reviewers (of 4.0). The use of these
constructs has been reduced in 4.01, and the code is clearer
now.</p>
<p>Other attributes are affected as follows. In parentheses the
estimated priorities are listed, <em>not</em> the degree to which
the attributes are being achieved:</p>
<ul>
<li>Performance (high): Early versions of the templating system
were a compuational burden. This has been fixed. Thanks to
compilation of .adp pages and caching of both .adp and .tcl parts
as procs, templated pages are much faster now; the caching can in
fact make a templated page faster than an old-style .tcl page,
which is <code>source</code>d and parsed on every request.</li><li>Flexibility (high): the recursive composition of pages allows
for a big deal of flexibility.</li><li>Interoperability (low): The templating system must tie in with
the request processor for delivery of pages and with
<code>ad_page_contract</code> for the specification of the expected
parameters (called query) and the datasources it will supply
(called properties). The templating system is registered with the
request processor as the handler for both <code>adp</code> and
<code>tcl</code> extensions.</li><li>Reliability and robustness (medium): Considering how many parts
have to play together, one might not predict a very reliable
system. In practice, the package works reliably. It is robust to
user errors in the sense that it won&#39;t error out if a file is
missing or such; rather it quietly proceeds. Error reporting to the
user is not very sophisticated.</li><li>Usability (high): Emphasis has been put on the easy use of the
system. In particular, a graphics designer should only have to
learn a small number of special markup tags.</li><li>Maintainability (medium): The code is well structured in
reasonably sized procedures, and well commented.</li><li>Portability (high): Unlike most other parts of the ACS, the
templating system can work standalone. It doesn&#39;t need the
database nor the acs-kernel or any other part of the ACS. All you
need is AOLserver with the fancy ADP parser.</li><li>Reusability (low): Many parts of the templating system are
actually generally reusable, and probably should be extracted into
a common set of utility procs used by this package and the ACS;
this would reduce code duplication. The API lets programmers call
into the system at different level. The templating system will
probably mostly deliver HTML pages, but it has also been used to
format mass mailings (spam), and any other formal (e.g., XML) could
be used.</li><li>Testability(low): A demonstration sample page exercises most
mechanisms of the templating system.</li>
</ul>
<h3>VI. API</h3>
<p>Details are in the <a href="developer-guide">developer
guide</a>. Here we give an overview, and then the more obscure
aspects of the current implementation.</p>
<p>The most important abstraction is the data source, of which
there are several kinds:</p>
<ul>
<li>onevalue (string)</li><li>onerow</li><li>multirow</li><li><em>onelist</em></li><li><em>multilist</em></li>
</ul>
<p>Currently <code>ad_page_contract</code> does not allow
specifying the latter two.</p>
<h4>Process Flow</h4>

In a simple case, the following is the sequence of steps that
serving a templated page involves.
<ol>
<li>The request processor gets a URL and maps it to a
<code>.adp</code> or <code>.tcl</code> file. As both invoke the
same handler, it doesn&#39;t matter that adp take precedence.</li><li>If a <code>.tcl</code> file is present, its <a href="/api-doc/proc-view?proc=ad_page_contract"><code>ad_page_contract</code></a>
in the <code>-properties</code> block indicates a set of data
sources that will be made available to the template.</li><li>The rest of the Tcl script executes, defining these data
sources. It may change the name of the page being served by calling
<code>template::set_file</code> directly or through the wrapper
<code>ad_return_template</code>.</li><li>The corresponding template (file <em>stub</em>.adp) is
interpreted and the data sources from the .tcl script are
interpolated into the template.</li><li>The HTML is streamed to the client by the handler.</li>
</ol>

Less simple cases involve dependent templated pages. They are
requested with the <code>&lt;include&gt;</code>
 and
<code>&lt;master&gt;</code>
 tags. In these cases, Tcl and/or ADP
parsing happens recursively.
<h4>Tcl Call Stack</h4>
<p>Below is a diagram of the typical call stack when processing a
page without dependent pages. To conform to the Tcl notion of
what&#39;s up and down (as in <strong>up</strong>var), the stack
grows down.</p>
<blockquote><table>
<tr>
<th align="left">Level</th><th align="left">Procedure</th><th align="left">Arguments</th>
</tr><tr>
<td>#1</td><td>rp_handler</td><td></td>
</tr><tr>
<td>#2</td><td>rp_serve_abstract_file</td><td>/web/<em>service</em>/www/page</td>
</tr><tr>
<td>#3</td><td>rp_serve_concrete_file</td><td>/web/<em>service</em>/www/page.adp</td>
</tr><tr>
<td>#4</td><td>adp_parse_ad_conn_file</td><td></td>
</tr><tr>
<td>#5</td><td>template::adp_parse</td><td>/web/<em>service</em>/www/page {}</td>
</tr><tr>
<td>(6)</td><td>template::adp_prepare</td><td></td>
</tr><tr>
<td><strong>#5</strong></td><td>template::code::tcl::/web/<em>service</em>/www/page</td>
</tr>
</table></blockquote>
<p>Levels #1 to #3 exposed here are request processor internals. In
the case shown, datasources reside in level #5. Due to the
<code>uplevel</code> command, the frame of the sixth procedure is
not accessible in the call stack at this moment, and the seventh
runs in stack frame #5. If the <code>&lt;include&gt;</code> or
<code>&lt;master&gt;</code> tags are used, <code>adp_parse</code>
will be invoked recursively. Datasources always reside in the stack
frame of an instance of <code>adp_parse</code>.</p>
<p>To keep track of data sources of several page components, the
templating system maintains a stack of their stack levels in the
variable <code>template::parse_level</code>. In our case, it just
contains 5. But if this page included another page or designated is
as its master, the level of the next <code>adp_parse</code> would
be pushed to the list, and popped when that proc returned. This
next level will appear as #6, due to the repeated
<code>uplevel</code>ing.</p>
<h4>Caching and Template Compilation</h4>
<p>To improve performance, adp pages are compiled into a Tcl proc,
and thus cached for future use. Tcl pages are also cached in a
proc; this saves the trouble of reading and parsing the file the
next time. The template system remembers the modification times of
the adp and Tcl sources, and re-processes any requested file if the
cached version is no longer current. Consequently, this cacheing is
transparent in normal use.</p>
<p>To emphasize that "normal" use essentially always
applies, here&#39;s a scenario for abnormal use: Save version
<var>n</var> of a file at 11:36:05.1; request a page that uses it
at 11:36:05.3; modify and save version <var>n</var>+1 of the file
at 11:36:05.9. If you work that fast (!), the new version will have
the same modification time -- kept with 1 second resolution in Unix
--, and will not be refreshed.</p>
<p>For timing measurements and performance tuning, you can set the
parameter <code>RefreshCache</code> in section
<code>template</code> to <code>never</code> or <code>always</code>.
The former suppresses checking mtime and may improve performance on
a production server, where the content pages don&#39;t change. The
latter is only inteded for testing.</p>
<h3>VII. Data Model Discussion</h3>
<p>This package doesn&#39;t need a data model.</p>
<p>It comes with its own database interfaces, one for using ns_ora,
the Oracle driver from ArsDigita, and one for ns_db, the built-in
database interface of the AOL server. If you are programming under
the ACS, you should use neither of these, but rather the
<code>db_*</code> interface, in particular
<code>db_multirow</code>.</p>
<h3>VIII. User Interface</h3>
<p>This package doesn&#39;t have a user interface. It is the
<em>substrate</em> of all user interfaces, be it user or admin
pages.</p>
<h3>IX. Configuration/Parameters</h3>

There are two parameters.
<pre>
      [ns/server/yourservername/acs/template]
      ; the site-wide Master template
      DefaultMaster=/www/default-master
      ; anything other than "never" or "always" means normal operation
      RefreshCache=as necessary
    </pre>
<h3>X. Future Improvements/Areas of Likely Change</h3>
<p>Passing datasources by reference is new. The acs-templating
syntax <code>&amp;formal="actual"</code> is different
from the independent ATS, which used
<code>formal="\@actual.*\@"</code>. The latter is phased
out.</p>
<p>We intend to add a <code>&lt;which&gt;</code>,
<code>&lt;switch&gt;</code>, or <code>&lt;case&gt;</code> tag, to
complement sequential nested
<code>&lt;if&gt;</code>/<code>&lt;else&gt;</code> constructs.</p>
<h3>Authors</h3>
<ul>
<li>System creator: <a href="mailto:karl\@arsdigita.com">Karl
Goldstein</a>
</li><li>System owners: <a href="mailto:karl\@arsdigita.com">Karl
Goldstein</a> and <a href="mailto:christian\@arsdigita.com">Christian Brechbühler</a>
</li><li>Documentation authors: <a href="mailto:karl\@arsdigita.com">Karl
Goldstein</a>, <a href="mailto:christian\@arsdigita.com">Christian
Brechbühler</a>, and <a href="mailto:bquinn\@arsdigita.com">Bryan
Quinn</a>
</li>
</ul>
<h3>XII. Revision History</h3>
<table cellpadding="2" cellspacing="2" width="90%" bgcolor="#EFEFEF">
<tr bgcolor="#E0E0E0">
<th width="10%">Document Revision #</th><th width="50%">Action Taken, Notes</th><th>When?</th><th>By Whom?</th>
</tr><tr>
<td>0.1</td><td>Brought into the form suggested by Finkler, McLoghlin and Wu
(http://dev.arsdigita.com/ad-sepg/process/design-template)</td><td>18 Jul 2000</td><td>Christian Brechbühler</td>
</tr><tr>
<td>0.2</td><td>Adapted to acs-templating as distributed with ACS/Tcl 4.01</td><td>22 Nov 2000</td><td>Christian Brechbühler</td>
</tr>
</table>
<hr>
<address><a href="mailto:christian\@arsdigita.com">Christian
Brechbuehler</a></address>
<!-- Created: Mon Aug 14 11:53:07 EDT 2000 -->
Last modified: $&zwnj;Id: design.html,v 1.9 2018/04/11 20:52:01 hectorr
Exp $
