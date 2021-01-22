
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System Tag Reference: Master}</property>
<property name="doc(title)">Templating System Tag Reference: Master</property>
<master>
<h2>Master</h2>
<a href="..">Templating System</a>
 : <a href="../designer-guide">Designer Guide</a>
 : <a href="index">Tag Reference</a>
 : Master
<h3>Summary</h3>
<p>The <kbd>master</kbd> tag is used to specify the relative or
absolute URL of another template to serve as a frame for the
current template. The entire contents of the current template are
inserted into the master template at a position designated by the
<a href="slave"><kbd>slave</kbd></a> tag in the master
template.</p>
<h3>Usage</h3>
<pre>
&lt;master src="master"&gt;

&lt;property name="title"&gt;My Home Page&lt;/property&gt;

&lt;p&gt;Welcome to my home page!&lt;/p&gt;

...
</pre>
<h3>Note(s)</h3>
<ul><li><p>See <a href="property"><kbd>property</kbd></a> and <a href="slave"><kbd>slave</kbd></a> for more information related to
master templates.</p></li></ul>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->