
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System Tag Reference: Property}</property>
<property name="doc(title)">Templating System Tag Reference: Property</property>
<master>
<h2>Property</h2>
<a href="..">Templating System</a>
 : <a href="../designer-guide">Designer Guide</a>
 : <a href="index">Tag Reference</a>
 : Property
<h3>Summary</h3>
<p>The <kbd>property</kbd> tag is used to set named attributes of the
page.  The boolean attribute <kbd>adp</kbd> can be used to control, whether
the content of the element should be processed by the ADP paraser or
not. Properties are most commonly used to pass information to a master
template, such as a title or logo.</p>
<h3>Usage</h3>
<pre>&lt;master src="master"&gt;
&lt;property name="title"&gt;My Home Page&lt;/property&gt;
&lt;p&gt;Welcome to my home page!&lt;/p&gt;x
...
</pre>
<h3>Note(s)</h3>
<ul><li><p>See <a href="master"><kbd>master</kbd></a> and <a href="slave"><kbd>slave</kbd></a> for more information about master
templates.</p></li></ul>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->