
<property name="context">{/doc/acs-templating {Templating}} {Templating System User Guide: Writing Templates}</property>
<property name="doc(title)">Templating System User Guide: Writing Templates</property>
<master>

<body>
<h2>Writing Templates</h2><p>Templates are the primary means for separating the work of
developers and designers. A template is written by a designer and
consists largely of static HTML (or other markup). The template
author uses a small set of special markup tags to reference dynamic
data prepared by the developer. A reasonably skilled template
author should be able to implement a template without any
assistance from the developer, other than assuring that the proper
dynamic data is accessible.</p><p>This document introduces the basic concepts underlying the use
of template tags in ACS 4.0.</p><h3>Variable Substitution</h3><p>Much like the mail merge feature of a word processor, template
authors must use special tags to position each piece of dynamic
data within the layout. Each template is associated with a data
dictionary that lists all available variables.</p><p>See <a href="../tagref/variable.html">Variable
Substitution</a>.</p><h3>Use of Components</h3><p>To speed development and ensure consistency of design, template
authors are encouraged to assemble pages from distinct component
templates that may be recycled in different contexts. One typical
practice is to build a "master" template for an entire section of a
site, with a common header, footer and sidebar layout. For each
page request, the "content" template is incorporated dynamically
into a specified area of the master template, usually a table
cell.</p><p>(graphic)</p><p>Another common practice is to build small reusable templates
that may be included in other templates as logical components. This
may be useful for common "widgets" such as search boxes or lists of
related links, as well as for building configurable portal pages
where users may assemble different types of content to their
liking.</p><p>(graphic)</p><p>See <a href="../tagref/include.html"><tt>include</tt></a>.</p><h3>Property Declarations</h3><p>Template authors need a simple mechanism for declaring
properties within the templates. The most common use of such
properties is for configuring elements of an enclosing master
template, such as the title, navigation links, and whether to
include a search box. The data dictionary specifies available
properties as well as the set of valid values when appropriate.</p><p>(graphic)</p><p>See <a href="../tagref/property.html"><tt>property</tt></a>.</p><h3>Conditional Insertion</h3><p>Designers often need to tailor the layout depending on the
specific data being presented. For example, when presenting a list
of library books that a user has checked out, the designer might
want to highlight the overdue ones in red.</p><p>See <a href="../tagref/if.html"><tt>if..else</tt></a>.</p><h3>Iteration</h3><p>Dynamic pages often present lists of values or records, each of
which typically represents the results of a database query.
Template authors must have a way to iterate over each value or
record in such a list and format it appropriately. In the simplest
scenario, the exact HTML is repeated with each iteration. However,
template authors often need to vary the design depending on the
context. For example:</p><ol>
<li><p>First and last items may be formatted differently from items in
between.</p></li><li><p>Special breaks may be required when a particular value changes.
For example, a query may return the name and office of all
employees in a company, and the designer may wish to insert a
subheading for each office.</p></li><li><p>Colors or patterns may alternate between items. For example, the
designer may want to have alternate between white and gray bands in
a table.</p></li>
</ol><p>To accomodate these type of scenarios, the template parser sets
some additional variables that the designer can reference to vary
the layout from item to item.</p><p>See <a href="../tagref/multiple.html"><tt>multiple</tt></a>,
<a href="../tagref/group.html"><tt>group</tt></a>, <a href="../tagref/list.html"><tt>list</tt></a>.</p><hr><a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>
</body>
