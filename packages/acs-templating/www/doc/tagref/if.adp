
<property name="context">{/doc/acs-templating {Templating}} {Templating System Tag Reference: If}</property>
<property name="doc(title)">Templating System Tag Reference: If</property>
<master>

<body>
<h2>If</h2><a href="..">Templating System</a> : <a href="../designer-guide.html">Designer Guide</a> : <a href="index">Tag Reference</a> : If
<h3>Summary</h3><p>The <tt>if</tt> tag is used to output a template section only
when certain conditions are met.</p><h3>Usage Examples</h3><pre>
&lt;if \@x\@ eq 5&gt;True&lt;/if&gt;
&lt;if \@x\@ eq "Greta"&gt;True&lt;/if&gt;

&lt;if \@x\@ ne 5&gt;True&lt;/if&gt;
&lt;if \@x\@ ne "Greta"&gt;True&lt;/if&gt;

&lt;if \@x\@ lt 5&gt;True&lt;/if&gt;
&lt;if \@x\@ le 5&gt;True&lt;/if&gt;

&lt;if \@x\@ gt 5&gt;True&lt;/if&gt;
&lt;if \@x\@ ge 5&gt;True&lt;/if&gt;

&lt;if \@x\@ odd&gt;True&lt;/if&gt;
&lt;if \@x\@ even&gt;True&lt;/if&gt;

&lt;if \@x\@ between 3 6&gt;True&lt;/if&gt;
&lt;if \@x\@ not between 3 6&gt;True&lt;/if&gt;

&lt;if \@x\@ eq 5 and \@y\@ eq 2&gt;True&lt;/if&gt;
&lt;if \@x\@ ge 5 or \@y\@ le 2&gt;True&lt;/if&gt;

&lt;if \@s\@ nil&gt;True&lt;/if&gt;
&lt;if \@s\@ not nil&gt;True&lt;/if&gt;

&lt;if \@z\@ in "Greta" "Fred" "Sam"&gt;True&lt;/if&gt;
&lt;if \@z\@ not in "Greta" "Fred" "Sam"&gt;True&lt;/if&gt;
</pre><h3>Expression Syntax</h3>
The condition of the &lt;if&gt; tag is built from terms of the form
<blockquote>
<var>x</var><sub>0</sub> [<code>not</code>]
<code><b>op</b></code><var>x</var><sub>1</sub><var>x</var><sub>2</sub> ...</blockquote>
The operator <code><b>op</b></code> determines the number operands
(<var>x</var><sub>0</sub>, ...
<var>x</var><sub>
<var>n</var>-1</sub>).
<p>The following operators are available:</p><ul>
<li>binary
<ul>
<li>
<var>x</var><sub>0</sub><code><b>gt</b></code> 
<var>x</var><sub>1</sub>
</li><li>
<var>x</var><sub>0</sub><code><b>ge</b></code> 
<var>x</var><sub>1</sub>
</li><li>
<var>x</var><sub>0</sub><code><b>lt</b></code> 
<var>x</var><sub>1</sub>
</li><li>
<var>x</var><sub>0</sub><code><b>le</b></code> 
<var>x</var><sub>1</sub>
</li><li>
<var>x</var><sub>0</sub><code><b>eq</b></code> 
<var>x</var><sub>1</sub>
</li><li>
<var>x</var><sub>0</sub><code><b>ne</b></code> 
<var>x</var><sub>1</sub>
</li>
</ul>
</li><li>n-ary
<ul><li>
<var>x</var><sub>0</sub><code><b>in</b></code> 
<var>x</var><sub>1</sub><var>x</var><sub>2</sub><var>x</var><sub>3</sub> ...</li></ul>
</li><li>ternary
<ul><li>
<var>x</var><sub>0</sub><code><b>between</b></code> 
<var>x</var><sub>1</sub><var>x</var><sub>2</sub>
</li></ul>
</li><li>unary
<ul>
<li>
<var>x</var><sub>0</sub><code><b>nil</b></code>
</li><li>
<var>x</var><sub>0</sub><code><b>defined</b></code>
</li><li>
<var>x</var><sub>0</sub><code><b>odd</b></code>
</li><li>
<var>x</var><sub>0</sub><code><b>even</b></code>
</li><li>
<var>x</var><sub>0</sub><code><b>true</b></code>
</li><li>
<var>x</var><sub>0</sub><code><b>false</b></code>
</li>
</ul>
</li>
</ul><p>Any of these operators can be prefixed with
<code><b>not</b></code> to invert the outcome.</p><h3>Notes</h3><ul>
<li><p>Any legal variables that may be referenced in the template may
also be used in <tt>if</tt> statements. Words not surrounded with
the commerical at sign (<tt>\@</tt>) are interpreted literally.</p></li><li>
<p>Phrases with spaces in them must be enclosed in quotes to be
grouped correctly:</p><pre>
  &lt;if \@datasource.variable\@ eq "blue sky"&gt;
    &lt;td bgcolor=#0000ff&gt;
  &lt;/if&gt;
</pre>
</li><li>
<p>The <tt>elseif</tt> tag may be used following an <tt>if</tt>
block to specify an alternate conditional template section.</p><pre>
  &lt;if \@datasource.variable\@ eq "blue"&gt;
    &lt;td bgcolor=#0000ff&gt;
  &lt;/if&gt;
  &lt;elseif \@datasource.variable\@ eq "red"&gt;
    &lt;td bgcolor=red&gt;
  &lt;/elseif&gt;
  &lt;else&gt;
    &lt;td bgcolor=#ffffff&gt;
  &lt;/else&gt;
</pre>
</li><li>
<p>The <tt>else</tt> tag may be used following an <tt>if</tt> block
to specify an alternate template section when a condition is not
true:</p><pre>
  &lt;if \@datasource.variable\@ eq "blue"&gt;
    &lt;td bgcolor=#0000ff&gt;
  &lt;/if&gt;
  &lt;else&gt;
    &lt;td bgcolor=#ffffff&gt;
  &lt;/else&gt;
</pre>
</li><li><p>Compound expressions can be created by combining terms with the
<tt>and</tt> and <tt>or</tt> keywords, as illustrated above. Any
number of statements may be connected in this fashion. There is no
way to group statements to change the order of evaluation.</p></li><li><p>When a variable is tested using the <tt>nil</tt> operator, it
will return true if the variable is undefined or if the value of
the variable is an empty string.</p></li>
</ul><hr><a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>
</body>
