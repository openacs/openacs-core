
<property name="context">{/doc/acs-templating {Templating}} {Templating System Tag Reference: Group}</property>
<property name="doc(title)">Templating System Tag Reference: Group</property>
<master>

<body>
<h2>Group</h2><a href="..">Templating System</a> : <a href="../designer-guide.html">Designer Guide</a> : <a href="index">Tag Reference</a> : Group
<h3>Summary</h3><p>The <tt>group</tt> tag is used only within the body of a
<a href="multiple">multiple</a> tag to provide additional
formatting control between subsets of a multirow data source. The
tag takes a column name from the enclosing multiple tag as its only
attribute. It repeats a template section as long as the value of
the column does not change from row to row.</p><p>The <tt>group</tt> tag also sets two additional values in your
multirow:</p><ul>
<li>
<tt>groupnum</tt> is the rownum within the innermost group tag,
starting from 1, 2, 3, etc.</li><li>
<tt>groupnum_last_p</tt> is a boolean saying whether this is
the last row inside the current group tag, before the value of
<tt>column</tt> changes. <b>Note</b>, however, that this
<b>only</b> works inside the <b>inner-most</b><tt>group</tt> if
you have multiple <tt>group</tt> tags nested within each
other.</li>
</ul><h3>Usage</h3><pre>
&lt;table&gt;

&lt;multiple name="shirts"&gt;

  &lt;!-- Start a new row if the style changes --&gt;

  &lt;tr&gt;
    &lt;td&gt;
      \@shirts.style\@
    &lt;/td&gt;
    &lt;td&gt;

  &lt;!-- List colors for the same style in a single cell --&gt;

  &lt;group column="style"&gt;
    \@shirts.color\@

    &lt;!-- \@shirts.groupnum\@ will be the number of the color within the style --&gt;

    &lt;if \@shirts.groupnum_last_p\@ false&gt;, &lt;/if&gt;
    &lt;else&gt;, or &lt;/if&gt;

  &lt;/group&gt;

  &lt;!-- End the row if the style is going to change on the next row

    &lt;/td&gt;
  &lt;/tr&gt;

&lt;/multiple&gt;

&lt;/table&gt;
</pre><p>[Note: Carsten added this feature during the Berlin Hackaton
2004-02-14]</p><p>The <tt>delimiter</tt> attribute will add a string after each
row except the last row in the group:</p><pre>
  &lt;group delimiter=" | "&gt;
  ...
</pre><p>This attribute will cause the rows within the group to appear to
be sepparated by vertical bars. This is much more convenient than
using the <tt>&lt;groupnum_last_p&gt;</tt> tags to check whether we
are on the last row.</p><h3>Notes</h3><ul>
<li><p>
<tt>Group</tt> tags may be nested to perform even more complex
formatting.</p></li><li><p>Be careful when nesting several group tags. The group tag works
very narrowly - it only looks at the column you provide it with and
so long as that column doesn't change, it keeps looping. E.g. if
you have 3 levels and the value of the outermost column changes but
the value of the middle column doesn't, the inner group tag won't
notice and will continue to loop. A workaround would be to create a
derived column, which contains e.g. "$f1,$f2", and use that as the
column for the inner group tag. (See also <a href="http://openacs.org/bugtracker/openacs/bug?bug%5fnumber=428">this
bug</a>).</p></li>
</ul><hr><a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>
</body>
