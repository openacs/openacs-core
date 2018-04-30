
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Package: content_item}</property>
<property name="doc(title)">Package: content_item</property>
<master>
<h2>content_item</h2>
<p>
<a href="../index">Content Repository</a> :
content_item</p>
<hr>
<ul>
<li><a href="#overview">Overview</a></li><li><a href="#related">Related Objects</a></li><li><a href="#api">API</a></li>
</ul>
<p> </p>
<a name="overview" id="overview"><h3>Overview</h3></a>
<p>Content items store the overview of the content published on a
website. The actual content is stored in content revisions. It is
implemented this way so that there can be multiple versions of the
actual content while the main idea remains constant. For example:
If there is a review for the movie "Terminator," there
will exist a content item by the name "terminator" with
all the right parameters (supertype, parent, etc), there will also
exist at least one content revision pointing to this item with the
actual review content.</p>
<p> </p>
<a name="related" id="related"><h3>Related Objects</h3></a>
 See also: content_revision, content_folder
<p> </p>
<a name="api" id="api"><h3>API</h3></a>
<ul>
<li>
<font size="+1">Function:</font> content_item.get_content_type
<p>Retrieve the content type of this item. Only objects of this
type may be used as revisions for the item.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The content type of the item</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item for which the content type is to be retrieved</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_content_type (
  item_id     in cr_items.item_id%TYPE
) return cr_items.content_type%TYPE;

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_item.get_context
<p>Retrieve the parent of the given item</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The id of the parent for this item</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item for which the parent is to be retrieved</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_context (
  item_id       in cr_items.item_id%TYPE
) return acs_objects.context_id%TYPE;

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_item.get_id
<p>Takes in a path, such as
"/tv/programs/star_trek/episode_203" and returns the id
of the item with this path. Note: URLs are abstract (no extensions
are allowed in content item names and extensions are stripped when
looking up content items)</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The id of the item with the given path, or null if
no such item exists</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_path:</th><td>  </td><td>The path to be resolved</td>
</tr><tr>
<th align="right" valign="top">root_folder_id:</th><td>  </td><td>Starts path resolution from this folder. Defaults to the root
of the sitemap</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_id (
  item_path   in varchar2,
  root_folder_id in cr_items.item_id%TYPE default c_root_folder_id
) return cr_items.item_id%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.get_path</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font>
content_item.get_latest_revision
<p>Retrieves the id of the latest revision for the item (as opposed
to the live revision)</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The id of the latest revision for this item, or
null if no revisions exist</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item for which the latest revision is to be retrieved</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_latest_revision (
  item_id    in cr_items.item_id%TYPE
) return cr_revisions.revision_id%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.get_live_revision</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_item.get_live_revision
<p>Retrieves the id of the live revision for the item</p><p>Note that this function does nothing else besides retrieving the
value of the column <code>cr_items.live_revision</code>. It is thus
more efficient in many cases to join against <code>cr_items</code>
and retrieve the value directly.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Returns:</th><td align="left">The id of the live revision for this item, or null
if no live revision exists</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item for which the live revision is to be retrieved</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_live_revision (
  item_id   in cr_items.item_id%TYPE
) return cr_revisions.revision_id%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.set_live_revision,
content_item.get_latest_revision</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_item.get_parent_folder
<p>Get the parent folder.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Michael Pih</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">the folder_id of the parent folder, null
otherwise</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item id</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_parent_folder (
  item_id       in cr_items.item_id%TYPE
) return cr_folders.folder_id%TYPE;

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_item.get_path
<p>Retrieves the full path to an item, in the form of
"/tv/programs/star_trek/episode_203"</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The path to the item</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item for which the path is to be retrieved</td>
</tr><tr>
<th align="right" valign="top">root_folder_id:</th><td>  </td><td>Starts path resolution from this folder. Defaults to the root
of the sitemap</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_path (
  item_id        in cr_items.item_id%TYPE,
  root_folder_id in cr_items.item_id%TYPE default c_root_folder_id
) return varchar2;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.get_id, content_item.write_to_file</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_item.get_publish_date
<p>Retrieves the publish date for the item</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The publish date for the item, or null if the item
has no revisions</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item for which the publish date is to be retrieved</td>
</tr><tr>
<th align="right" valign="top">is_live:</th><td>  </td><td>If 't', use the live revision for the item. Otherwise,
use the latest revision. The default is 'f'</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_publish_date (
  item_id    in cr_items.item_id%TYPE,
  is_live    in char default 'f'
) return cr_revisions.publish_date%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.get_live_revision,
content_item.get_latest_revision,</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font>
content_item.get_revision_count
<p>Return the total count of revisions for this item</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The number of revisions for this item</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The id the item</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_revision_count (
  item_id   in cr_items.item_id%TYPE
) return number;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_revision.new</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_item.get_root_folder
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><em>Not yet documented</em></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_root_folder return cr_folders.folder_id%TYPE;

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_item.get_template
<p>Retrieves the template which should be used to render this item.
If no template is registered to specifically render the item in the
given context, the default template for the item&#39;s type is
returned.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The id of the registered template, or null if no
template could be found</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item for which the template will be unregistered</td>
</tr><tr>
<th align="right" valign="top">use_context:</th><td>  </td><td>The context in the item is to be rendered, such as
'admin' or 'public'</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_template (
  item_id     in cr_items.item_id%TYPE,
  use_context in cr_item_template_map.use_context%TYPE
) return cr_templates.template_id%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_type.register_template,
content_item.register_template,</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_item.get_title
<p>Retrieves the title for the item, using either the latest or the
live revision. If the specified item is in fact a folder, return
the folder&#39;s label. In addition, this function will
automatically resolve symlinks.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The title of the item</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item for which the title is to be retrieved</td>
</tr><tr>
<th align="right" valign="top">is_live:</th><td>  </td><td>If 't', use the live revision to get the title.
Otherwise, use the latest revision. The default is 'f'</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_title (
  item_id    in cr_items.item_id%TYPE,
  is_live    in char default 'f'
) return cr_revisions.title%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.get_live_revision,
content_item.get_latest_revision, content_symlink.resolve</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_item.get_virtual_path
<p>Retrieves the virtual path to an item, in the form of
"/tv/programs/star_trek/episode_203"</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Michael Pih</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The virtual path to the item</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item for which the path is to be retrieved</td>
</tr><tr>
<th align="right" valign="top">root_folder_id:</th><td>  </td><td>Starts path resolution from this folder. Defaults to the root
of the sitemap</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_virtual_path (
  item_id        in cr_items.item_id%TYPE,
  root_folder_id in cr_items.item_id%TYPE default c_root_folder_id
) return varchar2;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.get_id, content_item.write_to_file,
content_item.get_path</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_item.is_index_page
<p>Determine if the item is an index page for the specified folder.
The item is an index page for the folder if it exists in the folder
and its item name is "index".</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">'t' if the item is an index page for the
specified folder, 'f' otherwise</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item id</td>
</tr><tr>
<th align="right" valign="top">folder_id:</th><td>  </td><td>The folder id</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function is_index_page (
  item_id   in cr_items.item_id%TYPE,
  folder_id in cr_folders.folder_id%TYPE
) return varchar2;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_folder.get_index_page</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_item.is_publishable
<p>Determines if an item is publishable. Publishable items must
meet the following criteria: 1) for each child type, the item has n
children, min_n &lt; n &lt; max_n 2) for each relation type, the
item has n relations, min_n &lt; n &lt; max_n 3) any
'publishing_wf' workflows are finished</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Michael Pih</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">'t' if the item is publishable in its
present state, Otherwise, returns 'f'</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">item_id The:</th><td>  </td><td>item ID of the potential parent</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function is_publishable (
  item_id               in cr_items.item_id%TYPE
) return char;

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_item.is_subclass
<p>Determines if one type is a subclass of another. A class is
always a subclass of itself.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">'t' if the child class is a subclass of
the superclass, 'f' otherwise</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">object_type:</th><td>  </td><td>The child class</td>
</tr><tr>
<th align="right" valign="top">supertype:</th><td>  </td><td>The superclass</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function is_subclass (
  object_type in acs_object_types.object_type%TYPE,
  supertype     in acs_object_types.supertype%TYPE
) return char;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_object_type.create_type</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_item.is_valid_child
<p>Determines if an item would be a valid child of another item by
checking if the parent allows children of the would-be child&#39;s
content type and if the parent already has n_max children of that
content type.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Michael Pih</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">'t' if the item would be a valid child,
'f' otherwise</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id The:</th><td>  </td><td>item ID of the potential parent</td>
</tr><tr>
<th align="right" valign="top">content_type The:</th><td>  </td><td>content type of the potential child item</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function is_valid_child (
  item_id       in cr_items.item_id%TYPE,
  content_type  in acs_object_types.object_type%TYPE
) return char;

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_item.new
<p>Creates a new content item. If the <kbd>data</kbd>,
<kbd>title</kbd> or <kbd>text</kbd> parameters are specified, also
creates a revision for the item.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The id of the newly created item</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">name:</th><td>  </td><td>The name for the item, must be URL-encoded. If an item with
this name already exists under the specified parent item, an error
is thrown</td>
</tr><tr>
<th align="right" valign="top">parent_id:</th><td>  </td><td>The parent of this item, defaults to null</td>
</tr><tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The id of the new item. A new id will be allocated if this
parameter is null</td>
</tr><tr>
<th align="right" valign="top">locale:</th><td>  </td><td>The locale for this item, for use with Intermedia search</td>
</tr><tr>
<th align="right" valign="top">item_subtype:</th><td>  </td><td>The type of the new item, defaults to 'content_item'
This parameter is used to support inheritance, so that subclasses
of <kbd>content_item</kbd> can call this function to initialize the
parent class</td>
</tr><tr>
<th align="right" valign="top">content_type:</th><td>  </td><td>The content type for the item, defaults to
'content_revision'. Only objects of this type may be used
as revisions for the item</td>
</tr><tr>
<th align="right" valign="top">title:</th><td>  </td><td>The user-readable title for the item, defaults to the
item&#39;s name</td>
</tr><tr>
<th align="right" valign="top">description:</th><td>  </td><td>A short description for the item (4000 characters maximum)</td>
</tr><tr>
<th align="right" valign="top">mime_type:</th><td>  </td><td>The file type of the item, defaults to
'text/plain'</td>
</tr><tr>
<th align="right" valign="top">nls_language:</th><td>  </td><td>The language for the item, used for Intermedia search</td>
</tr><tr>
<th align="right" valign="top">text:</th><td>  </td><td>The text content of the new revision, 4000 charcters maximum.
Cannot be specified simultaneously with the <kbd>data</kbd>
parameter</td>
</tr><tr>
<th align="right" valign="top">data:</th><td>  </td><td>The blob content of the new revison. Cannot be specified
simultaneously with the <kbd>text</kbd> parameter</td>
</tr><tr>
<th align="right" valign="top">relation_tag:</th><td>  </td><td>If a parent-child relationship is registered for these content
types, use this tag to describe the parent-child relationship.
Defaults to 'parent content type'-'child content
type'</td>
</tr><tr>
<th align="right" valign="top">is_live:</th><td>  </td><td>If 't', the new revision will become live</td>
</tr><tr>
<th align="right" valign="top">creation_date:</th><td>  </td><td>As in <kbd>acs_object.new</kbd>
</td>
</tr><tr>
<th align="right" valign="top">creation_ip:</th><td>  </td><td>As in <kbd>acs_object.new</kbd>
</td>
</tr><tr>
<th align="right" valign="top">creation_user:</th><td>  </td><td>As in <kbd>acs_object.new</kbd>
</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function new (
  name          in cr_items.name%TYPE,
  parent_id     in acs_objects.context_id%TYPE default null,
  item_id       in acs_objects.object_id%TYPE default null,
  locale        in cr_items.locale%TYPE default null,
  creation_date in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user in acs_objects.creation_user%TYPE
                           default null,
  creation_ip   in acs_objects.creation_ip%TYPE default null,
  item_subtype  in acs_object_types.object_type%TYPE
                           default 'content_item',
  content_type  in acs_object_types.object_type%TYPE
                           default 'content_revision',
  title         in cr_revisions.title%TYPE default null,
  description   in cr_revisions.description%TYPE default null,
  mime_type     in cr_revisions.mime_type%TYPE default 'text/plain',
  nls_language  in cr_revisions.nls_language%TYPE default null,
  text          in varchar2 default null,
  data          in cr_revisions.content%TYPE default null,
  relation_tag  in cr_child_rels.relation_tag%TYPE default null,
  is_live       in char default 'f'
) return cr_items.item_id%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_object.new</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_item.relate
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><em>Not yet documented</em></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function relate (
  item_id       in cr_items.item_id%TYPE,
  object_id     in acs_objects.object_id%TYPE,
  relation_tag in cr_type_relations.relation_tag%TYPE default 'generic',
  order_n       in cr_item_rels.order_n%TYPE default null,
  relation_type in acs_object_types.object_type%TYPE default 'cr_item_rel'
) return cr_item_rels.rel_id%TYPE;

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_item.copy
<p>Copies the item to a new location, creating an identical item
with no revisions or associated workflow. If the target folder does
not exist, or if the folder already contains an item with the same
name as the given item, an error will be thrown.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item to be copied</td>
</tr><tr>
<th align="right" valign="top">target_folder_id:</th><td>  </td><td>The folder where the item is to be copied</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure copy (
  item_id               in cr_items.item_id%TYPE,
  target_folder_id      in cr_folders.folder_id%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.new, content_folder.new, content_item.move</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_item.delete
<p>Deletes the specified content item, along with any revisions,
symlinks, workflows, and template relations for the item. Use with
caution - this operation cannot be undone.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The id of the item to delete</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure delete (
  item_id       in cr_items.item_id%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_object.delete</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_item.move
<p>Move the specified item to a different folder. If the target
folder does not exist, or if the folder already contains an item
with the same name as the given item, an error will be thrown.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item to be moved</td>
</tr><tr>
<th align="right" valign="top">target_folder_id:</th><td>  </td><td>The new folder for the item</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure move (
  item_id               in cr_items.item_id%TYPE,
  target_folder_id      in cr_folders.folder_id%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.new, content_folder.new, content_item.copy</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_item.register_template
<p>Registers a template which will be used to render this item.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item for which the template will be registered</td>
</tr><tr>
<th align="right" valign="top">template_id:</th><td>  </td><td>The template to be registered</td>
</tr><tr>
<th align="right" valign="top">use_context:</th><td>  </td><td>The context in which the template is appropriate, such as
'admin' or 'public'</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure register_template (
  item_id      in cr_items.item_id%TYPE,
  template_id  in cr_templates.template_id%TYPE,
  use_context  in cr_item_template_map.use_context%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_type.register_template,
content_item.unregister_template, content_item.get_template</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_item.edit_name
<p>Renames the item. If an item with the specified name already
exists under this item&#39;s parent, an error is thrown</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The id of the item to rename</td>
</tr><tr>
<th align="right" valign="top">name:</th><td>  </td><td>The new name for the item, must be URL-encoded</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure rename (
  item_id        in cr_items.item_id%TYPE,
  name           in cr_items.name%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.new</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_item.set_live_revision
<p>Make the specified revision the live revision for the item</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">revision_id:</th><td>  </td><td>The id of the revision which is to become live for its
corresponding item</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure set_live_revision (
  revision_id   in cr_revisions.revision_id%TYPE,
  publish_status in cr_items.publish_status%TYPE default 'ready'
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.get_live_revision</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_item.set_release_period
<p>Sets the release period for the item. This information may be
used by applications to update the publishing status of items at
periodic intervals.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The id the item.</td>
</tr><tr>
<th align="right" valign="top">start_when:</th><td>  </td><td>The time and date when the item should be released.</td>
</tr><tr>
<th align="right" valign="top">end_when:</th><td>  </td><td>The time and date when the item should be expired.</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure set_release_period (
  item_id    in cr_items.item_id%TYPE,
  start_when date default null,
  end_when   date default null
);

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_item.unregister_template
<p>Unregisters a template which will be used to render this
item.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item for which the template will be unregistered</td>
</tr><tr>
<th align="right" valign="top">template_id:</th><td>  </td><td>The template to be registered</td>
</tr><tr>
<th align="right" valign="top">use_context:</th><td>  </td><td>The context in which the template is appropriate, such as
'admin' or 'public'</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure unregister_template (
  item_id      in cr_items.item_id%TYPE,
  template_id  in cr_templates.template_id%TYPE default null,
  use_context  in cr_item_template_map.use_context%TYPE default null
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_type.register_template, content_item.register_template,
content_item.get_template</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_item.unset_live_revision
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><em>Not yet documented</em></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure unset_live_revision (
  --/** Set the live revision to null for the item
  --    \@author Michael Pih
  --    \@param item_id The id of the item for which to unset the live revision
  --    \@see {content_item.set_live_revision}
  item_id      in cr_items.item_id%TYPE
);

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_item.write_to_file
<p>Writes the content of the live revision of this item to a file,
creating all the necessary directories in the process</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item to be written to a file</td>
</tr><tr>
<th align="right" valign="top">root_path:</th><td>  </td><td>The path in the filesystem to which the root of the sitemap
corresponds</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure write_to_file (
  item_id     in cr_items.item_id%TYPE,
  root_path   in varchar2
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.get_path</td>
</tr>
</table>
</li>
</ul>
<p> </p>

Last Modified: $&zwnj;Id: item.html,v 1.6 2018/04/11 21:35:06 hectorr Exp
$
