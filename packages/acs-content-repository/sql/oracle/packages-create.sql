
-- Ensure that the data model is up-to-date before compiling packages

@@ content-util.sql
@@ content-update.sql

create or replace package content_type AUTHID CURRENT_USER as
--/** This package is used to manipulate content types and attributes
--    
--*/

procedure create_type (
  --/** Create a new content type. Automatically create the attribute table
  --    for the type if the table does not already exist.
  --    @author Karl Goldstein
  --    @param content_type  The name of the new type
  --    @param supertype     The supertype, defaults to content_revision
  --    @param pretty_name   Pretty name for the type, singular
  --    @param pretty_plural Pretty name for the type, plural
  --    @param table_name    The name for the attribute table, defaults to
  --                         the name of the supertype
  --    @param id_column     The primary key for the table, defaults to 'XXX'
  --    @param name_method   As in <tt>acs_object_type.create_type</tt>
  --    @see {acs_object_type.create_type}
  --*/
  content_type		in acs_object_types.object_type%TYPE,
  supertype		in acs_object_types.object_type%TYPE 
                           default 'content_revision',
  pretty_name		in acs_object_types.pretty_name%TYPE,
  pretty_plural	        in acs_object_types.pretty_plural%TYPE,
  table_name		in acs_object_types.table_name%TYPE default null,
  id_column		in acs_object_types.id_column%TYPE default 'XXX',
  name_method           in acs_object_types.name_method%TYPE default null
);

procedure drop_type (
  --/** First drops all attributes related to a specific type, then drops type
  --    the given type.
  --    @author Simon Huynh
  --    @param content_type  The content type to be dropped
  --    @param drop_children_p If 't', then the sub-types
  --    of the given content type and their associated tables
  --    are also dropped.
  --*/
  content_type		in acs_object_types.object_type%TYPE,
  drop_children_p	in char default 'f',
  drop_table_p		in char default 'f',
  drop_objects_p		in char default 'f'
);


function create_attribute (
  --/** Create a new attribute for the specified type. Automatically create
  --    the column for the attribute if the column does not already exist.
  --    @author Karl Goldstein
  --    @param content_type   The name of the type to alter
  --    @param attribute_name The name of the attribute to create
  --    @param pretty_name    Pretty name for the new attribute, singular
  --    @param pretty_plural  Pretty name for the new attribute, plural
  --    @param default_value  The default value for the attribute, defaults to null
  --    @return The id of the newly created attribute
  --    @see {acs_object_type.create_attribute}, {content_type.create_type}
  --*/
  content_type		in acs_attributes.object_type%TYPE,
  attribute_name	in acs_attributes.attribute_name%TYPE,
  datatype		in acs_attributes.datatype%TYPE,
  pretty_name		in acs_attributes.pretty_name%TYPE,
  pretty_plural	in acs_attributes.pretty_plural%TYPE default null,
  sort_order		in acs_attributes.sort_order%TYPE default null,
  default_value	in acs_attributes.default_value%TYPE default null,
  column_spec           in varchar2  default 'varchar2(4000)'
) return acs_attributes.attribute_id%TYPE;

procedure drop_attribute (
  --/** Drop an existing attribute. If you are using CMS, make sure to
  --    call <tt>cm_form_widget.unregister_attribute_widget</tt> before calling
  --    this function.
  --    @author Karl Goldstein
  --    @param content_type   The name of the type to alter
  --    @param attribute_name The name of the attribute to drop
  --    @param drop_column    If 't', will also alter the table and remove
  --         the column where the attribute is stored. The default is 'f'
  --         (leaves the table untouched).
  --    @see {acs_object.drop_attribute}, {content_type.create_attribute},
  --         {cm_form_widget.unregister_attribute_widget}
  --*/
  content_type		in acs_attributes.object_type%TYPE,
  attribute_name	in acs_attributes.attribute_name%TYPE,
  drop_column           in varchar2 default 'f'
);

procedure register_template (
  --/** Register a template for the content type. This template may be used
  --    to render all items of that type.
  --    @author Karl Goldstein
  --    @param content_type  The type for which the template is to be registered
  --    @param template_id   The ID of the template to register
  --    @param use_context   The context in which the template is appropriate, such
  --                         as 'admin' or 'public'
  --    @param is_default    If 't', this template becomes the default template for
  --                         the type, default is 'f'.
  --    @see {content_item.register_template}, {content_item.unregister_template}, 
  --         {content_item.get_template}, {content_type.unregister_template},
  --         {content_type.set_default_template}, {content_type.get_template}
  --*/
  content_type  in cr_type_template_map.content_type%TYPE,
  template_id   in cr_templates.template_id%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE,
  is_default    in cr_type_template_map.is_default%TYPE default 'f'
);

procedure set_default_template (
  --/** Make the registered template a default template. The default template
  --    will be used to render all items of the type for which no individual
  --    template is registered.
  --    @author Karl Goldstein
  --    @param content_type  The type for which the template is to be made default
  --    @param template_id   The ID of the template to make default
  --    @param use_context   The context in which the template is appropriate, such
  --                         as 'admin' or 'public'
  --    @see {content_item.register_template}, {content_item.unregister_template}, 
  --         {content_item.get_template}, {content_type.unregister_template},
  --         {content_type.register_template}, {content_type.get_template}
  --*/
  content_type  in cr_type_template_map.content_type%TYPE,
  template_id   in cr_templates.template_id%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE
);

function get_template (
  --/** Retrieve the appropriate template for rendering items of the specified type.
  --    @author Karl Goldstein
  --    @param content_type  The type for which the template is to be retrieved
  --    @param use_context   The context in which the template is appropriate, such
  --                         as 'admin' or 'public'
  --    @return The ID of the template to use
  --    @see {content_item.register_template}, {content_item.unregister_template}, 
  --         {content_item.get_template}, {content_type.unregister_template},
  --         {content_type.register_template}, {content_type.set_default_template}
  --*/
  content_type  in cr_type_template_map.content_type%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE
) return cr_templates.template_id%TYPE;

procedure unregister_template (
  --/** Unregister a template.  If the unregistered template was the default template,
  --    the content_type can no longer be rendered in the use_context,
  --    @author Karl Goldstein
  --    @param content_type  The type for which the template is to be unregistered
  --    @param template_id   The ID of the template to unregister
  --    @param use_context   The context in which the template is to be unregistered
  --    @see {content_item.register_template}, {content_item.unregister_template}, 
  --         {content_item.get_template}, {content_type.set_default_template},
  --         {content_type.register_template}, {content_type.get_template}
  --*/
  content_type  in cr_type_template_map.content_type%TYPE default null,
  template_id   in cr_templates.template_id%TYPE,
  use_context   in cr_type_template_map.use_context%TYPE default null
);

procedure refresh_view (
  --/** Create a view for the type which joins all attributes of the type, 
  --    including the inherited attributes.  The view is named 
  --    "<table name for content_type>X"
  --    Called by create_attribute and create_type.
  --    @author Karl Goldstein
  --    @param content_type  The type for which the view is to be created.
  --    @see {content_type.create_type}
  --*/
  content_type  in cr_type_template_map.content_type%TYPE
);

procedure register_relation_type (
  --/** Register a relationship between a content type and another object
  --    type.  This may then be used by the content_item.is_valid_relation
  --    function to validate any relationship between an item and another
  --    object.
  --    @author Karl Goldstein
  --    @param content_type  The type of the item from which the relationship
  --                          originated.
  --    @param target_type   The type of the item to which the relationship
  --                          is targeted.
  --    @param relation_tag  A simple token used to identify a set of
  --                          relations.
  --    @param min_n          The minimum number of relationships of this type
  --                          which an item must have to go live.
  --    @param max_n          The minimum number of relationships of this type
  --                          which an item must have to go live.
  --    @see {content_type.unregister_relation_type}
  --*/
  content_type  in cr_type_relations.content_type%TYPE,
  target_type   in cr_type_relations.target_type%TYPE,
  relation_tag  in cr_type_relations.relation_tag%TYPE default 'generic',
  min_n         in integer default 0,
  max_n         in integer default null
);

procedure unregister_relation_type (
  --/** Unregister a relationship between a content type and another object
  --    type.
  --    @author Karl Goldstein
  --    @param content_type  The type of the item from which the relationship
  --                          originated.
  --    @param target_type   The type of the item to which the relationship
  --                          is targeted.
  --    @param relation_tag  A simple token used to identify a set of
  --                          relations.
  --    @see {content_type.register_relation_type}
  --*/
  content_type in cr_type_relations.content_type%TYPE,
  target_type  in cr_type_relations.target_type%TYPE,
  relation_tag in cr_type_relations.relation_tag%TYPE default null
);

procedure register_child_type (
  --/** Register a parent-child relationship between a content type
  --    and another object
  --    type.  This may then be used by the content_item.is_valid_relation
  --    function to validate the relationship between an item and a potential
  --    child.
  --    @author Karl Goldstein
  --    @param content_type  The type of the item from which the relationship
  --                          originated.
  --    @param child_type    The type of the child item.
  --    @param relation_tag  A simple token used to identify a set of
  --                          relations.
  --    @param min_n         The minimum number of parent-child
  --                          relationships of this type
  --                          which an item must have to go live.
  --    @param max_n         The minimum number of relationships of this type
  --                          which an item must have to go live.
  --    @see {content_type.register_relation_type}, {content_type.register_child_type}
  --*/
  parent_type  in cr_type_children.parent_type%TYPE,
  child_type    in cr_type_children.child_type%TYPE,
  relation_tag  in cr_type_children.relation_tag%TYPE default 'generic',
  min_n         in integer default 0,
  max_n         in integer default null
);

procedure unregister_child_type (
  --/** Register a parent-child relationship between a content type
  --    and another object
  --    type.  This may then be used by the content_item.is_valid_relation
  --    function to validate the relationship between an item and a potential
  --    child.
  --    @author Karl Goldstein
  --    @param parent_type   The type of the parent item.
  --    @param child_type    The type of the child item.
  --    @param relation_tag  A simple token used to identify a set of
  --                          relations.
  --    @see {content_type.register_relation_type}, {content_type.register_child_type}
  --*/
  parent_type  in cr_type_children.parent_type%TYPE,
  child_type   in cr_type_children.child_type%TYPE,
  relation_tag in cr_type_children.relation_tag%TYPE default null
);

procedure register_mime_type (
  content_type  in cr_content_mime_type_map.content_type%TYPE,
  mime_type	in cr_content_mime_type_map.mime_type%TYPE
);

procedure unregister_mime_type (
  content_type  in cr_content_mime_type_map.content_type%TYPE,
  mime_type	in cr_content_mime_type_map.mime_type%TYPE
);

function is_content_type (
  object_type   in acs_object_types.object_type%TYPE
) return char;

procedure rotate_template (
  --/** Sets the default template for a content type and registers all the
  --    previously existing items of that content type to the original 
  --    template
  --    @author Michael Pih
  --    @param template_id The template that will become the default 
  --      registered template for the specified content type and use context
  --    @param v_content_type The content type
  --    @param use_context The context in which the template will be used
  --*/
  template_id     in cr_templates.template_id%TYPE,
  v_content_type    in cr_items.content_type%TYPE,
  use_context     in cr_type_template_map.use_context%TYPE
);

-- Create or replace a trigger on insert for simplifying addition of
-- revisions for any content type

procedure refresh_trigger (
  content_type  in acs_object_types.object_type%TYPE
);

end content_type;
/
show errors;

create or replace package content_item
as

--/** 
--Content items store the overview of the content published on a
--website. The actual content is stored in content revisions. It is
--implemented this way so that there can be multiple versions of the
--actual content while the main idea remains constant. For example: If
--there is a review for the movie "Terminator," there will exist a
--content item by the name "terminator" with all the right parameters
--(supertype, parent, etc), there will also exist at least one content
--revision pointing to this item with the actual review content.  
--@see {content_revision}, {content_folder} 
--*/

c_root_folder_id constant integer := -100;

function get_root_folder (
  item_id  in cr_items.item_id%TYPE default null
) return cr_folders.folder_id%TYPE;

function new (
  --/** Creates a new content item. If the <tt>data</tt>, <tt>title</tt> or <tt>text</tt>
  --    parameters are specified, also creates a revision for the item.
  --    @author Karl Goldstein
  --    @param name          The name for the item, must be URL-encoded.
  --                         If an item with this name already exists under the specified
  --                         parent item, an error is thrown
  --    @param parent_id     The parent of this item, defaults to null
  --    @param item_id       The id of the new item. A new id will be allocated if this
  --                         parameter is null
  --    @param locale        The locale for this item, for use with Intermedia search
  --    @param item_subtype  The type of the new item, defaults to 'content_item'
  --                         This parameter is used to support inheritance, so that
  --                         subclasses of <tt>content_item</tt> can call this function
  --                         to initialize the parent class
  --    @param content_type  The content type for the item, defaults to 
  --                        'content_revision'. Only objects of this type 
  --                         may be used as revisions for the item
  --    @param title         The user-readable title for the item, defaults to the item's
  --                         name
  --    @param description   A short description for the item (4000 characters maximum)
  --    @param mime_type     The file type of the item, defaults to 'text/plain'
  --    @param nls_language  The language for the item, used for Intermedia search
  --    @param text          The text content of the new revision, 4000 charcters maximum.
  --                         Cannot be specified simultaneously with the <tt>data</tt>
  --                         parameter
  --    @param data          The blob content of the new revision. Cannot be specified 
  --                         simultaneously with the <tt>text</tt> parameter
  --    @param relation_tag  If a parent-child relationship is registered
  --                         for these content types, use this tag to  
  --			     describe the parent-child relationship.  Defaults
  --                         to 'parent content type'-'child content type'
  --    @param is_live       If 't', the new revision will become live
  --    @param context_id    Security context id, as in <tt>acs_object.new</tt>
  --                         If null, defaults to parent_id, and copies permissions
  --                         from the parent into the current item
  --    @param storage_type  in ('lob','file').  Indicates how content is to be stored.
  --                         'file' content is stored externally in the file system.
  --    @param <i>others</i> As in acs_object.new
  --    @return The id of the newly created item
  --    @see {acs_object.new}
  --*/
  name          in cr_items.name%TYPE,
  parent_id     in cr_items.parent_id%TYPE default null,
  item_id	in acs_objects.object_id%TYPE default null,
  locale        in cr_items.locale%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE
			   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
			   default null,
  context_id    in acs_objects.context_id%TYPE default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  item_subtype	in acs_object_types.object_type%TYPE 
                           default 'content_item',
  content_type  in acs_object_types.object_type%TYPE 
                           default 'content_revision',
  title         in cr_revisions.title%TYPE default null,
  description   in cr_revisions.description%TYPE default null,
  mime_type   	in cr_revisions.mime_type%TYPE default 'text/plain',
  nls_language 	in cr_revisions.nls_language%TYPE default null,
  text	        in varchar2 default null,
  data	        in cr_revisions.content%TYPE default null,
  relation_tag  in cr_child_rels.relation_tag%TYPE default null,
  is_live       in char default 'f',
  storage_type  in cr_items.storage_type%TYPE default 'lob',
  security_inherit_p in acs_objects.security_inherit_p%TYPE default 't',
  package_id    in acs_objects.package_id%TYPE default null
) return cr_items.item_id%TYPE;


function is_published (
  --/** Determines whether an item is published or not.
  --    @author Michael Pih
  --    @param item_id		The item ID
  --    @return 't' if the item is published, 'f' otherwise
 --*/
  item_id	        in cr_items.item_id%TYPE
) return char;


function is_publishable (
  --/** Determines if an item is publishable.  Publishable items must
  --    meet the following criteria:
  --	1) for each child type, the item has n children, min_n < n < max_n
  --	2) for each relation type, the item has n relations, min_n < n < max_n
  --	3) any 'publishing_wf' workflows are finished
  --    @author Michael Pih
  --    @param item_id		The item ID
  --    @return 't' if the item is publishable in its present state,
  --            Otherwise, returns 'f'
  --*/
  item_id		in cr_items.item_id%TYPE
) return char;



function is_valid_child (
  --/** Determines if an item would be a valid child of another item by
  --    checking if the parent allows children of the would-be child's
  --    content type and if the parent already has n_max children of
  --    that content type.
  --    @author Michael Pih
  --    @param item_id		The item ID of the potential parent
  --    @param content_type	The content type of the potential child item
  --    @return 't' if the item would be a valid child, 'f' otherwise
  --*/

  item_id	in cr_items.item_id%TYPE,
  content_type  in acs_object_types.object_type%TYPE,
  relation_tag  in cr_child_rels.relation_tag%TYPE default null
) return char;

procedure del (
  --/** Deletes the specified content item, along with any revisions, symlinks, 
  --    workflows, associated templates, associated keywords, 
  --    child and item relationships for the item. Use with caution - this
  --    operation cannot be undone.
  --    @author Karl Goldstein
  --    @param item_id The id of the item to delete
  --    @see {acs_object.delete}
  --*/  
  item_id	in cr_items.item_id%TYPE
);

procedure edit_name (
  --/** Renames the item. If an item with the specified name already exists 
  --    under this item's parent, an error is thrown
  --    @author Karl Goldstein
  --    @param item_id The id of the item to rename
  --    @param name    The new name for the item, must be URL-encoded
  --    @see {content_item.new}
  --*/ 
  item_id	 in cr_items.item_id%TYPE,
  name           in cr_items.name%TYPE
);

function get_id (
  --/** Takes in a path, such as "/tv/programs/star_trek/episode_203"
  --    and returns the id of the item with this path.  Note:  URLs are abstract (no
  --    extensions are allowed in content item names and extensions are stripped when
  --    looking up content items)
  --    @author Karl Goldstein
  --    @param item_path       The path to be resolved
  --    @param root_folder_id  Starts path resolution from this folder. Defaults to
  --                           the root of the sitemap
  --    @param resolve_index   Boolean flag indicating whether to return the
  --                           id of the index page for folders (if one 
  --                           exists). Defaults to 'f'.
  --    @return The id of the item with the given path, or null if no such item exists
  --    @see {content_item.get_path}
  --*/   
  item_path   in varchar2,
  root_folder_id in cr_items.item_id%TYPE default c_root_folder_id,
  resolve_index  in char default 'f'
) return cr_items.item_id%TYPE;

function get_path (
  --/** Retrieves the full path to an item, in the form of
  --    "/tv/programs/star_trek/episode_203"
  --    @author Karl Goldstein
  --    @param item_id         	The item for which the path is to be retrieved
  --    @param root_folder_id  	Starts path resolution from this folder. 
  --                            Defaults to the root of the sitemap
  --    @return The path to the item
  --    @see {content_item.get_id}, {content_item.write_to_file}
  --*/   
  item_id        in cr_items.item_id%TYPE,
  root_folder_id in cr_items.item_id%TYPE default null
) return varchar2;

function get_virtual_path (
  --/** Retrieves the virtual path to an item, in the form of
  --    "/tv/programs/star_trek/episode_203"
  --    @author Michael Pih
  --    @param item_id         The item for which the path is to be retrieved
  --    @param root_folder_id  Starts path resolution from this folder. 
  --                           Defaults to the root of the sitemap
  --    @return The virtual path to the item
  --    @see {content_item.get_id}, {content_item.write_to_file}, {content_item.get_path}
  --*/   
  item_id        in cr_items.item_id%TYPE,
  root_folder_id in cr_items.item_id%TYPE default c_root_folder_id
) return varchar2;

procedure write_to_file (
  --/** Writes the content of the  live revision of this item to a file, 
  --    creating all the necessary directories in the process
  --    @author Karl Goldstein
  --    @param item_id         The item to be written to a file
  --    @param root_path       The path in the filesystem to which the root of the
  --                           sitemap corresponds
  --    @see {content_item.get_path}
  --*/
  item_id     in cr_items.item_id%TYPE,
  root_path   in varchar2
);

procedure register_template (
  --/** Registers a template which will be used to render this item.
  --    @author Karl Goldstein
  --    @param item_id         The item for which the template will be registered
  --    @param template_id     The template to be registered
  --    @param use_context     The context in which the template is appropriate, such
  --                           as 'admin' or 'public'
  --    @see {content_type.register_template}, {content_item.unregister_template},
  --         {content_item.get_template}       
  --*/
  item_id      in cr_items.item_id%TYPE,
  template_id  in cr_templates.template_id%TYPE,
  use_context  in cr_item_template_map.use_context%TYPE
);

procedure unregister_template (
  --/** Unregisters a template which will be used to render this item.
  --    @author Karl Goldstein
  --    @param item_id         The item for which the template will be unregistered
  --    @param template_id     The template to be registered
  --    @param use_context     The context in which the template is appropriate, such
  --                           as 'admin' or 'public'
  --    @see {content_type.register_template}, {content_item.register_template},
  --         {content_item.get_template}       
  --*/
  item_id      in cr_items.item_id%TYPE,
  template_id  in cr_templates.template_id%TYPE default null,
  use_context  in cr_item_template_map.use_context%TYPE default null
);

function get_template (
  --/** Retrieves the template which should be used to render this item. If no template
  --    is registered to specifically render the item in the given context, the 
  --    default template for the item's type is returned.
  --    @author Karl Goldstein
  --    @param item_id         The item for which the template will be unregistered
  --    @param use_context     The context in the item is to be rendered, such
  --                           as 'admin' or 'public'
  --    @return The id of the registered template, or null if no template could be
  --            found
  --    @see {content_type.register_template}, {content_item.register_template},
  --*/
  item_id     in cr_items.item_id%TYPE,
  use_context in cr_item_template_map.use_context%TYPE
) return cr_templates.template_id%TYPE;

function get_live_revision (
  --/** Retrieves the id of the live revision for the item
  --    @param item_id         The item for which the live revision is to be retrieved
  --    @return The id of the live revision for this item, or null if no live revision
  --            exists
  --    @see {content_item.set_live_revision}, {content_item.get_latest_revision}
  --*/
  item_id   in cr_items.item_id%TYPE
) return cr_revisions.revision_id%TYPE;
  
procedure set_live_revision (
  --/** Make the specified revision the live revision for the item
  --    @author Karl Goldstein
  --    @param revision_id The id of the revision which is to become live 
  --                       for its corresponding item
  --    @see {content_item.get_live_revision}
  --*/
  revision_id   in cr_revisions.revision_id%TYPE,
  publish_status in cr_items.publish_status%TYPE default 'ready'
);


procedure unset_live_revision (
  --/** Set the live revision to null for the item
  --    @author Michael Pih
  --    @param item_id The id of the item for which to unset the live revision
  --    @see {content_item.set_live_revision}
  item_id      in cr_items.item_id%TYPE
);

procedure set_release_period (
  --/** Sets the release period for the item.  This information may be
  --    used by applications to update the publishing status of items
  --    at periodic intervals.
  --    @author Karl Goldstein
  --    @param item_id    The id the item.
  --    @param start_when The time and date when the item should be released.
  --    @param end_when   The time and date when the item should be expired.
  --*/
  item_id    in cr_items.item_id%TYPE,
  start_when date default null,
  end_when   date default null
);


function get_revision_count (
  --/** Return the total count of revisions for this item
  --    @author Karl Goldstein
  --    @param item_id The id the item
  --    @return The number of revisions for this item
  --    @see {content_revision.new}
  --*/
  item_id   in cr_items.item_id%TYPE
) return number;

-- Return the object type of this item
function get_content_type (
  --/** Retrieve the content type of this item. Only objects of this type may be
  --    used as revisions for the item. 
  --    @author Karl Goldstein
  --    @param item_id     The item for which the content type is to be retrieved
  --    @return The content type of the item
  --*/
  item_id     in cr_items.item_id%TYPE
) return cr_items.content_type%TYPE;

function get_context (
  --/** Retrieve the parent of the given item
  --    @author Karl Goldstein
  --    @param item_id     The item for which the parent is to be retrieved
  --    @return The id of the parent for this item
  --*/
  item_id	in cr_items.item_id%TYPE
) return acs_objects.context_id%TYPE;

procedure move (
  --/** Move the specified item to a different folder. If the target folder does
  --    not exist, or if the folder already contains an item with the same name
  --    as the given item, an error will be thrown.
  --    @author Karl Goldstein
  --    @param item_id          The item to be moved
  --    @param target_folder_id The new folder for the item
  --    @see {content_item.new}, {content_folder.new}, {content_item.copy}
  --*/
  item_id		in cr_items.item_id%TYPE,
  target_folder_id	in cr_folders.folder_id%TYPE,
  name                  in cr_items.name%TYPE default null
);

procedure copy (
  --/** Copies the item to a new location, creating an identical item with 
  --    an identical latest revision (if any).  If the target folder does
  --    not exist, or if the folder already contains an item with the same name
  --    as the given item, an error will be thrown.
  --    @author Karl Goldstein, Michael Pih
  --    @param item_id          The item to be copied
  --    @param target_folder_id The folder where the item is to be copied
  --    @param creation_user    The user_id of the creator
  --    @param creation_ip      The IP address of the creator
  --    @see {content_item.new}, {content_folder.new}, {content_item.move}
  --*/
  item_id		in cr_items.item_id%TYPE,
  target_folder_id	in cr_folders.folder_id%TYPE,
  creation_user		in acs_objects.creation_user%TYPE,
  creation_ip		in acs_objects.creation_ip%TYPE default null,
  name                  in cr_items.name%TYPE default null
);

function copy2 (
  --/** Copies the item to a new location, creating an identical item with 
  --    an identical latest revision (if any).  If the target folder does
  --    not exist, or if the folder already contains an item with the same name
  --    as the given item, an error will be thrown.
  --    @author Karl Goldstein, Michael Pih
  --    @param item_id          The item to be copied
  --    @param target_folder_id The folder where the item is to be copied
  --    @param creation_user    The user_id of the creator
  --    @param creation_ip      The IP address of the creator
  --    @return The item ID of the new copy.
  --    @see {content_item.new}, {content_folder.new}, {content_item.move}
  --*/
  item_id		in cr_items.item_id%TYPE,
  target_folder_id	in cr_folders.folder_id%TYPE,
  creation_user		in acs_objects.creation_user%TYPE,
  creation_ip		in acs_objects.creation_ip%TYPE default null,
  name                  in cr_items.name%TYPE default null
) return cr_items.item_id%TYPE;

-- get the latest revision for an item
function get_latest_revision (
  --/** Retrieves the id of the latest revision for the item (as opposed to the live
  --    revision)
  --    @author Karl Goldstein
  --    @param item_id         The item for which the latest revision is to be retrieved
  --    @return The id of the latest revision for this item, or null if no revisions 
  --            exist
  --    @see {content_item.get_live_revision}
  --*/
  item_id    in cr_items.item_id%TYPE
) return cr_revisions.revision_id%TYPE;


function get_best_revision (
  --/** Retrieves the id of the live revision for the item if one exists, 
  --    otherwise retrieves the id of the latest revision if one exists.
  --    revision)
  --    @author Michael Pih
  --    @param item_id The item for which the revision is to be retrieved
  --    @return The id of the live or latest revision for this item, 
  --            or null if no revisions exist
  --    @see {content_item.get_live_revision}, {content_item.get_latest_revision}
  --*/
  item_id	in cr_items.item_id%TYPE
) return cr_revisions.revision_id%TYPE;

function get_title (
  --/** Retrieves the title for the item, using either the latest or the live revision.
  --    If the specified item is in fact a folder, return the folder's label.
  --    In addition, this function will automatically resolve symlinks.
  --    @author Karl Goldstein
  --    @param item_id        The item for which the title is to be retrieved
  --    @param is_live        If 't', use the live revision to get the title. Otherwise,
  --                          use the latest revision. The default is 'f'
  --    @return The title of the item
  --    @see {content_item.get_live_revision}, {content_item.get_latest_revision}, 
  --         {content_symlink.resolve}
  --*/
  item_id    in cr_items.item_id%TYPE,
  is_live    in char default 'f'
) return cr_revisions.title%TYPE;

function get_publish_date (
  --/** Retrieves the publish date for the item
  --    @author Karl Goldstein
  --    @param item_id     The item for which the publish date is to be retrieved
  --    @param is_live     If 't', use the live revision for the item. Otherwise, use
  --                       the latest revision. The default is 'f'
  --    @return The publish date for the item, or null if the item has no revisions
  --    @see {content_item.get_live_revision}, {content_item.get_latest_revision}, 
  --*/
  item_id    in cr_items.item_id%TYPE,
  is_live    in char default 'f'
) return cr_revisions.publish_date%TYPE;

function is_subclass (
  --/** Determines if one type is a subclass of another. A class is always a subclass of
  --    itself. 
  --    @author Karl Goldstein
  --    @param object_type    The child class
  --    @param supertype      The superclass
  --    @return 't' if the child class is a subclass of the superclass, 'f' otherwise
  --    @see {acs_object_type.create_type}
  --*/
  object_type in acs_object_types.object_type%TYPE,
  supertype	in acs_object_types.supertype%TYPE
) return char;

function relate (
  --/** Relates two content items
  --    @author Karl Goldstein
  --    @param item_id		The item id
  --    @param object_id	The item id of the related object
  --    @param relation_tag	A tag to help identify the relation type, 
  --      defaults to 'generic'
  --    @param order_n		The order of this object among other objects
  --      of the same relation type, defaults to null.
  --    @param relation_type    The object type of the relation, defaults to
  --      'cr_item_rel'
  --*/
  item_id       in cr_items.item_id%TYPE,
  object_id     in acs_objects.object_id%TYPE,
  relation_tag in cr_type_relations.relation_tag%TYPE default 'generic',
  order_n       in cr_item_rels.order_n%TYPE default null,
  relation_type in acs_object_types.object_type%TYPE default 'cr_item_rel'
) return cr_item_rels.rel_id%TYPE;


procedure unrelate (
  --/** Delete the item relationship between two items
  --    @author Michael Pih
  --    @param rel_id The relationship id
  --    @see {content_item.relate}
  --*/
  rel_id	  in cr_item_rels.rel_id%TYPE
);

function is_index_page (
  --/** Determine if the item is an index page for the specified folder.
  --    The item is an index page for the folder if it exists in the
  --    folder and its item name is "index".
  --    @author Karl Goldstein
  --    @param item_id The item id
  --    @param folder_id The folder id
  --    @return 't' if the item is an index page for the specified
  --     folder, 'f' otherwise
  --    @see {content_folder.get_index_page}
  --*/
  item_id   in cr_items.item_id%TYPE,
  folder_id in cr_folders.folder_id%TYPE
) return varchar2;


function get_parent_folder (
  --/** Get the parent folder.
  --    @author Michael Pih
  --    @param item_id The item id
  --    @return the folder_id of the parent folder, null otherwise
  --*/
  item_id	in cr_items.item_id%TYPE
) return cr_folders.folder_id%TYPE;

end content_item;
/
show errors

	
create or replace package content_revision
as

function new (
  --/** Create a new revision for an item. 
  --    @author Karl Goldstein
  --    @param title        The revised title for the item
  --    @param description  A short description of this revision, 4000 characters maximum
  --    @param publish_date Publication date.
  --    @param mime_type    The revised mime type of the item, defaults to 'text/plain'
  --    @param nls_language The revised language of the item, for use with Intermedia searching
  --    @param data         The blob which contains the body of the revision
  --    @param item_id      The id of the item being revised
  --    @param revision_id  The id of the new revision. A new id will be allocated by default
  --    @param creation_date As in <tt>acs_object.new</tt>
  --    @param creation_ip   As in <tt>acs_object.new</tt>
  --    @param creation_user As in <tt>acs_object.new</tt>
  --    @return The id of the newly created revision
  --    @see {acs_object.new}, {content_item.new}
  --*/
  title         in cr_revisions.title%TYPE,
  description   in cr_revisions.description%TYPE default null,
  publish_date  in cr_revisions.publish_date%TYPE default sysdate,
  mime_type   	in cr_revisions.mime_type%TYPE default 'text/plain',
  nls_language 	in cr_revisions.nls_language%TYPE default null,
  data	        in cr_revisions.content%TYPE,
  item_id       in cr_items.item_id%TYPE,
  revision_id   in cr_revisions.revision_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE
			   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
			   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  filename	in cr_revisions.filename%TYPE default null,
  package_id	in acs_objects.package_id%TYPE default null
) return cr_revisions.revision_id%TYPE;

function new (
  title         in cr_revisions.title%TYPE,
  description   in cr_revisions.description%TYPE default null,
  publish_date  in cr_revisions.publish_date%TYPE default sysdate,
  mime_type   	in cr_revisions.mime_type%TYPE default 'text/plain',
  nls_language 	in cr_revisions.nls_language%TYPE default null,
  text		in varchar2 default null,
  item_id       in cr_items.item_id%TYPE,
  revision_id   in cr_revisions.revision_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE default sysdate,
  creation_user	in acs_objects.creation_user%TYPE default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  package_id	in acs_objects.package_id%TYPE default null,
  filename	in cr_revisions.filename%TYPE default null
) return cr_revisions.revision_id%TYPE;

function copy (
  --/** Creates a new copy of a revision, including all attributes and content
  --    and content, returning the ID of the new revision
  --    @author Karl Goldstein, Michael Pih
  --    @param revision_id	The id of the revision to copy
  --    @param copy_id		The id of the new copy (default null)
  --    @param target_item_id	The id of the item which will own the copied revision. If null, the item that holds the original revision will own the copied revision. Defaults to null.
  --    @param creation_user	The id of the creation user
  --    @param creation_ip  The IP address of the creation user (default null)
  --    @return		    The id of the new revision
  --    @see {content_revision.new}
  --*/
  revision_id		in cr_revisions.revision_id%TYPE,
  copy_id		in cr_revisions.revision_id%TYPE default null,
  target_item_id	in cr_items.item_id%TYPE default null,
  creation_user		in acs_objects.creation_user%TYPE default null,
  creation_ip		in acs_objects.creation_ip%TYPE default null
) return cr_revisions.revision_id%TYPE;

procedure del (
  --/** Deletes the revision.
  --    @author Karl Goldstein
  --    @param revision_id The id of the revision to delete
  --    @see {content_revision.new}, {acs_object.delete}
  --*/
  revision_id	in cr_revisions.revision_id%TYPE
);

function get_number (
  --/** Return the revision number of the specified revision, according to 
  --    the chronological
  --    order in which revisions have been added for this item.
  --    @author Karl Goldstein
  --    @param revision_id The id the revision
  --    @return The number of the revision
  --    @see {content_revision.new}
  --*/
  revision_id   in cr_revisions.revision_id%TYPE
) return number;

function revision_name (
  --/** Return a pretty string 'revision x of y'
  --*/
  revision_id   in cr_revisions.revision_id%TYPE
) return varchar2;

procedure index_attributes(
  --/** Generates an XML document for insertion into cr_revision_attributes,
  --    which is indexed by Intermedia for searching attributes.
  --    @author Karl Goldstein
  --    @param revision_id The id of the revision to index
  --    @see {content_revision.new}
  --*/
  revision_id IN cr_revisions.revision_id%TYPE
);

function export_xml (
  revision_id IN cr_revisions.revision_id%TYPE
) return cr_xml_docs.doc_id%TYPE;

function write_xml (
  revision_id IN number,
  clob_loc IN clob
) return number as language
  java
name
  'com.arsdigita.content.XMLExchange.exportRevision(
     java.lang.Integer, oracle.sql.CLOB
  ) return int';

function import_xml (
  item_id IN cr_items.item_id%TYPE,
  revision_id IN cr_revisions.revision_id%TYPE,
  doc_id IN number
) return cr_revisions.revision_id%TYPE;

function read_xml (
  item_id IN number,
  revision_id IN number,
  clob_loc IN clob
) return number as language
  java
name
  'com.arsdigita.content.XMLExchange.importRevision(
     java.lang.Integer, java.lang.Integer, oracle.sql.CLOB
  ) return int';

procedure to_html (
  --/** Converts a revision uploaded as a binary document to html
  --    @author Karl Goldstein
  --    @param revision_id The id of the revision to index
  --*/
  revision_id IN cr_revisions.revision_id%TYPE
);

procedure replace(
  revision_id number, search varchar2, replace varchar2)
as language 
  java 
name 
  'com.arsdigita.content.Regexp.replace(
    int, java.lang.String, java.lang.String
   )';

function is_live (
  -- /** Determine if the revision is live
  --   @author Karl Goldstein, Stanislav Freidin
  --   @param revision_id The id of the revision to check
  --   @return 't' if the revision is live, 'f' otherwise
  --   @see {content_revision.is_latest}
  --*/
  revision_id in cr_revisions.revision_id%TYPE
) return varchar2;

function is_latest (
  -- /** Determine if the revision is the latest revision
  --   @author Karl Goldstein, Stanislav Freidin
  --   @param revision_id The id of the revision to check
  --   @return 't' if the revision is the latest revision for its item, 'f' otherwise
  --   @see {content_revision.is_live}
  --*/
  revision_id in cr_revisions.revision_id%TYPE
) return varchar2;

procedure to_temporary_clob (
  revision_id in cr_revisions.revision_id%TYPE
);

procedure content_copy (
  -- /** Copies the content of the specified revision to the content
  --   of another revision
  --   @author Michael Pih
  --   @param revision_id The id of the revision with the content to be copied
  --   @param revision_id The id of the revision to be updated, defaults to the
  --   latest revision of the item with which the source revision is 
  --   associated.
  --*/
  revision_id	       in cr_revisions.revision_id%TYPE,
  revision_id_dest     in cr_revisions.revision_id%TYPE default null
);

end content_revision;
/
show errors

create or replace package content_symlink
as

function new (
  --/** Create a new symlink, linking two items
  --    @author Karl Goldstein
  --    @param name          The name for the new symlink, defaults to the name of the
  --                         target item
  --    @param label	     The label of the symlink, defaults to 'Symlinke to <target_item_name>'
  --    @param target_id     The item which the symlink will point to
  --    @param parent_id     The parent folder for the symlink. This must actually be a folder
  --                         and not a generic content item.
  --    @param symlink_id    The id of the new symlink. A new id will be allocated by default
  --    @param creation_date As in <tt>acs_object.new</tt>
  --    @param creation_ip   As in <tt>acs_object.new</tt>
  --    @param creation_user As in <tt>acs_object.new</tt>
  --    @return The id of the newly created symlink
  --    @see {acs_object.new}, {content_item.new}, {content_symlink.resolve}
  --*/
  name          in cr_items.name%TYPE default null,
  label		in cr_symlinks.label%TYPE default null,
  target_id	in cr_items.item_id%TYPE,
  parent_id     in cr_items.parent_id%TYPE,
  symlink_id	in cr_symlinks.symlink_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE
			   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
			   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  package_id    in acs_objects.package_id%TYPE default null
) return cr_symlinks.symlink_id%TYPE;


procedure del (
  --/** Deletes the symlink
  --    @author Karl Goldstein
  --    @param symlink_id The id of the symlink to delete
  --    @see {content_symlink.new}, {acs_object.delete}
  --*/
  symlink_id	in cr_symlinks.symlink_id%TYPE
);


procedure copy (
  --/** Copies the symlink itself to another folder, without resolving the symlink
  --    @author Karl Goldstein
  --    @param symlink_id        The id of the symlink to copy
  --    @param target_folder_id  The id of the folder where the symlink is to be copied
  --    @param creation_user	 The id of the creation user
  --    @param creation_ip	 The IP address of the creation user (default null)
  --    @see {content_symlink.new}, {content_item.copy}
  --*/
  symlink_id		in cr_symlinks.symlink_id%TYPE,
  target_folder_id	in cr_folders.folder_id%TYPE,
  creation_user		in acs_objects.creation_user%TYPE,
  creation_ip		in acs_objects.creation_ip%TYPE default null,
  name                  in cr_items.name%TYPE default null
);

function is_symlink (
  --/** Determines if the item is a symlink
  --    @author Karl Goldstein
  --    @param item_id The item id
  --    @return 't' if the item is a symlink, 'f' otherwise
  --    @see {content_symlink.new}, {content_symlink.resolve}
  --*/
  item_id	   in cr_items.item_id%TYPE
) return char;


function resolve (
  --/** Resolves the symlink and returns the target item id. 
  --    @author Karl Goldstein
  --    @param item_id The item id to be resolved
  --    @return The target item of the symlink, or the original item id if
  --            the item is not in fact a symlink
  --    @see {content_symlink.new}, {content_symlink.is_symlink}
  --*/
  item_id	in cr_items.item_id%TYPE
) return cr_items.item_id%TYPE;


function resolve_content_type (
  --/** Gets the content type of the target item.
  --    @author Michael Pih
  --    @param item_id The item id to be resolved
  --    @return The content type of the symlink target, otherwise null.
  --            the item is not in fact a symlink
  --    @see {content_symlink.resolve}
  --*/
  item_id	in cr_items.item_id%TYPE
) return cr_items.content_type%TYPE;


end content_symlink;
/
show errors

create or replace package content_extlink
as

function new (
  --/** Create a new extlink, an item pointing to an off-site resource
  --    @author Karl Goldstein
  --    @param name          The name for the new extlink, defaults to the name of the
  --                         target item
  --    @param url           The URL of the item 
  --    @param label         The text label or title of the item
  --    @param description   A brief description of the item
  --    @param parent_id     The parent folder for the extlink. This must actually be a folder
  --                         and not a generic content item.
  --    @param extlink_id    The id of the new extlink. A new id will be allocated by default
  --    @param creation_date As in <tt>acs_object.new</tt>
  --    @param creation_ip   As in <tt>acs_object.new</tt>
  --    @param creation_user As in <tt>acs_object.new</tt>
  --    @return The id of the newly created extlink
  --    @see {acs_object.new}, {content_item.new}, {content_extlink.resolve}
  --*/
  name          in cr_items.name%TYPE default null,
  url   	in cr_extlinks.url%TYPE,
  label   	in cr_extlinks.label%TYPE default null,
  description   in cr_extlinks.description%TYPE default null,
  parent_id     in cr_items.parent_id%TYPE,
  extlink_id	in cr_extlinks.extlink_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE
			   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
			   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  package_id    in acs_objects.package_id%TYPE default null
) return cr_extlinks.extlink_id%TYPE;


procedure del (
  --/** Deletes the extlink
  --    @author Karl Goldstein
  --    @param extlink_id The id of the extlink to delete
  --    @see {content_extlink.new}, {acs_object.delete}
  --*/
  extlink_id	in cr_extlinks.extlink_id%TYPE
);


function is_extlink (
  --/** Determines if the item is a extlink
  --    @author Karl Goldstein
  --    @param item_id The item id
  --    @return 't' if the item is a extlink, 'f' otherwise
  --    @see {content_extlink.new}, {content_extlink.resolve}
  --*/
  item_id	   in cr_items.item_id%TYPE
) return char;

procedure copy (
  extlink_id		in cr_extlinks.extlink_id%TYPE,
  target_folder_id	in cr_folders.folder_id%TYPE,
  creation_user		in acs_objects.creation_user%TYPE,
  creation_ip		in acs_objects.creation_ip%TYPE default null,
  name                  in cr_items.name%TYPE default null
);

end content_extlink;
/
show errors

create or replace package content_folder
as

function new (
  --/** Create a new folder
  --    @author Karl Goldstein
  --    @param label        The label for the folder
  --    @param description  A short description of the folder, 4000 characters maximum
  --    @param parent_id    The parent of the folder
  --    @param folder_id    The id of the new folder. A new id will be allocated by default
  --    @param context_id  The context id. The parent id will be used as the default context
  --    @param creation_date As in <tt>acs_object.new</tt>
  --    @param creation_ip   As in <tt>acs_object.new</tt>
  --    @param creation_user As in <tt>acs_object.new</tt>
  --    @param package_id  The package id.
  --    @return The id of the newly created folder
  --    @see {acs_object.new}, {content_item.new}
  --*/
  name          in cr_items.name%TYPE,
  label         in cr_folders.label%TYPE,
  description   in cr_folders.description%TYPE default null,
  parent_id     in cr_items.parent_id%TYPE default null,
  context_id	in acs_objects.context_id%TYPE default null,
  folder_id	in cr_folders.folder_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE default sysdate,
  creation_user	in acs_objects.creation_user%TYPE default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  security_inherit_p in acs_objects.security_inherit_p%TYPE default 't',
  package_id	in acs_objects.package_id%TYPE default null
) return cr_folders.folder_id%TYPE;

procedure del (
  --/** Delete a folder. An error is thrown if the folder is not empty
  --    @author Karl Goldstein
  --    @param folder_id    The id of the folder to delete
  --    @see {acs_object.delete}, {content_item.delete}
  --*/
  folder_id	in cr_folders.folder_id%TYPE,
  cascade_p     in char default 'f' 
);

procedure edit_name (
  --/** Change the name, label and/or description of the folder
  --    @author Karl Goldstein
  --    @param folder_id    The id of the folder to modify
  --    @param name         The new name for the folder. An error will be thrown if 
  --                        an item with this name already exists under this folder's
  --                        parent. If this parameter is null, the old name will be preserved
  --    @param label        The new label for the folder. The old label will be preserved if
  --                        this parameter is null
  --    @param label        The new description for the folder. The old description
  --                        will be preserved if this parameter is null
  --    @see {content_folder.new}
  --*/
  folder_id	 in cr_folders.folder_id%TYPE,
  name           in cr_items.name%TYPE default null,
  label  	 in cr_folders.label%TYPE default null,
  description    in cr_folders.description%TYPE default null
);

procedure move (
  --/** Recursively move the folder and all items in into a new location. 
  --    An error is thrown if either of the parameters is not a folder. 
  --    The root folder of the sitemap and the root folder of the
  --    templates cannot be moved.
  --    @author Karl Goldstein
  --    @param folder_id         The id of the folder to move
  --    @param target_folder_id  The destination folder
  --    @see {content_folder.new}, {content_folder.copy}
  --*/
  folder_id		in cr_folders.folder_id%TYPE,
  target_folder_id	in cr_folders.folder_id%TYPE,
  name                  in cr_items.name%TYPE default null
);

procedure copy (
  --/** Recursively copy the folder and all items in into a new location. 
  --    An error is thrown if either of the parameters is not a folder. 
  --    The root folder of the sitemap and the root folder of the
  --    templates cannot be copied
  --    @author Karl Goldstein
  --    @param folder_id         The id of the folder to copy
  --    @param target_folder_id  The destination folder
  --    @param creation_user	 The id of the creation user
  --	@param creation_ip	 The IP address of the creation user (defaults to null)
  --    @see {content_folder.new}, {content_folder.copy}
  --*/
  folder_id		in cr_folders.folder_id%TYPE,
  target_folder_id	in cr_folders.folder_id%TYPE,
  creation_user		in acs_objects.creation_user%TYPE,
  creation_ip		in acs_objects.creation_ip%TYPE default null,
  name                  in cr_items.name%TYPE default null
);

function is_folder (
  --/** Determine if the item is a folder
  --    @author Karl Goldstein
  --    @param item_id         The item id
  --    @return 't' if the item is a folder, 'f' otherwise
  --    @see {content_folder.new}, {content_folder.is_sub_folder}
  --*/
  item_id	  in cr_items.item_id%TYPE
) return char;

function is_sub_folder (
  --/** Determine if the item <tt>target_folder_id</tt> is a subfolder of
  --    the item <tt>folder_id</tt>
  --    @author Karl Goldstein
  --    @param folder_id        The superfolder id
  --    @param target_folder_id The subfolder id 
  --    @return 't' if the item <tt>target_folder_id</tt> is a subfolder of
  --            the item <tt>folder_id</tt>, 'f' otherwise
  --    @see {content_folder.is_folder}
  --*/
  folder_id		in cr_folders.folder_id%TYPE,
  target_folder_id	in cr_folders.folder_id%TYPE
) return char;

function is_empty (
  --/** Determine if the folder is empty
  --    @author Karl Goldstein
  --    @param folder_id        The folder id
  --    @return 't' if the folder contains no subfolders or items, 'f' otherwise
  --    @see {content_folder.is_folder}
  --*/
  folder_id  in cr_folders.folder_id%TYPE
) return varchar2;

function is_root (
  --/** Determine whether the folder is a root (has a parent_id of 0)
  --    @author Karl Goldstein
  --    @param folder_id    The folder ID
  --    @return 't' if the folder is a root or 'f' otherwise
  --*/
  folder_id in cr_folders.folder_id%TYPE
) return char;

procedure register_content_type (
  --/** Register a content type to the folder, if it is not already registered.
  --    Only items of the registered type(s) may be added to the folder.
  --    @author Karl Goldstein
  --    @param folder_id        The folder id
  --    @param content_type     The content type to be registered
  --    @see {content_folder.unregister_content_type}, 
  --         {content_folder.is_registered}
  --*/
  folder_id		in cr_folders.folder_id%TYPE,
  content_type		in cr_folder_type_map.content_type%TYPE,
  include_subtypes	in varchar2 default 'f'
);

procedure unregister_content_type (
  --/** Unregister a content type from the folder, if it has been registered.
  --    Only items of the registered type(s) may be added to the folder.
  --    If the folder already contains items of the type to be unregistered, the
  --    items remain in the folder.
  --    @author Karl Goldstein
  --    @param folder_id        The folder id
  --    @param content_type     The content type to be unregistered
  --    @param include_subtypes If 't', all subtypes of <tt>content_type</tt> will be
  --                            unregistered as well
  --    @see {content_folder.register_content_type}, {content_folder.is_registered}
  --*/
  folder_id		in cr_folders.folder_id%TYPE,
  content_type		in cr_folder_type_map.content_type%TYPE,
  include_subtypes	in varchar2 default 'f'
);

-- change this to is_type_registered
function is_registered (
  --/** Determines if a content type is registered to the folder
  --    Only items of the registered type(s) may be added to the folder.
  --    @author Karl Goldstein
  --    @param folder_id        The folder id
  --    @param content_type     The content type to be checked
  --    @param include_subtypes If 't', all subtypes of the <tt>content_type</tt> 
  --                            will be checked, returning 't' if all of them are registered. If 'f',
  --                            only an exact match with <tt>content_type</tt> will be
  --                            performed.
  --    @return 't' if the type is registered to this folder, 'f' otherwise                        
  --    @see {content_folder.register_content_type}, {content_folder.unregister_content_type}, 
  --*/
  folder_id		in cr_folders.folder_id%TYPE,
  content_type		in cr_folder_type_map.content_type%TYPE,
  include_subtypes	in varchar2 default 'f'
) return varchar2;


function get_label (
  --/** Returns the label for the folder. This function is the default name method
  --    for the folder object.
  --    @author Karl Goldstein
  --    @param folder_id        The folder id
  --    @return The folder's label
  --    @see {acs_object_type.create_type}, the docs for the name_method parameter
  --*/
  folder_id in cr_folders.folder_id%TYPE
) return cr_folders.label%TYPE;


function get_index_page (
  --/** Returns the item ID of the index page of the folder, null otherwise
  --    @author Michael Pih
  --    @param folder_id	The folder id
  --    @return The item ID of the index page
  --*/
  folder_id in cr_folders.folder_id%TYPE
) return cr_items.item_id%TYPE;



end content_folder;
/
show errors



create or replace package content_template
as

c_root_folder_id constant integer := -200;

function get_root_folder return cr_folders.folder_id%TYPE;

function new (
  --/** Creates a new content template which can be used to render content items.
  --    @author Karl Goldstein
  --    @param name          The name for the template, must be a valid UNIX-like filename.
  --                         If a template with this name already exists under the specified
  --                         parent item, an error is thrown
  --    @param text          The body of the .adp template itself, defaults to null
  --    @param parent_id     The parent of this item, defaults to null
  --    @param is_live       The should the revision be set live, defaults to 't'. Requires
  --                         that text is not null or there will be no revision to begin with                             
  --    @param template_id   The id of the new template. A new id will be allocated if this
  --                         parameter is null
  --    @param creation_date As in <tt>acs_object.new</tt>
  --    @param creation_ip   As in <tt>acs_object.new</tt>
  --    @param creation_user As in <tt>acs_object.new</tt>
  --    @return The id of the newly created template
  --    @see {acs_object.new}, {content_item.new}, {content_item.register_template},
  --         {content_type.register_template}
  --*/
  name          in cr_items.name%TYPE,
  text          in varchar2 default null,
  parent_id     in cr_items.parent_id%TYPE default null,
  is_live 		in char default 't',
  template_id	in cr_templates.template_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE
			   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
			   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  package_id    in acs_objects.package_id%TYPE default null
) return cr_templates.template_id%TYPE;

procedure del (
  --/** Deletes the specified template, and unregisters the template from
  --    all content types and content items.
  --    Use with caution - this operation cannot be undone.
  --    @author Karl Goldstein
  --    @param template_id        The id of the template to delete
  --    @see {acs_object.delete}, {content_item.unregister_template}, 
  --         {content_type.unregister_template},
  --*/
  template_id	in cr_templates.template_id%TYPE
);

function is_template (
  --/** Determine if an item is a template.
  --    @author Karl Goldstein
  --    @param item_id  The item id        
  --    @return 't' if the item is a template, 'f' otherwise
  --    @see {content_template.new}
  --*/
  template_id	in cr_templates.template_id%TYPE
) return varchar2;

function get_path (
  --/** Retrieves the full path to the template, as described in content_item.get_path
  --    @author Karl Goldstein
  --    @param template_id        The id of the template for which the path is to 
  --                              be retrieved
  --    @param root_folder_id     Starts path resolution at this folder
  --    @return The path to the template, starting with the specified root folder
  --    @see {content_item.get_path}
  --*/
  template_id    in cr_templates.template_id%TYPE,
  root_folder_id in cr_folders.folder_id%TYPE default c_root_folder_id
) return varchar2;

end content_template;
/
show errors

create or replace package content_keyword
as

function new (
  --/** Creates a new keyword (also known as "subject category").
  --    @author Karl Goldstein
  --    @param heading       The heading for the new keyword
  --    @param description   The description for the new keyword
  --    @param parent_id     The parent of this keyword, defaults to null.
  --    @param keyword_id    The id of the new keyword. A new id will be allocated if this
  --                         parameter is null
  --    @param object_type   The type for the new keyword, defaults to 'content_keyword'.
  --                         This parameter may be used by subclasses of 
  --                         <tt>content_keyword</tt> to initialize the superclass.
  --    @param creation_date As in <tt>acs_object.new</tt>
  --    @param creation_ip   As in <tt>acs_object.new</tt>
  --    @param creation_user As in <tt>acs_object.new</tt>
  --    @return The id of the newly created keyword
  --    @see {acs_object.new}, {content_item.new}, {content_keyword.item_assign},
  --         {content_keyword.delete}
  --*/
  heading       in cr_keywords.heading%TYPE,
  description   in cr_keywords.description%TYPE default null,
  parent_id     in cr_keywords.parent_id%TYPE default null,
  keyword_id    in cr_keywords.keyword_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE
			   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
			   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  object_type   in acs_object_types.object_type%TYPE default 'content_keyword',
  package_id    in acs_objects.package_id%TYPE default null
) return cr_keywords.keyword_id%TYPE;

procedure del (
  --/** Deletes the specified keyword, which must be a leaf. Unassigns the
  --    keyword from all content items.  Use with caution - this
  --    operation cannot be undone.
  --    @author Karl Goldstein
  --    @param keyword_id The id of the keyword to be deleted
  --    @see {acs_object.delete}, {content_keyword.item_unassign}
  --*/  
  keyword_id  in cr_keywords.keyword_id%TYPE
);

function get_heading (
  --/** Retrieves the heading of the content keyword
  --    @author Karl Goldstein
  --    @param keyword_id         The keyword id
  --    @return The heading for the specified keyword
  --    @see {content_keyword.set_heading}, {content_keyword.get_description}
  --*/
  keyword_id  in cr_keywords.keyword_id%TYPE
) return varchar2;

function get_description (
  --/** Retrieves the description of the content keyword
  --    @author Karl Goldstein
  --    @param keyword_id         The keyword id
  --    @return The description for the specified keyword
  --    @see {content_keyword.get_heading}, {content_keyword.set_description}
  --*/
  keyword_id  in cr_keywords.keyword_id%TYPE
) return varchar2;

procedure set_heading (
  --/** Sets a new heading for the keyword
  --    @author Karl Goldstein
  --    @param keyword_id         The keyword id
  --    @param heading            The new heading
  --    @see {content_keyword.get_heading}, {content_keyword.set_description}
  --*/
  keyword_id  in cr_keywords.keyword_id%TYPE,
  heading     in cr_keywords.heading%TYPE
);

procedure set_description (
  --/** Sets a new description for the keyword
  --    @author Karl Goldstein
  --    @param keyword_id         The keyword id
  --    @param description        The new description
  --    @see {content_keyword.set_heading}, {content_keyword.get_description}
  --*/
  keyword_id  in cr_keywords.keyword_id%TYPE,
  description in cr_keywords.description%TYPE
);

function is_leaf (
  --/** Determines if the keyword has no sub-keywords associated with it
  --    @author Karl Goldstein
  --    @param keyword_id         The keyword id
  --    @return 't' if the keyword has no descendants, 'f' otherwise
  --    @see {content_keyword.new}
  --*/
  keyword_id  in cr_keywords.keyword_id%TYPE
) return varchar2;

procedure item_assign (
  --/** Assigns this keyword to a content item, creating a relationship between them
  --    @author Karl Goldstein
  --    @param item_id            The item to be assigned to
  --    @param keyword_id         The keyword to be assigned
  --    @param context_id         As in <tt>acs_rel.new</tt>, deprecated
  --    @param creation_ip        As in <tt>acs_rel.new</tt>, deprecated
  --    @param creation_user      As in <tt>acs_rel.new</tt>, deprecated
  --    @see {acs_rel.new}, {content_keyword.item_unassign}
  --*/
  item_id       in cr_items.item_id%TYPE,
  keyword_id    in cr_keywords.keyword_id%TYPE, 
  context_id	in acs_objects.context_id%TYPE default null,
  creation_user in acs_objects.creation_user%TYPE default null,
  creation_ip   in acs_objects.creation_ip%TYPE default null
);

procedure item_unassign (
  --/** Unassigns this keyword to a content item, removing a relationship between them
  --    @author Karl Goldstein
  --    @param item_id            The item to be unassigned from
  --    @param keyword_id         The keyword to be unassigned
  --    @see {acs_rel.delete}, {content_keyword.item_assign}
  --*/
  item_id     in cr_items.item_id%TYPE,
  keyword_id  in cr_keywords.keyword_id%TYPE 
);  

function is_assigned (
  --/** Determines if the keyword is assigned to the item
  --    @author Karl Goldstein
  --    @param item_id            The item id
  --    @param keyword_id         The keyword id to be checked for assignment
  --    @param recurse            Specifies if the keyword search is 
  --                              recursive. May be set to one of the following
  --                              values:<ul>
  --     <li><b>none</b>: Not recursive. Look for an exact match.</li>
  --     <li><b>up</b>: Recursive from specific to general. A search for 
  --       "attack dogs" will also match "dogs", "animals", "mammals", etc.</li>
  --     <li><b>down</b>: Recursive from general to specific. A search for
  --       "mammals" will also match "dogs", "attack dogs", "cats", "siamese cats",
  --       etc.</li></ul>
  --    @return 't' if the keyword may be matched to an item, 'f' otherwise
  --    @see {content_keyword.item_assign}
  --*/
  item_id      in cr_items.item_id%TYPE,
  keyword_id   in cr_keywords.keyword_id%TYPE,
  recurse      in varchar2 default 'none'
) return varchar2;

function get_path (
  --/** Retrieves a path to the keyword/subject category, with the most general 
  --    category at the root of the path
  --    @author Karl Goldstein
  --    @param keyword_id         The keyword id 
  --    @return The path to the keyword, or null if no such keyword exists
  --    @see {content_keyword.new}
  --*/
  keyword_id in cr_keywords.keyword_id%TYPE
) return varchar2;

end content_keyword;
/
show errors




create or replace package content_permission 
is

  procedure inherit_permissions (
    --/** Make the child object inherit all of the permissions of the parent
    --    object. Typically, this function is called whenever a new object 
    --    is created under a given parent
    --    @author Karl Goldstein
    --    @param parent_object_id   The parent object id
    --    @param child_object_id    The child object id
    --    @see {content_permission.grant}, {acs_permission.grant_permission}
    --*/  
    parent_object_id  in acs_objects.object_id%TYPE,
    child_object_id   in acs_objects.object_id%TYPE,
    child_creator_id  in parties.party_id%TYPE default null
  );

  function has_grant_authority (
    --/** Determine if the user may grant a certain permission to another
    --    user. The permission may only be granted if the user has 
    --    the permission himself and possesses the cm_perm access, or if the
    --    user possesses the cm_perm_admin access.
    --    @author Karl Goldstein
    --    @param object_id   The object whose permissions are to be changed
    --    @param holder_id   The person who is attempting to grant the permissions
    --    @param privilege   The privilege to be granted
    --    @return 't' if the donation is possible, 'f' otherwise
    --    @see {content_permission.grant_permission}, {content_permission.is_has_revoke_authority},
    --         {acs_permission.grant_permission}
    --*/
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE, 
    privilege         in acs_privileges.privilege%TYPE
  ) return varchar2;
   
  procedure grant_permission_h (
    --/** This is a helper function for content_permission.grant_permission and
    --    should not be called individually.<p>
    --    Grants a permission and revokes all descendants of the permission, since
    --    they are no longer relevant.
    --    @author Karl Goldstein
    --    @param object_id     The object whose permissions are to be changed
    --    @param grantee_id    The person who should gain the parent privilege
    --    @param privilege     The parent privilege to be granted
    --    @see {content_permission.grant_permission}
    --*/
    object_id         in acs_objects.object_id%TYPE,
    grantee_id        in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  );

  procedure grant_permission (
    --/** Grant the specified privilege to another user. If the donation is
    --    not possible, the procedure does nothing.
    --    @author Karl Goldstein
    --    @param object_id     The object whose permissions are to be changed
    --    @param holder_id     The person who is attempting to grant the permissions
    --    @param privilege     The privilege to be granted
    --    @param recipient_id  The person who will gain the privilege 
    --    @param is_recursive  If 't', applies the donation recursively to
    --      all child objects of the object (equivalent to UNIX's <tt>chmod -r</tt>).
    --      If 'f', only affects the objects itself.
    --    @see {content_permission.has_grant_authority}, {content_permission.revoke_permission},
    --         {acs_permission.grant_permission}
    --*/
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    recipient_id      in parties.party_id%TYPE,
    is_recursive      in varchar2 default 'f',
    object_type       in acs_objects.object_type%TYPE default 'content_item'
  );

  function has_revoke_authority (
    --/** Determine if the user may take a certain permission away from another
    --    user. The permission may only be revoked if the user has 
    --    the permission himself and possesses the cm_perm access, while the
    --    other user does not, or if the user possesses the cm_perm_admin access.
    --    @author Karl Goldstein
    --    @param object_id   The object whose permissions are to be changed
    --    @param holder_id   The person who is attempting to revoke the permissions
    --    @param privilege   The privilege to be revoked
    --    @param revokee_id  The user from whom the privilege is to be taken away
    --    @return 't' if it is possible to revoke the privilege, 'f' otherwise
    --    @see {content_permission.has_grant_authority}, {content_permission.revoke_permission},
    --         {acs_permission.revoke_permission}
    --*/
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    revokee_id        in parties.party_id%TYPE
  ) return varchar2;

  procedure revoke_permission_h (
    --/** This is a helper function for content_permission.revoke_permission and
    --    should not be called individually.<p>
    --    Revokes a permission but grants all child permissions to the holder, to
    --    ensure that the permission is not permanently lost
    --    @author Karl Goldstein
    --    @param object_id     The object whose permissions are to be changed
    --    @param revokee_id    The person who should lose the parent permission
    --    @param privilege     The parent privilege to be revoked
    --    @see {content_permission.revoke_permission}
    --*/
    object_id         in acs_objects.object_id%TYPE,
    revokee_id        in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  );

  procedure revoke_permission (
    --/** Take the specified privilege away from another user. If the operation is
    --    not possible, the procedure does nothing.
    --    @author Karl Goldstein
    --    @param object_id     The object whose permissions are to be changed
    --    @param holder_id     The person who is attempting to revoke the permissions
    --    @param privilege     The privilege to be revoked 
    --    @param recipient_id  The person who will lose the privilege 
    --    @param is_recursive  If 't', applies the operation recursively to
    --      all child objects of the object (equivalent to UNIX's <tt>chmod -r</tt>).
    --      If 'f', only affects the objects itself.
    --    @see {content_permission.grant_permission}, {content_permission.has_revoke_authority},
    --         {acs_permission.revoke_permission}
    --*/
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE,
    revokee_id        in parties.party_id%TYPE,
    is_recursive      in varchar2 default 'f',
    object_type       in acs_objects.object_type%TYPE default 'content_item'
  );

  function permission_p (
    --/** Determine if the user has the specified permission on the specified 
    --    object. Does NOT check objects recursively: that is, if the user has
    --    the permission on the parent object, he does not automatically gain 
    --    the permission on all the child objects.
    --    @author Karl Goldstein
    --    @param object_id     The object whose permissions are to be checked
    --    @param holder_id     The person whose permissions are to be examined
    --    @param privilege     The privilege to be checked
    --    @return 't' if the user has the specified permission on the object, 
    --                'f' otherwise
    --    @see {content_permission.grant_permission}, {content_permission.revoke_permission},
    --         {acs_permission.permission_p}
    --*/
    object_id         in acs_objects.object_id%TYPE,
    holder_id         in parties.party_id%TYPE,
    privilege         in acs_privileges.privilege%TYPE
  ) return varchar2;

  function cm_admin_exists 
    -- /** Determine if there exists a user who has administrative 
    --     privileges on the entire content repository.
    --     @author Stanislav Freidin
    --     @return 't' if an administrator exists, 'f' otherwise
    --     @see {content_permission.grant_permission}
  return varchar2;

end content_permission;
/
show errors

@@content-type
@@content-item
@@content-revision
@@content-symlink
@@content-extlink
@@content-folder
@@content-template
@@content-keyword


