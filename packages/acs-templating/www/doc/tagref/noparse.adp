
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System Tag Reference: Noparse}</property>
<property name="doc(title)">Templating System Tag Reference: Noparse</property>
<master>
<h2>Noparse</h2>
<strong>
<a href="../index">Templating System</a> : Tag
Reference</strong>
<h3>Summary</h3>
<p>The <kbd>noparse</kbd> tag is used to protect template tags that
should not be parsed. It is useful when templates are generated
dynamically. For example, the templating system uses the
<kbd>noparse</kbd> tag in the "style" templates used for
auto-generated forms.</p>
<h3>Usage</h3>
<pre>
&lt;noparse&gt;
  &lt;multiple name=cars&gt;
    \\@cars.make\\@
    \\@cars.model\\@
  &lt;/multiple&gt;
&lt;/noparse&gt;
</pre>
<h3>Note(s)</h3>
<ul><li><p>Normal variable references <em>are</em> interpreted, even within
a <kbd>noparse</kbd> tag. This is useful for generating templates
where the attributes of the output template (such as references to
component templates in an <kbd>include</kbd> tag or to form
elements in a <kbd>formwidget</kbd> tag) must be</p></li></ul>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->