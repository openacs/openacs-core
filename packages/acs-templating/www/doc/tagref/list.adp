
<property name="context">{/doc/acs-templating {Templating}} {Templating System Tag Reference: List}</property>
<property name="doc(title)">Templating System Tag Reference: List</property>
<master>

<body>
<h2>List</h2><a href="..">Templating System</a> : <a href="../designer-guide.html">Designer Guide</a> : <a href="index">Tag Reference</a> : List
<h3>Summary</h3><p>The <tt>list</tt> tag is used to repeat a template section for
each item in a list data source.</p><h3>Usage</h3><pre>
&lt;list name="datasource"&gt;

  &lt;if \@datasource:rownum\@ ne \@datasource:rowcount\@&gt;
    \@datasource:item\@ :
  &lt;/if&gt;
  &lt;else&gt;
    &lt;b&gt;\@datasource:item\@&lt;/b&gt;
  &lt;/else&gt;

&lt;/list&gt;
</pre><h3>Notes</h3><ul>
<li><p>The special variable <tt>datasource<b>:</b>rownum</tt> has the
same meaning as the special column
<tt>datasource<b>.</b>rownum</tt> in the body of a
<tt>multiple</tt> tag.</p></li><li><p>The special variable <tt>datasource:rowcount</tt> has the same
meaning in the list context as it does for multirow data
sources.</p></li>
</ul><hr><a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>
</body>
