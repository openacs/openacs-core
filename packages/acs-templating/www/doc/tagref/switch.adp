
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System Tag Reference: Switch}</property>
<property name="doc(title)">Templating System Tag Reference: Switch</property>
<master>
<h2>Switch</h2>
<a href="..">Templating System</a>
 : <a href="../designer-guide">Designer Guide</a>
 : <a href="index">Tag Reference</a>
 : Switch
<h3>Summary</h3>
<p>The <kbd>switch</kbd> tag is used to output one of n-sections
when the switch variable matches one of the n-case statements. A
default section can also be output if none of the n-case statements
matches the switch variable.</p>
<h3>Usage Examples</h3>
<pre>
&lt;switch \@x\@&gt;
    &lt;case value="Fred"&gt;
         Hello Fred.
    &lt;/case&gt;
    &lt;case value="Greta"&gt;
         Hello Greta.
    &lt;/case&gt;
    &lt;case value="Sam"&gt;
         Hello Sam
    &lt;/case&gt;
    &lt;default&gt;
         I don&#39;t recognize your name.
    &lt;/default&gt;
&lt;/switch&gt;
</pre>
<p>Tcl-equivalent flags have the same meaning as in the tcl-switch
statement. Supported flags include exact, glob, and regexp.</p>
<pre>
&lt;switch flag=glob \@x\@&gt;
    &lt;case value="F*"&gt;
         Hello Fred.
    &lt;/case&gt;
    &lt;case value="G*"&gt;
         Hello Greta.
    &lt;/case&gt;
    &lt;case value="H*"&gt;
         Hello Sam
    &lt;/case&gt;
    &lt;default&gt;
         You are in the section for people whose names start with F, G, or H.
    &lt;/default&gt;
&lt;/switch&gt;
</pre>
<p>Case tags also have an alternative form for matching a list of
items.</p>
<pre>
&lt;switch \@x\@&gt;
    &lt;case in "Fred" "Greta" "Sam"&gt;
         Your must be Fred Greta or Sam, but I&#39;m not sure which one.
    &lt;/case&gt;
    &lt;default&gt;
         I don&#39;t recognize your name.
    &lt;/default&gt;
&lt;/switch&gt;
</pre>
<h3>Notes</h3>
<ul>
<li><p>Any legal variables that may be referenced in the template may
also be used in <kbd>switch</kbd> statements.</p></li><li>
<p>Phrases with spaces in them must be enclosed in double quotes
and curly braces to be matched correctly. Failure to quote words
with spaces correctly results in an error.</p><pre>
  &lt;case "{blue sky}"&gt;
    &lt;td bgcolor="#0000ff"&gt;
  &lt;/case&gt;</pre>
</li>
</ul>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->