
<property name="context">{/doc/acs-templating {Templating}} {Templating System Tag Reference: Formgroup}</property>
<property name="doc(title)">Templating System Tag Reference: Formgroup</property>
<master>

<body>
<h2>Formgroup</h2><a href="..">Templating System</a> : <a href="../designer-guide.html">Designer Guide</a> : <a href="index">Tag Reference</a> : Formgroup
<h3>Summary</h3><p>The <tt>formgroup</tt> tag is used to lay out a set of check
boxes or radio buttons in a dynamic form template. All the check
boxes or radio buttons in a group share the same name. A button
group must be created as an element in the Tcl script associated
with the template.</p><h3>Usage</h3><pre>
  &lt;formtemplate id="choose_services"&gt;
    &lt;table&gt;
      &lt;formgroup id=services&gt;
         &lt;tr&gt;&lt;td&gt;\@formgroup.widget\@&lt;/td&gt;&lt;td&gt;\@formgroup.label\@&lt;/td&gt;&lt;/tr&gt;
      &lt;/formgroup&gt;
    &lt;/table&gt;&lt;br&gt;
  &lt;input type=submit value="Submit"&gt;
  &lt;/formtemplate&gt;
</pre><h3>Notes</h3><ul>
<li><p>The <tt>formgroup</tt> tag contains a template for formatting
each check box or radio button in the group. The tag makes a
special multirow data source named <tt>formgroup</tt> available in
the body of the tag. The <tt>formgroup</tt> data source includes
two columns. The first is <tt>widget</tt>, containing an HTML
<tt>input</tt> tag for one of the buttons in the group. The second
is <tt>label</tt>, containing a corresponding label for the
button.</p></li><li><p>The <tt>formgroup</tt> tag may emulate either the <a href="multiple"><tt>multiple</tt></a> or <a href="grid"><tt>grid</tt></a> tags in repeating the template
section within the tag. By default it emulates the <a href="multiple"><tt>multiple</tt></a> tag. If the <tt>cols</tt>
attribute is specified, the <tt>formgroup</tt> tag will emulate the
<a href="grid"><tt>grid</tt></a> tag.</p></li><li>
<p>HTML attributes, including JavaScript event handlers, may be
specified as attributes to the <tt>formgroup</tt> tag. The system
will include all such attributes in the <tt>input</tt> tags of each
radio button or check box in the group.</p><pre>
&lt;formgroup id="services" onChange="validate();"&gt;
</pre>
</li><li><p>See the <a href="formtemplate"><tt>formtemplate</tt></a>
and <a href="formwidget"><tt>formwidget</tt></a> tags for more
information on writing the body of a dynamic form template.</p></li>
</ul><hr><a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>
</body>
