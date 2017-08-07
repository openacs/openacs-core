
<property name="context">{/doc/acs-templating {ACS Templating}} {}</property>
<property name="doc(title)"></property>
<master>
<h2>Namespace item</h2>
<blockquote>The item commands allow easy access to properties of
the content_item object. In the future, a unified API for caching
item properties will be developed here.</blockquote>
<p>Also see:</p>
<dl>
<dt>namespace</dt><dd><a href="publish">publish</a></dd>
</dl>
<h3>Method Summary</h3>

Listing of public methods:<br>
<blockquote>
<a href="#item::content_is_null">item::content_is_null</a><br><a href="#item::content_methods_by_type">item::content_methods_by_type</a><br><a href="#item::get_best_revision">item::get_best_revision</a><br><a href="#item::get_content_type">item::get_content_type</a><br><a href="#item::get_extended_url">item::get_extended_url</a><br><a href="#item::get_id">item::get_id</a><br><a href="#item::get_item_from_revision">item::get_item_from_revision</a><br><a href="#item::get_live_revision">item::get_live_revision</a><br><a href="#item::get_mime_info">item::get_mime_info</a><br><a href="#item::get_publish_status">item::get_publish_status</a><br><a href="#item::get_revision_content">item::get_revision_content</a><br><a href="#item::get_template_id">item::get_template_id</a><br><a href="#item::get_template_url">item::get_template_url</a><br><a href="#item::get_title">item::get_title</a><br><a href="#item::get_url">item::get_url</a><br><a href="#item::is_publishable">item::is_publishable</a><br>
</blockquote>
<h3>Method Detail</h3>
<p align="right">
<font color="red">*</font> indicates required</p>
<strong>Public Methods:</strong>
<br>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="item::content_is_null" id="item::content_is_null"><font size="+1" weight="bold">item::content_is_null</font></a></td></tr><tr><td>
<blockquote>Determines if the content for the revision is null (not
mereley zero-length)</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>revision_id</code><font color="red">*</font>
</td><td align="left">The revision id</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>1 if the content is null, 0 otherwise</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="item::content_methods_by_type" id="item::content_methods_by_type"><font size="+1" weight="bold">item::content_methods_by_type</font></a></td></tr><tr><td>
<blockquote>Determines all the valid content methods for
instantiating a content type. Possible choices are text_entry,
file_upload, no_content and xml_import. Currently, this proc merely
removes the text_entry method if the item does not have a text mime
type registered to it. In the future, a more sophisticated
mechanism will be implemented.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>content_type</code><font color="red">*</font>
</td><td align="left">The content type</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>A Tcl list of all possible content methods</dd><dt><strong>Options:</strong></dt><dd><table><tr>
<td align="right"><code>get_labels</code></td><td align="left">Return not just a list of types, but a list of
name-value pairs, as in the -options ATS switch for form
widgets</td>
</tr></table></dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="item::get_best_revision" id="item::get_best_revision"><font size="+1" weight="bold">item::get_best_revision</font></a></td></tr><tr><td>
<blockquote>Attempts to retrieve the live revision for the item. If
no live revision exists, attempts to retrieve the latest revision.
If the item has no revisions, returns an empty string.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The item id</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>The best revision id for the item, or an empty string if no
revisions exist</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="item">item::get_item_from_revision</a><br><a href="item">item::get_live_revision</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="item::get_content_type" id="item::get_content_type"><font size="+1" weight="bold">item::get_content_type</font></a></td></tr><tr><td>
<blockquote>Retrieves the content type of the item. If the item
does not exist, returns an empty string.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The item id</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>The content type of the item, or an empty string if no such
item exists</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="item::get_extended_url" id="item::get_extended_url"><font size="+1" weight="bold">item::get_extended_url</font></a></td></tr><tr><td>
<blockquote>Retrieves the relative URL of the item with a file
extension based on the item&#39;s mime_type (Example: {
/foo/bar/baz.html} ).</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The item id</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>The relative URL of the item with the appropriate file
extension or an empty string on failure</dd><dt><strong>Options:</strong></dt><dd><table>
<tr>
<td align="right"><code>template_extension</code></td><td align="left">Signifies that the file extension should be
retrieved using the mime_type of the template assigned to the item,
not from the item itself. The live revision of the template is
used. If there is no template which could be used to render the
item, or if the template has no live revision, the extension
defaults to { .html}</td>
</tr><tr>
<td align="right"><code>revision_id</code></td><td align="left">
<em>default</em> the live revision; Specifies the
revision_id which will be used to retrieve the item&#39;s
mime_type. This option is ignored if the -template_extension option
is specified.</td>
</tr>
</table></dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="item">item::get_mime_info</a><br><a href="item">item::get_template_id</a><br><a href="item">item::get_url</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="item::get_id" id="item::get_id"><font size="+1" weight="bold">item::get_id</font></a></td></tr><tr><td>
<blockquote>Looks up the URL and gets the item id at that URL, if
any.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>url</code><font color="red">*</font>
</td><td align="left">The URL</td>
</tr><tr>
<td align="right"><code>root_folder</code></td><td align="left">
<em>default</em> The Sitemap; The ID of the root
folder to use for resolving the URL</td>
</tr>
</table>
</dd><dt><strong>Returns:</strong></dt><dd>The item ID of the item at that URL, or the empty string on
failure</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="item">item::get_url</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="item::get_item_from_revision" id="item::get_item_from_revision"><font size="+1" weight="bold">item::get_item_from_revision</font></a></td></tr><tr><td>
<blockquote>Gets the item_id of the item to which the revision
belongs.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>revision_id</code><font color="red">*</font>
</td><td align="left">The revision id</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>The item_id of the item to which this revision belongs</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="item">item::get_best_revision</a><br><a href="item">item::get_live_revision</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="item::get_live_revision" id="item::get_live_revision"><font size="+1" weight="bold">item::get_live_revision</font></a></td></tr><tr><td>
<blockquote>Retrieves the live revision for the item. If the item
has no live revision, returns an empty string.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The item id</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>The live revision id for the item, or an empty string if no
live revision exists</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="item">item::get_best_revision</a><br><a href="item">item::get_item_from_revision</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="item::get_mime_info" id="item::get_mime_info"><font size="+1" weight="bold">item::get_mime_info</font></a></td></tr><tr><td>
<blockquote>Creates a onerow datasource in the calling frame which
holds the mime_type and file_extension of the specified revision.
If the revision does not exist, does not create the
datasource.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>revision_id</code><font color="red">*</font>
</td><td align="left">The revision id</td>
</tr><tr>
<td align="right"><code>datasource_ref</code></td><td align="left">
<em>default</em> mime_info; The name of the
datasource to be created. The datasource will have two columns,
mime_type and file_extension. return 1 (one) if the revision
exists, 0 (zero) otherwise.</td>
</tr>
</table>
</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="item">item::get_extended_url</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="item::get_publish_status" id="item::get_publish_status"><font size="+1" weight="bold">item::get_publish_status</font></a></td></tr><tr><td>
<blockquote>Get the publish status of the item. The publish status
will be one of the following:
<ul>
<li>
<kbd>production</kbd> - The item is still in production. The
workflow (if any) is not finished, and the item has no live
revision.</li><li>
<kbd>ready</kbd> - The item is ready for publishing</li><li>
<kbd>live</kbd> - The item has been published</li><li>
<kbd>expired</kbd> - The item has been published in the past,
but its publication has expired</li>
</ul>
</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The item id</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>The publish status of the item, or the empty string on
failure</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="item">item::is_publishable</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="item::get_revision_content" id="item::get_revision_content"><font size="+1" weight="bold">item::get_revision_content</font></a></td></tr><tr><td>
<blockquote>Create a onerow datasource called content in the
calling frame which contains all attributes for the revision
(including inherited ones).
<p>The datasource will contain a column called { text} ,
representing the main content (blob) of the revision, but only if
the revision has a textual mime-type.</p>
</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>revision_id</code><font color="red">*</font>
</td><td align="left">The revision whose attributes are to be
retrieved</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>1 on success (and create a content array in the calling frame),
0 on failure</dd><dt><strong>Options:</strong></dt><dd><table><tr>
<td align="right"><code>item_id</code></td><td align="left">
<em>default</em><em>auto-generated</em>; The
item_id of the corresponding item.</td>
</tr></table></dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="item">item::get_content_type</a><br><a href="item">item::get_mime_info</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="item::get_template_id" id="item::get_template_id"><font size="+1" weight="bold">item::get_template_id</font></a></td></tr><tr><td>
<blockquote>Retrieves the template which can be used to render the
item. If there is a template registered directly to the item,
returns the id of that template. Otherwise, returns the id of the
default template registered to the item&#39;s content_type. Returns
an empty string on failure.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The item id</td>
</tr><tr>
<td align="right"><code>context</code></td><td align="left">
<em>default</em> 'public'; The context in
which the template will be used.</td>
</tr>
</table>
</dd><dt><strong>Returns:</strong></dt><dd>The template_id of the template which can be used to render the
item, or an empty string on failure</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="item">item::get_template_url</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="item::get_template_url" id="item::get_template_url"><font size="+1" weight="bold">item::get_template_url</font></a></td></tr><tr><td>
<blockquote>Retrieves the relative URL of the template which can be
used to render the item. The URL is relative to the TemplateRoot as
it is specified in the ini file.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The item id</td>
</tr><tr>
<td align="right"><code>context</code></td><td align="left">
<em>default</em> 'public'; The context in
which the template will be used.</td>
</tr>
</table>
</dd><dt><strong>Returns:</strong></dt><dd>The template_id of the template which can be used to render the
item, or an empty string on failure</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="item">item::get_template_id</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="item::get_title" id="item::get_title"><font size="+1" weight="bold">item::get_title</font></a></td></tr><tr><td>
<blockquote>Get the title for the item. If a live revision for the
item exists, use the live revision. Otherwise, use the latest
revision.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The item id</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>The title of the item</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="item">item::get_best_revision</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="item::get_url" id="item::get_url"><font size="+1" weight="bold">item::get_url</font></a></td></tr><tr><td>
<blockquote>Retrieves the relative URL stub to th item. The URL is
relative to the page root, and has no extension (Example: {
/foo/bar/baz} ).</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The item id</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>The relative URL to the item, or an empty string on
failure</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="item">item::get_extended_url</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="item::is_publishable" id="item::is_publishable"><font size="+1" weight="bold">item::is_publishable</font></a></td></tr><tr><td>
<blockquote>Determine if the item is publishable. The item is
publishable only if:
<ul>
<li>All child relations, as well as item relations, are satisfied
(according to min_n and max_n)</li><li>The workflow (if any) for the item is finished</li>
</ul>
</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The item id</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>1 if the item is publishable, 0 otherwise</dd>
</dl>
</td></tr>
</table>
<p align="right">
<font color="red">*</font> indicates required</p>
