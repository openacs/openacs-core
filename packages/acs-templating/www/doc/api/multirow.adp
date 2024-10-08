
<property name="context">{/doc/acs-templating/ {ACS Templating}} {Templating System API: Multirow}</property>
<property name="doc(title)">Templating System API: Multirow</property>
<master>
<style>
div.sect2 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 16px;}
div.sect3 > div.itemizedlist > ul.itemizedlist > li.listitem {margin-top: 6px;}
</style>              
<h2>Multirow</h2>
<strong>
<a href="../index">Templating System</a> : API
Reference</strong>
<h3>Summary</h3>
<p>Access and modify rows and columns of a multirow data
source.</p>
<h3>Methods</h3>
<pre>multirow <strong>get</strong><em> name index column</em>
</pre>
<blockquote>
<p>Get a particular column value or a reference to an entire
row.</p><ul>
<li>Rows are indexed starting with 1.</li><li>If a column name is omitted, this procedure will set
<kbd>name</kbd> to be a reference to an array containing the values
for the row specified by <kbd>index</kbd>.</li>
</ul>
</blockquote>
<pre>multirow <strong>set</strong><em> name index column value</em>
</pre>
<blockquote><p>Set the value of a column in a specified row.</p></blockquote>
<pre>multirow <strong>size</strong><em> name</em>
</pre>
<blockquote><p>Get the number of rows in the data source.</p></blockquote>
<pre>multirow <strong>create</strong><em> name column [column ...]</em>
</pre>
<blockquote><p>Set up a new multirow data source. This is an alternative to
having <a href="">db_multirow</a> create the data source.</p></blockquote>
<pre>multirow <strong>append</strong><em> name value [value ...]</em>
</pre>
<blockquote><p>Add a row at the end of the data source. Extra values are
dropped, missing values default to the empty string</p></blockquote>
<pre>multirow <strong>map</strong><em> name body</em>
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
<ul><li>Use the <kbd>eval</kbd> option to template::query to modify
column values while building a data source from a multirow query
result.</li></ul>
<hr>
<!-- <a href="mailto:templating\@arsdigita.com">templating\@arsdigita.com</a> -->