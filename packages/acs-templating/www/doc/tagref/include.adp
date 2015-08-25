
<property name="context">{/doc/acs-templating {Templating}} {Templating System Tag Reference: Include}</property>
<property name="doc(title)">Templating System Tag Reference: Include</property>
<master>
<h2>Include</h2>
<a href="..">Templating System</a>
 : <a href="../designer-guide.html">Designer Guide</a>
 : <a href="index">Tag Reference</a>
 : Include
<h3>Summary</h3>
<p>The <tt>include</tt> tag is used to include a dynamic
subtemplate into the current template. Subtemplates are evaluated
in the same fashion as any other dynamic template; the developer
may associate data sources and other properties to them.</p>
<h3>Usage</h3>
<pre>
&lt;include src="subtemplate" attribute="value" ...&gt;
</pre>

or
<pre>
&lt;include src="/packages/packagename/www/lib/subtemplate" attribute="value" ...&gt;
</pre>
<h3>Notes</h3>
<ul>
<li>Arguments may be passed to the subtemplate by specifying
additional attributes to the <tt>include</tt> tag. All attributes
except for <tt>src</tt> are assumed to be arguments and are set as
variables which the subtemplate may reference using the
<tt>var</tt> tag. To pass a dynamic variable to the subtemplate,
specify the variable name surrounded by at signs as the value:
<pre>
&lt;include src="subtemplate" source_id="\@source_id\@" ...&gt;
</pre>
Note that passing an html string to a subtemplate via
<code>\@var\@</code> will result in passing an html-escaped and
internationalized string. To prevent this, use
<code>\@var;literal\@</code> when passing html to subtemplates.
Alternatively the variable can by passed by name (similar to
call-by-reference) causing a variable alias to be created in the
scope of the subtemplate. This variant is necessary for e.g.
passing a Tcl array like a templating datasource. To pass e.g.
<code>users</code> by reference, use this notation:
<pre>
&lt;include src="subtemplate" &amp;persons="users" ...&gt;
</pre>
This is particularly useful for passing onerow and multirow data
sourced. Note that in this case, if the subtemplate modifies the
value this will affect the includer. When the datasource in the
included page has the same name (<code>&amp;users="users"</code>),
you can use the shorthand <code>&amp;="users"</code>.</li><li>It is important to note that variables passed through
<tt>include</tt> become available to the .tcl and .adp files being
include'd, but it <b>does not</b> make them settable through
<tt>ad_page_contract</tt>.
<p>So if you'd like to have a template that will return a fragment
of a page that you'd like to include in other pages, make sure its
.tcl component does not call <tt>ad_page_contract</tt>.</p><p>If you'd like to include a full page (that is, one which calls
<tt>ad_page_contract</tt>) then instead of passing a parameter
through <tt>&lt;include&gt;</tt>, you could use <tt><a href="http://openacs.org/api-doc/proc-view?proc=rp%5fform%5fput">rp_form_put</a></tt>
to add the variable to that page's form. For additional references,
see how message-chunk is used throughout the forums package.</p>
</li><li>If the <tt>src</tt> attribute begins with a slash, the path is
assumed to be relative to the server root, the parent directory of
the tcl library. If not, the path is assumed to be relative to the
<em>current template</em>, <em>not</em> the URL of the page
request.</li><li>If the page layout is sensitive to additional whitespace
surrounding the subtemplate, then care must be taken that the
subtemplate does not contain any blank lines at the beginning or
end of the file.</li>
</ul>
<hr>
