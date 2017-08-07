
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System Tag Reference: include-optional}</property>
<property name="doc(title)">Templating System Tag Reference: include-optional</property>
<master>
<h2>Include</h2>
<a href="..">Templating System</a>
 : <a href="../designer-guide">Designer Guide</a>
 : <a href="index">Tag Reference</a>
 : include-optional
<h3>Summary</h3>
<p>The <kbd>include-optional</kbd> tag is used to include another
template in the current template, but make some other chunk
dependent on whether or not the included template returned
something.</p>
<p>This is useful if, say, you want to wrap the template with some
HTML, for example, a frame in a portal, but if there&#39;s nothing
to show, you don&#39;t want to show the frame either.</p>
<h3>Usage</h3>
<pre>
&lt;include-optional src="blog-months"&gt;
  &lt;tr&gt;
    &lt;th bgcolor="\@header_background_color\@"&gt;
      Archive
    &lt;/th&gt;
  &lt;/tr&gt;
  &lt;tr&gt;
    &lt;td nowrap align="center"&gt;
      &lt;include-output&gt;
    &lt;/td&gt;
  &lt;/tr&gt;
  &lt;tr&gt;
    &lt;td height="16"&gt;
      &lt;table&gt;&lt;tr&gt;&lt;td&gt;&lt;/td&gt;&lt;/tr&gt;&lt;/table&gt;
    &lt;/td&gt;
  &lt;/tr&gt;
&lt;/include-optional&gt;
</pre>
<h3>Notes</h3>
<ul><li>The output of the included template will be put where the
<kbd>&lt;include-output&gt;</kbd> appears.</li></ul>
<hr>
<small>Tag added by: Lars Pinds (lars\@collaboraid.net)<br>
Documentation added from sources on Nov 2002, Roberto
Mello.</small>
