
<property name="context">{/doc/acs-templating {ACS Templating}} {Templating System User Guide: Data Sources}</property>
<property name="doc(title)">Templating System User Guide: Data Sources</property>
<master>
<h2>Implementing Data Sources</h2>
<a href="..">Templating System</a>
 : <a href="../developer-guide">Developer Guide</a>
 : User Guide
<p>Data sources are implemented in a Tcl script using regular Tcl
variables, lists and arrays. The templating system includes a set
of procedures to simplify the construction of data sources from
relational database queries.</p>
<h3>The Structure of Data Sources</h3>
<p>The templating system can manipulate four basic types of
structures as data sources:</p>
<table cellspacing="0" cellpadding="4" border="1">
<tr>
<td><kbd>onevalue</kbd></td><td>A simple scalar, such as a user&#39;s first name or the total
due on a purchase order.</td>
</tr><tr>
<td><kbd>onelist</kbd></td><td>A list of simple scalars.</td>
</tr><tr>
<td><kbd>onerow</kbd></td><td>A one-row data table, with values in one or more columns.</td>
</tr><tr>
<td><kbd>multirow</kbd></td><td>A multi-row, multi-column data table.</td>
</tr>
</table>
<h3><kbd>onevalue</kbd></h3>
<p>
<kbd>onevalue</kbd> data sources are implemented simply by
setting a Tcl variable:</p>
<code>set name "Walter Cronkite"</code>
<p>The <kbd>query</kbd> procedure may be used to set a onevalue
data source based on a database query:</p>
<code>query name onevalue "select name from users where
user_id = 123"</code>
<p>You can embed a <kbd>onevalue</kbd> data source in a template
with simple <a href="../tagref/variable">variable
substitution</a>.</p>
<h3><kbd>onerow</kbd></h3>
<p>
<kbd>onerow</kbd> data sources are implemented as Tcl
arrays:</p>
<code>set name(first_name) Walter<br>
set name(last_name) Cronkite</code>
<p>The <a href="../api/database"><kbd>query</kbd></a>
procedure may be used as a convenient way to store the result of a
one-row database query into an array:</p>
<pre>
query name onerow "
  select 
    first_name, last_name 
  from 
    users 
  where  
    user_id = 123"
</pre>
<p>You can embed references to column values of a <kbd>onerow</kbd>
data source in a template with simple <a href="../tagref/variable">variable substitution</a>.</p>
<h3><kbd>onelist</kbd></h3>
<p>
<kbd>onelist</kbd> data sources are implemented by creating a
Tcl list:</p>
<pre>
set names [list "Walter" "Fred" "Susy" "Frieda"]
</pre>
<p>The <kbd>query</kbd> procedure may be used to set a onelist data
source based on a one-column database query:</p>
<code>query name onevalue "select name from users"</code>
<p>You can iterate over a <kbd>onelist</kbd> data source in a
template with the <a href="../tagref/list">list</a> tag.</p>
<h3><kbd>multirow</kbd></h3>
<p>
<kbd>multirow</kbd> data sources are not represented by a single
Tcl data structure. As such the templating system includes a
special API for constructing and manipulating them.</p>
<pre>
multirow create cars make model year
multirow append cars "Toyota" "Camry" "1996"
multirow append cars "Volvo" "960" "1995"
</pre>
<p>The <a href="../api/database"><kbd>query</kbd></a>
procedure may be used as a convenient way to store the result of a
multi-row, multi-column database query into a <kbd>multirow</kbd>
data source:</p>
<pre>
query name multirow "
  select 
    make, model, year
  from 
    cars"
</pre>
<p>You can iterate over a <kbd>multirow</kbd> data source in a
template with the <a href="../tagref/multiple">multiple</a>
tag.</p>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->