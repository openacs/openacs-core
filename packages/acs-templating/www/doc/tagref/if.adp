
<property name="context">{/doc/acs-templating/ {ACS Templating}} {Templating System Tag Reference: If}</property>
<property name="doc(title)">Templating System Tag Reference: If</property>
<master>
<style>
div.sect2 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 16px;}
div.sect3 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 6px;}
</style>              
<h2>If</h2>
<a href="..">Templating System</a>
 : <a href="../designer-guide">Designer Guide</a>
 : <a href="index">Tag Reference</a>
 : If
<h3>Summary</h3>
<p>The <kbd>if</kbd> tag is used to output a template section only
when certain conditions are met. It has the form <kbd>&lt;if
<em>expression</em>&gt;</kbd>.</p>
<h3>Expression Syntax</h3>

The expressions used in the <kbd>&lt;if&gt;</kbd>
 tag have the
following form
<blockquote>
<var>x</var><sub>0</sub> [<code>not</code>]
<code><strong>op</strong></code><var>x</var><sub>1</sub><var>x</var><sub>2</sub> ...</blockquote>

The operator <code><strong>op</strong></code>
 determines the number
operands (<var>x</var>
<sub>0</sub>
, ...
<var>x</var>
<sub>
<var>n</var>-1</sub>
).
<p>The following operators are available:</p>
<ul>
<li>binary
<ul>
<li>
<var>x</var><sub>0</sub><code><strong>gt</strong></code> 
<var>x</var><sub>1</sub>
</li><li>
<var>x</var><sub>0</sub><code><strong>ge</strong></code> 
<var>x</var><sub>1</sub>
</li><li>
<var>x</var><sub>0</sub><code><strong>lt</strong></code> 
<var>x</var><sub>1</sub>
</li><li>
<var>x</var><sub>0</sub><code><strong>le</strong></code> 
<var>x</var><sub>1</sub>
</li><li>
<var>x</var><sub>0</sub><code><strong>eq</strong></code> 
<var>x</var><sub>1</sub>
</li><li>
<var>x</var><sub>0</sub><code><strong>ne</strong></code> 
<var>x</var><sub>1</sub>
</li>
</ul>
</li><li>n-ary
<ul><li>
<var>x</var><sub>0</sub><code><strong>in</strong></code> 
<var>x</var><sub>1</sub><var>x</var><sub>2</sub><var>x</var><sub>3</sub> ...</li></ul>
</li><li>ternary
<ul><li>
<var>x</var><sub>0</sub><code><strong>between</strong></code> 
<var>x</var><sub>1</sub><var>x</var><sub>2</sub>
</li></ul>
</li><li>unary
<ul>
<li>
<var>x</var><sub>0</sub><code><strong>nil</strong></code>
</li><li>
<var>x</var><sub>0</sub><code><strong>defined</strong></code>
</li><li>
<var>x</var><sub>0</sub><code><strong>odd</strong></code>
</li><li>
<var>x</var><sub>0</sub><code><strong>even</strong></code>
</li><li>
<var>x</var><sub>0</sub><code><strong>true</strong></code>
</li><li>
<var>x</var><sub>0</sub><code><strong>false</strong></code>
</li>
</ul>
</li>
</ul>
<p>Any of these operators can be prefixed with
<code><strong>not</strong></code> to invert the outcome.</p>
<h3>Usage Examples</h3>
<pre>&lt;if \@x\@ eq 5&gt;True&lt;/if&gt;
&lt;if \@x\@ eq "Greta"&gt;True&lt;/if&gt;

&lt;if \@x\@ ne 5&gt;True&lt;/if&gt;
&lt;if \@x\@ ne "Greta"&gt;True&lt;/if&gt;

&lt;if \@x\@ lt 5&gt;True&lt;/if&gt;
&lt;if \@x\@ le 5&gt;True&lt;/if&gt;

&lt;if \@x\@ gt 5&gt;True&lt;/if&gt;
&lt;if \@x\@ ge 5&gt;True&lt;/if&gt;

&lt;if \@x\@ true&gt;True&lt;/if&gt;
&lt;if \@x\@ false&gt;False&lt;/if&gt;

&lt;if \@x\@ odd&gt;True&lt;/if&gt;
&lt;if \@x\@ even&gt;True&lt;/if&gt;

&lt;if \@x\@ between 3 6&gt;True&lt;/if&gt;
&lt;if \@x\@ not between 3 6&gt;True&lt;/if&gt;

&lt;if \@x\@ eq 5 and \@y\@ eq 2&gt;True&lt;/if&gt;
&lt;if \@x\@ ge 5 or \@y\@ le 2&gt;True&lt;/if&gt;

&lt;if \@s\@ nil&gt;True&lt;/if&gt;
&lt;if \@s\@ not nil&gt;True&lt;/if&gt;

&lt;if \@z\@ in "Greta" "Fred" "Sam"&gt;True&lt;/if&gt;
&lt;if \@z\@ not in "Greta" "Fred" "Sam"&gt;True&lt;/if&gt;</pre>
<h3>Notes</h3>
<ul>
<li><p>Any legal variables that may be referenced in the template may
also be used in <kbd>if</kbd> statements. Words not surrounded with
the commercial at sign (<kbd>\@</kbd>) are interpreted
literally.</p></li><li>
<p>Phrases with spaces in them must be enclosed in quotes to be
grouped correctly:</p><pre>
  &lt;if \@datasource.variable\@ eq "blue sky"&gt;
    &lt;td bgcolor="#0000ff"&gt;
  &lt;/if&gt;</pre>
</li><li>
<p>The <kbd>elseif</kbd> tag may be used following an <kbd>if</kbd>
block to specify an alternate conditional template section.</p><pre>
  &lt;if \@datasource.variable\@ eq "blue"&gt;
    &lt;td bgcolor="#0000ff"&gt;
  &lt;/if&gt;
  &lt;elseif \@datasource.variable\@ eq "red"&gt;
    &lt;td bgcolor=red&gt;
  &lt;/elseif&gt;
  &lt;else&gt;
    &lt;td bgcolor="#ffffff"&gt;
  &lt;/else&gt;</pre>
</li><li>
<p>The <kbd>else</kbd> tag may be used following an <kbd>if</kbd>
block to specify an alternate template section when a condition is
not true:</p><pre>
  &lt;if \@datasource.variable\@ eq "blue"&gt;
    &lt;td bgcolor="#0000ff"&gt;
  &lt;/if&gt;
  &lt;else&gt;
    &lt;td bgcolor="#ffffff"&gt;
  &lt;/else&gt;</pre>
</li><li><p>Compound expressions can be created by combining terms with the
<kbd>and</kbd> and <kbd>or</kbd> keywords, as illustrated above.
Any number of statements may be connected in this fashion. There is
no way to group statements to change the order of evaluation.</p></li><li><p>When a variable is tested using the <kbd>nil</kbd> operator, it
will return true if the variable is undefined or if the value of
the variable is an empty string.</p></li>
</ul>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->