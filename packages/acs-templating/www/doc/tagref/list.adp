
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System Tag Reference: List}</property>
<property name="doc(title)">Templating System Tag Reference: List</property>
<master>
<h2>List</h2>
<a href="..">Templating System</a>
 : <a href="../designer-guide">Designer Guide</a>
 : <a href="index">Tag Reference</a>
 : List
<h3>Summary</h3>
<p>The <kbd>list</kbd> tag is used to repeat a template section for
each item in a list data source.</p>
<h3>Usage</h3>
<pre>
&lt;list name="datasource"&gt;

  &lt;if \@datasource:rownum\@ ne \@datasource:rowcount\@&gt;
    \@datasource:item\@ :
  &lt;/if&gt;
  &lt;else&gt;
    &lt;b&gt;\@datasource:item\@&lt;/b&gt;
  &lt;/else&gt;

&lt;/list&gt;
</pre>
<h3>Notes</h3>
<ul>
<li><p>The special variable
<kbd>datasource<strong>:</strong>rownum</kbd> has the same meaning
as the special column <kbd>datasource<strong>.</strong>rownum</kbd>
in the body of a <kbd>multiple</kbd> tag.</p></li><li><p>The special variable <kbd>datasource:rowcount</kbd> has the same
meaning in the list context as it does for multirow data
sources.</p></li>
</ul>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->