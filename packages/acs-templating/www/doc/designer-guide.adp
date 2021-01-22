
<property name="context">{/doc/acs-templating {ACS Templating}} {Template Designer Guide}</property>
<property name="doc(title)">Template Designer Guide</property>
<master>
<h2>Designer Guide</h2>
<a href="">Templating System</a>
 : Designer Guide
<h3>Overview</h3>
<p>Templates are the primary means for separating the work of
developers and designers. A template is written by a designer and
consists largely of static HTML (or other markup). The template
author uses a small set of special markup tags to reference dynamic
data prepared by the developer.The tags allow authors to accomplish
four basic tasks that are not possible with standard HTML:</p>
<ul>
<li>Embed a dynamic variable in a template (<kbd><a href="tagref/variable">var</a></kbd>).</li><li>Repeat a template section for each object in a dynamic list of
objects (<kbd><a href="tagref/multiple">multiple</a></kbd>,
<kbd><a href="tagref/grid">grid</a></kbd>).</li><li>Output different template sections depending on the value of
one or more dynamic variables (<kbd><a href="tagref/if">if</a></kbd>).</li><li>Provide a mechanism for building complete pages from multiple
component templates (<kbd><a href="tagref/include">include</a></kbd>).</li>
</ul>
<p>A reasonably skilled template author should be able to implement
a template without any assistance from the developer, other than
assuring that the proper dynamic data is accessible.</p>
<h3>Concepts</h3>
<p>This section introduces the basic concepts underlying the use of
template tags in ACS 4.0.</p>
<h4>Variable Substitution</h4>
<p>Much like the mail merge feature of a word processor, template
authors must use special tags to position each piece of dynamic
data within the layout. Each template is associated with a data
dictionary that lists all available data sources.</p>
<p>See <a href="tagref/variable">Variable
Substitution</a>.</p>
<h4>Use of Components</h4>
<p>To speed development and ensure consistency of design, template
authors are encouraged to assemble pages from distinct component
templates that may be recycled in different contexts. One typical
practice is to build a "master" template for an entire
section of a site, with a common header, footer and sidebar layout.
For each page request, the "content" template is
incorporated dynamically into a specified area of the master
template, usually a table cell.</p>
<p>(graphic)</p>
<p>Another common practice is to build small reusable templates
that may be included in other templates as logical components. This
may be useful for common "widgets" such as search boxes
or lists of related links, as well as for building configurable
portal pages where users may assemble different types of content to
their liking.</p>
<p>(graphic)</p>
<p>See <a href="tagref/include"><kbd>include</kbd></a> and
<a href="tagref/master"><kbd>master</kbd></a>. See also
<a href="guide/components">Building reusable layout
components</a> and <a href="guide/master">Using master
templates</a>.</p>
<h4>Property Declarations</h4>
<p>Template authors need a simple mechanism for declaring
properties within the templates. The most common use of such
properties is for configuring elements of an enclosing master
template, such as the title, navigation links, and whether to
include a search box. The data dictionary specifies available
properties as well as the set of valid values when appropriate.</p>
<p>(graphic)</p>
<p>See <a href="tagref/property"><kbd>property</kbd></a>.</p>
<h4>Conditional Insertion</h4>
<p>Designers often need to tailor the layout depending on the
specific data being presented. For example, when presenting a list
of library books that a user has checked out, the designer might
want to highlight the overdue ones in red.</p>
<p>See <a href="tagref/if"><kbd>if..else</kbd></a>.</p>
<h4>Iteration</h4>
<p>Dynamic pages often present lists of values or records, each of
which typically represents the results of a database query.
Template authors must have a way to iterate over each value or
record in such a list and format it appropriately. In the simplest
scenario, the exact HTML is repeated with each iteration. However,
template authors often need to vary the design depending on the
context. For example:</p>
<ol>
<li><p>First and last items may be formatted differently from items in
between.</p></li><li><p>Special breaks may be required when a particular value changes.
For example, a query may return the name and office of all
employees in a company, and the designer may wish to insert a
subheading for each office.</p></li><li><p>Colors or patterns may alternate between items. For example, the
designer may want to have alternate between white and gray bands in
a table.</p></li>
</ol>
<p>To accommodate these type of scenarios, the template parser sets
some additional variables that the designer can reference to vary
the layout from item to item.</p>
<p>See <a href="tagref/multiple"><kbd>multiple</kbd></a>,
<a href="tagref/group"><kbd>group</kbd></a>, <a href="tagref/grid"><kbd>grid</kbd></a>.</p>
<a href="tagref/list"><!-- invisible<kbd>list</kbd>.--></a>
<h3>Notes</h3>
<ul>
<li><p>Template tags are processed by the server each time a page is
requested. The end result of this processing is a standard HTML
page that is delivered to the user. Users do not see template tags
in the HTML source code of the delivered page.</p></li><li>
<p>With normal usage, the use of dynamic tags tends to increase the
amount of whitespace in the final HTML as compared to the template.
This usually does not affect how browsers display the page.
However, if a page layout depends on the presence or absence of
whitespace between HTML tags for proper display, then special care
must be taken with dynamic tags to avoid adding whitespace.</p><p>When placed on a line by themselves, tags that are containers
for template sections (<kbd>grid</kbd>, <kbd>if</kbd>, and
<kbd>multiple</kbd>) will cause newlines to be added to the page at
the beginning and end of the section. This can be avoided by
crowding the start and end tags like so:</p><pre>
&lt;td&gt;&lt;if %x% eq 5&gt;&lt;img src="five.gif"&gt;&lt;/if&gt;
&lt;else&gt;&lt;img src="notfive.gif"&gt;&lt;/else&gt;&lt;/td&gt;
</pre><p>Note that this should not be done unless necessary, since it
reduces the legibility of the template to others who need to edit
the template later.</p>
</li><li><p>
<strong>Caution:</strong>   Do not write to the connection.
Specifically, if you must use the <code>&lt;% %&gt;</code> tag, do
not call <code>ns_puts</code>, because it will not work the same
way as in AOLserver&#39;s ADP pages.</p></li>
</ul>
<hr>
<address><a href="mailto:christian\@arsdigita.com">Christian
Brechbuehler</a></address>
<!-- Created: Mon Aug 14 11:53:07 EDT 2000 --><!-- hhmts start -->
Last modified: Mon Oct 2 14:12:08 EDT 2000 <!-- hhmts end -->