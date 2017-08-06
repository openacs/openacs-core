
<property name="context">{/doc/acs-content-repository {ACS Content Repository}} {Package: content_type}</property>
<property name="doc(title)">Package: content_type</property>
<master>
<h2>content_type</h2>
<p>
<a href="../index">Content Repository</a> :
content_type</p>
<hr>
<ul>
<li><a href="#overview">Overview</a></li><li><a href="#related">Related Objects</a></li><li><a href="#api">API</a></li>
</ul>
<p> </p>
<h3><a name="overview">Overview</a></h3>
<p>This package is used to manipulate content types and attributes
Content types represent the different kind of content displayed on
a website. All content items should subclass a content type.</p>
<p> </p>
<h3><a name="related">Related Objects</a></h3>

See also: {Content Item }
<p> </p>
<h3><a name="api">API</a></h3>
<ul>
<li>
<font size="+1">Function:</font> content_type.create_attribute
<p>Create a new attribute for the specified type. Automatically
create the column for the attribute if the column does not already
exist.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The id of the newly created attribute</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">content_type:</th><td>  </td><td>The name of the type to alter</td>
</tr><tr>
<th align="right" valign="top">attribute_name:</th><td>  </td><td>The name of the attribute to create</td>
</tr><tr>
<th align="right" valign="top">pretty_name:</th><td>  </td><td>Pretty name for the new attribute, singular</td>
</tr><tr>
<th align="right" valign="top">pretty_plural:</th><td>  </td><td>Pretty name for the new attribute, plural</td>
</tr><tr>
<th align="right" valign="top">default_value:</th><td>  </td><td>The default value for the attribute, defaults to null</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function create_attribute (
  content_type          in acs_attributes.object_type%TYPE,
  attribute_name        in acs_attributes.attribute_name%TYPE,
  datatype              in acs_attributes.datatype%TYPE,
  pretty_name           in acs_attributes.pretty_name%TYPE,
  pretty_plural in acs_attributes.pretty_plural%TYPE default null,
  default_value in acs_attributes.default_value%TYPE default null,
  column_spec           in varchar2  default 'varchar2(4000)'
) return acs_attributes.attribute_id%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_object_type.create_attribute, content_type.create_type</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_type.get_template
<p>Retrieve the appropriate template for rendering items of the
specified type.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr>
<th align="left">Returns:</th><td align="left">The ID of the template to use</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">content_type:</th><td>  </td><td>The type for which the template is to be retrieved</td>
</tr><tr>
<th align="right" valign="top">use_context:</th><td>  </td><td>The context in which the template is appropriate, such as
'admin' or 'public'</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function get_template (
  content_type  in cr_type_template_map.content_type%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE
) return cr_templates.template_id%TYPE;

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.register_template,
content_item.unregister_template, content_item.get_template,
content_type.unregister_template, content_type.register_template,
content_type.set_default_template</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Function:</font> content_type.is_content_type
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><em>Not yet documented</em></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
function is_content_type (
  object_type   in acs_object_types.object_type%TYPE
) return char;

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_type.create_type
<p>Create a new content type. Automatically create the attribute
table for the type if the table does not already exist.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">content_type:</th><td>  </td><td>The name of the new type</td>
</tr><tr>
<th align="right" valign="top">supertype:</th><td>  </td><td>The supertype, defaults to content_revision</td>
</tr><tr>
<th align="right" valign="top">pretty_name:</th><td>  </td><td>Pretty name for the type, singular</td>
</tr><tr>
<th align="right" valign="top">pretty_plural:</th><td>  </td><td>Pretty name for the type, plural</td>
</tr><tr>
<th align="right" valign="top">table_name:</th><td>  </td><td>The name for the attribute table, defaults to the name of the
supertype</td>
</tr><tr>
<th align="right" valign="top">id_column:</th><td>  </td><td>The primary key for the table, defaults to 'XXX'</td>
</tr><tr>
<th align="right" valign="top">name_method:</th><td>  </td><td>As in <kbd>acs_object_type.create_type</kbd>
</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure create_type (
  content_type          in acs_object_types.object_type%TYPE,
  supertype             in acs_object_types.object_type%TYPE
                           default 'content_revision',
  pretty_name           in acs_object_types.pretty_name%TYPE,
  pretty_plural         in acs_object_types.pretty_plural%TYPE,
  table_name            in acs_object_types.table_name%TYPE default null,
  id_column             in acs_object_types.id_column%TYPE default 'XXX',
  name_method           in acs_object_types.name_method%TYPE default null
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_object_type.create_type</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_type.drop_attribute
<p>Drop an existing attribute. If you are using CMS, make sure to
call <kbd>cm_form_widget.unregister_attribute_widget</kbd> before
calling this function.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">content_type:</th><td>  </td><td>The name of the type to alter</td>
</tr><tr>
<th align="right" valign="top">attribute_name:</th><td>  </td><td>The name of the attribute to drop</td>
</tr><tr>
<th align="right" valign="top">drop_column:</th><td>  </td><td>If 't', will also alter the table and remove the column
where the attribute is stored. The default is 'f' (leaves
the table untouched).</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure drop_attribute (
  content_type          in acs_attributes.object_type%TYPE,
  attribute_name        in acs_attributes.attribute_name%TYPE,
  drop_column           in varchar2 default 'f'
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>acs_object.drop_attribute, content_type.create_attribute,
cm_form_widget.unregister_attribute_widget</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font> content_type.refresh_view
<p>Create a view for the type which joins all attributes of the
type, including the inherited attributes. The view is named
"</p>
X" Called by create_attribute and create_type.
<table name="" for="" content_type="">
<tr><td></td></tr><tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1"><tr>
<th align="right" valign="top">content_type:</th><td>  </td><td>The type for which the view is to be created.</td>
</tr></table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure refresh_view (
  content_type  in cr_type_template_map.content_type%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_type.create_type</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_type.register_child_type
<p>Register a parent-child relationship between a content type and
another object type. This may then be used by the
content_item.is_valid_relation function to validate the
relationship between an item and a potential child.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">content_type:</th><td>  </td><td>The type of the item from which the relationship
originated.</td>
</tr><tr>
<th align="right" valign="top">child_type:</th><td>  </td><td>The type of the child item.</td>
</tr><tr>
<th align="right" valign="top">relation_tag:</th><td>  </td><td>A simple token used to identify a set of relations.</td>
</tr><tr>
<th align="right" valign="top">min_n:</th><td>  </td><td>The minimun number of parent-child relationships of this type
which an item must have to go live.</td>
</tr><tr>
<th align="right" valign="top">max_n:</th><td>  </td><td>The minimun number of relationships of this type which an item
must have to go live.</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure register_child_type (
  parent_type  in cr_type_children.parent_type%TYPE,
  child_type    in cr_type_children.child_type%TYPE,
  relation_tag  in cr_type_children.relation_tag%TYPE default 'generic',
  min_n         in integer default 0,
  max_n         in integer default null
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_type.register_relation_type,
content_type.register_child_type</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_type.register_mime_type
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><em>Not yet documented</em></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure register_mime_type (
  content_type  in cr_content_mime_type_map.content_type%TYPE,
  mime_type     in cr_content_mime_type_map.mime_type%TYPE
);

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_type.register_relation_type
<p>Register a relationship between a content type and another
object type. This may then be used by the
content_item.is_valid_relation function to validate any
relationship between an item and another object.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">content_type:</th><td>  </td><td>The type of the item from which the relationship
originated.</td>
</tr><tr>
<th align="right" valign="top">target_type:</th><td>  </td><td>The type of the item to which the relationship is
targeted.</td>
</tr><tr>
<th align="right" valign="top">relation_tag:</th><td>  </td><td>A simple token used to identify a set of relations.</td>
</tr><tr>
<th align="right" valign="top">min_n:</th><td>  </td><td>The minimun number of relationships of this type which an item
must have to go live.</td>
</tr><tr>
<th align="right" valign="top">max_n:</th><td>  </td><td>The minimun number of relationships of this type which an item
must have to go live.</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure register_relation_type (
  content_type  in cr_type_relations.content_type%TYPE,
  target_type   in cr_type_relations.target_type%TYPE,
  relation_tag  in cr_type_relations.relation_tag%TYPE default 'generic',
  min_n         in integer default 0,
  max_n         in integer default null
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_type.unregister_relation_type</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_type.register_template
<p>Register a template for the content type. This template may be
used to render all items of that type.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">content_type:</th><td>  </td><td>The type for which the template is to be registered</td>
</tr><tr>
<th align="right" valign="top">template_id:</th><td>  </td><td>The ID of the template to register</td>
</tr><tr>
<th align="right" valign="top">use_context:</th><td>  </td><td>The context in which the template is appropriate, such as
'admin' or 'public'</td>
</tr><tr>
<th align="right" valign="top">is_default:</th><td>  </td><td>If 't', this template becomes the default template for
the type, default is 'f'.</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure register_template (
  content_type  in cr_type_template_map.content_type%TYPE,
  template_id   in cr_templates.template_id%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE,
  is_default    in cr_type_template_map.is_default%TYPE default 'f'
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.register_template,
content_item.unregister_template, content_item.get_template,
content_type.unregister_template,
content_type.set_default_template, content_type.get_template</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_type.set_default_template
<p>Make the registered template a default template. The default
template will be used to render all items of the type for which no
individual template is registered.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">content_type:</th><td>  </td><td>The type for which the template is to be made default</td>
</tr><tr>
<th align="right" valign="top">template_id:</th><td>  </td><td>The ID of the template to make default</td>
</tr><tr>
<th align="right" valign="top">use_context:</th><td>  </td><td>The context in which the template is appropriate, such as
'admin' or 'public'</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure set_default_template (
  content_type  in cr_type_template_map.content_type%TYPE,
  template_id   in cr_templates.template_id%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.register_template,
content_item.unregister_template, content_item.get_template,
content_type.unregister_template, content_type.register_template,
content_type.get_template</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_type.unregister_child_type
<p>Register a parent-child relationship between a content type and
another object type. This may then be used by the
content_item.is_valid_relation function to validate the
relationship between an item and a potential child.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">parent_type:</th><td>  </td><td>The type of the parent item.</td>
</tr><tr>
<th align="right" valign="top">child_type:</th><td>  </td><td>The type of the child item.</td>
</tr><tr>
<th align="right" valign="top">relation_tag:</th><td>  </td><td>A simple token used to identify a set of relations.</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure unregister_child_type (
  parent_type  in cr_type_children.parent_type%TYPE,
  child_type   in cr_type_children.child_type%TYPE,
  relation_tag in cr_type_children.relation_tag%TYPE default null
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_type.register_relation_type,
content_type.register_child_type</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_type.unregister_mime_type
<table cellpadding="3" cellspacing="0" border="0">
<tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><em>Not yet documented</em></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure unregister_mime_type (
  content_type  in cr_content_mime_type_map.content_type%TYPE,
  mime_type     in cr_content_mime_type_map.mime_type%TYPE
);

</kbd></pre></td></tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_type.unregister_relation_type
<p>Unregister a relationship between a content type and another
object type.</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">content_type:</th><td>  </td><td>The type of the item from which the relationship
originated.</td>
</tr><tr>
<th align="right" valign="top">target_type:</th><td>  </td><td>The type of the item to which the relationship is
targeted.</td>
</tr><tr>
<th align="right" valign="top">relation_tag:</th><td>  </td><td>A simple token used to identify a set of relations.</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure unregister_relation_type (
  content_type in cr_type_relations.content_type%TYPE,
  target_type  in cr_type_relations.target_type%TYPE,
  relation_tag in cr_type_relations.relation_tag%TYPE default null
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_type.register_relation_type</td>
</tr>
</table><p> </p>
</li><li>
<font size="+1">Procedure:</font>
content_type.unregister_template
<p>Unregister a template. If the unregistered template was the
default template, the content_type can no longer be rendered in the
use_context,</p><table cellpadding="3" cellspacing="0" border="0">
<tr>
<th align="left">Author:</th><td align="left">Karl Goldstein</td>
</tr><tr><th align="left" colspan="2">Parameters:</th></tr><tr><td></td></tr><tr><td align="left" colspan="2"><blockquote><table border="0" cellpadding="0" cellspacing="1">
<tr>
<th align="right" valign="top">content_type:</th><td>  </td><td>The type for which the template is to be unregistered</td>
</tr><tr>
<th align="right" valign="top">template_id:</th><td>  </td><td>The ID of the template to unregister</td>
</tr><tr>
<th align="right" valign="top">use_context:</th><td>  </td><td>The context in which the template is to be unregistered</td>
</tr>
</table></blockquote></td></tr><tr><th align="left" colspan="2">Declaration:</th></tr><tr align="left"><td colspan="2" align="left"><pre><kbd>
procedure unregister_template (
  content_type  in cr_type_template_map.content_type%TYPE default null,
  template_id   in cr_templates.template_id%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE default null
);

</kbd></pre></td></tr><tr>
<th align="left" valign="top">See Also:</th><td>content_item.register_template,
content_item.unregister_template, content_item.get_template,
content_type.set_default_template, content_type.register_template,
content_type.get_template</td>
</tr>
</table><p> </p>
</li>
</ul>

Last Modified: $&zwnj;Id: type.html,v 1.1.1.1.30.2 2016/06/22 07:40:41
gustafn Exp $
