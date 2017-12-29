
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System: Goals}</property>
<property name="doc(title)">Templating System: Goals</property>
<master>
<h2>Goals</h2>
<strong><a href="index">Templating System</a></strong>
<p>The overall goal of the templating system is to provide the
publishing team with a set of tools for simplifying the development
and maintenance of the user interface. In particular:</p>
<ul>
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
HTML template used to present the data. HTML authors should be able
to write templates that reference the data sources and properties
without further intervention from the programmer to produce a
finished page.</p></li><li><p>
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
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->