
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System Tag Reference: Grid}</property>
<property name="doc(title)">Templating System Tag Reference: Grid</property>
<master>
<h2>Grid</h2>
<a href="..">Templating System</a>
 : <a href="../designer-guide">Designer Guide</a>
 : <a href="index">Tag Reference</a>
 : Grid
<h3>Summary</h3>
<p>The <kbd>grid</kbd> tag is used to output each row of a multirow
datasource as a cell of an <var>n</var> column grid.</p>
<h3>Usage</h3>
<pre>
&lt;!-- Begid grid layout, i.e. &lt;table&gt; --&gt;
&lt;table&gt;

&lt;grid name="datasource" cols="n"&gt;

  &lt;if \@datasource.col\@ eq 1&gt;
    &lt;!-- Begin row, i.e. &lt;tr&gt; --&gt;
    &lt;tr&gt;
  &lt;/if&gt;

  &lt;!-- Cell layout, i.e. &lt;td&gt;...&lt;/td&gt; --&gt;
  &lt;td&gt;

    &lt;!-- Cells may be unoccupied at the end. --&gt;
    &lt;if \@datasource.rownum\@ le \@datasource:rowcount\@&gt;
      ...
      \@datasource.variable\@
      ...
    &lt;/if&gt;

    &lt;else&gt;
      &lt;!-- Placeholder to retain cell formatting --&gt;
       
    &lt;/else&gt;

  &lt;/td&gt;

  &lt;if \@datasource.col\@ eq "n"&gt;
    &lt;!-- End row, i.e. &lt;/tr&gt; --&gt;
    &lt;/tr&gt;
  &lt;/if&gt;

&lt;/grid&gt;
</pre>
<h3>Notes</h3>
<ul>
<li>
<p>Rows from the data source are output in column-first order. For
example, if a datsource has 10 datasources and the grid has 3
columns, the rows from the datasource will appear in the following
order:</p><table cellpadding="2" cellspacing="0" border="1" bgcolor="#EEEEEE">
<tr>
<td width="30">1</td><td width="30">5</td><td width="30">9</td>
</tr><tr>
<td width="30">2</td><td width="30">6</td><td width="30">10</td>
</tr><tr>
<td width="30">3</td><td width="30">7</td><td width="30"> </td>
</tr><tr>
<td width="30">4</td><td width="30">8</td><td width="30"> </td>
</tr>
</table>
</li><li>
<p>The <kbd>\@datasource.row\@</kbd> variable can be used to band
grid rows:</p><pre>
  &lt;if \@datasource.col\@ eq 1 and \@datasource.row\@ odd&gt;
    &lt;tr bgcolor="#eeeeee"&gt;
  &lt;/if&gt;

  &lt;if \@datasource.col\@ eq 1 and \@datasource.row\@ even&gt;
    &lt;tr bgcolor="#ffffff"&gt;
  &lt;/if&gt;
</pre><p>Note that this is different from the <a href="multiple"><kbd>multiple</kbd></a> tag, where the
<kbd>\@datasource.rownum\@</kbd> is used for this effect.</p>
</li>
</ul>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->