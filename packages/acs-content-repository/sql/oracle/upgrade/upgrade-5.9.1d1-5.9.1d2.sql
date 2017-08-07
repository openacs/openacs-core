--
-- upgrade of content_item.set_live_revision() by adding an optional
-- argument for the publish_date in order not to force the current
-- time to be the publish date.
--
--
create or replace package body content_item
as

function get_root_folder (
  item_id  in cr_items.item_id%TYPE default null
) return cr_folders.folder_id%TYPE is

  v_folder_id cr_folders.folder_id%TYPE;

begin

  if item_id is NULL or item_id in (-4,-100,-200) then

    v_folder_id := c_root_folder_id;

  else

    select
      item_id into v_folder_id
    from
      cr_items
    where 
      parent_id = -4
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
  storage_type  in cr_items.storage_type%TYPE default 'lob',
  security_inherit_p in acs_objects.security_inherit_p%TYPE default 't',
  package_id    in acs_objects.package_id%TYPE default null
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

  if v_parent_id = -4 or 
    content_folder.is_folder(v_parent_id) = 't' then

    if v_parent_id ^= -4 and 
      content_folder.is_registered(
        v_parent_id, content_item.new.content_type, 'f') = 'f' then

      raise_application_error(-20000, 
        'This item''s content type ' || content_item.new.content_type ||
        ' is not registered to this folder ' || v_parent_id);

    end if;

  elsif v_parent_id ^= -4 then

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
      title             => content_item.new.name,
      package_id        => content_item.new.package_id,
      context_id        => v_context_id,
      creation_date	=> content_item.new.creation_date, 
      creation_user	=> content_item.new.creation_user, 
      creation_ip	=> content_item.new.creation_ip,
      security_inherit_p => content_item.new.security_inherit_p
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
  if v_parent_id ^= -4 and
    content_folder.is_folder(v_parent_id) = 'f' then

    v_rel_id := acs_object.new(
      object_type	=> 'cr_item_child_rel',
      title		=> v_rel_tag || ': ' || v_parent_id || ' - ' || v_item_id,
      package_id	=> content_item.new.package_id,
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
        package_id    => content_item.new.package_id,
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
        package_id    => content_item.new.package_id,
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

  -- 2) delete all symlinks to this item
  for v_symlink_val in c_symlink_cur loop
    content_symlink.del(v_symlink_val.symlink_id);
  end loop;

  delete from cr_release_periods
    where item_id = content_item.del.item_id;

  -- 3) delete all revisions of this item
  delete from cr_item_publish_audit
    where item_id = content_item.del.item_id;
  for v_revision_val in c_revision_cur loop
    content_revision.del(v_revision_val.revision_id);
  end loop;
  
  -- 4) unregister all templates to this item
  delete from cr_item_template_map
    where item_id = content_item.del.item_id; 

  -- Delete all relations on this item
  for v_rel_val in c_rel_cur loop
    acs_rel.del(v_rel_val.rel_id);
  end loop;  

  for v_rel_val in c_child_cur loop
    acs_rel.del(v_rel_val.rel_id);
  end loop;  

  for v_rel_val in c_parent_cur loop
    acs_rel.del(v_rel_val.rel_id);
    content_item.del(v_rel_val.child_id);
  end loop;  

  -- 5) delete associated permissions
  delete from acs_permissions
    where object_id = content_item.del.item_id;

  -- 6) delete keyword associations
  delete from cr_item_keyword_map
    where item_id = content_item.del.item_id;

  -- 7) delete associated comments
  journal_entry.delete_for_object( content_item.del.item_id );

  -- context_id debugging loop
  --for v_error_val in c_error_cur loop
  --  dbms_output.put_line('ID=' || v_error_val.object_id || ' TYPE=' 
  --    || v_error_val.object_type);
  --end loop;

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

    update acs_objects
      set title = content_item.edit_name.name
      where object_id = content_item.edit_name.item_id;
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
  v_parent_id integer := -4;
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

  v_rel_parent_id integer := -4;
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
  publish_status in cr_items.publish_status%TYPE default 'ready',
  publish_date   in cr_revisions.publish_date%TYPE default sysdate
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
    publish_date = set_live_revision.publish_date
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

    if name is not null then
      update acs_objects
        set title = move.name
        where object_id = move.item_id;
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
  v_package_id          acs_objects.package_id%TYPE;
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

    v_package_id := acs_object.package_id(relate.item_id);

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
        title           => relation_tag || ': ' || relate.item_id || ' - ' || relate.object_id,
        package_id      => v_package_id,
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

      update acs_objects set
        title = relate.relation_tag || ': ' || relate.item_id || ' - ' || relate.object_id
      where object_id = v_rel_id;
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
