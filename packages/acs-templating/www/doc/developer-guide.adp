
<property name="context">{/doc/acs-templating {ACS Templating}} {Template System Guide}</property>
<property name="doc(title)">Template System Guide</property>
<master>
<h2>Programmer / Developer Guide</h2>
<a href="">Templating System</a>
 : Developer Guide
<h3>Mini How To</h3>

Start a Tcl page as usual with <code>ad_page_contract</code>
. Be
sure to pass a <code>-properties</code>
 block; this signals the use
of templating. The Tcl page should fill the data sources you
promised in the contract, and not write to the connection. At the
end of your Tcl page, call <code>ad_return_template</code>
. The
template system will look for an adp page with the file name stub
you indicate (defaulting to the same stub as the Tcl page), process
that, and deliver it to the client. The adp page can use the
datasources defined in the Tcl page.
<h3>Guide</h3>
<ol>
<li>User Guide
<ul>
<li><a href="guide/index">Overview</a></li><li>Establishing data sources
<ul>
<li><a href="guide/data">Implementing data sources</a></li><li><a href="guide/document">Documenting data sources</a></li>
</ul>
</li><li>Creating templates
<ul>
<li><a href="guide/templates">Writing dynamic
templates</a></li><li><a href="guide/components">Building reusable layout
components</a></li><li><a href="guide/master">Using master templates</a></li><li><a href="guide/composite">Composite pages</a></li><li><a href="guide/skins">Presenting data in multiple styles
and formats</a></li><li><a href="guide/tcl">Mixing Tcl and HTML</a></li>
</ul>
</li><li>Managing forms
<ul>
<li><a href="guide/forms">Creating and populating
forms</a></li><li><a href="guide/form-templates">Customizing form
templates</a></li><li><a href="guide/form-process">Validating and processing
form submissions</a></li><li><a href="guide/wizards">Integrating forms into a
wizard</a></li><li><a href="guide/search">Implementing a search-and-select
form</a></li><li><a href="guide/form-widgets">Implementing custom
widgets</a></li><li><a href="guide/form-datatypes">Implementing custom data
types</a></li>
</ul>
</li><li>Handling errors
<ul><li>See the "contract", "error", and
"state" <a href="demo/">demos</a>.</li></ul>
</li>
</ul>
</li><li>Object and API Reference
<ul>
<li><a href="api/database">Database Query</a></li><li><a href="api/multirow">Mutirow Data Source</a></li><li><a href="api/request">Request</a></li><li><a href="api/form">Form</a></li><li><a href="api/element">Form Element</a></li><li><a href="widgets">Form Widgets</a></li>
</ul>
</li><li><a href="tagref">Template Markup Tag Reference</a></li><li>Appendices
<ul>
<li><a href="demo/">Appendix A: Sample templates</a></li><li><a href="appendices/memory">Appendix B: Parsing templates
in memory</a></li>
</ul>
</li>
</ol>
<h3>API</h3>

After the script for a page is executed, acs-templating processes
the template, interpolating any data sources and executing the
special tags. The resulting HTML page is written to the connection
(i.e., returned to the user).
<h5><code><a href="/api-doc/proc-view?proc=ad%5freturn%5ftemplate">ad_return_template</a></code></h5>

Normally, does nothing at all. With the <code>-string</code>
 option
you get the resulting HTML page returned as a string.
<p>The optional <code>template</code> argument is a path to a page
(tcl/adp file pair). Note that you don&#39;t supply the
".tcl" or ".adp" extension. It is resolved by
help of <code>template::util::url_to_file</code> (with the current
file stub as reference path) and passed to
<code>template::set_file</code>, to change the name of the page
being served currently. If it starts with a "/", it is
taken to be a path relative to the server root; otherwise it is a
filename relative to the directory of the Tcl script.</p>
<h5><code><a href="/api-doc/proc-view?proc=ad_page_contract">ad_page_contract</a></code></h5>

Normally, complaints about incorrect parameters are written
directly to the connection, and the script is aborted. With the
option <code>-return_errors</code>
 you can name a variable into
which to put any error messages as a list, and
<code>ad_page_contract</code>
 will return in any case. You can then
present the errors to the user in a templated page, consistent with
the look and feel of the rest of your service. If there&#39;s no
complaint, <code>ad_page_contract</code>
 won&#39;t touch the
variable; typically it will stay undefined.
<hr>
<address><a href="mailto:christian\@arsdigita.com">Christian
Brechbühler</a></address>
<!-- Created: Mon Aug 14 11:53:07 EDT 2000 -->
Last modified: $&zwnj;Id: developer-guide.html,v 1.5 2017/08/07 23:48:02
gustafn Exp $
