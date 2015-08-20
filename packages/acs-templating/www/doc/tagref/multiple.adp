
<property name="context">{/doc/acs-templating {Templating}} {Templating System Tag Reference: Multiple}</property>
<property name="doc(title)">Templating System Tag Reference: Multiple</property>
<master>

<body>
<h2>Multiple</h2><a href="..">Templating System</a> : <a href="../designer-guide.html">Designer Guide</a> : <a href="index">Tag Reference</a> : Multiple
<h3>Summary</h3><p>The <tt>multiple</tt> tag is used to repeat a template section
for each row of a multirow data source. Column variables are reset
with each repetition to the values of the next row of the data
source.</p><h3>Usage</h3><pre>
&lt;!-- Begin multiple layout, i.e. &lt;table&gt; --&gt;
&lt;table&gt;

&lt;multiple name="users"&gt;

  &lt;!-- Row layout, i.e. &lt;tr&gt;...&lt;/tr&gt; --&gt;
  &lt;tr&gt;

    &lt;td&gt;
     \@users.first_name\@
    &lt;/td&gt;

    &lt;td&gt;
      \@users.last_name\@
    &lt;/td&gt;

    &lt;td&gt;
      \@users.state\@
    &lt;/td&gt;

  &lt;/tr&gt;

&lt;/multiple&gt;

&lt;!-- End multiple layout, i.e. &lt;/table&gt; --&gt;
&lt;/table&gt;
</pre><pre></pre><h3>Notes</h3><ul>
<li><p>The special variable <tt>datasource:rowcount</tt> may be used to
check for no rows in a data source (or any other special condition
related to the number of rows in the data source).</p></li><li>
<p>The special column <tt>datasource.rownum</tt> is set implicitly
for each repetition and can be used in conjunction with the
<tt>if</tt> tag to do row banding:</p><pre>
  &lt;multiple&gt;

  &lt;if \@datasource.rownum\@ odd&gt;
    &lt;tr bgcolor=#eeeeee&gt;
  &lt;/if&gt;

  &lt;if \@datasource.rownum\@ even&gt;
    &lt;tr bgcolor=#ffffff&gt;
  &lt;/if&gt;

  ...
</pre>
</li><li>
<p>The <tt>maxrows</tt> attribute may be used to limit the number
of rows that are output from the data source:</p><pre>
  &lt;multiple maxrows="n"&gt;
  ...
</pre><p>This attribute will cause processing to stop after <var>n</var>
rows have been output.</p>
</li><li>
<p>The <tt>startrow</tt> attribute may be used to skip a number of
rows at the beginning of the data source:</p><pre>
  &lt;multiple startrow="n"&gt;
  ...
</pre><p>This attribute will cause processing of the data source to begin
at row <var>n + 1</var>.</p>
</li><li>
<p>[Note: Carsten added this feature during the Berlin Hackaton
2004-02-14]</p><p>The <tt>delimiter</tt> attribute will add a string after each
row except the last row:</p><pre>
  &lt;multiple delimiter=" | "&gt;
  ...
</pre><p>This attribute will cause the rows to appear to be sepparated by
vertical bars. This is much more convenient than using the
<tt>&lt;if&gt;</tt> tags to check whether we are on the last
row.</p>
</li><li><p>The <tt>startrow</tt> and <tt>maxrows</tt> attributes may be
used together to output any range from the data source.</p></li><li><p>See the <tt><a href="group">group</a></tt> tag for
formatting subsets of a multirow data source. In the current
implementation, the <code>&lt;multiple&gt;</code> tag does not
nest.</p></li>
</ul><hr><a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>
</body>
