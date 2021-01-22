
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System User Guide: Overview}</property>
<property name="doc(title)">Templating System User Guide: Overview</property>
<master>
<h2>Overview</h2>
<a href="../index">Templating System</a>
 : <a href="../developer-guide">Developer Guide</a>
 : User Guide
<p>This document provides a brief introduction to the design of the
templating system and the process of building dynamic pages with
the templating system.</p>
<h3>Introduction</h3>

The templating system solves a clear business need: providing a
system for efficient collaboration between designers and developers
on building a web site. Writing a dynamic web page requires writing
application logic that retrieves data from a database and HTML
markup that presents this data in a readable form for the user. In
practice on production sites, this requires collaboration between
designers sensitive to issues of usability and the user experience
and developers who are sensitive to programming and performance
requirements. Without a templating system, a single script
containing the application logic and presentation markup is often
authored by both a designer and a developer simultaneously. This is
inefficient, error-prone, and difficult to maintain, as multiple
people with different purposes in mind must change the same file.
To solve this problem, the ACS Templating System, separates the
responsibilities of writing the page into separate application
logic and presentation layers.
<h3>How the Templating System Works</h3>
<p>This separation is achieved through utilization of the
Model-View-Controller (MVC) pattern. The MVC pattern is a classic
design pattern that identifies clear roles for components in GUI
application with persistent data originally developed for
SmallTalk-80 by Steve Burbeck. The <strong>model</strong>
represents the object, its data, and methods for updating the data.
The <strong>view</strong> provides a user a UI to see and
manipulate the data in the model. The <strong>controller</strong>
provides the system necessary to connect the model and the view to
the user&#39;s requests. This <a href="templating.jpg">diagram</a>
summarizes how the process flow of the templating system using the
MVC framework. The filename <strong>dynamic-page</strong> is simply
an example.</p>
<p>The <strong>model</strong> in the templating system is the
representation in the database of the <a href="/doc/objects">ACS Objects</a> and their associated PL/SQL
package methods. The <strong>view</strong> is the ADP template that
formats the datasources retrieved through the controller into a
presentation for a user. The <strong>controller</strong> is the
combination of the <a href="/doc/request-processor">Request
Processor</a> and the application logic pages implemented as .tcl
scripts that prepare data sources for the templating system.</p>
<p>This framework permits a clear separation between the logic that
retrieves data from the database and the markup that prepares the
data for display. The designer can focus on presentation and
usability issues and need only write HTML markup. The developer can
focus on the programming necessary to retrieve the data for the
designer and does not need to write HTML markup. These tasks are
separated into separate files so that the two tasks do not
interfere with each other.</p>
<p>The design of the templating system makes it easier to include
reusable presentation components as <a href="components">included templates</a> and <a href="master">master templates</a>, as explained in "<a href="composite">Composite Page</a>". Moreover, the ACS Core
pages are templated which enables users of the ACS who want to
customize their look and feel to update a site-wide master or the
individual templates without touching the application logic. If a
bug is fixed in the application logic, the application logic script
can be replaced without affecting the template.</p>
<p>The rest of this document explains the steps necessary to write
a templated page.</p>
<h3>Choose the data you wish to present</h3>
<p>The first step in building a dynamic page is to decide, at least
to a first approximation, on the data you wish to present to the
user. For example, a site that allows users to manage their car
maintenance records might want to present the following data on the
user&#39;s home page:</p>
<ul>
<li>The user&#39;s name.</li><li>The user&#39;s city of residence.</li><li>A list of the user&#39;s cars, showing the year, make, and
model.</li><li>A list of messages or alerts related to the user&#39;s
cars.</li><li>A list of local events or special offers from mechanics or
dealers.</li>
</ul>
<p>Note that our definition of <em>data</em> encompasses
<em>everything that is unique to a particular user&#39;s
experience</em>. It does <em>not</em> include text or other layout
features that will appear the same for all users.</p>
<p>Each of the items in the above list constitutes a <em>data
source</em> which the system merges with a template to produce the
finished page. The publisher typically describes the data to
present on each page as part of the site specification.</p>
<h3>Implement the Data Sources</h3>
<p>Once the publishing team has described the data to present on a
page, the developer writes a Tcl script to <a href="data">implement the data sources</a>. The Tcl script should
be located under the page root at the URL of the finished page. For
example, a dynamic page that will be located at
<kbd>http://yoursite.com/cars.acs</kbd> requires a Tcl script
located on the server at <kbd>/web/yoursite/www/cars.tcl</kbd> (or
wherever your pages happen to be located).</p>
<p>In addition to setting data sources, the Tcl script may perform
any other required tasks, such as checking permissions, performing
database transactions or sending email. It may also redirect to
another URL if necessary. The Tcl script may optionally use logic
to change which page is being delivered, specified by
<code>ad_return_template &lt;filename&gt;</code>. If no filename is
supplied, <code>ad_return_template</code> does nothing. If the page
as defined after the last call to ad_return_template differs from
what it was at the beginning of the page, its datasource
preparation script is run <em>in the same scope</em>, in fact
accumulating datasources. By default the templating system looks
for a file with the same name as the Tcl script, but for the
template with the extension <strong>.adp</strong>.</p>
<h3>Document the Data Sources</h3>
<p>The developer should include comments in the Tcl code
documenting each data source. A templating system specifies
recognizes special <a href="document">documentation
directives</a> that allow the comments to be extracted from the
code and accessed by the designer or publisher for reference.</p>
<h3>Write the Template</h3>
<p>The final step is to <a href="templates">write a
template</a> specifying the layout of the page. Template files must
have the <kbd>adp</kbd> extension. By default the system looks for
the template at the same location as the associated Tcl script,
such as <kbd>/web/yoursite/www/cars.adp</kbd>.</p>
<p>The layout is mostly HTML, with a small number of additional
custom tags to control the presentation of dynamic data on the
page. In most cases, the initial draft of the template will be
written by the developer in the course of testing the Tcl script.
The designer may then enhance the layout as required.</p>
<hr>
<a href="mailto:docs\@openacs.org">docs\@openacs.org</a>
