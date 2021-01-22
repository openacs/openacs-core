
<property name="context">{/doc/acs-templating {ACS Templating}} {}</property>
<property name="doc(title)"></property>
<master>
<h2>Namespace pagination</h2>
<blockquote>Procedures for paginating a datasource</blockquote>
<h3>Method Summary</h3>

Listing of public methods:<br>
<blockquote>
<a href="#pagination::get_total_pages">pagination::get_total_pages</a><br><a href="#pagination::page_number_links">pagination::page_number_links</a><br><a href="#pagination::paginate_query">pagination::paginate_query</a><br>
</blockquote>
<h3>Method Detail</h3>
<p align="right">
<font color="red">*</font> indicates required</p>
<strong>Public Methods:</strong>
<br>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="pagination::get_total_pages" id="pagination::get_total_pages"><font size="+1" weight="bold">pagination::get_total_pages</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Gets the number of pages returned by a query PRE:
requires {$sql}</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>db</code><font color="red">*</font>
</td><td align="left">A database handle</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="pagination::page_number_links" id="pagination::page_number_links"><font size="+1" weight="bold">pagination::page_number_links</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Generate HTML for navigating pages of a
datasource</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>page</code><font color="red">*</font>
</td><td align="left">The current page number</td>
</tr><tr>
<td align="right">
<code>total_pages</code><font color="red">*</font>
</td><td align="left">The total pages returned by the query</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="pagination::paginate_query" id="pagination::paginate_query"><font size="+1" weight="bold">pagination::paginate_query</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Paginates a query</blockquote><dl><dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>sql</code><font color="red">*</font>
</td><td align="left">The sql query to paginate</td>
</tr><tr>
<td align="right">
<code>page</code><font color="red">*</font>
</td><td align="left">The current page number</td>
</tr>
</table>
</dd></dl>
</td></tr>
</table>
<p>
<strong>Private Methods</strong>:<br>
</p>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="pagination::get_rows_per_page" id="pagination::get_rows_per_page"><font size="+1" weight="bold">pagination::get_rows_per_page</font></a></td></tr><tr><td><blockquote>Returns the number of rows per page</blockquote></td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="pagination::ns_set_to_url_vars" id="pagination::ns_set_to_url_vars"><font size="+1" weight="bold">pagination::ns_set_to_url_vars</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Converts an ns_set into a list of url
variables</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>set_id</code><font color="red">*</font>
</td><td align="left">The set id</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<p align="right">
<font color="red">*</font> indicates required</p>
