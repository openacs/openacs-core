
<property name="context">{/doc/acs-templating {Templating}} {Templating System Tag Reference: Noparse}</property>
<property name="doc(title)">Templating System Tag Reference: Noparse</property>
<master>

<body>
<h2>Noparse</h2><h3>Summary</h3><p>The <tt>noparse</tt> tag is used to protect template tags that
should not be parsed. It is useful when templates are generated
dynamically. For example, the templating system uses the
<tt>noparse</tt> tag in the "style" templates used for
auto-generated forms.</p><h3>Usage</h3><pre>
&lt;noparse&gt;
  &lt;multiple name=cars&gt;
    \\@cars.make\\@
    \\@cars.model\\@
  &lt;/multiple&gt;
&lt;/noparse&gt;
</pre><h3>Note(s)</h3><ul><li><p>Normal variable references <em>are</em> interpreted, even within
a <tt>noparse</tt> tag. This is useful for generating templates
where the attributes of the output template (such as references to
component templates in an <tt>include</tt> tag or to form elements
in a <tt>formwidget</tt> tag) must be</p></li></ul><hr><a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>
</body>
