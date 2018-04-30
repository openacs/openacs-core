
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Package: content_keyword}</property>
<property name="doc(title)">Package: content_keyword</property>
<master>
<h2>content_keyword</h2>
<p>
<a href="../index">Content Repository</a> :
content_keyword</p>
<hr>
<ul>
<li><a href="#overview">Overview</a></li><li><a href="#related">Related Objects</a></li><li><a href="#api">API</a></li>
</ul>
<p> </p>
<a name="overview" id="overview"><h3>Overview</h3></a>
<p>Keyword cassify a content_item. For example: If you have some
press releases about dogs. You might want assigning the Keyword dog
to every single content_item.</p>
<p> </p>
<a name="related" id="related"><h3>Related Objects</h3></a>
 See also: content_item
<p> </p>
<a name="api" id="api"><h3>API</h3></a>
<ul>
<li>
<font size="+1">Function:</font>
content_keyword.get_description
<p>Retrieves the description of the content keyword</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The description for the specified keyword</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">keyword_id:</th><td>  </td><td>The keyword id</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_description (
  keyword_id  in cr_keywords.keyword_id%TYPE
) return varchar2;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_keyword.get_heading,
content_keyword.set_description</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_keyword.get_heading
<p>Retrieves the heading of the content keyword</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The heading for the specified keyword</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">keyword_id:</th><td>  </td><td>The keyword id</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_heading (
  keyword_id  in cr_keywords.keyword_id%TYPE
) return varchar2;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_keyword.set_heading,
content_keyword.get_description</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_keyword.get_path
<p>Retrieves a path to the keyword/subject category, with the most
general category at the root of the path</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The path to the keyword, or null if no such
keyword exists</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">keyword_id:</th><td>  </td><td>The keyword id</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_path (
  keyword_id in cr_keywords.keyword_id%TYPE
) return varchar2;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_keyword.new</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_keyword.is_assigned
<p>Determines if the keyword is assigned to the item</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">'t' if the keyword may be matched to an
item, 'f' otherwise</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item id</td>
</tr><tr>
<th align="right" valign="top">keyword_id:</th><td>  </td><td>The keyword id to be checked for assignment</td>
</tr><tr>
<th align="right" valign="top">recurse:</th><td>  </td><td>Specifies if the keyword search is recursive. May be set to one
of the following values:
<ul>
<li>
<strong>none</strong>: Not recursive. Look for an exact
match.</li><li>
<strong>up</strong>: Recursive from specific to general. A
search for "attack dogs" will also match
"dogs", "animals", "mammals",
etc.</li><li>
<strong>down</strong>: Recursive from general to specific. A
search for "mammals" will also match "dogs",
"attack dogs", "cats", "siamese
cats", etc.</li>
</ul>
</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function is_assigned (
  item_id      in cr_items.item_id%TYPE,
  keyword_id   in cr_keywords.keyword_id%TYPE,
  recurse      in varchar2 default 'none'
) return varchar2;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_keyword.item_assign</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_keyword.is_leaf
<p>Determines if the keyword has no sub-keywords associated with
it</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">'t' if the keyword has no descendants,
'f' otherwise</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">keyword_id:</th><td>  </td><td>The keyword id</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function is_leaf (
  keyword_id  in cr_keywords.keyword_id%TYPE
) return varchar2;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_keyword.new</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_keyword.new
<p>Creates a new keyword (also known as "subject
category").</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The id of the newly created keyword</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">heading:</th><td>  </td><td>The heading for the new keyword</td>
</tr><tr>
<th align="right" valign="top">description:</th><td>  </td><td>The description for the new keyword</td>
</tr><tr>
<th align="right" valign="top">parent_id:</th><td>  </td><td>The parent of this keyword, defaults to null.</td>
</tr><tr>
<th align="right" valign="top">keyword_id:</th><td>  </td><td>The id of the new keyword. A new id will be allocated if this
parameter is null</td>
</tr><tr>
<th align="right" valign="top">object_type:</th><td>  </td><td>The type for the new keyword, defaults to
'content_keyword'. This parameter may be used by subclasses
of <kbd>content_keyword</kbd> to initialize the superclass.</td>
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
  heading       in cr_keywords.heading%TYPE,
  description   in cr_keywords.description%TYPE default null,
  parent_id     in cr_keywords.parent_id%TYPE default null,
  keyword_id    in cr_keywords.keyword_id%TYPE default null,
  creation_date in acs_objects.creation_date%TYPE
                           default sysdate,
  creation_user in acs_objects.creation_user%TYPE
                           default null,
  creation_ip   in acs_objects.creation_ip%TYPE default null,
  object_type   in acs_object_types.object_type%TYPE default 'content_keyword'
) return cr_keywords.keyword_id%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_object.new, content_item.new, content_keyword.item_assign,
content_keyword.delete</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_keyword.delete
<p>Deletes the specified keyword, which must be a leaf. Unassigns
the keyword from all content items. Use with caution - this
operation cannot be undone.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">keyword_id:</th><td>  </td><td>The id of the keyword to be deleted</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure delete (
  keyword_id  in cr_keywords.keyword_id%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_object.delete, content_keyword.item_unassign</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_keyword.item_assign
<p>Assigns this keyword to a content item, creating a relationship
between them</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item to be assigned to</td>
</tr><tr>
<th align="right" valign="top">keyword_id:</th><td>  </td><td>The keyword to be assigned</td>
</tr><tr>
<th align="right" valign="top">context_id:</th><td>  </td><td>As in <kbd>acs_rel.new</kbd>, deprecated</td>
</tr><tr>
<th align="right" valign="top">creation_ip:</th><td>  </td><td>As in <kbd>acs_rel.new</kbd>, deprecated</td>
</tr><tr>
<th align="right" valign="top">creation_user:</th><td>  </td><td>As in <kbd>acs_rel.new</kbd>, deprecated</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure item_assign (
  item_id       in cr_items.item_id%TYPE,
  keyword_id    in cr_keywords.keyword_id%TYPE,
  context_id    in acs_objects.context_id%TYPE default null,
  creation_user in acs_objects.creation_user%TYPE default null,
  creation_ip   in acs_objects.creation_ip%TYPE default null
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_rel.new, content_keyword.item_unassign</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_keyword.item_unassign
<p>Unassigns this keyword to a content item, removing a
relationship between them</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">item_id:</th><td>  </td><td>The item to be unassigned from</td>
</tr><tr>
<th align="right" valign="top">keyword_id:</th><td>  </td><td>The keyword to be unassigned</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure item_unassign (
  item_id     in cr_items.item_id%TYPE,
  keyword_id  in cr_keywords.keyword_id%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_rel.delete, content_keyword.item_assign</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_keyword.set_description
<p>Sets a new description for the keyword</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">keyword_id:</th><td>  </td><td>The keyword id</td>
</tr><tr>
<th align="right" valign="top">description:</th><td>  </td><td>The new description</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure set_description (
  keyword_id  in cr_keywords.keyword_id%TYPE,
  description in cr_keywords.description%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_keyword.set_heading,
content_keyword.get_description</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_keyword.set_heading
<p>Sets a new heading for the keyword</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">keyword_id:</th><td>  </td><td>The keyword id</td>
</tr><tr>
<th align="right" valign="top">heading:</th><td>  </td><td>The new heading</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure set_heading (
  keyword_id  in cr_keywords.keyword_id%TYPE,
  heading     in cr_keywords.heading%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_keyword.get_heading,
content_keyword.set_description</td>
</tr>
</table>
</li>
</ul>
<p> </p>

Last Modified: $&zwnj;Id: keyword.html,v 1.2 2017/08/07 23:47:47 gustafn
Exp $
