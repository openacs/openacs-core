
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Package: content_symlink}</property>
<property name="doc(title)">Package: content_symlink</property>
<master>
<h2>content_symlink</h2>
<p>
<a href="../index">Content Repository</a> :
content_symlink</p>
<hr>
<ul>
<li><a href="#overview">Overview</a></li><li><a href="#related">Related Objects</a></li><li><a href="#api">API</a></li>
</ul>
<p> </p>
<h3><a name="overview">Overview</a></h3>
<p>Symlinks are pointers to items within the content repository.
They are simply used to create links between content items.</p>
<p> </p>
<h3><a name="related">Related Objects</a></h3>

See also: content_item, content_folder
<p> </p>
<h3><a name="api">API</a></h3>
<ul>
<li>
<font size="+1">Function:</font> content_symlink.is_symlink
<p>Determines if the item is a symlink</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">'t' if the item is a symlink, 'f'
otherwise</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item id</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function is_symlink (
  item_id          in cr_items.item_id%TYPE
) return char;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_symlink.new, content_symlink.resolve</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_symlink.new
<p>Create a new symlink, linking two items</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The id of the newly created symlink</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">name:</th><td>  </td><td>The name for the new symlink, defaults to the name of the
target item</td>
</tr><tr>
<th align="right" valign="top">label :</th><td>  </td><td>The label of the symlink, defaults to 'Symlink to
&lt;target_item_name&gt;'</td>
</tr><tr>
<th align="right" valign="top">target_id:</th><td>  </td><td>The item which the symlink will point to</td>
</tr><tr>
<th align="right" valign="top">parent_id:</th><td>  </td><td>The parent folder for the symlink. This must actually be a
folder and not a generic content item.</td>
</tr><tr>
<th align="right" valign="top">symlink_id:</th><td>  </td><td>The id of the new symlink. A new id will be allocated by
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
  name          in cr_items.name%TYPE default null,
  label         in cr_symlinks.label%TYPE default null,
  target_id     in cr_items.item_id%TYPE,
  parent_id     in acs_objects.context_id%TYPE,
  symlink_id    in cr_symlinks.symlink_id%TYPE default null,
  creation_date in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user in acs_objects.creation_user%TYPE
                           default null,
  creation_ip   in acs_objects.creation_ip%TYPE default null
) return cr_symlinks.symlink_id%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_object.new, content_item.new, content_symlink.resolve</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_symlink.resolve
<p>Resolves the symlink and returns the target item id.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The target item of the symlink, or the original
item id if the item is not in fact a symlink</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item id to be resolved</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function resolve (
  item_id       in cr_items.item_id%TYPE
) return cr_items.item_id%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_symlink.new, content_symlink.is_symlink</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font>
content_symlink.resolve_content_type
<p>Gets the content type of the target item.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Michael Pih</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The content type of the symlink target, otherwise
null. the item is not in fact a symlink</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item id to be resolved</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function resolve_content_type (
  item_id       in cr_items.item_id%TYPE
) return cr_items.content_type%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_symlink.resolve</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_symlink.copy
<p>Copies the symlink itself to another folder, without resolving
the symlink</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">symlink_id:</th><td>  </td><td>The id of the symlink to copy</td>
</tr><tr>
<th align="right" valign="top">target_folder_id:</th><td>  </td><td>The id of the folder where the symlink is to be copied</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure copy (
  symlink_id            in cr_symlinks.symlink_id%TYPE,
  target_folder_id      in cr_folders.folder_id%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_symlink.new, content_item.copy</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_symlink.delete
<p>Deletes the symlink</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">symlink_id:</th><td>  </td><td>The id of the symlink to delete</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure delete (
  symlink_id    in cr_symlinks.symlink_id%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_symlink.new, acs_object.delete</td>
</tr>
</table>
</li>
</ul>
<p> </p>

Last Modified: $&zwnj;Id: symlink.html,v 1.2.2.2 2016/06/22 07:40:41
gustafn Exp $
