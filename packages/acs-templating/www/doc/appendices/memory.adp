
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System Appendix D: Parsing templates in
memory}</property>
<property name="doc(title)">Templating System Appendix D: Parsing templates in
memory</property>
<master>
<h2>Parsing Templates in Memory</h2>
<strong><a href="../index">Templating System</a></strong>
<p>The templating system code is oriented towards parsing templates
stored in the file system, in conjunction with a Tcl script that is
also stored as a file. However, when the template is not actually
stored in the file system, you will need to parse it as a string in
memory. Two common situations in which this occurs are:</p>
<ul>
<li>Templates are stored in the database.</li><li>Templates are generated dynamically, possibly based in turn on
a "style" template. This is how ATS auto-generates
forms.</li>
</ul>
<h3>The Parsing Process</h3>
<p>Whether the template is ultimately stored in a file or not, the
templating system follows the same basic process during the parsing
process:</p>
<ol>
<li>
<em>Prepare data sources.</em> Some Tcl code is evaluated to
prepare data sources (scalars, lists, multirow data structures) for
merging with the template. (For file-based templates the
interpreted code is cached in a procedure after the first
time).</li><li>
<em>Compile the template.</em>. The template markup is compiled
into a chunk of Tcl code that builds the page into a single output
string. (For file-based templates the resulting code is cached in a
procedure after the first time).</li><li>
<em>Evaluate the compiled template</em>. The template code is
evaluated in the same stack frame as the data source code, so that
all variables declared as data sources are directly available to
the template. The result of the evaluation step is a single string,
which normally is written to the connection.</li>
</ol>
<h3>How to Parse Templates in Memory</h3>
<p>The templating system provides a low-level API that allows you
to perform the three steps described above in the context of your
own code:</p>
<blockquote><pre>
<font color="green"># set up any number of data sources:</font>

set first_name George

query cars multirow "
  select make, model from cars where first_name = :first_name"

<font color="green"># get the template.  This may be a static string, be queried from the
# database, generated dynamically, etc.</font>

set template "
Hello \@first_name\@!

&lt;multiple name=cars&gt;
  \@cars.rownum\@. \@cars.make\@ \@cars.model\@&lt;br&gt;
&lt;/multiple&gt;
"

<font color="green"># compile the template.  The templating system takes the
# result of this step and wraps it in a proc so that it is 
# bytecode-cached in the interpreter.  You may wish to implement
# some sort of simple caching here as well.</font>

set code [template::adp_compile -string $template]

<font color="green"># evaluate the template code.  Note that you pass a <em>reference</em>
# to the variable containing the code, not the value itself.  The code
# is evaluated in the calling stack frame (by uplevel) so that
# the above data sources are directly accessible.</font>

set output [template::adp_eval code]

<font color="green"># now use the output however you wish</font>
</pre></blockquote>

Also see the "<a href="../demo/index">string</a>
" demo.
<h3>Generating Templates from Other Templates</h3>
<p>In some cases, the template itself may be based on yet another
base template. For example, the templating system itself generates
form templates based on a generic "style" template. The
generic template primarily depends on a single data source,
<kbd>elements</kbd>, which references the element list for a
particular form object. A single <kbd>multiple</kbd>loop is used to
lay out the specific <kbd>formwidget</kbd> and <kbd>formgroup</kbd>
tags, along with labels and validation text, for the form. The
output of this first step is then rendered into HTML and returned
to the user.</p>
<p>Note that the generic "style" template contains
templating tags (<kbd>formwidget</kbd>, <kbd>formgroup</kbd>,
<kbd>if</kbd> etc.) that must be "protected" during the
first step. The templating system provides the <a href="../tagref/noparse"><kbd>noparse</kbd></a> tag to do this.</p>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> --><br>


Last modified: $&zwnj;Id: memory.html,v 1.2 2017/08/07 23:48:02 gustafn
Exp $
