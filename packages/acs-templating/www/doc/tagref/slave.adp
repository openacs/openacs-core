
<property name="context">{/doc/acs-templating {Templating}} {Templating System Tag Reference: Slave}</property>
<property name="doc(title)">Templating System Tag Reference: Slave</property>
<master>
<h2>Slave</h2>
<a href="..">Templating System</a>
 : <a href="../designer-guide">Designer Guide</a>
 : <a href="index">Tag Reference</a>
 : Slave
<h3>Summary</h3>
<p>The <tt>slave</tt> tag is used to mark the position in the
master template where the body template should be inserted.</p>
<h3>Usage</h3>
<pre>
&lt;html&gt;
&lt;head&gt;&lt;title&gt;\@title\@&lt;/title&gt;&lt;/head&gt;
&lt;body&gt;
&lt;h2&gt;\@title\@&lt;/h2&gt;
&lt;hr&gt;
&lt;blockquote&gt;
  &lt;slave&gt;
&lt;/blockquote&gt;
&lt;hr&gt;
</pre>
<h3>Note(s)</h3>
<ul><li><p>See <a href="property"><tt>property</tt></a> and <a href="master"><tt>master</tt></a> for more information related to
master templates.</p></li></ul>
<hr>
<a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>
