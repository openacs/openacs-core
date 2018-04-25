
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System Tag Reference: Formgroup}</property>
<property name="doc(title)">Templating System Tag Reference: Formgroup</property>
<master>
<h2>Formgroup</h2>
<a href="..">Templating System</a>
 : <a href="../designer-guide">Designer Guide</a>
 : <a href="index">Tag Reference</a>
 : Formgroup
<h3>Summary</h3>
<p>The <kbd>formgroup</kbd> tag is used to lay out a set of check
boxes or radio buttons in a dynamic form template. All the check
boxes or radio buttons in a group share the same name. A button
group must be created as an element in the Tcl script associated
with the template.</p>
<h3>Usage</h3>
<pre>
  &lt;formtemplate id="choose_services"&gt;
    &lt;table&gt;
      &lt;formgroup id=services&gt;
         &lt;tr&gt;&lt;td&gt;\@formgroup.widget\@&lt;/td&gt;&lt;td&gt;\@formgroup.label\@&lt;/td&gt;&lt;/tr&gt;
      &lt;/formgroup&gt;
    &lt;/table&gt;&lt;br&gt;
  &lt;input type="submit" value="Submit"&gt;
  &lt;/formtemplate&gt;
</pre>
<h3>Notes</h3>
<ul>
<li><p>The <kbd>formgroup</kbd> tag contains a template for formatting
each check box or radio button in the group. The tag makes a
special multirow data source named <kbd>formgroup</kbd> available
in the body of the tag. The <kbd>formgroup</kbd> data source
includes two columns. The first is <kbd>widget</kbd>, containing an
HTML <kbd>input</kbd> tag for one of the buttons in the group. The
second is <kbd>label</kbd>, containing a corresponding label for
the button.</p></li><li><p>The <kbd>formgroup</kbd> tag may emulate either the <a href="multiple"><kbd>multiple</kbd></a> or <a href="grid"><kbd>grid</kbd></a> tags in repeating the template
section within the tag. By default it emulates the <a href="multiple"><kbd>multiple</kbd></a> tag. If the <kbd>cols</kbd>
attribute is specified, the <kbd>formgroup</kbd> tag will emulate
the <a href="grid"><kbd>grid</kbd></a> tag.</p></li><li>
<p>HTML attributes may be specified as attributes to the
<kbd>formgroup</kbd> tag. The system will include all such
attributes in the <kbd>input</kbd> tags of each radio button or
check box in the group. Although possible, newer browser security
features such as CSP discourage the use of inline Javascript event
handlers.</p><pre>
&lt;formgroup id="services" style="background-color:white;"&gt;</pre>
</li><li><p>See the <a href="formtemplate"><kbd>formtemplate</kbd></a>
and <a href="formwidget"><kbd>formwidget</kbd></a> tags for
more information on writing the body of a dynamic form
template.</p></li>
</ul>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->