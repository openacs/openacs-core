
<property name="context">{/doc/acs-templating {ACS Templating}} {}</property>
<property name="doc(title)"></property>
<master>
<h2>Namespace content_method</h2>
<blockquote>Procedures regarding content methods</blockquote>
<h3>Method Summary</h3>

Listing of public methods:<br>
<blockquote>
<a href="#content_method::flush_content_methods_cache">content_method::flush_content_methods_cache</a><br><a href="#content_method::get_content_methods">content_method::get_content_methods</a><br>
</blockquote>
<h3>Method Detail</h3>
<p align="right">
<font color="red">*</font> indicates required</p>
<strong>Public Methods:</strong>
<br>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="content_method::flush_content_methods_cache" id="content_method::flush_content_methods_cache"><font size="+1" weight="bold">content_method::flush_content_methods_cache</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Flushes the cache for content_method_types for a given
content type. If no content type is specified, the entire
content_method_types cache is flushed</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>content_type</code><font color="red">*</font>
</td><td align="left">The content type, default null</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="content_method::get_content_methods" id="content_method::get_content_methods"><font size="+1" weight="bold">content_method::get_content_methods</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Returns a list of content_methods that are associated
with a content type, first checking for a default method, then for
registered content methods, and then for all content
methods</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>content_type</code><font color="red">*</font>
</td><td align="left">The content type</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>A list of content methods or a list of label-value pairs of
content methods if the " -get_labels" option is
specified</dd><dt><strong>Options:</strong></dt><dd><table><tr>
<td align="right"><code>get_labels</code></td><td align="left">Instead of a list of content methods, return a
list of label-value pairs of associated content methods.</td>
</tr></table></dd><dt><strong>See Also:</strong></dt><dd>content_method::get_content_method_options,
content_method::text_entry_filter_sql - <a href=""></a><br>
</dd>
</dl>
</td></tr>
</table>
<p>
<strong>Private Methods</strong>:<br>
</p>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="content_method::get_content_method_options" id="content_method::get_content_method_options"><font size="+1" weight="bold">content_method::get_content_method_options</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Returns a list of label, content_method pairs that are
associated with a content type, first checking for a default
method, then for registered content methods, and then for all
content methods</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>content_type</code><font color="red">*</font>
</td><td align="left">The content type</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>A list of label, value pairs of content methods</dd><dt><strong>See Also:</strong></dt><dd>content_method::get_content_methods,
content_method::text_entry_filter_sql - <a href=""></a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF">
<a name="content_method::text_entry_filter_sql" id="content_method::text_entry_filter_sql"><font size="+1" weight="bold">content_method::text_entry_filter_sql</font></a><br><small><em>  by Michael Pih</em></small>
</td></tr><tr><td>
<blockquote>Generate a SQL stub that filters out the text_entry
content method</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>content_type</code><font color="red">*</font>
</td><td align="left"></td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>SQL stub that possibly filters out the text_entry content
method</dd>
</dl>
</td></tr>
</table>
<p align="right">
<font color="red">*</font> indicates required</p>
