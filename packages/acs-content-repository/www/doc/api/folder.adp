
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Package: content_folder}</property>
<property name="doc(title)">Package: content_folder</property>
<master>
<h2>content_folder</h2>
<p>
<a href="../index">Content Repository</a> :
content_folder</p>
<hr>
<ul>
<li><a href="#overview">Overview</a></li><li><a href="#related">Related Objects</a></li><li><a href="#api">API</a></li>
</ul>
<p> </p>
<h3><a name="overview">Overview</a></h3>
<p>Content folders contain related content items and allow content
managers to group content as they see fit. Within a content folder,
content items must have unique names since this is where they will
be served from. For example within the folder "movies"
(served from "/movies") all items must have unique names,
such as: "terminator," "terminator2" (served
from "/movies/terminator, "/movies/terminator2"
respectively).</p>
<p> </p>
<h3><a name="related">Related Objects</a></h3>

See also: Content Item
<p> </p>
<h3><a name="api">API</a></h3>
<ul>
<li>
<font size="+1">Function:</font> content_folder.get_index_page
<p>Returns the item ID of the index page of the folder, null
otherwise</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Michael Pih</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The item ID of the index page</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">folder_id The:</th><td>  </td><td>folder id</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_index_page (
  folder_id in cr_folders.folder_id%TYPE
) return cr_items.item_id%TYPE;

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_folder.get_label
<p>Returns the label for the folder. This function is the default
name method for the folder object.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The folder&#39;s label</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">folder_id:</th><td>  </td><td>The folder id</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_label (
  folder_id in cr_folders.folder_id%TYPE
) return cr_folders.label%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_object_type.create_type, the docs for the name_method
parameter</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_folder.is_empty
<p>Determine if the folder is empty</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">'t' if the folder contains no subfolders
or items, 'f' otherwise</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">folder_id:</th><td>  </td><td>The folder id</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function is_empty (
  folder_id  in cr_folders.folder_id%TYPE
) return varchar2;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_folder.is_folder</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_folder.is_folder
<p>Determine if the item is a folder</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">'t' if the item is a folder, 'f'
otherwise</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item id</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function is_folder (
  item_id         in cr_items.item_id%TYPE
) return char;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_folder.new, content_folder.is_sub_folder</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_folder.is_registered
<p>change this to is_type_registered Determines if a content type
is registered to the folder Only items of the registered type(s)
may be added to the folder.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">'t' if the type is registered to this
folder, 'f' otherwise</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">folder_id:</th><td>  </td><td>The folder id</td>
</tr><tr>
<th align="right" valign="top">content_type:</th><td>  </td><td>The content type to be checked</td>
</tr><tr>
<th align="right" valign="top">include_subtypes:</th><td>  </td><td>If 't', all subtypes of the <kbd>content_type</kbd>
will be checked, returning 't' if all of them are
registered. If 'f', only an exact match with
<kbd>content_type</kbd> will be performed.</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function is_registered (
  folder_id             in cr_folders.folder_id%TYPE,
  content_type          in cr_folder_type_map.content_type%TYPE,
  include_subtypes      in varchar2 default 'f'
) return varchar2;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_folder.register_content_type,
content_folder.unregister_content_type,</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_folder.is_sub_folder
<p>Determine if the item <kbd>target_folder_id</kbd> is a subfolder
of the item <kbd>folder_id</kbd>
</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">'t' if the item
<kbd>target_folder_id</kbd> is a subfolder of the item
<kbd>folder_id</kbd>, 'f' otherwise</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">folder_id:</th><td>  </td><td>The superfolder id</td>
</tr><tr>
<th align="right" valign="top">target_folder_id:</th><td>  </td><td>The subfolder id</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function is_sub_folder (
  folder_id             in cr_folders.folder_id%TYPE,
  target_folder_id      in cr_folders.folder_id%TYPE
) return char;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_folder.is_folder</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_folder.new
<p>Create a new folder</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The id of the newly created folder</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">label:</th><td>  </td><td>The label for the folder</td>
</tr><tr>
<th align="right" valign="top">description:</th><td>  </td><td>A short description of the folder, 4000 characters maximum</td>
</tr><tr>
<th align="right" valign="top">parent_id:</th><td>  </td><td>The parent of the folder</td>
</tr><tr>
<th align="right" valign="top">folder_id:</th><td>  </td><td>The id of the new folder. A new id will be allocated by
default</td>
</tr><tr>
<th align="right" valign="top">revision_id:</th><td>  </td><td>The id of the new revision. A new id will be allocated by
default</td>
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
  label         in cr_folders.label%TYPE,
  description   in cr_folders.description%TYPE default null,
  parent_id     in acs_objects.context_id%TYPE default null,
  folder_id     in cr_folders.folder_id%TYPE default null,
  creation_date in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user in acs_objects.creation_user%TYPE
                           default null,
  creation_ip   in acs_objects.creation_ip%TYPE default null
) return cr_folders.folder_id%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_object.new, content_item.new</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_folder.copy
<p>Recursively copy the folder and all items in into a new
location. An error is thrown if either of the parameters is not a
folder. The root folder of the sitemap and the root folder of the
templates cannot be copied</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">folder_id:</th><td>  </td><td>The id of the folder to copy</td>
</tr><tr>
<th align="right" valign="top">target_folder_id:</th><td>  </td><td>The destination folder</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure copy (
  folder_id             in cr_folders.folder_id%TYPE,
  target_folder_id      in cr_folders.folder_id%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_folder.new, content_folder.copy</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_folder.delete
<p>Delete a folder. An error is thrown if the folder is not
empty</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">folder_id:</th><td>  </td><td>The id of the folder to delete</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure delete (
  folder_id     in cr_folders.folder_id%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_object.delete, content_item.delete</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_folder.move
<p>Recursively move the folder and all items in into a new
location. An error is thrown if either of the parameters is not a
folder. The root folder of the sitemap and the root folder of the
templates cannot be moved.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">folder_id:</th><td>  </td><td>The id of the folder to move</td>
</tr><tr>
<th align="right" valign="top">target_folder_id:</th><td>  </td><td>The destination folder</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure move (
  folder_id             in cr_folders.folder_id%TYPE,
  target_folder_id      in cr_folders.folder_id%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_folder.new, content_folder.copy</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_folder.register_content_type
<p>Register a content type to the folder, if it is not already
registered. Only items of the registered type(s) may be added to
the folder.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">folder_id:</th><td>  </td><td>The folder id</td>
</tr><tr>
<th align="right" valign="top">content_type:</th><td>  </td><td>The content type to be registered</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure register_content_type (
  folder_id             in cr_folders.folder_id%TYPE,
  content_type          in cr_folder_type_map.content_type%TYPE,
  include_subtypes      in varchar2 default 'f'
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_folder.unregister_content_type,
content_folder.is_registered</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_folder.edit_name
<p>Change the name, label and/or description of the folder</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">folder_id:</th><td>  </td><td>The id of the folder to modify</td>
</tr><tr>
<th align="right" valign="top">name:</th><td>  </td><td>The new name for the folder. An error will be thrown if an item
with this name already exists under this folder&#39;s parent. If
this parameter is null, the old name will be preserved</td>
</tr><tr>
<th align="right" valign="top">label:</th><td>  </td><td>The new label for the folder. The old label will be preserved
if this parameter is null</td>
</tr><tr>
<th align="right" valign="top">label:</th><td>  </td><td>The new description for the folder. The old description will be
preserved if this parameter is null</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure rename (
  folder_id      in cr_folders.folder_id%TYPE,
  name           in cr_items.name%TYPE default null,
  label          in cr_folders.label%TYPE default null,
  description    in cr_folders.description%TYPE default null
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_folder.new</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_folder.unregister_content_type
<p>Unregister a content type from the folder, if it has been
registered. Only items of the registered type(s) may be added to
the folder. If the folder already contains items of the type to be
unregistered, the items remain in the folder.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">folder_id:</th><td>  </td><td>The folder id</td>
</tr><tr>
<th align="right" valign="top">content_type:</th><td>  </td><td>The content type to be unregistered</td>
</tr><tr>
<th align="right" valign="top">include_subtypes:</th><td>  </td><td>If 't', all subtypes of <kbd>content_type</kbd> will be
unregistered as well</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure unregister_content_type (
  folder_id             in cr_folders.folder_id%TYPE,
  content_type          in cr_folder_type_map.content_type%TYPE,
  include_subtypes      in varchar2 default 'f'
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_folder.register_content_type,
content_folder.is_registered</td>
</tr>
</table>
</li>
</ul>
<p> </p>

Last Modified: $&zwnj;Id: folder.html,v 1.2.18.2 2016/06/22 07:40:41
gustafn Exp $
