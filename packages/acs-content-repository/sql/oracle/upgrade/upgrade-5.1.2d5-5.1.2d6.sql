
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

    if v_parent_id = folder_id then
        v_sub_folder_p := 't';
    end if;

    exit when c_tree_cur%NOTFOUND;
  end loop;
  close c_tree_cur;

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




