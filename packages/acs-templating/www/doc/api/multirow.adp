
<property name="context">{/doc/acs-templating {Templating}} {Templating System API: Multirow}</property>
<property name="doc(title)">Templating System API: Multirow</property>
<master>
<h2>Multirow</h2>
<h3>Summary</h3>
<p>Access and modify rows and columns of a multirow data
source.</p>
<h3>Methods</h3>
<pre>
multirow <b>get</b><em>name index column</em>
</pre>
<blockquote>
<p>Get a particular column value or a reference to an entire
row.</p><ul>
<li>Rows are indexed starting with 1.</li><li>If a column name is omitted, this procedure will set
<tt>name</tt> to be a reference to an array containing the values
for the row specified by <tt>index</tt>.</li>
</ul>
</blockquote>
<pre>
multirow <b>set</b><em>name index column value</em>
</pre>
<blockquote><p>Set the value of a column in a specified row.</p></blockquote>
<pre>
multirow <b>size</b><em>name</em>
</pre>
<blockquote><p>Get the number of rows in the data source.</p></blockquote>
<pre>
multirow <b>create</b><em>name column [column ...]</em>
</pre>
<blockquote><p>Set up a new multirow data source. This is an alternative to
having <a href="/api-doc/proc-view?proc=db%5fmultirow">db_multirow</a> create the
data source.</p></blockquote>
<pre>
multirow <b>append</b><em>name value [value ...]</em>
</pre>
<blockquote><p>Add a row at the end of the data source. Extra values are
dropped, missing values default to the empty string</p></blockquote>
<pre>
multirow <b>map</b><em>name body</em>
</pre>
<blockquote><p>Evaluate <em>body</em> for each row of the data source, and
return a list with all results. Within the body, all columns of the
current row are accessible (and modifiable) as local variables.
(Not yet committed.)</p></blockquote>
<h3>Examples</h3>
<pre>
  template::query foo multirow "select first_name, last_name from users"

  <font color="green"># get the first name of the first user</font>
  set first_name [multirow get foo 1 first_name]

  <font color="green"># get a reference to the entire row</font>
  multirow get foo 1

  <font color="green"># this will the full name of the first user</font>
  set full_name "$foo(first_name) $foo(last_name)"
</pre>
<h3>Note(s)</h3>
<ul><li>Use the <tt>eval</tt> option to template::query to modify
column values while building a data source from a multirow query
result.</li></ul>
<hr>
<a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a>
