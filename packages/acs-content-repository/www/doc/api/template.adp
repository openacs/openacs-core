
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Package: content_template}</property>
<property name="doc(title)">Package: content_template</property>
<master>
<h2>content_template</h2>
<p>
<a href="../index">Content Repository</a> :
content_template</p>
<hr>
<ul>
<li><a href="#overview">Overview</a></li><li><a href="#related">Related Objects</a></li><li><a href="#api">API</a></li>
</ul>
<p> </p>
<h3><a name="overview">Overview</a></h3>
<p>Templates are a special class of text objects that are used for
specifying the layout of a content item. They may be mapped to
content types, meaning that every item of that type will display
using that template unless a specific item overrides the default by
mapping to a template itself.</p>
<p> </p>
<h3><a name="related">Related Objects</a></h3>

See also: content_item, content_folder
<p> </p>
<h3><a name="api">API</a></h3>
<ul>
<li>
<font size="+1">Function:</font> content_template.get_path
<p>Retrieves the full path to the template, as described in
content_item.get_path</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The path to the template, starting with the
specified root folder</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">template_id:</th><td>  </td><td>The id of the template for which the path is to be
retrieved</td>
</tr><tr>
<th align="right" valign="top">root_folder_id:</th><td>  </td><td>Starts path resolution at this folder</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_path (
  template_id    in cr_templates.template_id%TYPE,
  root_folder_id in cr_folders.folder_id%TYPE default c_root_folder_id
) return varchar2;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.get_path</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font>
content_template.get_root_folder
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><em>Not yet documented</em></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_root_folder return cr_folders.folder_id%TYPE;

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_template.is_template
<p>Determine if an item is a template.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">'t' if the item is a template, 'f'
otherwise</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item id</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function is_template (
  template_id   in cr_templates.template_id%TYPE
) return varchar2;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_template.new</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_template.new
<p>Creates a new content template which can be used to render
content items.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The id of the newly created template</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">name:</th><td>  </td><td>The name for the template, must be a valid UNIX-like filename.
If a template with this name already exists under the specified
parent item, an error is thrown</td>
</tr><tr>
<th align="right" valign="top">parent_id:</th><td>  </td><td>The parent of this item, defaults to null</td>
</tr><tr>
<th align="right" valign="top">template_id:</th><td>  </td><td>The id of the new template. A new id will be allocated if this
parameter is null</td>
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
  template_id   in cr_templates.template_id%TYPE default null,
  creation_date in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user in acs_objects.creation_user%TYPE
                           default null,
  creation_ip   in acs_objects.creation_ip%TYPE default null
) return cr_templates.template_id%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_object.new, content_item.new,
content_item.register_template, content_type.register_template</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_template.delete
<p>Deletes the specified template, and unregisters the template
from all content types and content items. Use with caution - this
operation cannot be undone.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">template_id:</th><td>  </td><td>The id of the template to delete</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure delete (
  template_id   in cr_templates.template_id%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_object.delete, content_item.unregister_template,
content_type.unregister_template,</td>
</tr>
</table><p> </p>
</li>
</ul>

Last Modified: $&zwnj;Id: template.html,v 1.1.1.1.30.2 2016/06/22
07:40:41 gustafn Exp $
