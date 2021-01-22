
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Package: content_extlink}</property>
<property name="doc(title)">Package: content_extlink</property>
<master>
<h2>content_extlink</h2>
<p>
<a href="../index">Content Repository</a> :
content_extlink</p>
<hr>
<ul>
<li><a href="#overview">Overview</a></li><li><a href="#related">Related Objects</a></li><li><a href="#api">API</a></li>
</ul>
<p> </p>
<h3><a name="overview" id="overview">Overview</a></h3>
<p>External links are references to content pages on other web
sites. They provide the basis for maintaining a hierarchy of
"bookmarks" that may be managed in a manner analogous to
other content items. In particular, external links may be tagged
with keywords and related to the site&#39;s own content items.</p>
<p> </p>
<h3><a name="related" id="related">Related Objects</a></h3>

See also: {content_item}
<p> </p>
<h3><a name="api" id="api">API</a></h3>
<ul>
<li>
<font size="+1">Function:</font> content_extlink.is_extlink
<p>Determines if the item is a extlink</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">'t' if the item is a extlink, 'f'
otherwise</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item id</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function is_extlink (
  item_id          in cr_items.item_id%TYPE
) return char;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_extlink.new, content_extlink.resolve</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_extlink.new
<p>Create a new extlink, an item pointing to an off-site
resource</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The id of the newly created extlink</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">name:</th><td>  </td><td>The name for the new extlink, defaults to the name of the
target item</td>
</tr><tr>
<th align="right" valign="top">url:</th><td>  </td><td>The URL of the item</td>
</tr><tr>
<th align="right" valign="top">label:</th><td>  </td><td>The text label or title of the item</td>
</tr><tr>
<th align="right" valign="top">description:</th><td>  </td><td>A brief description of the item</td>
</tr><tr>
<th align="right" valign="top">parent_id:</th><td>  </td><td>The parent folder for the extlink. This must actually be a
folder and not a generic content item.</td>
</tr><tr>
<th align="right" valign="top">extlink_id:</th><td>  </td><td>The id of the new extlink. A new id will be allocated by
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
  url           in cr_extlinks.url%TYPE,
  label         in cr_extlinks.label%TYPE default null,
  description   in cr_extlinks.description%TYPE default null,
  parent_id     in acs_objects.context_id%TYPE,
  extlink_id    in cr_extlinks.extlink_id%TYPE default null,
  creation_date in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user in acs_objects.creation_user%TYPE
                           default null,
  creation_ip   in acs_objects.creation_ip%TYPE default null
) return cr_extlinks.extlink_id%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_object.new, content_item.new, content_extlink.resolve</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_extlink.delete
<p>Deletes the extlink</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">extlink_id:</th><td>  </td><td>The id of the extlink to delete</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure delete (
  extlink_id    in cr_extlinks.extlink_id%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_extlink.new, acs_object.delete</td>
</tr>
</table>
</li>
</ul>

Last Modified: $&zwnj;Id: extlink.html,v 1.1.1.1.30.2 2016/06/22 07:40:41
gustafn Exp $
