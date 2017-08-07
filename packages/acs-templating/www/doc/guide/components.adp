
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System User Guide: Building Reusable Template
Components}</property>
<property name="doc(title)">Templating System User Guide: Building Reusable Template
Components</property>
<master>
<h2>Building Reusable Template Components</h2>
<a href="..">Templating System</a>
 : <a href="../developer-guide">Developer Guide</a>
 : User Guide
<p>Most page layouts can be separated into smaller components, many
of which may appear in different contexts throughout a site.
Examples include:</p>
<ul>
<li>A box or section of the page listing contextual links related
to the contents of the page.</li><li>A list of comments on the contents of the page.</li><li>A search box, user poll, or other small embedded form.</li><li>Reports and other administrative pages, where the employee may
wish to assemble multiple panels of information on a single
page.</li><li>Many popular portal sites allow users to customize their home
pages by choosing and arranging a set of small layout components
within a table grid.</li>
</ul>
<p>The templating system makes it easy to build <a href="">reusable
components</a> for any of the above scenarios. The basic process is
to build a container template, which delineates the skeletal layout
of the page. Component templates may then be placed in the
container template with the <kbd>include</kbd> tag. The container
may pass arguments to the components as needed for personalization
or any other purpose.</p>
<!--
 <h3>Building the Container Template</h3>
 <h3>Including Component Templates</h3>
--><hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->