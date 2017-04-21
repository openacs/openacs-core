
<property name="context">{/doc/acs-templating {ACS Templating}} {}</property>
<property name="doc(title)"></property>
<master>
<h2>Namespace publish</h2>

  <em>by Stanislav Freidin The procs in this namespace
are useful for publishing items, including items inside other
items, and writing items to the filesystem.</em>
<p><em>Specifically, the <kbd>content</kbd>, <kbd>child</kbd> and
<kbd>relation</kbd> tags are defined here.</em></p>
<p>Also see:</p>
<dl>
<dt>namespace</dt><dd><a href="item">item</a></dd>
</dl>
<h3>Method Summary</h3>

Listing of public methods:<br>
<blockquote>
<a href="#publish::get_html_body">publish::get_html_body</a><br><a href="#publish::get_mime_handler">publish::get_mime_handler</a><br><a href="#publish::get_page_root">publish::get_page_root</a><br><a href="#publish::get_publish_roots">publish::get_publish_roots</a><br><a href="#publish::get_template_root">publish::get_template_root</a><br><a href="#publish::handle_binary_file">publish::handle_binary_file</a><br><a href="#publish::item_include_tag">publish::item_include_tag</a><br><a href="#publish::mkdirs">publish::mkdirs</a><br><a href="#publish::proc_exists">publish::proc_exists</a><br><a href="#publish::publish_revision">publish::publish_revision</a><br><a href="#publish::schedule_status_sweep">publish::schedule_status_sweep</a><br><a href="#publish::set_publish_status">publish::set_publish_status</a><br><a href="#publish::unpublish_item">publish::unpublish_item</a><br><a href="#publish::unschedule_status_sweep">publish::unschedule_status_sweep</a><br><a href="#publish::write_content">publish::write_content</a><br>
</blockquote>
<h3>Method Detail</h3>
<p align="right">
<font color="red">*</font> indicates required</p>
<strong>Public Methods:</strong>
<br>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::get_html_body" id="publish::get_html_body"><font size="+1" weight="bold">publish::get_html_body</font></a></td></tr><tr><td>
<blockquote>Strip the {&lt;body&gt;} tags from the HTML, leaving
just the body itself. Useful for including templates in each
other.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>html</code><font color="red">*</font>
</td><td align="left">The html to be processed</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>Everything between the &lt;body&gt; and the &lt;/body&gt; tags
if they exist; the unchanged HTML if they do not</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::get_mime_handler" id="publish::get_mime_handler"><font size="+1" weight="bold">publish::get_mime_handler</font></a></td></tr><tr><td>
<blockquote>Return the name of a proc that should be used to render
items with the given mime-type. The mime type handlers should all
follow the naming convention
<blockquote><kbd>proc
publish::handle::<em>mime_prefix</em>::<em>mime_suffix</em>
</kbd></blockquote>
If the specific mime handler could not be found,
<kbd>get_mime_handler</kbd> looks for a generic procedure with the
name
<blockquote><kbd>proc
publish::handle::<em>mime_prefix</em>
</kbd></blockquote>
If the generic mime handler does not exist either,
<kbd>get_mime_handler</kbd> returns { }</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>mime_type</code><font color="red">*</font>
</td><td align="left">The full mime type, such as { text/html} or {
image/jpg}</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>The name of the proc which should be used to handle the
mime-type, or an empty string on failure.</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::handle_item</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::get_page_root" id="publish::get_page_root"><font size="+1" weight="bold">publish::get_page_root</font></a></td></tr><tr><td>
<blockquote>Get the page root. All items will be published to the
filesystem with their URLs relative to this root. The page root is
controlled by the PageRoot parameter in CMS. A relative path is
relative to {[ns_info} pageroot\] The default is {[ns_info}
pageroot\]</blockquote><dl>
<dt><strong>Returns:</strong></dt><dd>The page root</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::get_publish_roots</a><br><a href="publish">publish::get_template_root</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::get_publish_roots" id="publish::get_publish_roots"><font size="+1" weight="bold">publish::get_publish_roots</font></a></td></tr><tr><td>
<blockquote>Get a list of all page roots to which files may be
published. The publish roots are controlled by the PublishRoots
parameter in CMS, which should be a space-separated list of all the
roots. Relative paths are relative to publish::get_page_root. The
default is {[list} {[publish::get_page_root]]}</blockquote><dl>
<dt><strong>Returns:</strong></dt><dd>A list of all the publish roots</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::get_page_root</a><br><a href="publish">publish::get_template_root</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::get_template_root" id="publish::get_template_root"><font size="+1" weight="bold">publish::get_template_root</font></a></td></tr><tr><td>
<blockquote>Get the template root. All templates are assumed to
exist in the filesystem with their URLs relative to this root. The
page root is controlled by the TemplateRoot parameter in CMS. The
default is /web/yourserver/templates</blockquote><dl>
<dt><strong>Returns:</strong></dt><dd>The template root</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="proc">content::get_template_root,</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::handle_binary_file" id="publish::handle_binary_file"><font size="+1" weight="bold">publish::handle_binary_file</font></a></td></tr><tr><td>
<blockquote>Helper procedure for writing handlers for binary files.
It will write the blob of the item to the filesystem, but only if
-embed is specified. Then, it will attempt to merge the image with
its template.<br>
This proc accepts exactly the same options a typical
handler.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The id of the item to handle</td>
</tr><tr>
<td align="right">
<code>revision_id_ref</code><font color="red">*</font>
</td><td align="left">
<em>required</em> The name of the variable in the
calling frame that will receive the revision_id whose content blob
was written to the filesystem.</td>
</tr><tr>
<td align="right">
<code>url_ref</code><font color="red">*</font>
</td><td align="left">The name of the variable in the calling frame that
will receive the relative URL of the file in the file system which
contains the content blob</td>
</tr><tr>
<td align="right">
<code>error_ref</code><font color="red">*</font>
</td><td align="left">The name of the variable in the calling frame that
will receive an error message. If no error has occurred, this
variable will be set to the empty string { }</td>
</tr>
</table>
</dd><dt><strong>Returns:</strong></dt><dd>The HTML resulting from merging the item with its template, or
" " if no template exists or the <kbd>-no_merge</kbd>
flag was specified</dd><dt><strong>Options:</strong></dt><dd><table>
<tr>
<td align="right"><code>embed</code></td><td align="left">Signifies that the content should be embedded
directly in the parent item. <kbd>-embed</kbd> is
<strong>required</strong> for this proc, since it makes no sense to
handle the binary file in any other way.</td>
</tr><tr>
<td align="right"><code>revision_id</code></td><td align="left">
<em>default</em> The live revision for the item;
The revision whose content is to be used</td>
</tr><tr>
<td align="right"><code>no_merge</code></td><td align="left">If present, do NOT merge with the template, in
order to prevent infinite recursion in the {&lt;content&gt;} tag.
In this case, the proc will return the empty string { }</td>
</tr>
</table></dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish__handle">publish::handle::image</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::item_include_tag" id="publish::item_include_tag"><font size="+1" weight="bold">publish::item_include_tag</font></a></td></tr><tr><td>
<blockquote>Create an include tag to include an item, in the form
<blockquote><kbd>include src=/foo/bar/baz item_id=<em>item_id</em>
param=value param=value ...</kbd></blockquote>
</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The item id</td>
</tr><tr>
<td align="right">
<code>extra_args</code><font color="red">*</font>
</td><td align="left">{} A list of extra parameters to be passed to the
<kbd>include</kbd> tag, in form {name value name value ...}</td>
</tr>
</table>
</dd><dt><strong>Returns:</strong></dt><dd>The HTML for the include tag</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="item">item::item_url</a><br><a href="publish">publish::html_args</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::mkdirs" id="publish::mkdirs"><font size="+1" weight="bold">publish::mkdirs</font></a></td></tr><tr><td>
<blockquote>Create all the directories necessary to save the
specified file</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>path</code><font color="red">*</font>
</td><td align="left">The path to the file that is about to be
saved</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::proc_exists" id="publish::proc_exists"><font size="+1" weight="bold">publish::proc_exists</font></a></td></tr><tr><td>
<blockquote>Determine if a procedure exists in the given
namespace</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>namespace_name</code><font color="red">*</font>
</td><td align="left">The fully qualified namespace name, such as {
template::util}</td>
</tr><tr>
<td align="right">
<code>proc_name</code><font color="red">*</font>
</td><td align="left">The proc name, such as { is_nil}</td>
</tr>
</table>
</dd><dt><strong>Returns:</strong></dt><dd>1 if the proc exists in the given namespace, 0 otherwise</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::publish_revision" id="publish::publish_revision"><font size="+1" weight="bold">publish::publish_revision</font></a></td></tr><tr><td>
<blockquote>Render a revision for an item and write it to the
filesystem. The revision is always rendered with the
<kbd>-embed</kbd> option turned on.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>revision_id</code><font color="red">*</font>
</td><td align="left">The revision id</td>
</tr></table>
</dd><dt><strong>Options:</strong></dt><dd><table><tr>
<td align="right"><code>root_path</code></td><td align="left">
<em>default</em> All paths in the PublishPaths
parameter; Write the content to this path only.</td>
</tr></table></dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="item">item::get_extended_url</a><br><a href="publish">publish::get_publish_paths</a><br><a href="publish">publish::handle_item</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::schedule_status_sweep" id="publish::schedule_status_sweep"><font size="+1" weight="bold">publish::schedule_status_sweep</font></a></td></tr><tr><td>
<blockquote>Schedule a proc to keep track of the publish status.
Resets the publish status to { expired} if the expiration date has
passed. Publishes the item and sets the publish status to { live}
if the current status is { ready} and the scheduled publication
time has passed.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right"><code>interval</code></td><td align="left">
<em>default</em> 3600; The interval, in seconds,
between the sweeps of all items in the content repository. Lower
values increase the precision of the publishing/expiration dates
but decrease performance. If this parameter is not specified, the
value of the StatusSweepInterval parameter in the server&#39;s INI
file is used (if it exists).</td>
</tr></table>
</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::set_publish_status</a><br><a href="publish">publish::track_publish_status</a><br><a href="publish">publish::unschedule_status_sweep</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::set_publish_status" id="publish::set_publish_status"><font size="+1" weight="bold">publish::set_publish_status</font></a></td></tr><tr><td>
<blockquote>Set the publish status of the item. If the status is
live, publish the live revision of the item to the filesystem.
Otherwise, unpublish the item from the filesystem.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>db</code><font color="red">*</font>
</td><td align="left">The database handle</td>
</tr><tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The item id</td>
</tr><tr>
<td align="right">
<code>new_status</code><font color="red">*</font>
</td><td align="left">The new publish status. Must be { production} , {
expired} , { ready} or { live}</td>
</tr><tr>
<td align="right"><code>revision_id</code></td><td align="left">
<em>default</em> The live revision; The revision
id to be used when publishing the item to the filesystem.</td>
</tr>
</table>
</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::publish_revision</a><br><a href="publish">publish::unpublish_item</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::unpublish_item" id="publish::unpublish_item"><font size="+1" weight="bold">publish::unpublish_item</font></a></td></tr><tr><td>
<blockquote>Delete files which were created by
<kbd>publish_revision</kbd>
</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The item id</td>
</tr></table>
</dd><dt><strong>Options:</strong></dt><dd><table>
<tr>
<td align="right"><code>revision_id</code></td><td align="left">
<em>default</em> The live revision; The revision
which is to be used for determining the item filename</td>
</tr><tr>
<td align="right"><code>root_path</code></td><td align="left">
<em>default</em> All paths in the PublishPaths
parameter; Write the content to this path only.</td>
</tr>
</table></dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::publish_revision</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::unschedule_status_sweep" id="publish::unschedule_status_sweep"><font size="+1" weight="bold">publish::unschedule_status_sweep</font></a></td></tr><tr><td>
<blockquote>Unschedule the proc which keeps track of the publish
status.</blockquote><dl>
<dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::schedule_status_sweep</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::write_content" id="publish::write_content"><font size="+1" weight="bold">publish::write_content</font></a></td></tr><tr><td>
<blockquote>Write the content (blob) of a revision into a binary
file in the filesystem. The file will be published at the relative
URL under each publish root listed under the PublishRoots parameter
in the server&#39;s INI file (the value returnded by
publish::get_page_root is used as the default). The file extension
will be based on the revision&#39;s mime-type.<br>
For example, an revision whose mime-type is { image/jpeg} for an
item at { Sitemap/foo/bar} may be written as
/web/your_server_name/www/foo/bar.jpg</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>revision_id</code><font color="red">*</font>
</td><td align="left">The id of the revision to write</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>The relative URL of the file that was written, or an empty
string on failure</dd><dt><strong>Options:</strong></dt><dd><table>
<tr>
<td align="right"><code>item_id</code></td><td align="left">
<em>default</em> The item_id of the revision;
Specifies the item to which this revision belongs (mereley for
optimization purposes)</td>
</tr><tr>
<td align="right"><code>text</code></td><td align="left">If specified, indicates that the content of the
revision is readable text (clob), not a binary file</td>
</tr><tr>
<td align="right"><code>root_path</code></td><td align="left">
<em>default</em> All paths in the PublishPaths
parameter; Write the content to this path only.</td>
</tr>
</table></dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="content">content::get_content_value</a><br><a href="publish">publish::get_publish_roots</a><br>
</dd>
</dl>
</td></tr>
</table>
<p>
<strong>Private Methods</strong>:<br>
</p>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::delete_multiple_files" id="publish::delete_multiple_files"><font size="+1" weight="bold">publish::delete_multiple_files</font></a></td></tr><tr><td>
<blockquote>Delete the specified URL from the filesystem, for all
revisions</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>url</code><font color="red">*</font>
</td><td align="left">Relative URL of the file to write</td>
</tr></table>
</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::get_publish_roots</a><br><a href="publish">publish::write_multiple_blobs</a><br><a href="publish">publish::write_multiple_files</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::foreach_publish_path" id="publish::foreach_publish_path"><font size="+1" weight="bold">publish::foreach_publish_path</font></a></td></tr><tr><td>
<blockquote>Execute some Tcl code for each root path in the
PublishRoots parameter</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>url</code><font color="red">*</font>
</td><td align="left">Relative URL to append to the roots</td>
</tr><tr>
<td align="right">
<code>code</code><font color="red">*</font>
</td><td align="left">Execute this code</td>
</tr><tr>
<td align="right"><code>root_path</code></td><td align="left">
<em>default</em> The empty string; Use this root
path instead of the paths specified in the INI file</td>
</tr>
</table>
</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::get_publish_roots</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::get_main_item_id" id="publish::get_main_item_id"><font size="+1" weight="bold">publish::get_main_item_id</font></a></td></tr><tr><td>
<blockquote>Get the main item id from the top of the
stack</blockquote><dl>
<dt><strong>Returns:</strong></dt><dd>the main item id</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::get_main_revision_id</a><br><a href="publish">publish::pop_id</a><br><a href="publish">publish::push_id</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::get_main_revision_id" id="publish::get_main_revision_id"><font size="+1" weight="bold">publish::get_main_revision_id</font></a></td></tr><tr><td>
<blockquote>Get the main item revision from the top of the
stack</blockquote><dl>
<dt><strong>Returns:</strong></dt><dd>the main item id</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::get_main_item_id</a><br><a href="publish">publish::pop_id</a><br><a href="publish">publish::push_id</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::handle_item" id="publish::handle_item"><font size="+1" weight="bold">publish::handle_item</font></a></td></tr><tr><td>
<blockquote>Render an item either by looking it up in the the
temporary cache, or by using the appropriate mime handler. Once the
item is rendered, it is stored in the temporary cache under a key
which combines the item_id, any extra HTML parameters, and a flag
which specifies whether the item was merged with its template.<br>
This proc takes the same arguments as the individual mime
handlers.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The id of the item to be rendered</td>
</tr><tr>
<td align="right">
<code>context</code><font color="red">*</font>
</td><td align="left">The context for the item (default public)</td>
</tr>
</table>
</dd><dt><strong>Returns:</strong></dt><dd>The rendered HTML for the item, or an empty string on
failure</dd><dt><strong>Options:</strong></dt><dd><table>
<tr>
<td align="right"><code>revision_id</code></td><td align="left">
<em>default</em> The live revision; The revision
which is to be used when rendering the item</td>
</tr><tr>
<td align="right"><code>no_merge</code></td><td align="left">Indicates that the item should NOT be merged with
its template. This option is used to avoid infinite recursion.</td>
</tr><tr>
<td align="right"><code>refresh</code></td><td align="left">Re-render the item even if it exists in the cache.
Use with caution - circular dependencies may cause infinite
recursion if this option is specified</td>
</tr><tr>
<td align="right"><code>embed</code></td><td align="left">Signifies that the content should be statically
embedded directly in the HTML. If this option is not specified, the
item may be dynamically referenced, f.ex. using the
{<kbd>&lt;include&gt;</kbd>} tag</td>
</tr><tr>
<td align="right"><code>html</code></td><td align="left">Extra HTML parameters to be passed to the item
handler, in format {name value name value ...}</td>
</tr>
</table></dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish__handle">publish::handle::image</a><br><a href="publish__handle">publish::handle::text</a><br><a href="publish">publish::handle_binary_file</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::html_args" id="publish::html_args"><font size="+1" weight="bold">publish::html_args</font></a></td></tr><tr><td>
<blockquote>Concatenate a list of name-value pairs as returned by
<kbd>set_to_pairs</kbd> into a list of { name=value}
pairs</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>argv</code><font color="red">*</font>
</td><td align="left">The list of name-value pairs</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>An HTML string in format " name=value name=value
..."</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::set_to_pairs</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::merge_with_template" id="publish::merge_with_template"><font size="+1" weight="bold">publish::merge_with_template</font></a></td></tr><tr><td>
<blockquote>Merge the item with its template and return the
resulting HTML. This proc is simlar to
<kbd>content::init</kbd>
</blockquote><dl>
<dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The item id</td>
</tr></table>
</dd><dt><strong>Returns:</strong></dt><dd>The rendered HTML, or the empty string on failure</dd><dt><strong>Options:</strong></dt><dd><table>
<tr>
<td align="right"><code>revision_id</code></td><td align="left">
<em>default</em> The live revision; The revision
which is to be used when rendering the item</td>
</tr><tr>
<td align="right"><code>html</code></td><td align="left">Extra HTML parameters to be passed to the ADP
parser, in format {name value name value ...}</td>
</tr>
</table></dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::handle_item</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::pop_id" id="publish::pop_id"><font size="+1" weight="bold">publish::pop_id</font></a></td></tr><tr><td>
<blockquote>Pop the item_id and the revision_id off the top of the
stack. Clear the temporary item cache if the stack becomes
empty.</blockquote><dl>
<dt><strong>Returns:</strong></dt><dd>The popped item id, or the empty string if the string is
already empty</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::get_main_item_id</a><br><a href="publish">publish::get_main_revision_id</a><br><a href="publish">publish::push_id</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::process_tag" id="publish::process_tag"><font size="+1" weight="bold">publish::process_tag</font></a></td></tr><tr><td>
<blockquote>Process a <kbd>child</kbd> or <kbd>relation</kbd> tag.
This is a helper proc for the tags, which acts as a wrapper for
<kbd>render_subitem</kbd>.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>relation_type</code><font color="red">*</font>
</td><td align="left">Either <kbd>child</kbd> or
<kbd>relation</kbd>
</td>
</tr><tr>
<td align="right">
<code>params</code><font color="red">*</font>
</td><td align="left">The ns_set id for extra HTML parameters</td>
</tr>
</table>
</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::render_subitem</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::push_id" id="publish::push_id"><font size="+1" weight="bold">publish::push_id</font></a></td></tr><tr><td>
<blockquote>Push an item id on top of stack. This proc is used to
store state between <kbd>child</kbd>, <kbd>relation</kbd> and
<kbd>content</kbd> tags.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>item_id</code><font color="red">*</font>
</td><td align="left">The id to be put on stack</td>
</tr><tr>
<td align="right"><code>revision_id</code></td><td align="left">
<em>default</em> { }; The id of the revision to
use. If missing, live revision will most likely be used</td>
</tr>
</table>
</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::get_main_item_id</a><br><a href="publish">publish::get_main_revision_id</a><br><a href="publish">publish::pop_id</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::render_subitem" id="publish::render_subitem"><font size="+1" weight="bold">publish::render_subitem</font></a></td></tr><tr><td>
<blockquote>Render a child/related item and return the resulting
HTML, stripping off the headers.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>main_item_id</code><font color="red">*</font>
</td><td align="left">The id of the parent item</td>
</tr><tr>
<td align="right">
<code>relation_type</code><font color="red">*</font>
</td><td align="left">Either <kbd>child</kbd> or <kbd>relation</kbd>.
Determines which tables are searched for subitems.</td>
</tr><tr>
<td align="right">
<code>relation_tag</code><font color="red">*</font>
</td><td align="left">The relation tag to look for</td>
</tr><tr>
<td align="right">
<code>index</code><font color="red">*</font>
</td><td align="left">The relative index of the subitem. The subitem
with lowest <kbd>order_n</kbd> has index 1, the second lowest
<kbd>order_n</kbd> has index 2, and so on.</td>
</tr><tr>
<td align="right">
<code>is_embed</code><font color="red">*</font>
</td><td align="left">If { t} , the child item may be embedded directly
in the HTML. Otherwise, it may be dynamically included. The proc
does not process this parameter directly, but passes it to
<kbd>handle_item</kbd>
</td>
</tr><tr>
<td align="right">
<code>extra_args</code><font color="red">*</font>
</td><td align="left">Any additional HTML arguments to be used when
rendering the item, in form {name value name value ...}</td>
</tr><tr>
<td align="right"><code>is_merge</code></td><td align="left">
<em>default</em> t; If { t} ,
<kbd>merge_with_template</kbd> may be used to render the subitem.
Otherwise, <kbd>merge_with_template</kbd> should not be used, in
order to prevent infinite recursion.</td>
</tr><tr>
<td align="right"><code>context</code></td><td align="left">
<em>default</em> public;</td>
</tr>
</table>
</dd><dt><strong>Returns:</strong></dt><dd>The rendered HTML for the child item</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::handle_item</a><br><a href="publish">publish::merge_with_template</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::set_to_pairs" id="publish::set_to_pairs"><font size="+1" weight="bold">publish::set_to_pairs</font></a></td></tr><tr><td>
<blockquote>Convert an ns_set into a list of name-value pairs, in
form {name value name value ...}</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>params</code><font color="red">*</font>
</td><td align="left">The ns_set id</td>
</tr><tr>
<td align="right">
<code>exclusion_list</code><font color="red">*</font>
</td><td align="left">{} A list of keys to be ignored</td>
</tr>
</table>
</dd><dt><strong>Returns:</strong></dt><dd>A list of name-value pairs representing the data in the
ns_set</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::track_publish_status" id="publish::track_publish_status"><font size="+1" weight="bold">publish::track_publish_status</font></a></td></tr><tr><td>
<blockquote>Scheduled proc which keeps the publish status
updated</blockquote><dl>
<dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::schedule_status_sweep</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::write_multiple_blobs" id="publish::write_multiple_blobs"><font size="+1" weight="bold">publish::write_multiple_blobs</font></a></td></tr><tr><td>
<blockquote>Write the content of some revision to multiple
publishing roots.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>db</code><font color="red">*</font>
</td><td align="left">A valid database handle</td>
</tr><tr>
<td align="right">
<code>url</code><font color="red">*</font>
</td><td align="left">Relative URL of the file to write</td>
</tr><tr>
<td align="right">
<code>revision_id</code><font color="red">*</font>
</td><td align="left">Write the blob for this revision</td>
</tr>
</table>
</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::get_publish_roots</a><br><a href="publish">publish::write_multiple_files</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name="publish::write_multiple_files" id="publish::write_multiple_files"><font size="+1" weight="bold">publish::write_multiple_files</font></a></td></tr><tr><td>
<blockquote>Write a relative URL to the multiple publishing
roots.</blockquote><dl>
<dd>
<strong>Parameters:</strong><table>
<tr>
<td align="right">
<code>url</code><font color="red">*</font>
</td><td align="left">Relative URL of the file to write</td>
</tr><tr>
<td align="right">
<code>text</code><font color="red">*</font>
</td><td align="left">A string of text to be written to the URL</td>
</tr>
</table>
</dd><dt><strong>See Also:</strong></dt><dd>proc - <a href="publish">publish::get_publish_roots</a><br><a href="publish">publish::write_multiple_blobs</a><br><a href="template__util">template::util::write_file</a><br>
</dd>
</dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Implements the <kbd>child</kbd> tag which renders a
child item. See the Developer Guide for more information.<br>
The child tag format is
<blockquote><kbd>{&lt;child} tag=<em>tag</em> index=<em>n embed
{args</em>&gt;}</kbd></blockquote>
</blockquote><dl><dd>
<kbd><strong>Parameters:</strong></kbd><table><tr>
<td align="right">
<code>params</code><font color="red">*</font>
</td><td align="left">The ns_set id for extra HTML parameters</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Implements the <kbd>content</kbd> tag which renders the
content of the current item. See the Developer Guide for more
information.<br>
The content tag format is simply {<kbd>&lt;content&gt;</kbd>.} The
<kbd>embed</kbd> and <kbd>no_merge</kbd> parameters are implicit to
the tag.</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>params</code><font color="red">*</font>
</td><td align="left">The ns_set id for extra HTML parameters</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<table width="100%">
<tr><td width="100%" bgcolor="#CCCCFF"><a name=""></a></td></tr><tr><td>
<blockquote>Implements the <kbd>relation</kbd> tag which renders a
related item. See the Developer Guide for more information.<br>
The relation tag format is
<blockquote><kbd>{&lt;relation} tag=<em>tag</em> index=<em>n embed
{args</em>&gt;}</kbd></blockquote>
</blockquote><dl><dd>
<strong>Parameters:</strong><table><tr>
<td align="right">
<code>params</code><font color="red">*</font>
</td><td align="left">The ns_set id for extra HTML parameters</td>
</tr></table>
</dd></dl>
</td></tr>
</table>
<p align="right">
<font color="red">*</font> indicates required</p>
