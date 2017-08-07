
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System User Guide: Using Master Templates}</property>
<property name="doc(title)">Templating System User Guide: Using Master Templates</property>
<master>
<h2>Using Master Templates</h2>
<a href="..">Templating System</a>
 : <a href="../developer-guide">Developer Guide</a>
 : User Guide
<p>Master templates dramatically simplify the task of maintaining a
consistent look and feel across all the pages of a site (or section
of a site). This document gives a brief overview of how to
implement a master template.</p>
<h3>Design a Content Frame</h3>
<p>Most web pages are laid out with a central <em>content area</em>
where the actual unique content of the page is displayed.
Surrounding the content area is a <em>frame</em> with common
elements that are consistent from page to page:</p>
<table cellspacing="0" cellpadding="10" border="1">
<tr>
<td align="center" bgcolor="#CCCCCC">Logo</td><td bgcolor="#CCCCCC" width="300" align="center" colspan="2">Ad
Banner</td>
</tr><tr><td></td></tr><tr><td bgcolor="#CCCCCC" align="center" colspan="3">Navigation/Context
Bar</td></tr><tr>
<td bgcolor="#CCCCCC">Section<br>
Links</td><td bgcolor="#FFCCCC" align="center" colspan="2">
<p> </p><p> </p>
CONTENT<br>
AREA
<p> </p><p> </p>
</td>
</tr><tr><td align="center" colspan="3" bgcolor="#CCCCCC">Footer</td></tr>
</table>
<p>Most sites use an HTML table to delineate the content area
within the frame, allowing for the inclusion of a sidebar along
with a header and footer. Sites that opt for a simpler layout may
only have a header above and a footer below the content area.</p>
<p>The master template is typically highly dynamic. Menus, context
bars and other navigational controls must change depending on the
section of the site the user is browsing. A "Related
Links" box would have to reflect the specific contents of the
page. The master template may also be personalized for registered
users to include their name and access to restricted areas of the
site. Special formatting preferences may also be applied for
registered users.</p>
<h3>Write the Master Template</h3>
<p>A master template to implement the page layout shown above would
have this basic structure:</p>
<blockquote><pre>
&lt;html&gt;&lt;body&gt;&lt;table width="100%" cellspacing="0" cellpadding="0" border="0"&gt;

&lt;tr&gt;
  &lt;td&gt;&lt;!-- LOGO --&gt;&lt;/td&gt;
  &lt;td colspan="2"&gt;&lt;!-- AD BANNER --&gt;&lt;/td&gt;
&lt;/tr&gt;

&lt;tr&gt;&lt;td colspan="3"&gt;&lt;!-- NAVIGATION/CONTEXT BAR --&gt;&lt;/td&gt;&lt;/tr&gt;

&lt;tr&gt;
  &lt;td&gt;&lt;!-- SECTION LINKS --&gt;&lt;/td&gt;
  &lt;td colspan="2"&gt;
    &lt;!-- CONTENT --&gt;
    <strong>&lt;slave&gt;</strong>
  &lt;/td&gt;
&lt;/tr&gt;

&lt;tr&gt;&lt;td colspan="3"&gt;&lt;!-- FOOTER --&gt;&lt;/td&gt;&lt;/tr&gt;

&lt;/table&gt;&lt;/body&gt;&lt;/html&gt;
</pre></blockquote>
<p>The only special feature of this master template is the
<kbd>slave</kbd> tag, which marks the location of the content area.
Note that the content is inserted into the master template as a
single passage of HTML or plain text. The master template should
always frame the content area within a <kbd>td</kbd> tag when using
a table to specify the overall layout of the page. Page layouts
that do not rely on tables often use <kbd>hr</kbd> tags to
demarcate the content area from the header and footer.</p>
<h3>Write the Page Template(s)</h3>
<p>A page template must include a <kbd>master</kbd> tag to specify
that its output should be enclosed in a master template:</p>
<blockquote><pre>
&lt;master src="/templates/master"&gt;

&lt;!--Begin layout of page content--&gt;
&lt;h3&gt;\@title\@&lt;/h3&gt;
&lt;p&gt;by \@name\@&lt;/p&gt;
&lt;p&gt;&lt;b&gt;\@byline\@&lt;/b&gt;: \@text&lt;/p&gt;
...
</pre></blockquote>
<p>The <kbd>master</kbd> tag may be included anywhere in the body
of the page template, although usually the top of the file is the
best location for it.</p>
<h3>Adding Dynamic Elements to the Master Template</h3>
<p>The master template may be associated with its own Tcl script,
which may set data sources to support dynamic elements outside the
main content area. For example, you might wish to include the
user&#39;s name on every page to indicate that the site has been
personalized. The Tcl script associated with the master template
would include code like this:</p>
<blockquote><pre>
set user_name [your_procedure_to_get_the_current_user_name]
</pre></blockquote>
<p>The template would have a section like this:</p>
<blockquote><pre>
&lt;if \@user_name\@ nil&gt;
  &lt;a href="/register.acs"&gt;Register Now!&lt;/a&gt;
&lt;/if&gt;
&lt;else&gt;
  \@user_name\@ (&lt;a href="/signout.acs"&gt;Sign Out&lt;/a&gt;)
&lt;/else&gt;
</pre></blockquote>
<h3>Passing Property Values from the Page Template to Master
Template</h3>
<p>As mentioned above, in many cases the dynamic elements of the
master template depend on whatever is appearing in the content area
for a particular request. The <kbd>property</kbd> tag may be used
in the page template to specify values that should be passed to the
master template:</p>
<blockquote><pre>
&lt;master src="/templates/master"&gt;
&lt;property name="title"&gt;\@title\@&lt;/property&gt;

&lt;!--Begin layout of page content--&gt;
...
</pre></blockquote>
<p>In this case, the <kbd>property</kbd> tag establishes
<kbd>title</kbd> as a data source for the master template.
Properties are set as regular Tcl variables prior to executing the
Tcl script associated with the master template. This allows the
page template to pass an ID which the Tcl script associated with
the master template may use to query for additional
information.</p>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->