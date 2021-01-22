
<property name="context">{/doc/acs-templating {ACS Templating}} {ACS Templating Requirements}</property>
<property name="doc(title)">ACS Templating Requirements</property>
<master>
<h2>ACS Templating Requirements</h2>

by <a href="mailto:karlg\@arsdigita.com">Karl Goldstein</a>
,
<a href="mailto:christian\@arsdigita.com">Christian
Brechbühler</a>
, <a href="mailto:psu\@arsdigita.com">Peter
Su</a>
, and <a href="mailto:yon\@arsdigita.com">Yonatan Feldman</a>
<a name="introduction" id="introduction"></a>
<h3>I. Introduction</h3>

The following is a requirements document for the ACS Templating
System version 0.5. It has also been called Karl&#39;s Templates,
the Dynamic Publishing System (DPS), and Stencil. The official
package name for the system is now
<code><strong>acs-templating</strong></code>
. <a name="vision" id="vision"></a>
<h3>II. Vision Statement</h3>

On websites of sufficient size, a consistent look and feel (the UI,
or user interface) for users is important, while for site
publishers and administrators, de-coupling the UI from programming
allows for easier maintenance and more efficient workflow. Thus the
ACS 4 Templating system provides mechanisms that allow programmers
and graphic designers to work independently of each other.
Templates specify the layout of the page separately from the
dynamic content of the page. Graphic designers work primarily on
the layout, that is the template, while programmers work primarily
on a script or program that generates the dynamic content that
fills the blanks in the template. In addition, the templating
system provides a way to use a single layout specification for the
majority - if not all - of a website&#39;s pages, so the overall
layout of a site can be more easily administered. <a name="system" id="system"></a>
<h3>III. System Overview</h3>

The templating system provides:
<ul>
<li>A set of custom markup tags (using ADP, AOLserver Dynamic
Pages) that are used to specify page layout, and to declare where
dynamically generated content belongs in the layout.</li><li>An API for specifying the content part of the page. This API is
used by programmers to specify the script that generates the
content in a page.</li><li>A mechanism for combining the data (from a data source) with
the layout (from a layout template) into a single dynamically
generated HTML page.</li><li>A mechanism for specifying a single master template to be used
for multiple pages.</li>
</ul>
<a name="usercases" id="usercases"></a>
<h3>IV. Use-cases and User-scenarios</h3>
<p>The template system is designed to be used by two classes of
users: programmers and designers. In bulding a web site,
programmers are generally responsible for defining and implementing
the <em>application logic</em> of the site, while designers are
more responsible for the <em>presentation</em>. Generally speaking,
the application logic generates data for the presentation to
display to the user. The template system must provide mechanisms
that supports both of these tasks and allows the designer and
programmer to work separately, but for their work to be combined at
runtime into something that the user sees as a single page.</p>
<p>Thus, pages are naturally split into two parts. The <em>logic
part</em> executes application logic and generates data, and the
<em>presentation</em> part that specifies the layout of the page
and so on.</p>
<p>What is needed is:</p>
<ol>
<li>A notation and API for the programmer specify the application
logic and to generate the data to be displayed. In ACS, we call the
data that we wish to display a <em>data source</em> or <em>page
property</em>. Application logic is driven by the inputs the page
gathers from the user request (e.g. the HTTP request), and the
computation that the page must perform on this input. This
computation will generally create and populate the data sources and
page properties. Data sources tend to be connected to database
queries, while page properties can be defined by any arbitrary
computation.</li><li>A notation and API for the designer to specify how the data
sources and page properties will be presented to the user. This
notation will generally take the form of some kind extended
HTML.</li><li>A mechanism for communicating the data sources and page
properties from the logic part of the page</li>
</ol>
<p>Jane Programmer writes a page contract and a draft template,
that uses the promised page properties. Joe Designer takes that
template and makes it look nice, using his design skills and HTML
literacy. Meanwhile Jane Programmer writes code to generate the
page properties, typically by querying the database. When both are
done, the page is ready for Jim User, who requests it using his web
browser.</p>
<p>
<em>Alternate scenario:</em> Judy Designer is familiar with the
template system. She starts directly from a defined page contract,
so Jane Programmer doesn&#39;t need to write the draft
template.</p>
<h3>V. Related Links</h3>
<ul><li>Design document</li></ul>
<a name="functional" id="functional"></a>
<h3>VI.A Functional Requirements</h3>
<ul>
<li>
<a name="10.0"></a><strong>10.0 A Common Solution</strong><p>Programmers and designers should only have to learn a single
system that serves as a UI substrate for all the functionally
specific modules in the toolkit.</p><div style="margin-left: 2em">
<strong>10.0.1</strong><p>The system should not make any assumptions about how pages
should look or function.</p><strong>10.0.5</strong><p>Publishers should be able to change the default presentation of
any module using a single methodology with minimal exposure to
code.</p>
</div><strong>10.5 Programmer&#39;s API</strong><p>It must be easy to use/integrate the templating system with any
application. This implies a stable, simple, and comprehensive API
for programmers to use when writing or converting modules.</p><div style="margin-left: 2em">
<strong>10.5.1 Page Properties
Publishing</strong><p>Programmers must be able to publish a page&#39;s data sources,
so that a graphic designer knows what data sources are
available.</p><strong>10.5.2 Page Contract Implementation</strong><p>Programmers must be able to generate and populate the page
properties they promise. This includes page properties of types:
onevalue, onerow, multirow, onelist, and multilist.</p>
</div><strong>10.10 Graphic Designer&#39;s API</strong><p>It must be simple for graphic designers to create and maintain
templates that include dynamic data, and other templates. This
requires a stable, simple, and comprehensive API for graphic
designers to use when creating the layout pages for a site.</p><ul>
<li style="list-style: none">
<strong>10.10.1 Variable
Substitution</strong><p>Much like the "mail merge" feature of a word
processor, template authors must use special tags to position each
piece of dynamic data within the layout. Each template is
associated with a data dictionary that lists all available
variables.</p><strong>10.10.2 Use of Components</strong><p>To speed development and ensure consistency of design, template
authors are encouraged to assemble pages from distinct
<em>component templates</em> that may be recycled in different
contexts. One typical practice is to build a "master"
template for an entire section of a site, with a common header,
footer and sidebar layout. For each page request, the
"content" template is incorporated dynamically into a
specified area of the master template, usually a table cell.</p><p>Another common practice is to build small reusable templates
that may be included in other templates as logical components. This
may be useful for common "widgets" such as search boxes
or lists of related links, as well as for building configurable
portal pages where users may assemble different types of content to
their liking.</p><strong>10.10.3 Inter-Template Communication</strong><p>Template authors need a simple mechanism for declaring
properties within templates. The most common use of such properties
is for configuring elements of an enclosing master template, such
as the title, navigation links, and whether to include a search
box.</p><strong>10.10.4 Conditional Insertion</strong><p>Designers often need to tailor the layout depending on the
specific data being presented. For example, when presenting a list
of library books that a user has checked out, the designer might
want to highlight the overdue ones in red. For this, designers must
have the ability to write simple program logic (<em>Note: We run
the risk of inventing our own language here, we must be
careful</em>).</p>
</li><li style="list-style: none">
<strong>10.10.5 Iteration</strong><p>Dynamic pages often present lists of values or records, each of
which typically represents the results of a database query.
Template authors must have a way to iterate over each value or
record in such a list and format it appropriately. In the simplest
scenario, the exact HTML is repeated with each iteration. However,
template authors often need to vary the design depending on the
context.</p>
</li>
</ul>
</li><li>
<a name="20.0"></a><strong>20.0 Separation of Code and
Layout</strong><p>Programmers should be able to specify the page properties
independently of the markup used to present the data in the
template. Markup authors should be to able to write templates that
reference the page properties without further intervention from the
programmer to produce a finished page.</p><div style="margin-left: 2em">
<strong>20.5 Programmer - Graphic
Designer Communication</strong><p>A graphic designer must be able to look at the documentation for
a page in a documentation browser and find out what properties a
page publishes and what types they are. This documentation should
be available through the standard ACS documentation facilities.</p>
</div>
</li><li>
<a name="30.0"></a><strong>30.0 Separation of Page
Components</strong><p>There should be provisions so that pages can be broken into
discrete components to simplify maintenance of the markup code and
allow for reuse in different contexts. Examples of common page
components include a navigation bar, a search box, or a section of
a report or story.</p>
</li><li>
<a name="40.0"></a><strong>40.0 Global Control Over
Presentation</strong><p>There should be a way to define one or more standard master
templates used by most pages on a site, so that changes to the
overall look and feel of a site can be made in one place.</p>
</li><li>
<a name="50.0"></a><strong>50.0 Dynamic Selection of
Presentation Style</strong><p>Given that the same data may be presented in many different
ways, there should be a general mechanism for selecting a specific
presentation (including file format, layout, character set and
language) for each page request, depending on characteristics such
as user preference, location, browser type and/or device.</p>
</li><li>
<a name="60.0"></a><strong>60.0 Usability</strong><p>Programmers should be able to develop template specifications
using their standard tools for writing and maintaining code on the
server. HTML authors should be able to access information about
template specifications and work on templates remotely without
needing shell access to the server.</p>
</li>
</ul>
<a name="nonfunctional" id="nonfunctional"></a>
<h3>VI.B Non-functional Requirements</h3>
<ul>
<li>
<a name="100.0"></a><strong>100.0 Distribution</strong><p>The Templating System must be releasable as part of the ACS and
as a separate product. When distributed as part of the ACS all
documentation, examples, and source code must follow ACS standards.
This includes but is not limited to: using the <code>db_api</code>,
using <code>ad_page_contract</code> appropriately.</p>
</li><li>
<a name="110.0"></a><strong>110.0 Performance</strong><p>The Templating System must not cause any performance problems to
a site. It must be fast and efficient, and it must not slow down
page load speed by more than 10% versus a Tcl page with inline
HTML.</p>
</li>
</ul>
<h3>VII. Revision History</h3>
<table cellpadding="2" cellspacing="2" width="90%" bgcolor="#EFEFEF">
<tr bgcolor="#E0E0E0">
<th width="10%">Document Revision #</th><th width="50%">Action Taken, Notes</th><th>When?</th><th>By Whom?</th>
</tr><tr>
<td>0.1</td><td>Creation</td><td>8/23/2000</td><td>Yonatan Feldman</td>
</tr><tr>
<td>0.2</td><td>Merge with previous docs</td><td>8/25/2000</td><td>Christian BrechbÃ&amp;frac14;hler</td>
</tr><tr>
<td>0.3</td><td>Edited, reviewed, pending freeze</td><td>8/28/2000</td><td>Kai Wu</td>
</tr>
</table>
<hr>
<address><a href="mailto:yon\@arsdigita.com">yon\@arsdigita.com</a></address>

Last modified: $&zwnj;Id: requirements.html,v 1.2.2.2 2017/04/21 16:50:30
gustafn Exp $
