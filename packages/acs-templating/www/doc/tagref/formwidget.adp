
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System Tag Reference: Formwidget}</property>
<property name="doc(title)">Templating System Tag Reference: Formwidget</property>
<master>
<h2>Formwidget</h2>
<a href="..">Templating System</a>
 : <a href="../designer-guide">Designer Guide</a>
 : <a href="index">Tag Reference</a>
 : Formwidget
<h3>Summary</h3>
<p>The <kbd>formwidget</kbd> tag is used to position a form element
in a dynamic form template. The element itself must be created in
the Tcl script associated with the template.</p>
<h3>Usage</h3>
<pre>
  &lt;formtemplate id="add_user"&gt;
  &lt;table&gt;
  &lt;tr&gt;
    &lt;td&gt;First Name&lt;/td&gt;&lt;td&gt;<strong>&lt;formwidget id="first_name"&gt;</strong>&lt;/td&gt;
  &lt;/tr&gt;
  &lt;tr&gt;
    &lt;td&gt;First Name&lt;/td&gt;&lt;td&gt;<strong>&lt;formwidget id="first_name"&gt;</strong>&lt;/td&gt;
  &lt;/tr&gt;
  &lt;/table&gt;&lt;br&gt;
  &lt;input type="submit" value="Submit"&gt;
  &lt;/formtemplate&gt;
</pre>
<h3>Notes</h3>
<ul>
<li><p>The <kbd>formwidget</kbd> tag takes the place of
<kbd>input</kbd> and <kbd>select</kbd> tags in static HTML forms.
The system substitutes these tags with the appropriate HTML tags,
complete with their proper values, options and other attributes,
while rendering the template. Explicit form tags in the template
may be used in special circumstances, but should be avoided
wherever possible.</p></li><li>
<p>HTML attributes may be specified as attributes to the
<kbd>formwidget</kbd> tag. The system will include all such
attributes in the <kbd>input</kbd> or <kbd>select</kbd> tag of the
rendered HTML form. Although possible, newer browser security
features such as CSP discourage the use of inline Javascript event
handlers.</p><pre>
&lt;formwidget id="cc_number" style="background-color:white;"&gt;</pre>
</li><li><p>See the <a href="formtemplate"><kbd>formtemplate</kbd></a>
and <a href="formgroup"><kbd>formgroup</kbd></a> tags for more
information on writing the body of a dynamic form template.</p></li>
</ul>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->