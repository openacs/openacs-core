
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System Tag Reference: Variables}</property>
<property name="doc(title)">Templating System Tag Reference: Variables</property>
<master>
<h2>Variables</h2>
<a href="..">Templating System</a>
 : <a href="../designer-guide">Designer Guide</a>
 : <a href="index">Tag Reference</a>
 : Variables
<h3>Summary</h3>
<p>Variables are used in templates as placeholders for dynamic
data.</p>
<h3>Usage</h3>
<p>Simple variables are referenced by surrounding the variable name
with "commercial at" (<kbd>\@</kbd>) signs:</p>
<pre>&lt;!-- simple variables --&gt;
&lt;b&gt;&lt;i&gt;\@first_name\@ \@last_name\@&lt;/b&gt;&lt;/i&gt;</pre>
<p>When processing this template, the server will look for
variables named <kbd>first_name</kbd> and <kbd>last_name</kbd> and
substitute their values in the output:</p>
<pre>&lt;b&gt;&lt;i&gt;Fred Finkel&lt;/b&gt;&lt;/i&gt;</pre>
<p>The columns of a row variable are referenced by separating the
data source name and column with a period:</p>
<pre>
&lt;!-- onerow or multirow data sources --&gt;
&lt;b&gt;&lt;i&gt;\@user.first_name\@ \@user.last_name\@&lt;/b&gt;&lt;/i&gt;</pre>
<h3>Note(s)</h3>
<ul><li><p>An attempt to reference a variable that does not exist will
cause an error message to appear in the browser.</p></li></ul>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->