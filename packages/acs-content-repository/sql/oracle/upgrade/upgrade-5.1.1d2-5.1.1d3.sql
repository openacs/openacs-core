
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
  storage_type  in cr_items.storage_type%TYPE default 'lob'
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
  creation_ip	in acs_objects.creation_ip%TYPE default null
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

create or replace package body content_item
as

function get_root_folder (
  item_id  in cr_items.item_id%TYPE default null
) return cr_folders.folder_id%TYPE is

  v_folder_id cr_folders.folder_id%TYPE;

begin

  if item_id is NULL then

    v_folder_id := c_root_folder_id;

  else

    select
      item_id into v_folder_id
    from
      cr_items
    where 
      parent_id = 0
    connect by
      prior parent_id = item_id
    start with
      item_id = get_root_folder.item_id;
    
  end if;    

  return v_folder_id;

exception
  when NO_DATA_FOUND then
    raise_application_error(-20000, 
      'Could not find a root folder for item ID ' || item_id || '.  ' ||
      'Either the item does not exist or its parent value is corrupted.');
end get_root_folder;

function new (
  name          in cr_items.name%TYPE,
  parent_id     in cr_items.parent_id%TYPE default null,
  item_id	in acs_objects.object_id%TYPE default null,
  locale        in cr_items.locale%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE
			   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
			   default null,
  context_id    in acs_objects.context_id%TYPE
                           default null,
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
  storage_type  in cr_items.storage_type%TYPE default 'lob'
) return cr_items.item_id%TYPE
is
  v_parent_id      cr_items.parent_id%TYPE;
  v_parent_type    acs_objects.object_type%TYPE;
  v_item_id	   cr_items.item_id%TYPE;
  v_revision_id    cr_revisions.revision_id%TYPE;
  v_title	   cr_revisions.title%TYPE;
  v_rel_id	   acs_objects.object_id%TYPE;
  v_rel_tag        cr_child_rels.relation_tag%TYPE;
  v_context_id     acs_objects.context_id%TYPE;
  v_storage_type   cr_items.storage_type%TYPE;
begin

  -- if content_item.is_subclass(item_subtype,'content_item') = 'f' then
  --  raise_application_error(-20000, 'The object_type ' || item_subtype || 
  --    ' does not inherit from content_item.');
  -- end if;

  -- place the item in the context of the pages folder if no
  -- context specified 

  if storage_type = 'text' then
     v_storage_type := 'lob';
  else 
     v_storage_type := storage_type;
  end if;

  if parent_id is null then
    v_parent_id := c_root_folder_id;
  else
    v_parent_id := parent_id;
  end if;

  -- Determine context_id
  if context_id is null then
    v_context_id := v_parent_id;
  else
    v_context_id := context_id;
  end if;

  if v_parent_id = 0 or 
    content_folder.is_folder(v_parent_id) = 't' then

    if v_parent_id ^= 0 and 
      content_folder.is_registered(
        v_parent_id, content_item.new.content_type, 'f') = 'f' then

      raise_application_error(-20000, 
        'This item''s content type ' || content_item.new.content_type ||
        ' is not registered to this folder ' || v_parent_id);

    end if;

  elsif v_parent_id ^= 0 then

    begin

     -- Figure out the relation_tag to use
     if content_item.new.relation_tag is null then
       v_rel_tag := content_item.get_content_type(v_parent_id) 
         || '-' || content_item.new.content_type;
     else
       v_rel_tag := content_item.new.relation_tag;
     end if;

     select object_type into v_parent_type from acs_objects
       where object_id = v_parent_id;

     if is_subclass(v_parent_type, 'content_item') = 't' and
	is_valid_child(v_parent_id, content_item.new.content_type, v_rel_tag) = 'f' then

       raise_application_error(-20000, 
	 'This item''s content type ' || content_item.new.content_type ||
	 ' is not allowed in this container ' || v_parent_id);

     end if;

     exception when NO_DATA_FOUND then

       raise_application_error(-20000,
	 'Invalid parent ID ' || v_parent_id || 
	 ' specified in content_item.new');

    end;

  end if;

  -- Create the object

  v_item_id := acs_object.new(
      object_id	        => content_item.new.item_id,
      object_type	=> content_item.new.item_subtype, 
      context_id        => v_context_id,
      creation_date	=> content_item.new.creation_date, 
      creation_user	=> content_item.new.creation_user, 
      creation_ip	=> content_item.new.creation_ip 
  );

  -- Turn off security inheritance if there is no security context
  --if context_id is null then
  --  update acs_objects set security_inherit_p = 'f'
  --    where object_id = v_item_id;
  --end if;

  insert into cr_items (
    item_id, name, content_type, parent_id, storage_type
  ) values (
    v_item_id, content_item.new.name, 
    content_item.new.content_type, v_parent_id, v_storage_type
  );

  -- if the parent is not a folder, insert into cr_child_rels
  -- We checked above before creating the object that it is a valid rel
  if v_parent_id ^= 0 and
    content_folder.is_folder(v_parent_id) = 'f' then

    v_rel_id := acs_object.new(
      object_type	=> 'cr_item_child_rel',
      context_id	=> v_parent_id
    );

    insert into cr_child_rels (
      rel_id, parent_id, child_id, relation_tag, order_n
    ) values (
      v_rel_id, v_parent_id, v_item_id, v_rel_tag, v_item_id
    );

  end if;

  -- use the name of the item if no title is supplied
  if content_item.new.title is null then
    v_title := content_item.new.name;
  else
    v_title := content_item.new.title;
  end if;

  -- create the revision if data or title or text is not null
  -- note that the caller could theoretically specify both text
  -- and data, in which case the text is ignored.

  if content_item.new.data is not null then

    v_revision_id := content_revision.new(
        item_id	      => v_item_id,
	title	      => v_title,
	description   => content_item.new.description,
	data	      => content_item.new.data,
	mime_type     => content_item.new.mime_type,
        creation_date => content_item.new.creation_date, 
        creation_user => content_item.new.creation_user, 
        creation_ip   => content_item.new.creation_ip,
	nls_language  => content_item.new.nls_language
    );

  elsif content_item.new.title is not null or 
      content_item.new.text is not null then

    v_revision_id := content_revision.new(
	item_id	      => v_item_id,
	title	      => v_title,
	description   => content_item.new.description,
	text	      => content_item.new.text,
	mime_type     => content_item.new.mime_type,
        creation_date => content_item.new.creation_date, 
        creation_user => content_item.new.creation_user, 
        creation_ip   => content_item.new.creation_ip
    );

  end if;

  -- make the revision live if is_live is 't'
  if content_item.new.is_live = 't' then
    content_item.set_live_revision(v_revision_id);
  end if;

  -- Have the new item inherit the permission of the parent item
  -- if no security context was specified
  --if parent_id is not null and context_id is null then
  --  content_permission.inherit_permissions (
  --    parent_id, v_item_id, creation_user
  --  );
  --end if;

  return v_item_id;
end new;

function is_published (
  item_id               in cr_items.item_id%TYPE
) return char
is
  v_is_published        char(1);
begin

  select
    't' into v_is_published
  from
    cr_items
  where
    live_revision is not null
  and
    publish_status = 'live'
  and
    item_id = is_published.item_id;

  return v_is_published;
  exception
    when NO_DATA_FOUND then
      return 'f';
end is_published;

function is_publishable (
  item_id		in cr_items.item_id%TYPE
) return char
is
  v_child_count		integer;
  v_rel_count		integer;
  v_template_id		cr_templates.template_id%TYPE;

  -- get the child types registered to this content type
  cursor c_child_types is
    select
      child_type, min_n, max_n
    from
      cr_type_children
    where
      parent_type = content_item.get_content_type( is_publishable.item_id );

  -- get the relation types registered to this content type
  cursor c_rel_types is
    select
      target_type, min_n, max_n
    from
      cr_type_relations
    where
      content_type = content_item.get_content_type( is_publishable.item_id );
  
  -- get the publishing workflows associated with this content item
  -- there should only be 1 if CMS exists, otherwise 0
  --   cursor c_pub_wf is
  --     select
  --       case_id, state
  --     from
  --       wf_cases
  --     where
  --       workflow_key = 'publishing_wf'
  --     and
  --       object_id = is_publishable.item_id;

begin

  -- validate children
  -- make sure the # of children of each type fall between min_n and max_n
  for v_child_type in c_child_types loop
    select
      count(rel_id) into v_child_count
    from
      cr_child_rels
    where
      parent_id = is_publishable.item_id
    and
      content_item.get_content_type( child_id ) = v_child_type.child_type;

    -- make sure # of children is in range
    if v_child_type.min_n is not null 
      and v_child_count < v_child_type.min_n then
      return 'f';
    end if;
    if v_child_type.max_n is not null
      and v_child_count > v_child_type.max_n then
      return 'f';
    end if;

  end loop;


  -- validate relations
  -- make sure the # of ext links of each type fall between min_n and max_n
  for v_rel_type in c_rel_types loop
    select
      count(rel_id) into v_rel_count
    from
      cr_item_rels i, acs_objects o
    where
      i.related_object_id = o.object_id
    and
      i.item_id = is_publishable.item_id
    and
      nvl(content_item.get_content_type(o.object_id),o.object_type) = v_rel_type.target_type;
      
    -- make sure # of object relations is in range
    if v_rel_type.min_n is not null 
      and v_rel_count < v_rel_type.min_n then
      return 'f';
    end if;
    if v_rel_type.max_n is not null 
      and v_rel_count > v_rel_type.max_n then
      return 'f';
    end if;
  end loop;

  -- validate publishing workflows
  -- make sure any 'publishing_wf' associated with this item are finished
  -- KG: logic is wrong here.  Only the latest workflow matters, and even
  -- that is a little problematic because more than one workflow may be
  -- open on an item.  In addition, this should be moved to CMS.

  -- Removed this as having workflow stuff in the CR is just plain wrong.
  -- DanW, Aug 25th, 2001.

  --   for v_pub_wf in c_pub_wf loop
  --     if v_pub_wf.state ^= 'finished' then
  --        return 'f';
  --     end if;
  --   end loop;

  return 't';
    exception
      when NO_DATA_FOUND then
        return 'f';
end is_publishable;

function is_valid_child (
  item_id		in cr_items.item_id%TYPE,
  content_type		in acs_object_types.object_type%TYPE,
  relation_tag          in cr_child_rels.relation_tag%TYPE default null
) return char
is
  v_is_valid_child      char(1);
  v_max_children	cr_type_children.max_n%TYPE;
  v_n_children		integer;
begin

  v_is_valid_child := 'f';

  -- first check if content_type is a registered child_type
  begin
    select
      sum(max_n) into v_max_children
    from
      cr_type_children
    where
      parent_type = content_item.get_content_type( is_valid_child.item_id )
    and
      child_type = is_valid_child.content_type
    and 
      (is_valid_child.relation_tag is null 
       or is_valid_child.relation_tag = relation_tag);

    exception
      when NO_DATA_FOUND then
        return 'f';
  end;

  -- if the max is null then infinite number is allowed
  if v_max_children is null then
    return 't';
  end if;

  -- next check if there are already max_n children of that content type
  select
    count(rel_id) into v_n_children
  from
    cr_child_rels
  where
    parent_id = is_valid_child.item_id
  and
    content_item.get_content_type( child_id ) = is_valid_child.content_type
  and 
    (is_valid_child.relation_tag is null 
     or is_valid_child.relation_tag = relation_tag);

  if v_n_children < v_max_children then
    v_is_valid_child := 't';
  end if;

  return v_is_valid_child;
  exception
    when NO_DATA_FOUND then
      return 'f';
end is_valid_child;

/* delete a content item
 1) delete all associated workflows
 2) delete all symlinks associated with this object
 3) delete any revisions for this item
 4) unregister template relations
 5) delete all permissions associated with this item
 6) delete keyword associations
 7) delete all associated comments */
procedure del (
  item_id in cr_items.item_id%TYPE
) is

--  cursor c_wf_cases_cur is
--    select
--      case_id
--    from
--      wf_cases
--    where
--      object_id = item_id;

  cursor c_symlink_cur is
    select 
      symlink_id
    from 
      cr_symlinks
    where 
      target_id = content_item.del.item_id;

  cursor c_revision_cur is
    select
      revision_id 
    from
      cr_revisions
    where
      item_id = content_item.del.item_id;

  cursor c_rel_cur is
    select
      rel_id
    from
      cr_item_rels
    where
      item_id = content_item.del.item_id
    or
      related_object_id = content_item.del.item_id;      

  cursor c_child_cur is
    select
      rel_id
    from
      cr_child_rels
    where
      child_id = content_item.del.item_id;

  cursor c_parent_cur is
    select
      rel_id, child_id
    from
      cr_child_rels
    where
      parent_id = content_item.del.item_id;

  --  this is strictly for debugging
  --  cursor c_error_cur is
  --    select
  --      object_id, object_type
  --    from
  --      acs_objects
  --    where
  --      context_id = content_item.delete.item_id;

begin

  -- Removed this as having workflow stuff in the CR is just plain wrong.
  -- DanW, Aug 25th, 2001.

  -- dbms_output.put_line('Deleting associated workflows...');
  -- 1) delete all workflow cases associated with this item
  -- for v_wf_cases_val in c_wf_cases_cur loop
  --   workflow_case.delete(v_wf_cases_val.case_id);
  -- end loop;

  dbms_output.put_line('Deleting symlinks...');
  -- 2) delete all symlinks to this item
  for v_symlink_val in c_symlink_cur loop
    content_symlink.del(v_symlink_val.symlink_id);
  end loop;

  dbms_output.put_line('Unscheduling item...');
  delete from cr_release_periods
    where item_id = content_item.del.item_id;

  dbms_output.put_line('Deleting associated revisions...');
  -- 3) delete all revisions of this item
  delete from cr_item_publish_audit
    where item_id = content_item.del.item_id;
  for v_revision_val in c_revision_cur loop
    content_revision.del(v_revision_val.revision_id);
  end loop;
  
  dbms_output.put_line('Deleting associated item templates...');
  -- 4) unregister all templates to this item
  delete from cr_item_template_map
    where item_id = content_item.del.item_id; 

  dbms_output.put_line('Deleting item relationships...');
  -- Delete all relations on this item
  for v_rel_val in c_rel_cur loop
    acs_rel.del(v_rel_val.rel_id);
  end loop;  

  dbms_output.put_line('Deleting child relationships...');
  for v_rel_val in c_child_cur loop
    acs_rel.del(v_rel_val.rel_id);
  end loop;  

  dbms_output.put_line('Deleting parent relationships...');
  for v_rel_val in c_parent_cur loop
    acs_rel.del(v_rel_val.rel_id);
    content_item.del(v_rel_val.child_id);
  end loop;  

  dbms_output.put_line('Deleting associated permissions...');
  -- 5) delete associated permissions
  delete from acs_permissions
    where object_id = content_item.del.item_id;

  dbms_output.put_line('Deleting keyword associations...');
  -- 6) delete keyword associations
  delete from cr_item_keyword_map
    where item_id = content_item.del.item_id;

  dbms_output.put_line('Deleting associated comments...');
  -- 7) delete associated comments
  journal_entry.delete_for_object( content_item.del.item_id );

  -- context_id debugging loop
  --for v_error_val in c_error_cur loop
  --  dbms_output.put_line('ID=' || v_error_val.object_id || ' TYPE=' 
  --    || v_error_val.object_type);
  --end loop;

  dbms_output.put_line('Deleting content item...');
  acs_object.del(content_item.del.item_id);

end del;


procedure edit_name (
  item_id in cr_items.item_id%TYPE,
  name	  in cr_items.name%TYPE
) is
  cursor exists_cur is
    select
      item_id
    from 
      cr_items
    where
      cr_items.name = content_item.edit_name.name
    and 
      parent_id = (select 
		     parent_id
		   from
		     cr_items
		   where
		     cr_items.item_id = content_item.edit_name.item_id);

  exists_id integer;
begin

  open exists_cur;
  fetch exists_cur into exists_id;

  if exists_cur%NOTFOUND then
    close exists_cur;
    update cr_items
	set cr_items.name = content_item.edit_name.name
       	where cr_items.item_id = content_item.edit_name.item_id;
  else
    close exists_cur;
    if exists_id <> item_id then
      raise_application_error(-20000, 
        'An item with the name ' || name || 
        ' already exists in this directory.');
    end if;
  end if;

end edit_name;

function get_id (
  item_path      in varchar2,
  root_folder_id in cr_items.item_id%TYPE default c_root_folder_id,
  resolve_index  in char default 'f'
) return cr_items.item_id%TYPE is

  v_item_path varchar2(4000);
  v_root_folder_id cr_items.item_id%TYPE;
  parent_id integer;
  child_id integer;
  start_pos integer := 1;
  end_pos integer;
  counter integer := 0;
  item_name varchar2(200);

begin

  v_root_folder_id := nvl(root_folder_id, c_root_folder_id);

  -- If the request path is the root, then just return the root folder
  if item_path = '/' then
    return v_root_folder_id;
  end if;  

  -- Remove leading, trailing spaces, leading slashes
  v_item_path := rtrim(ltrim(trim(item_path), '/'), '/');

  parent_id := v_root_folder_id;

  -- if parent_id is a symlink, resolve it
  parent_id := content_symlink.resolve(parent_id);

  loop

    end_pos := instr(v_item_path, '/', start_pos);

    if end_pos = 0 then
      item_name := substr(v_item_path, start_pos);
    else
      item_name := substr(v_item_path, start_pos, end_pos - start_pos);
    end if;

    select 
      item_id into child_id
    from 
      cr_items
    where
      parent_id = get_id.parent_id
    and
      name = item_name;

    exit when end_pos = 0;

    parent_id := child_id;

    -- if parent_id is a symlink, resolve it
    parent_id := content_symlink.resolve(parent_id);

    start_pos := end_pos + 1;
      
  end loop;

  if get_id.resolve_index = 't' then

    -- if the item is a folder and has an index page, then return

    if content_folder.is_folder( child_id ) = 't' and
      content_folder.get_index_page( child_id ) is not null then 

      child_id := content_folder.get_index_page( child_id );

    end if;

  end if;

  return child_id;

exception
  when NO_DATA_FOUND then 
    return null;
end get_id;

function get_path (
  item_id        in cr_items.item_id%TYPE,
  root_folder_id in cr_items.item_id%TYPE default null
) return varchar2
is

  cursor c_abs_cur is
    select
      name, parent_id, level as tree_level
    from
      cr_items
    where 
      parent_id <> 0
    connect by
      prior parent_id = item_id
    start with
      item_id = get_path.item_id
    order by
      tree_level desc;

  v_count integer;
  v_name varchar2(400); 
  v_parent_id integer := 0;
  v_tree_level integer;

  v_resolved_root_id integer;

  cursor c_rel_cur is
    select
      parent_id, level as tree_level
    from
      cr_items
    where 
      parent_id <> 0
    connect by
      prior parent_id = item_id
    start with
      item_id = v_resolved_root_id
    order by
      tree_level desc;

  v_rel_parent_id integer := 0;
  v_rel_tree_level integer := 0;

  v_path varchar2(4000) := '';

begin

  -- check that the item exists
  select count(*) into v_count from cr_items where item_id = get_path.item_id;

  if v_count = 0 then
    raise_application_error(-20000, 'Invalid item ID: ' || item_id);
  end if;

  -- begin walking down the path to the item (from the repository root)
  open c_abs_cur;

  -- if the root folder is not null then prepare for a relative path

  if root_folder_id is not null then

    -- if root_folder_id is a symlink, resolve it (child items will point
    -- to the actual folder, not the symlink)

    v_resolved_root_id := content_symlink.resolve(root_folder_id);

    -- begin walking down the path to the root folder.  Discard
    -- elements of the item path as long as they are the same as the root
    -- folder

    open c_rel_cur;

    while v_parent_id = v_rel_parent_id loop
	fetch c_abs_cur into v_name, v_parent_id, v_tree_level;
	fetch c_rel_cur into v_rel_parent_id, v_rel_tree_level;
	exit when c_abs_cur%NOTFOUND or c_rel_cur%NOTFOUND;
    end loop;

    -- walk the remainder of the relative path, add a '..' for each 
    -- additional step

    loop
      exit when c_rel_cur%NOTFOUND;
      v_path := v_path || '../';
      fetch c_rel_cur into v_rel_parent_id, v_rel_tree_level;
    end loop;
    close c_rel_cur;

    -- an item relative to itself is '../item'
    if v_resolved_root_id = item_id then
	v_path := '../';
    end if;

  else
  
    -- this is an absolute path so prepend a '/'
   v_path := '/';

   -- prime the pump to be consistent with relative path execution plan
   fetch c_abs_cur into v_name, v_parent_id, v_tree_level;	

  end if;

  -- loop over the remainder of the absolute path

  loop

    v_path := v_path || v_name;

    fetch c_abs_cur into v_name, v_parent_id, v_tree_level;

    exit when c_abs_cur%NOTFOUND;

    v_path := v_path || '/';

  end loop;
  close c_abs_cur;

  return v_path;

end get_path;


function get_virtual_path (
  item_id        in cr_items.item_id%TYPE,
  root_folder_id in cr_items.item_id%TYPE default c_root_folder_id
) return varchar2
is
  v_path	varchar2(4000);
  v_item_id	cr_items.item_id%TYPE;
  v_is_folder	char(1);
  v_index	cr_items.item_id%TYPE;
begin

  -- first resolve the item
  v_item_id := content_symlink.resolve( get_virtual_path.item_id );

  v_is_folder := content_folder.is_folder( v_item_id );
  v_index := content_folder.get_index_page( v_item_id );

  -- if the folder has an index page
  if v_is_folder = 't' and v_index is not null then
    v_path := content_item.get_path( content_symlink.resolve( v_index ));
  else
    v_path := content_item.get_path( v_item_id );
  end if;

  return v_path;
  exception
    when NO_DATA_FOUND then
      return null;
end get_virtual_path;



procedure write_to_file (
  item_id     in cr_items.item_id%TYPE,
  root_path   in varchar2
)is

  blob_loc   cr_revisions.content%TYPE;
  v_revision cr_items.live_revision%TYPE;

begin
  
  v_revision := get_live_revision(item_id);
  select content into blob_loc from cr_revisions 
    where revision_id = v_revision;
  
  blob_to_file(root_path || get_path(item_id), blob_loc);

exception when no_data_found then

  raise_application_error(-20000, 'No live revision for content item' ||
    item_id || ' in content_item.write_to_file.');    

end write_to_file;  

procedure register_template (
  item_id      in cr_items.item_id%TYPE,
  template_id  in cr_templates.template_id%TYPE,
  use_context  in cr_item_template_map.use_context%TYPE
) is

begin

 -- register template if it is not already registered
  insert into cr_item_template_map (
    template_id, item_id, use_context
  ) select
    register_template.template_id,
    register_template.item_id,
    register_template.use_context
  from
    dual
  where
    not exists ( select 1
                 from
                   cr_item_template_map
                 where
                   item_id = register_template.item_id
                 and
                   template_id = register_template.template_id
                 and
                   use_context = register_template.use_context );

end register_template;

procedure unregister_template (
  item_id	in cr_items.item_id%TYPE,
  template_id   in cr_templates.template_id%TYPE default null,
  use_context   in cr_item_template_map.use_context%TYPE default null
) is

begin

  if use_context is null and template_id is null then

    delete from cr_item_template_map
      where item_id = unregister_template.item_id;

  elsif use_context is null then

    delete from cr_item_template_map
      where template_id = unregister_template.template_id
      and item_id = unregister_template.item_id;

  elsif template_id is null then

    delete from cr_item_template_map
      where item_id = unregister_template.item_id
      and use_context = unregister_template.use_context;

  else

    delete from cr_item_template_map
      where template_id = unregister_template.template_id
      and item_id = unregister_template.item_id
      and use_context = unregister_template.use_context;

  end if;

end unregister_template;

function get_template (
  item_id     in cr_items.item_id%TYPE,
  use_context in cr_item_template_map.use_context%TYPE
) return cr_templates.template_id%TYPE is

  v_template_id	 cr_templates.template_id%TYPE; 
  v_content_type cr_items.content_type%TYPE;

  cursor item_cur is
    select
      template_id
    from
      cr_item_template_map
    where
      item_id = get_template.item_id
    and
      use_context = get_template.use_context;

begin

  -- look for a template assigned specifically to this item
  open item_cur;
  fetch item_cur into v_template_id;

  -- otherwise get the default for the content type
  if item_cur%NOTFOUND then
    select 
      m.template_id
    into 
      v_template_id
    from
      cr_items i, cr_type_template_map m
    where
      i.item_id = get_template.item_id
    and
      i.content_type = m.content_type
    and
      m.use_context = get_template.use_context
    and
      m.is_default = 't';
  end if;
  close item_cur;

  return v_template_id;

exception
  when NO_DATA_FOUND then 
    if item_cur%ISOPEN then 
       close item_cur;
    end if;
    return null;
end get_template;

-- Return the object type of this item

function get_content_type (
  item_id     in cr_items.item_id%TYPE
) return cr_items.content_type%TYPE is
  v_content_type cr_items.content_type%TYPE;
begin

  select
    content_type into v_content_type
  from 
    cr_items
  where 
    item_id = get_content_type.item_id;  

  return v_content_type;
exception
  when NO_DATA_FOUND then 
    return null;
end get_content_type;

function get_live_revision (
  item_id   in cr_items.item_id%TYPE
) return cr_revisions.revision_id%TYPE is

  v_revision_id acs_objects.object_id%TYPE;

begin

  select
    live_revision into v_revision_id
  from
    cr_items
  where
    item_id = get_live_revision.item_id;

  return v_revision_id;

exception
  when NO_DATA_FOUND then 
    return null;
end get_live_revision;

procedure set_live_revision (
  revision_id    in cr_revisions.revision_id%TYPE,
  publish_status in cr_items.publish_status%TYPE default 'ready'
) is
begin

  update
    cr_items
  set
    live_revision = set_live_revision.revision_id,
    publish_status = set_live_revision.publish_status
  where
    item_id = (select
                 item_id
               from
                 cr_revisions
               where
                 revision_id = set_live_revision.revision_id);

  update
    cr_revisions
  set
    publish_date = sysdate
  where
    revision_id = set_live_revision.revision_id;

end set_live_revision;


procedure unset_live_revision (
  item_id   in cr_items.item_id%TYPE
) is
begin

  update
    cr_items
  set
    live_revision = NULL
  where
    item_id = unset_live_revision.item_id;

  -- if an items publish status is "live", change it to "ready"
  update
    cr_items
  set
    publish_status = 'production'
  where
    publish_status = 'live'
  and
    item_id = unset_live_revision.item_id;


end unset_live_revision;


procedure set_release_period (
  item_id    in cr_items.item_id%TYPE,
  start_when date default null,
  end_when   date default null
) is

  v_count integer;

begin

  select decode(count(*),0,0,1) into v_count from cr_release_periods 
    where item_id = set_release_period.item_id;

  if v_count = 0 then

    insert into cr_release_periods (
      item_id, start_when, end_when
    ) values (
      item_id, start_when, end_when
    );

  else

    update cr_release_periods
      set start_when = set_release_period.start_when,
      end_when = set_release_period.end_when
    where
      item_id = set_release_period.item_id;

  end if;

end set_release_period;


function get_revision_count (
  item_id   in cr_items.item_id%TYPE
) return number is

  v_count integer;

begin

  select
    count(*) into v_count
  from 
    cr_revisions
  where
    item_id = get_revision_count.item_id;

  return v_count;

end get_revision_count;

function get_context (
  item_id	in cr_items.item_id%TYPE
) return acs_objects.context_id%TYPE is

  v_context_id acs_objects.context_id%TYPE;

begin

  select
    context_id
  into
    v_context_id
  from
    acs_objects
  where
    object_id = get_context.item_id;

  return v_context_id;

exception when no_data_found then

  raise_application_error(-20000, 'Content item '  || item_id || 
     ' does not exist in content_item.get_context');


end get_context;

-- 1) make sure we are not moving the item to an invalid location:
--   that is, the destination folder exists and is a valid folder
-- 2) make sure the content type of the content item is registered
--   to the target folder
-- 3) update the parent_id for the item
procedure move (
  item_id		in cr_items.item_id%TYPE,
  target_folder_id	in cr_folders.folder_id%TYPE,
  name                  in cr_items.name%TYPE default null
) is
begin

  if content_folder.is_folder(item_id) = 't' then
    content_folder.move(item_id, target_folder_id, name);
  elsif content_folder.is_folder(target_folder_id) = 't' then
   

    if content_folder.is_registered( move.target_folder_id,
          get_content_type( move.item_id )) = 't' and
       content_folder.is_registered( move.target_folder_id,
          get_content_type( content_symlink.resolve( move.item_id)),'f') = 't'
      then

    -- update the parent_id for the item
    update cr_items 
      set parent_id = move.target_folder_id,
	  name = nvl (move.name, cr_items.name)
      where item_id = move.item_id;
    end if;

  end if;
end move;

procedure copy (
  item_id               in cr_items.item_id%TYPE,
  target_folder_id      in cr_folders.folder_id%TYPE,
  creation_user         in acs_objects.creation_user%TYPE,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  name                  in cr_items.name%TYPE default null
) is

  copy_id cr_items.item_id%TYPE;

begin

  copy_id := copy2(item_id, target_folder_id, creation_user, creation_ip, name);

end copy;

-- copy a content item to a target folder
-- 1) make sure we are not copying the item to an invalid location:
--   that is, the destination folder exists, is a valid folder,
--   and is not the current folder
-- 2) make sure the content type of the content item is registered
--   with the current folder
-- 3) create a new item with no revisions in the target folder
-- 4) copy the latest revision from the original item to the new item (if any)

function copy2 (
  item_id               in cr_items.item_id%TYPE,
  target_folder_id      in cr_folders.folder_id%TYPE,
  creation_user         in acs_objects.creation_user%TYPE,
  creation_ip           in acs_objects.creation_ip%TYPE default null,
  name                  in cr_items.name%TYPE default null
) return cr_items.item_id%TYPE is
  v_current_folder_id cr_folders.folder_id%TYPE;
  v_num_revisions     integer;
  v_name              cr_items.name%TYPE;
  v_content_type      cr_items.content_type%TYPE;
  v_locale            cr_items.locale%TYPE;
  v_item_id           cr_items.item_id%TYPE;
  v_revision_id       cr_revisions.revision_id%TYPE;
  v_is_registered     char(1);
  v_old_revision_id   cr_revisions.revision_id%TYPE;
  v_new_revision_id   cr_revisions.revision_id%TYPE;
  v_storage_type      cr_items.storage_type%TYPE;
begin

  -- call content_folder.copy if the item is a folder
  if content_folder.is_folder(copy2.item_id) = 't' then
    content_folder.copy(
        folder_id        => copy2.item_id,
        target_folder_id => copy2.target_folder_id,
        creation_user    => copy2.creation_user,
        creation_ip      => copy2.creation_ip,
        name             => copy2.name
    );
  -- call content_symlink.copy if the item is a symlink
  elsif content_symlink.is_symlink(copy2.item_id) = 't' then
    content_symlink.copy(
        symlink_id       => copy2.item_id,
        target_folder_id => copy2.target_folder_id,
        creation_user    => copy2.creation_user,
        creation_ip      => copy2.creation_ip,
        name             => copy2.name
    );
  -- call content_extlink.copy if the item is a extlink
  elsif content_extlink.is_extlink(copy2.item_id) = 't' then
    content_extlink.copy(
        extlink_id       => copy2.item_id,
        target_folder_id => copy2.target_folder_id,
        creation_user    => copy2.creation_user,
        creation_ip      => copy2.creation_ip,
        name             => copy2.name
    );
  -- call content_extlink.copy if the item is a extlink
  elsif content_extlink.is_extlink(copy2.item_id) = 't' then
    content_extlink.copy(
        extlink_id       => copy2.item_id,
        target_folder_id => copy2.target_folder_id,
        creation_user    => copy2.creation_user,
        creation_ip      => copy2.creation_ip
    );
  -- make sure the target folder is really a folder
  elsif content_folder.is_folder(copy2.target_folder_id) = 't' then

    select
      parent_id
    into
      v_current_folder_id
    from
      cr_items
    where
      item_id = copy2.item_id;

    select
      content_type, name , locale,
      nvl(live_revision, latest_revision), storage_type
    into
      v_content_type, v_name, v_locale, v_revision_id, v_storage_type
    from
      cr_items
    where
      item_id = copy2.item_id;

    -- can't copy to the same folder unless name is different
    if copy2.target_folder_id ^= v_current_folder_id or (v_name != copy2.name and copy2.name is not null) then

      if copy2.name is not null then
        v_name := copy2.name;
      end if;
      -- make sure the content type of the item is registered to the folder
      v_is_registered := content_folder.is_registered(
          folder_id        => copy2.target_folder_id,
          content_type     => v_content_type,
          include_subtypes => 'f'
      );

      if v_is_registered = 't' then
        -- create the new content item
        v_item_id := content_item.new(
            parent_id     => copy2.target_folder_id,
            name          => v_name,
            locale        => v_locale,
            content_type  => v_content_type,
            creation_user => copy2.creation_user,
            creation_ip   => copy2.creation_ip,
            storage_type  => v_storage_type
        );

        -- get the latest revision of the old item
        select
          latest_revision into v_old_revision_id
        from
          cr_items
        where
          item_id = copy2.item_id;

        -- copy the latest revision (if any) to the new item
        if v_old_revision_id is not null then
          v_new_revision_id := content_revision.copy (
              revision_id    => v_old_revision_id,
              target_item_id => v_item_id,
              creation_user  => copy2.creation_user,
              creation_ip    => copy2.creation_ip
          );
        end if;
      end if;


    end if;
  end if;

  return v_item_id;

end copy2;

-- get the latest revision for an item
function get_latest_revision (
  item_id       in cr_items.item_id%TYPE
) return cr_revisions.revision_id%TYPE is
  v_revision_id integer;

  cursor c_revision_cur is
    select 
      r.revision_id 
    from 
      cr_revisions r, acs_objects o
    where 
      r.revision_id = o.object_id
    and 
      r.item_id = get_latest_revision.item_id
    order by 
      o.creation_date desc;
begin

  if item_id is null then
    return null;
  end if;

  open c_revision_cur;
  fetch c_revision_cur into v_revision_id;
  if c_revision_cur%NOTFOUND then
    close c_revision_cur;
    return null;
  end if;
  close c_revision_cur;
  return v_revision_id;

exception
  when NO_DATA_FOUND then 
    if c_revision_cur%ISOPEN then
       close c_revision_cur;
    end if;
    return null;
end get_latest_revision;



function get_best_revision (
  item_id	in cr_items.item_id%TYPE
) return cr_revisions.revision_id%TYPE
is
  v_revision_id cr_revisions.revision_id%TYPE;
begin
    
  select
    NVL (live_revision, latest_revision )
  into
    v_revision_id
  from
    cr_items
  where
    item_id = get_best_revision.item_id;

  return v_revision_id;
exception
  when NO_DATA_FOUND then
    return null;
end get_best_revision;


    
function get_title (
  item_id    in cr_items.item_id%TYPE,
  is_live    in char default 'f'
) return cr_revisions.title%TYPE is

  v_title cr_revisions.title%TYPE;
  v_content_type cr_items.content_type%TYPE;

begin
  
  select content_type into v_content_type from cr_items 
    where item_id = get_title.item_id;

  if v_content_type = 'content_folder' then
    select label into v_title from cr_folders 
      where folder_id = get_title.item_id;
  elsif v_content_type = 'content_symlink' then
    select label into v_title from cr_symlinks 
      where symlink_id = get_title.item_id;
  elsif v_content_type = 'content_extlink' then
    select label into v_title from cr_extlinks
      where extlink_id = get_title.item_id;
  else
    if is_live ^= 'f' then
      select
	title into v_title
      from
	cr_revisions r, cr_items i
      where
        i.item_id = get_title.item_id
      and
        r.revision_id = i.live_revision;
    else
      select
	title into v_title
      from
	cr_revisions r, cr_items i
      where
        i.item_id = get_title.item_id
      and
        r.revision_id = i.latest_revision;
    end if;
  end if;

  return v_title;

end get_title;

function get_publish_date (
  item_id    in cr_items.item_id%TYPE,
  is_live    in char default 'f'
) return cr_revisions.publish_date%TYPE
is                            
  v_revision_id  cr_revisions.revision_id%TYPE;
  v_publish_date cr_revisions.publish_date%TYPE;
begin
  
  if is_live ^= 'f' then
    select
	publish_date into v_publish_date
    from
	cr_revisions r, cr_items i
    where
      i.item_id = get_publish_date.item_id
    and
      r.revision_id = i.live_revision;
  else
    select
	publish_date into v_publish_date
    from
	cr_revisions r, cr_items i
    where
      i.item_id = get_publish_date.item_id
    and
      r.revision_id = i.latest_revision;
  end if;

  return v_publish_date;

exception when no_data_found then
  return null;
end get_publish_date;

function is_subclass (
  object_type   in acs_object_types.object_type%TYPE,
  supertype	in acs_object_types.supertype%TYPE
) return char is

  v_subclass_p char;

  cursor c_inherit_cur is
    select
      object_type
    from
      acs_object_types  
    connect by
      prior object_type = supertype
    start with 
      object_type = is_subclass.supertype;

begin

  v_subclass_p := 'f';

  for v_inherit_val in c_inherit_cur loop
    if v_inherit_val.object_type = is_subclass.object_type then
         v_subclass_p := 't';
    end if;
  end loop;

  return v_subclass_p;

end is_subclass;

function relate (
  item_id       in cr_items.item_id%TYPE,
  object_id     in acs_objects.object_id%TYPE,
  relation_tag  in cr_type_relations.relation_tag%TYPE default 'generic',
  order_n       in cr_item_rels.order_n%TYPE default null,
  relation_type in acs_object_types.object_type%TYPE default 'cr_item_rel'
) return cr_item_rels.rel_id%TYPE
is
  v_content_type	cr_items.content_type%TYPE;
  v_object_type		acs_objects.object_type%TYPE;
  v_is_valid		integer;
  v_rel_id		integer;
  v_exists		integer;
  v_order_n		cr_item_rels.order_n%TYPE;
begin

  -- check the relationship is valid
  v_content_type := content_item.get_content_type ( relate.item_id );
  v_object_type := content_item.get_content_type ( relate.object_id );

  select
    decode( count(1),0,0,1) into v_is_valid
  from
    cr_type_relations
  where
    content_item.is_subclass( v_object_type, target_type ) = 't'
  and
    content_item.is_subclass( v_content_type, content_type ) = 't';

  if v_is_valid = 0 then
    raise_application_error(-20000,
      'There is no registered relation type matching this item relation.');
  end if;

  if relate.item_id ^= relate.object_id then
    -- check that these two items are not related already
    --dbms_output.put_line( 'checking if the items are already related...');
    begin
      select
        rel_id, 1 as v_exists into v_rel_id, v_exists
      from
        cr_item_rels
      where
        item_id = relate.item_id
      and
        related_object_id = relate.object_id
      and
        relation_tag = relate.relation_tag;
    exception when no_data_found then
      v_exists := 0;
    end;


    -- if order_n is null, use rel_id (the order the item was related)
    if relate.order_n is null then
      v_order_n := v_rel_id;
    else
      v_order_n := relate.order_n;
    end if;


    -- if relationship does not exist, create it
    if v_exists <> 1 then
      --dbms_output.put_line( 'creating new relationship...');
      v_rel_id := acs_object.new(
        object_type     => relation_type,
        context_id      => item_id
      );
      insert into cr_item_rels (
        rel_id, item_id, related_object_id, order_n, relation_tag
      ) values (
        v_rel_id, item_id, object_id, v_order_n, relation_tag
      );

    -- if relationship already exists, update it
    else
      --dbms_output.put_line( 'updating existing relationship...');
      update cr_item_rels set
        relation_tag = relate.relation_tag,
        order_n = v_order_n
      where
        rel_id = v_rel_id;
    end if;

  end if;
  return v_rel_id;
end relate;


procedure unrelate (
  rel_id          in cr_item_rels.rel_id%TYPE
) is
begin

  -- delete the relation object
  acs_rel.del( unrelate.rel_id );

  -- delete the row from the cr_item_rels table
  delete from cr_item_rels where rel_id = unrelate.rel_id;

end unrelate;

function is_index_page (
  item_id   in cr_items.item_id%TYPE,
  folder_id in cr_folders.folder_id%TYPE
) return varchar2
is
begin
  if content_folder.get_index_page(folder_id) = item_id then
    return 't';
  else
    return 'f';
  end if;
end is_index_page;



function get_parent_folder (
  item_id	in cr_items.item_id%TYPE
) return cr_folders.folder_id%TYPE
is
  v_folder_id	      cr_folders.folder_id%TYPE;
  v_parent_folder_p   char(1);
begin
  v_parent_folder_p := 'f';
  v_folder_id := get_parent_folder.item_id;

  while v_parent_folder_p = 'f' and v_folder_id is not null loop
    select
      parent_id, content_folder.is_folder( parent_id ) 
    into 
      v_folder_id, v_parent_folder_p
    from
      cr_items
    where
      item_id = v_folder_id;

  end loop; 

  return v_folder_id;

end get_parent_folder;

end content_item;
/
show errors

create or replace package body content_folder
as

function new (
  name          in cr_items.name%TYPE,
  label         in cr_folders.label%TYPE,
  description   in cr_folders.description%TYPE default null,
  parent_id     in cr_items.parent_id%TYPE default null,
  context_id	in acs_objects.context_id%TYPE default null,
  folder_id	in cr_folders.folder_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE default sysdate,
  creation_user	in acs_objects.creation_user%TYPE default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null
) return cr_folders.folder_id%TYPE is
  v_folder_id	cr_folders.folder_id%TYPE;
  v_context_id	acs_objects.context_id%TYPE;
begin

  -- set the context_id
  if content_folder.new.context_id is null then
    v_context_id := content_folder.new.parent_id;
  else
    v_context_id := content_folder.new.context_id;
  end if;

  -- parent_id = 0 means that this is a mount point
  if parent_id ^= 0 and 
     content_folder.is_registered(parent_id,'content_folder') = 'f' then

    raise_application_error(-20000, 
        'This folder does not allow subfolders to be created');
  else

    v_folder_id := content_item.new(
        item_id       => folder_id,
        name          => name, 
        item_subtype  => 'content_folder',
        content_type  => 'content_folder',
	context_id    => v_context_id,
        creation_date => creation_date, 
        creation_user => creation_user, 
        creation_ip   => creation_ip, 
        parent_id     => parent_id 
    );

    insert into cr_folders (
      folder_id, label, description
    ) values (
      v_folder_id, label, description
    );

    -- inherit the attributes of the parent folder
    if content_folder.new.parent_id is not null then
    
      insert into cr_folder_type_map (
        folder_id, content_type
      ) select
          v_folder_id, content_type
        from
          cr_folder_type_map
        where
          folder_id = content_folder.new.parent_id;
    end if;

    -- update the child flag on the parent
    update cr_folders set has_child_folders = 't'
      where folder_id = content_folder.new.parent_id;

    return v_folder_id;
  end if;

end new;

procedure del (
  folder_id	in cr_folders.folder_id%TYPE,
  cascade_p     in char default 'f'
) is

  v_count integer;
  v_parent_id cr_items.parent_id%TYPE;
  v_child_item_id cr_items.item_id%TYPE;

  cursor c_folder_children_cur is
    select
      item_id
    from
      cr_items
    connect by
      prior item_id=parent_id
      start with parent_id = del.folder_id;

begin

  -- check if the folder contains any items

  select count(*) into v_count from cr_items where parent_id = folder_id;

  if v_count > 0 and content_folder.del.cascade_p='f' then
    raise_application_error(-20000, 
    'Folder ID ' || folder_id || ' (' || content_item.get_path(folder_id) ||
    ') cannot be deleted because it is not empty.');
  else
    open c_folder_children_cur;
	
	 loop

	fetch c_folder_children_cur into v_child_item_id;
	exit when c_folder_children_cur%NOTFOUND;
	if is_folder(v_child_item_id) = 't' then
	  content_folder.del(v_child_item_id,'t');
        else

         content_item.del(v_child_item_id);
      end if;
    end loop;
   close c_folder_children_cur;
  end if;  
  
  content_folder.unregister_content_type(
      folder_id	       => content_folder.del.folder_id,
      content_type     => 'content_revision',
      include_subtypes => 't' );

  delete from cr_folder_type_map
    where folder_id = content_folder.del.folder_id;

  select parent_id into v_parent_id from cr_items 
    where item_id = content_folder.del.folder_id;

  content_item.del(folder_id);

  -- check if any folders are left in the parent
  update cr_folders set has_child_folders = 'f' 
    where folder_id = v_parent_id and not exists (
      select 1 from cr_items 
        where parent_id = v_parent_id and content_type = 'content_folder');

end del;

-- renames a folder, making sure the new name is not already in use
procedure edit_name (
  folder_id	 in cr_folders.folder_id%TYPE,
  name	         in cr_items.name%TYPE default null,
  label	         in cr_folders.label%TYPE default null,
  description    in cr_folders.description%TYPE default null
) is
  v_name_already_exists_p integer := 0;
begin

  if name is not null then
    content_item.edit_name(folder_id, name);
  end if;

  if label is not null and description is not null then 

    update cr_folders
       set cr_folders.label = content_folder.edit_name.label,
       cr_folders.description = content_folder.edit_name.description
       where cr_folders.folder_id = content_folder.edit_name.folder_id;

  elsif label is not null and description is null then 

    update cr_folders
       set cr_folders.label = content_folder.edit_name.label
       where cr_folders.folder_id = content_folder.edit_name.folder_id;

  end if;

end edit_name;


-- 1) make sure we are not moving the folder to an invalid location:
--   a. destination folder exists
--   b. folder is not the webroot (folder_id = -1)
--   c. destination folder is not the same as the folder
--   d. destination folder is not a subfolder
-- 2) make sure subfolders are allowed in the target_folder
-- 3) update the parent_id for the folder

procedure move (
  folder_id		in cr_folders.folder_id%TYPE,
  target_folder_id	in cr_folders.folder_id%TYPE,
  name                  in cr_items.name%TYPE default null
) is
  v_source_folder_id integer;
  v_valid_folders_p integer := 0;
begin

  select 
    count(*)
  into 
    v_valid_folders_p
  from 
    cr_folders
  where
    folder_id = move.target_folder_id
  or 
    folder_id = move.folder_id;

  if v_valid_folders_p ^= 2 then
    raise_application_error(-20000,
      'content_folder.move - Not valid folder(s)');
  end if;

  if folder_id = content_item.get_root_folder or
    folder_id = content_template.get_root_folder then
    raise_application_error( -20000, 
      'content_folder.move - Cannot move root folder');
  end if;
  
  if target_folder_id = folder_id then
    raise_application_error(-20000,
      'content_folder.move - Cannot move a folder to itself');
  end if;

  if is_sub_folder(folder_id, target_folder_id) = 't' then
    raise_application_error(-20000,
      'content_folder.move - Destination folder is subfolder');
  end if;

  if is_registered(target_folder_id,'content_folder') ^= 't' then
    raise_application_error(-20000,
      'content_folder.move - Destination folder does not allow subfolders');
  end if;

  select parent_id into v_source_folder_id from cr_items 
    where item_id = move.folder_id;

   -- update the parent_id for the folder
   update cr_items 
     set parent_id = move.target_folder_id,
	 name=nvl(move.name, cr_items.name)
     where item_id = move.folder_id;

  -- update the has_child_folders flags

  -- update the source
  update cr_folders set has_child_folders = 'f' 
    where folder_id = v_source_folder_id and not exists (
      select 1 from cr_items 
        where parent_id = v_source_folder_id 
          and content_type = 'content_folder');

  -- update the destination
  update cr_folders set has_child_folders = 't'
    where folder_id = target_folder_id;

end move;

-- * make sure that subfolders are allowed in this folder
-- * creates new folder in the target folder with the same attributes
--   as the old one
-- * copies all contents of folder to the new one
procedure copy (
  folder_id		in cr_folders.folder_id%TYPE,
  target_folder_id	in cr_folders.folder_id%TYPE,
  creation_user		in acs_objects.creation_user%TYPE,
  creation_ip		in acs_objects.creation_ip%TYPE default null,
  name                  in cr_items.name%TYPE default null
) is
  v_valid_folders_p     integer := 0;
  v_current_folder_id   cr_folders.folder_id%TYPE;
  v_name		cr_items.name%TYPE;
  v_label		cr_folders.label%TYPE;
  v_description		cr_folders.description%TYPE;
  v_new_folder_id	cr_folders.folder_id%TYPE;

  -- cursor: items in the folder
  cursor c_folder_contents_cur is
    select
      item_id
    from
      cr_items
    where
      parent_id = copy.folder_id;

begin

  select 
    count(*)
  into 
    v_valid_folders_p
  from 
    cr_folders
  where
    folder_id = copy.target_folder_id
  or 
    folder_id = copy.folder_id;

  select
    parent_id
  into
    v_current_folder_id
  from
    cr_items
  where
    item_id = copy.folder_id;  

  if folder_id = content_item.get_root_folder or folder_id = content_template.get_root_folder or target_folder_id = folder_id then
    v_valid_folders_p := 0;
  end if;

  if v_valid_folders_p = 2 then 

      -- get the source folder info
      select
        name, label, description
      into
        v_name, v_label, v_description
      from 
        cr_items i, cr_folders f
      where
        f.folder_id = i.item_id
      and
        f.folder_id = copy.folder_id;

  if is_sub_folder(folder_id, target_folder_id) ^= 't' or v_current_folder_id != copy.target_folder_id or (v_name != copy.name and copy.name is not null) then
      if copy.name is not null then
	v_name := copy.name;
      end if;
      -- create the new folder
      v_new_folder_id := content_folder.new(
	  parent_id     => copy.target_folder_id,
          name	        => nvl(copy.name,v_name),
	  label	        => v_label,
	  description   => v_description,
	  creation_user => copy.creation_user,
	  creation_ip   => copy.creation_ip
      );

      -- copy attributes of original folder
      insert into cr_folder_type_map (
        folder_id, content_type
      ) select 
          v_new_folder_id, content_type
        from
          cr_folder_type_map map
        where
          folder_id = copy.folder_id
        and
	  -- do not register content_type if it is already registered
          not exists ( select 1 from cr_folder_type_map
	               where folder_id = v_new_folder_id 
		       and content_type = map.content_type ) ;

      -- for each item in the folder, copy it
      for v_folder_contents_val in c_folder_contents_cur loop
        
	content_item.copy(
	    item_id          => v_folder_contents_val.item_id,
	    target_folder_id => v_new_folder_id,
	    creation_user    => copy.creation_user,
	    creation_ip      => copy.creation_ip    
	);

      end loop;

    end if;
  end if;
end copy;





-- returns 1 if the item_id passed in is a folder
function is_folder (
  item_id	  in cr_items.item_id%TYPE
) return char is

  v_folder_p varchar2(1) := 'f';

begin

  select 't' into v_folder_p from cr_folders
    where folder_id = item_id;

  return v_folder_p;

exception
  when NO_DATA_FOUND then 
    return 'f';

end is_folder;

-- target_folder_id is the possible sub folder
function is_sub_folder (
  folder_id	      in cr_folders.folder_id%TYPE,
  target_folder_id    in cr_folders.folder_id%TYPE
) return char
is 
  cursor c_tree_cur is
    select
      parent_id
    from 
      cr_items
    connect by
      prior parent_id = item_id
    start with
      item_id = target_folder_id;

  v_parent_id integer := 0;
  v_sub_folder_p char := 'f';

begin

  if folder_id = content_item.get_root_folder or
    folder_id = content_template.get_root_folder then
    v_sub_folder_p := 't';
  end if;

  -- Get the parents
  open c_tree_cur;
  while v_parent_id <> folder_id loop
    fetch c_tree_cur into v_parent_id;
    exit when c_tree_cur%NOTFOUND;
  end loop;
  close c_tree_cur;

  if v_parent_id ^= 0 then 
    v_sub_folder_p := 't';
  end if;

  return v_sub_folder_p;

end is_sub_folder;

function is_empty (
  folder_id  in cr_folders.folder_id%TYPE
) return varchar2
is
  v_return varchar2(1);
begin

  select
    decode( count(*), 0, 't', 'f' ) into v_return
  from
    cr_items
  where
    parent_id = is_empty.folder_id;

  return v_return;
end is_empty;


procedure register_content_type (
  folder_id		in cr_folders.folder_id%TYPE,
  content_type		in cr_folder_type_map.content_type%TYPE,
  include_subtypes	in varchar2 default 'f'
) is

  v_is_registered varchar2(100);

begin

  if register_content_type.include_subtypes = 'f' then

    v_is_registered := is_registered(
        folder_id        => register_content_type.folder_id,
	content_type     => register_content_type.content_type, 
	include_subtypes => 'f' );

    if v_is_registered = 'f' then

        insert into cr_folder_type_map (
	  folder_id, content_type
	) values (
	  register_content_type.folder_id, 
	  register_content_type.content_type
	);

    end if;

  else
    
    insert into cr_folder_type_map (
      folder_id, content_type
    ) select 
        register_content_type.folder_id, object_type
      from
        acs_object_types
      where
        object_type ^= 'acs_object'
      and
        not exists (select 1 from cr_folder_type_map
                    where folder_id = register_content_type.folder_id
                    and content_type = acs_object_types.object_type)
      connect by 
        prior object_type = supertype
      start with 
        object_type = register_content_type.content_type;

  end if;

end register_content_type;

procedure unregister_content_type (
  folder_id		in cr_folders.folder_id%TYPE,
  content_type		in cr_folder_type_map.content_type%TYPE,
  include_subtypes	in varchar2 default 'f'
) is
begin

  if unregister_content_type.include_subtypes = 'f' then
    delete from cr_folder_type_map
      where folder_id = unregister_content_type.folder_id
      and content_type = unregister_content_type.content_type;
  else
    delete from cr_folder_type_map
    where folder_id = unregister_content_type.folder_id
    and content_type in (select object_type
           from acs_object_types    
	   where object_type ^= 'acs_object'
	   connect by prior object_type = supertype
	   start with 
             object_type = unregister_content_type.content_type);

  end if;

end unregister_content_type;




function is_registered (
  folder_id		in cr_folders.folder_id%TYPE,
  content_type		in cr_folder_type_map.content_type%TYPE,
  include_subtypes	in varchar2 default 'f'
) return varchar2 
is
  v_is_registered integer;
  cursor c_subtype_cur is
    select 
      object_type
    from 
      acs_object_types
    where 
      object_type ^= 'acs_object'
    connect by 
      prior object_type = supertype
    start with 
      object_type = is_registered.content_type;

begin

  if is_registered.include_subtypes = 'f' then
    select 
      count(1)
    into 
      v_is_registered
    from
      cr_folder_type_map
    where
      folder_id = is_registered.folder_id
    and
      content_type = is_registered.content_type;

  else

    v_is_registered := 1;
    for v_subtype_val in c_subtype_cur loop
      if is_registered(is_registered.folder_id,
                       v_subtype_val.object_type, 'f') = 'f' then
        v_is_registered := 0;
      end if;
    end loop;
  end if;

  if v_is_registered = 0 then
    return 'f';
  else
    return 't';
  end if;

end is_registered;

function get_label (
  folder_id in cr_folders.folder_id%TYPE
) return cr_folders.label%TYPE
is
  v_label cr_folders.label%TYPE;
begin

  select 
    label into v_label 
  from 
    cr_folders       
  where 
    folder_id = get_label.folder_id;

  return v_label;
end get_label;


function get_index_page (
  folder_id in cr_folders.folder_id%TYPE
) return cr_items.item_id%TYPE
is
  v_folder_id     cr_folders.folder_id%TYPE;
  v_index_page_id cr_items.item_id%TYPE;
begin

  -- if the folder is a symlink, resolve it
  if content_symlink.is_symlink( get_index_page.folder_id ) = 't' then
    v_folder_id := content_symlink.resolve( get_index_page.folder_id );
  else
    v_folder_id := get_index_page.folder_id;
  end if;

  select
    item_id into v_index_page_id
  from
    cr_items
  where
    parent_id = v_folder_id
  and
    name = 'index'
  and
    content_item.is_subclass(
      content_item.get_content_type( content_symlink.resolve(item_id) ),
    'content_folder') = 'f'
  and
    content_item.is_subclass(
      content_item.get_content_type( content_symlink.resolve(item_id) ),
    'content_template') = 'f';

  return v_index_page_id;

exception when no_data_found then
  return null;
end get_index_page;

function is_root (
  folder_id in cr_folders.folder_id%TYPE
) return char is
  v_is_root char(1);
begin

  select decode(parent_id, 0, 't', 'f') into v_is_root 
    from cr_items where item_id = is_root.folder_id;

  return v_is_root;
end is_root;

end content_folder;
/
show errors

