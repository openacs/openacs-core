-- Data model to support content repository of the ArsDigita
-- Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

create or replace package body content_extlink
as

function new (
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
  creation_ip	in acs_objects.creation_ip%TYPE default null
) return cr_extlinks.extlink_id%TYPE is

  v_extlink_id		cr_extlinks.extlink_id%TYPE;
  v_label		cr_extlinks.label%TYPE;
  v_name                cr_items.name%TYPE;

begin

  if label is null then
    v_label := url;
  else
    v_label := label;
  end if;

  if name is null then
    select acs_object_id_seq.nextval into v_extlink_id from dual;
    v_name := 'link' || v_extlink_id;
  else
    v_name := name;
  end if;

  v_extlink_id := content_item.new(
      item_id       => content_extlink.new.extlink_id,
      name          => v_name, 
      content_type  => 'content_extlink', 
      creation_date => content_extlink.new.creation_date, 
      creation_user => content_extlink.new.creation_user, 
      creation_ip   => content_extlink.new.creation_ip, 
      parent_id     => content_extlink.new.parent_id
  );

  insert into cr_extlinks
    (extlink_id, url, label, description)
  values
    (v_extlink_id, content_extlink.new.url, v_label, 
     content_extlink.new.description);

  return v_extlink_id;

end new;

procedure del (
  extlink_id	in cr_extlinks.extlink_id%TYPE
) is
begin

  delete from cr_extlinks
    where extlink_id = content_extlink.del.extlink_id;

  content_item.del(content_extlink.del.extlink_id);

end del;

function is_extlink (
  item_id	 in cr_items.item_id%TYPE
) return char
is
  v_extlink_p integer := 0;
begin

  select 
    count(1) into v_extlink_p
  from 
    cr_extlinks
  where 
    extlink_id = is_extlink.item_id;

  if v_extlink_p = 1 then
    return 't';
  else
    return 'f';
  end if;
  
end is_extlink;

procedure copy (
  extlink_id		in cr_extlinks.extlink_id%TYPE,
  target_folder_id	in cr_folders.folder_id%TYPE,
  creation_user		in acs_objects.creation_user%TYPE,
  creation_ip		in acs_objects.creation_ip%TYPE default null
) is
  v_current_folder_id   cr_folders.folder_id%TYPE;
  v_name		cr_items.name%TYPE;
  v_url		        cr_extlinks.url%TYPE;
  v_label		cr_extlinks.label%TYPE;
  v_description         cr_extlinks.description%TYPE;
  v_extlink_id		cr_extlinks.extlink_id%TYPE;
begin

  if content_folder.is_folder(copy.target_folder_id) = 't' then
    select
      parent_id
    into
      v_current_folder_id
    from
      cr_items
    where
      item_id = copy.extlink_id;

    -- can't copy to the same folder
    if copy.target_folder_id ^= v_current_folder_id then

      select
        i.name, e.url, e.label, e.description
      into
        v_name, v_url, v_label, v_description
      from
        cr_extlinks e, cr_items i
      where
        e.extlink_id = i.item_id
      and
        e.extlink_id = copy.extlink_id;

      if content_folder.is_registered(copy.target_folder_id, 'content_extlink') = 't' then

        v_extlink_id := content_extlink.new(
            parent_id     => copy.target_folder_id,
            name          => v_name,
            label         => v_label,
            description   => v_description,
            url           => v_url,
	    creation_user => copy.creation_user,
	    creation_ip   => copy.creation_ip
        );

      end if;
    end if;
  end if;
end copy;

end content_extlink;
/
show errors

-- Data model to support content repository of the ArsDigita Community
-- System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

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
  folder_id	in cr_folders.folder_id%TYPE
) is

  v_count integer;
  v_parent_id integer;
  
begin

  -- check if the folder contains any items

  select count(*) into v_count from cr_items where parent_id = folder_id;

  if v_count > 0 then
    raise_application_error(-20000, 
    'Folder ID ' || folder_id || ' (' || content_item.get_path(folder_id) ||
    ') cannot be deleted because it is not empty.');
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
procedure rename (
  folder_id	 in cr_folders.folder_id%TYPE,
  name	         in cr_items.name%TYPE default null,
  label	         in cr_folders.label%TYPE default null,
  description    in cr_folders.description%TYPE default null
) is
  v_name_already_exists_p integer := 0;
begin

  if name is not null then
    content_item.rename(folder_id, name);
  end if;

  if label is not null and description is not null then 

    update cr_folders
      set label = label,
      description = description
      where folder_id = folder_id;

  elsif label is not null and description is null then 

    update cr_folders
      set label = label
      where folder_id = folder_id;

  end if;

end rename;


-- 1) make sure we are not moving the folder to an invalid location:
--   a. destination folder exists
--   b. folder is not the webroot (folder_id = -1)
--   c. destination folder is not the same as the folder
--   d. destination folder is not a subfolder
-- 2) make sure subfolders are allowed in the target_folder
-- 3) update the parent_id for the folder

procedure move (
  folder_id		in cr_folders.folder_id%TYPE,
  target_folder_id	in cr_folders.folder_id%TYPE
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
     set parent_id = move.target_folder_id
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
  creation_ip		in acs_objects.creation_ip%TYPE default null
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

  if folder_id = content_item.get_root_folder or folder_id = content_template.get_root_folder or target_folder_id = folder_id or v_current_folder_id = target_folder_id then
    v_valid_folders_p := 0;
  end if;

  if v_valid_folders_p = 2 then 
    if is_sub_folder(folder_id, target_folder_id) ^= 't' then

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

      -- create the new folder
      v_new_folder_id := content_folder.new(
	  parent_id     => copy.target_folder_id,
          name	        => v_name,
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

-- Data model to support content repository of the ArsDigita
-- Publishing System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Hiro Iwashima (iwashima@mit.edu)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html


create or replace package image
as
  --/**
  -- Creates a new image
  -- Binary file stored in file-system
  --*/
  function new (
    name		in cr_items.name%TYPE,
    parent_id		in cr_items.parent_id%TYPE default null,
    item_id		in acs_objects.object_id%TYPE default null,
    revision_id		in acs_objects.object_id%TYPE default null,
    content_type	in acs_object_types.object_type%TYPE default 'image',
    creation_date	in acs_objects.creation_date%TYPE default sysdate, 
    creation_user	in acs_objects.creation_user%TYPE default null, 
    creation_ip		in acs_objects.creation_ip%TYPE default null, 
    locale		in cr_items.locale%TYPE default null,
    context_id		in acs_objects.context_id%TYPE default null,
    title		in cr_revisions.title%TYPE default null,
    description		in cr_revisions.description%TYPE default null,
    mime_type		in cr_revisions.mime_type%TYPE default null,
    nls_language	in cr_revisions.nls_language%TYPE default null,
    relation_tag	in cr_child_rels.relation_tag%TYPE default null,
    is_live		in char default 'f',
    publish_date	in cr_revisions.publish_date%TYPE default sysdate,
    data		in cr_revisions.content%TYPE default null,
    filename		in cr_revisions.filename%TYPE default null,
    height		in images.height%TYPE default null,
    width		in images.width%TYPE default null,
    file_size		in cr_revisions.content_length%TYPE default null,
    storage_type        in cr_items.storage_type%TYPE default 'file'
  ) return cr_items.item_id%TYPE;

  function new_revision (
    item_id		in acs_objects.object_id%TYPE default null,
    revision_id		in acs_objects.object_id%TYPE default null,
    creation_date	in acs_objects.creation_date%TYPE default sysdate, 
    creation_user	in acs_objects.creation_user%TYPE default null, 
    creation_ip		in acs_objects.creation_ip%TYPE default null, 
    title		in cr_revisions.title%TYPE default null,
    description		in cr_revisions.description%TYPE default null,
    mime_type		in cr_revisions.mime_type%TYPE default null,
    nls_language	in cr_revisions.nls_language%TYPE default null,
    is_live		in char default 'f',
    publish_date	in cr_revisions.publish_date%TYPE default sysdate,
    data                in cr_revisions.content%TYPE default null,
    filename		in cr_revisions.filename%TYPE default null,
    height		in images.height%TYPE default null,
    width		in images.width%TYPE default null,
    file_size		in cr_revisions.content_length%TYPE default null
  ) return cr_revisions.revision_id%TYPE;

  --/**
  -- Deletes a single revision of image
  -- Schedules binary file for deletion.
  -- File delete sweep checks to see if no other images are using binary prior to deleting
  --*/
  procedure delete_revision (
    revision_id		in cr_revisions.revision_id%TYPE
  );

  --/**
  -- Deletes a image and all revisions
  -- Schedules binary files for deletion.
  -- 
  -- Be careful, cannot be undone (easily)
  --*/
  procedure del (
    item_id		in cr_items.item_id%TYPE
  );

end image;
/
show errors;

create or replace package body image
as
  function new (
    name		in cr_items.name%TYPE,
    parent_id		in cr_items.parent_id%TYPE default null,
    item_id		in acs_objects.object_id%TYPE default null,
    revision_id		in acs_objects.object_id%TYPE default null,
    content_type	in acs_object_types.object_type%TYPE default 'image',
    creation_date	in acs_objects.creation_date%TYPE default sysdate, 
    creation_user	in acs_objects.creation_user%TYPE default null, 
    creation_ip		in acs_objects.creation_ip%TYPE default null, 
    locale		in cr_items.locale%TYPE default null,
    context_id		in acs_objects.context_id%TYPE default null,
    title		in cr_revisions.title%TYPE default null,
    description		in cr_revisions.description%TYPE default null,
    mime_type		in cr_revisions.mime_type%TYPE default null,
    nls_language	in cr_revisions.nls_language%TYPE default null,
    relation_tag	in cr_child_rels.relation_tag%TYPE default null,
    is_live		in char default 'f',
    publish_date	in cr_revisions.publish_date%TYPE default sysdate,
    data                in cr_revisions.content%TYPE default null,
    filename		in cr_revisions.filename%TYPE default null,
    height		in images.height%TYPE default null,
    width		in images.width%TYPE default null,
    file_size		in cr_revisions.content_length%TYPE default null,
    storage_type        in cr_items.storage_type%TYPE default 'file'
  ) return cr_items.item_id%TYPE
  is
    v_item_id	      cr_items.item_id%TYPE;
    v_revision_id     cr_revisions.revision_id%TYPE;
  begin
    
    v_item_id := content_item.new (
      name           => name,
      item_id	     => item_id,
      parent_id	     => parent_id,
      relation_tag   => relation_tag,
      content_type   => content_type,
      creation_date  => creation_date,
      creation_user  => creation_user,
      creation_ip    => creation_ip,
      locale	     => locale,
      context_id     => context_id,
      storage_type   => storage_type
    );

    v_revision_id := content_revision.new (
      title         => title,
      description   => description,
      item_id	    => v_item_id,
      revision_id   => revision_id,
      publish_date  => publish_date,
      mime_type	    => mime_type,
      nls_language  => nls_language,
      data          => data,
      filename      => filename,
      creation_date => sysdate,
      creation_user => creation_user,
      creation_ip   => creation_ip
    );

    insert into images
    (image_id, height, width)
    values
    (v_revision_id, height, width);

    -- update revision with image file info
    update cr_revisions
    set content_length = file_size
    where revision_id = v_revision_id;

    -- is_live => 't' not used as part of content_item.new
    -- because content_item.new does not let developer specify revision_id,
    -- revision_id is determined in advance 

    if is_live = 't' then
       content_item.set_live_revision (
         revision_id => v_revision_id
       );
    end if;

    return v_item_id;
  end new;

  function new_revision (
    item_id		in acs_objects.object_id%TYPE default null,
    revision_id		in acs_objects.object_id%TYPE default null,
    creation_date	in acs_objects.creation_date%TYPE default sysdate, 
    creation_user	in acs_objects.creation_user%TYPE default null, 
    creation_ip		in acs_objects.creation_ip%TYPE default null, 
    title		in cr_revisions.title%TYPE default null,
    description		in cr_revisions.description%TYPE default null,
    mime_type		in cr_revisions.mime_type%TYPE default null,
    nls_language	in cr_revisions.nls_language%TYPE default null,
    is_live		in char default 'f',
    publish_date	in cr_revisions.publish_date%TYPE default sysdate,
    data                in cr_revisions.content%TYPE default null,
    filename		in cr_revisions.filename%TYPE default null,
    height		in images.height%TYPE default null,
    width		in images.width%TYPE default null,
    file_size		in cr_revisions.content_length%TYPE default null
  ) return cr_revisions.revision_id%TYPE
  is
    v_revision_id     cr_revisions.revision_id%TYPE;

  begin
    v_revision_id := content_revision.new (
      title => title,
      description   => description,
      item_id	    => item_id,
      revision_id   => revision_id,
      publish_date  => publish_date,
      mime_type	    => mime_type,
      nls_language  => nls_language,
      data          => data,
      filename      => filename,
      creation_date => creation_date,
      creation_user => creation_user,
      creation_ip   => creation_ip
    );

    insert into images
    (image_id, height, width)
    values
    (v_revision_id, height, width);

    -- update revision with image file info
    update cr_revisions
    set content_length = file_size
    where revision_id = v_revision_id;

    -- is_live => 't' not used as part of content_item.new
    -- because content_item.new does not let developer specify revision_id,
    -- revision_id is determined in advance 

    if is_live = 't' then
       content_item.set_live_revision (
         revision_id => v_revision_id
       );
    end if;

    return v_revision_id;
  end new_revision;

  procedure delete_revision (
    revision_id		in cr_revisions.revision_id%TYPE
  )
  is
	v_content	cr_files_to_delete.path%TYPE default null;
  begin
    content_revision.del (
      revision_id => revision_id
    );
  end delete_revision;
  
  procedure del (
    item_id		in cr_items.item_id%TYPE
  )
  is 

    cursor image_revision_cur is
      select
        revision_id
      from
        cr_revisions
      where
        item_id = image.del.item_id
      order by revision_id asc;

      -- order by used in cursur so latest revision will be deleted last
      -- save resetting latest revision multiple times during delete process

  begin
    for v_revision_val in image_revision_cur loop
      image.delete_revision (
        revision_id => v_revision_val.revision_id
      );
    end loop;

    content_item.del (
      item_id => item_id
    );
  end del;
    
end image;
/
show errors;

-- Data model to support content repository of the ArsDigita
-- Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html
set serveroutput on size 1000000 format wrapped

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


procedure rename (
  item_id in cr_items.item_id%TYPE,
  name	  in cr_items.name%TYPE
) is
  cursor exists_cur is
    select
      item_id
    from 
      cr_items
    where
      name = name
    and 
      parent_id = (select 
		     parent_id
		   from
		     cr_items
		   where
		     item_id = item_id);

  exists_id integer;
begin

  open exists_cur;
  fetch exists_cur into exists_id;

  if exists_cur%NOTFOUND then
    close exists_cur;
    update cr_items
      set name = name
      where item_id = item_id;
  else
    close exists_cur;
    if exists_id <> item_id then
      raise_application_error(-20000, 
        'An item with the name ' || name || 
        ' already exists in this directory.');
    end if;
  end if;

end rename;

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
  target_folder_id	in cr_folders.folder_id%TYPE
) is
begin

  if content_folder.is_folder(item_id) = 't' then
    content_folder.move(item_id, target_folder_id);
  elsif content_folder.is_folder(target_folder_id) = 't' then
   

    if content_folder.is_registered( move.target_folder_id,
          get_content_type( move.item_id )) = 't' and
       content_folder.is_registered( move.target_folder_id,
          get_content_type( content_symlink.resolve( move.item_id)),'f') = 't'
      then

    -- update the parent_id for the item
    update cr_items 
      set parent_id = move.target_folder_id
      where item_id = move.item_id;
    end if;

  end if;
end move;

procedure copy (
  item_id               in cr_items.item_id%TYPE,
  target_folder_id      in cr_folders.folder_id%TYPE,
  creation_user         in acs_objects.creation_user%TYPE,
  creation_ip           in acs_objects.creation_ip%TYPE default null
) is

  copy_id cr_items.item_id%TYPE;

begin

  copy_id := copy2(item_id, target_folder_id, creation_user, creation_ip);

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
  creation_ip           in acs_objects.creation_ip%TYPE default null
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
        creation_ip      => copy2.creation_ip
    );
  -- call content_symlink.copy if the item is a symlink
  elsif content_symlink.is_symlink(copy2.item_id) = 't' then
    content_symlink.copy(
        symlink_id       => copy2.item_id,
        target_folder_id => copy2.target_folder_id,
        creation_user    => copy2.creation_user,
        creation_ip      => copy2.creation_ip
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

    -- can't copy to the same folder
    if copy2.target_folder_id ^= v_current_folder_id then

      select
        content_type, name, locale,
        nvl(live_revision, latest_revision), storage_type
      into
        v_content_type, v_name, v_locale, v_revision_id, v_storage_type
      from
        cr_items
      where
        item_id = copy2.item_id;

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

  while v_parent_folder_p = 'f' loop

    select
      parent_id, content_folder.is_folder( parent_id ) 
    into 
      v_folder_id, v_parent_folder_p
    from
      cr_items
    where
      item_id = get_parent_folder.item_id;

  end loop; 

  return v_folder_id;
  exception
    when NO_DATA_FOUND then
      return null;
end get_parent_folder;

end content_item;
/
show errors

-- Data model to support content repository of the ArsDigita
-- Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Stanislav Freidin (sfreidin@arsdigita.com)

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

create or replace package body content_keyword
as

function get_heading (
  keyword_id  in cr_keywords.keyword_id%TYPE
) return varchar2
is
  v_heading varchar2(4000);
begin

  select heading into v_heading from cr_keywords
    where keyword_id = content_keyword.get_heading.keyword_id;

  return v_heading;
end get_heading;

function get_description (
  keyword_id  in cr_keywords.keyword_id%TYPE
) return varchar2
is
  v_description varchar2(4000);
begin

  select description into v_description from cr_keywords
    where keyword_id = content_keyword.get_description.keyword_id;

  return v_description;
end get_description;

procedure set_heading (
  keyword_id  in cr_keywords.keyword_id%TYPE,
  heading     in cr_keywords.heading%TYPE
)
is
begin

  update cr_keywords set 
    heading = set_heading.heading
  where
    keyword_id = set_heading.keyword_id;

end set_heading;

procedure set_description (
  keyword_id  in cr_keywords.keyword_id%TYPE,
  description in cr_keywords.description%TYPE
)
is
begin

  update cr_keywords set 
    description = set_description.description
  where
    keyword_id = set_description.keyword_id;
end set_description;

function is_leaf (
  keyword_id  in cr_keywords.keyword_id%TYPE
) return varchar2
is
  v_leaf varchar2(1);

  cursor c_leaf_cur is
    select
      'f'
    from 
      cr_keywords k
    where
      k.parent_id = is_leaf.keyword_id;

begin

  open c_leaf_cur;
  fetch c_leaf_cur into v_leaf;
  if c_leaf_cur%NOTFOUND then
    v_leaf := 't';
  end if;
  close c_leaf_cur;

  return v_leaf;
end is_leaf;

function new (
  heading       in cr_keywords.heading%TYPE,
  description   in cr_keywords.description%TYPE default null,
  parent_id     in cr_keywords.parent_id%TYPE default null,
  keyword_id    in cr_keywords.keyword_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE
			   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
			   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  object_type   in acs_object_types.object_type%TYPE default 'content_keyword'
) return cr_keywords.keyword_id%TYPE
is
  v_id integer;
begin

  v_id := acs_object.new (object_id => keyword_id,
                          context_id => parent_id,
                          object_type => object_type,
                          creation_date => creation_date, 
                          creation_user => creation_user, 
                          creation_ip => creation_ip);
    
  insert into cr_keywords 
    (heading, description, keyword_id, parent_id)
  values
    (heading, description, v_id, parent_id);

  return v_id;
end new;

procedure del (
  keyword_id  in cr_keywords.keyword_id%TYPE
)
is
  v_item_id integer;
  cursor c_rel_cur is
    select item_id from cr_item_keyword_map 
    where keyword_id = content_keyword.del.keyword_id;
begin

  open c_rel_cur;
  loop
    fetch c_rel_cur into v_item_id;
    exit when c_rel_cur%NOTFOUND;
    item_unassign(v_item_id, content_keyword.del.keyword_id);
  end loop;
  close c_rel_cur;

  acs_object.del(keyword_id);
end del;

procedure item_assign (
  item_id       in cr_items.item_id%TYPE,
  keyword_id    in cr_keywords.keyword_id%TYPE, 
  context_id	in acs_objects.context_id%TYPE default null,
  creation_user in acs_objects.creation_user%TYPE default null,
  creation_ip   in acs_objects.creation_ip%TYPE default null
) 
is
  v_dummy integer;
begin
  
  -- Do nothing if the keyword is assigned already
  select decode(count(*),0,0,1) into v_dummy from dual 
    where exists (select 1 from cr_item_keyword_map
                   where item_id=item_assign.item_id 
                   and keyword_id=item_assign.keyword_id);

  if v_dummy > 0 then
    -- previous assignment exists 
    return;
  end if;

  insert into cr_item_keyword_map (
    item_id, keyword_id
  ) values (
    item_id, keyword_id
  );

end item_assign;

procedure item_unassign (
  item_id     in cr_items.item_id%TYPE,
  keyword_id  in cr_keywords.keyword_id%TYPE 
) is
begin

  delete from cr_item_keyword_map
    where item_id = item_unassign.item_id 
    and keyword_id = item_unassign.keyword_id;

end item_unassign;

function is_assigned (
  item_id     in cr_items.item_id%TYPE,
  keyword_id  in cr_keywords.keyword_id%TYPE,
  recurse     in varchar2 default 'none'
) return varchar2
is
  v_ret varchar2(1);
begin

  -- Look for an exact match
  if recurse = 'none' then
    declare
    begin
      select 't' into v_ret from cr_item_keyword_map
        where item_id = is_assigned.item_id
        and   keyword_id = is_assigned.keyword_id;
      return 't';
    exception when no_data_found then
      return 'f';    
    end;
  end if;

  -- Look from specific to general
  if recurse = 'up' then
    begin
      select 't' into v_ret from dual where exists (select 1 from
	(select keyword_id from cr_keywords
	   connect by parent_id = prior keyword_id
	   start with keyword_id = is_assigned.keyword_id
	 ) t, cr_item_keyword_map m
      where
	t.keyword_id = m.keyword_id
      and
	m.item_id = is_assigned.item_id);

      return 't';

    exception when no_data_found then
      return 'f';    
    end;
  end if;

  if recurse = 'down' then
    begin
      select 't' into v_ret from dual where exists ( select 1 from
	(select keyword_id from cr_keywords
	   connect by prior parent_id = keyword_id
	   start with keyword_id = is_assigned.keyword_id
	 ) t, cr_item_keyword_map m
      where
	t.keyword_id = m.keyword_id
      and
	m.item_id = is_assigned.item_id);

      return 't';

    exception when no_data_found then
      return 'f';    
    end;
  end if;  

  -- Tried none, up and down - must be an invalid parameter
  raise_application_error (-20000, 'The recurse parameter to ' || 
     'content_keyword.is_assigned should be ''none'', ''up'' or ''down''.');

end is_assigned;

function get_path (
  keyword_id in cr_keywords.keyword_id%TYPE
) return varchar2
is
  v_path     varchar2(4000) := '';
  v_is_found varchar2(1)    := 'f';
  
  cursor c_keyword_cur is 
    select 
      heading
    from (
      select 
        heading, level as tree_level
      from cr_keywords
        connect by prior parent_id = keyword_id
        start with keyword_id = get_path.keyword_id
    ) 
    order by 
      tree_level desc;

  v_heading cr_keywords.heading%TYPE;
begin

  open c_keyword_cur;
  loop
    fetch c_keyword_cur into v_heading;
    exit when c_keyword_cur%NOTFOUND;
    v_is_found := 't';
    v_path := v_path || '/' || v_heading;
  end loop;
  close c_keyword_cur;

  if v_is_found = 'f' then
    return null;
  else
    return v_path;
  end if;
end get_path;

end content_keyword;
/
show errors


-- Data model to support content repository of the ArsDigita
-- Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

create or replace package body content_revision
as

function new (
  title         in cr_revisions.title%TYPE,
  description   in cr_revisions.description%TYPE default null,
  publish_date  in cr_revisions.publish_date%TYPE default sysdate,
  mime_type   	in cr_revisions.mime_type%TYPE default 'text/plain',
  nls_language 	in cr_revisions.nls_language%TYPE default null,
  data	        in cr_revisions.content%TYPE,
  item_id       in cr_items.item_id%TYPE,
  revision_id   in cr_revisions.revision_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE default sysdate,
  creation_user	in acs_objects.creation_user%TYPE default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  filename	in cr_revisions.filename%TYPE default null

) return cr_revisions.revision_id%TYPE is

  v_revision_id integer;
  v_content_type acs_object_types.object_type%TYPE;

begin

  v_content_type := content_item.get_content_type(item_id);

  v_revision_id := acs_object.new(
      object_id     => revision_id,
      object_type   => v_content_type, 
      creation_date => creation_date, 
      creation_user => creation_user, 
      creation_ip   => creation_ip, 
      context_id    => item_id
  );

  insert into cr_revisions (
    revision_id, title, description, mime_type, publish_date,
    nls_language, content, item_id, filename
  ) values (
    v_revision_id, title, description, mime_type, publish_date,
    nls_language, data, item_id, filename
  );

  return v_revision_id;

end new;

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
  creation_ip	in acs_objects.creation_ip%TYPE default null
) return cr_revisions.revision_id%TYPE is

  v_revision_id integer;
  blob_loc cr_revisions.content%TYPE;

begin

  blob_loc := empty_blob();

  v_revision_id := content_revision.new(
      title         => title,
      description   => description,
      publish_date  => publish_date,
      mime_type     => mime_type,
      nls_language  => nls_language,
      data          => blob_loc,
      item_id       => item_id, 
      revision_id   => revision_id,
      creation_date => creation_date,
      creation_user => creation_user,
      creation_ip   => creation_ip
  );

  select 
    content into blob_loc
  from 
    cr_revisions 
  where 
    revision_id = v_revision_id
  for update;

  string_to_blob(text, blob_loc);

  return v_revision_id;

end new;

procedure copy_attributes (
  content_type  in acs_object_types.object_type%TYPE,
  revision_id	in cr_revisions.revision_id%TYPE,
  copy_id	in cr_revisions.revision_id%TYPE
) is

  v_table_name acs_object_types.table_name%TYPE;
  v_id_column acs_object_types.id_column%TYPE;

  cursor attr_cur is
    select
      attribute_name
    from
      acs_attributes
    where
      object_type = copy_attributes.content_type;

  cols varchar2(2000) := '';

begin

  select table_name, id_column into v_table_name, v_id_column
  from acs_object_types where object_type = copy_attributes.content_type;

  for attr_rec in attr_cur loop
    cols := cols || ', ' || attr_rec.attribute_name;
  end loop;

  execute immediate 'insert into ' || v_table_name || 
    ' ( ' || v_id_column || cols || ' ) ( select ' || copy_id || cols ||
    ' from ' || v_table_name || ' where ' || v_id_column || ' = ' || 
    revision_id || ')';
  
end copy_attributes;

function copy (
  revision_id		in cr_revisions.revision_id%TYPE,
  copy_id		in cr_revisions.revision_id%TYPE default null,
  target_item_id	in cr_items.item_id%TYPE default null,
  creation_user		in acs_objects.creation_user%TYPE default null,
  creation_ip		in acs_objects.creation_ip%TYPE default null
) return cr_revisions.revision_id%TYPE 
is 
  v_copy_id		cr_revisions.revision_id%TYPE;
  v_target_item_id	cr_items.item_id%TYPE;

  -- get the content_type and supertypes
  cursor type_cur is
    select                                                
      object_type
    from                                                
      acs_object_types                                  
    where                                               
      object_type ^= 'acs_object'                       
    and                                                 
      object_type ^= 'content_revision'                 
    connect by                                          
      prior supertype = object_type                     
    start with                                          
      object_type = (                                   
        select object_type from acs_objects where object_id = copy.revision_id
      )
    order by
      level desc;

begin
  -- use the specified item_id or the item_id of the original revision 
  --   if none is specified
  if target_item_id is null then
    select item_id into v_target_item_id from cr_revisions 
      where revision_id = copy.revision_id;
  else
    v_target_item_id := target_item_id;
  end if;

  -- use the copy_id or generate a new copy_id if none is specified
  --   the copy_id is a revision_id
  if copy_id is null then
    select acs_object_id_seq.nextval into v_copy_id from dual;
  else
    v_copy_id := copy_id;
  end if;

  -- create the basic object
  insert into acs_objects ( 
    object_id, object_type, context_id, security_inherit_p, 
    creation_user, creation_date, creation_ip,
    last_modified, modifying_user, modifying_ip
  ) ( select 
    v_copy_id, object_type, context_id, security_inherit_p, 
    copy.creation_user, sysdate, copy.creation_ip,
    sysdate, copy.creation_user, copy.creation_ip from
    acs_objects where object_id = copy.revision_id
  );
  
  -- create the basic revision (using v_target_item_id)
  insert into cr_revisions (
    revision_id, title, description, publish_date, mime_type, 
    nls_language, content, item_id
  ) ( select 
        v_copy_id, title, description, publish_date, mime_type, nls_language, 
	content, v_target_item_id 
      from 
        cr_revisions 
      where
        revision_id = copy.revision_id
  );

  -- iterate over the ancestor types and copy attributes
  for type_rec in type_cur loop
    copy_attributes(type_rec.object_type, copy.revision_id, v_copy_id);
  end loop;

  return v_copy_id;
end copy;

procedure del (
  revision_id	in cr_revisions.revision_id%TYPE
) is
  v_item_id         cr_items.item_id%TYPE;
  v_latest_revision cr_revisions.revision_id%TYPE;
  v_live_revision   cr_revisions.revision_id%TYPE;

begin

  -- Get item id and latest/live revisions
  select item_id into v_item_id from cr_revisions 
    where revision_id = content_revision.del.revision_id;

  select 
    latest_revision, live_revision
  into 
    v_latest_revision, v_live_revision
  from 
    cr_items
  where 
    item_id = v_item_id;

  -- Recalculate latest revision
  if v_latest_revision = content_revision.del.revision_id then
    declare
      cursor c_revision_cur is
        select r.revision_id from cr_revisions r, acs_objects o
         where o.object_id = r.revision_id
           and r.item_id = v_item_id
           and r.revision_id <> content_revision.del.revision_id
        order by o.creation_date desc;
    begin
      open c_revision_cur;
      fetch c_revision_cur into v_latest_revision;
      if c_revision_cur%NOTFOUND then
        v_latest_revision := null;        
      end if;
      close c_revision_cur;
    
      update cr_items set latest_revision = v_latest_revision
        where item_id = v_item_id;
    end;
  end if; 
 
  -- Clear live revision
  if v_live_revision = content_revision.del.revision_id then
    update cr_items set live_revision = null
      where item_id = v_item_id;   
  end if; 

  -- Clear the audit
  delete from cr_item_publish_audit
    where old_revision = content_revision.del.revision_id
       or new_revision = content_revision.del.revision_id;

  -- Delete the revision
  acs_object.del(revision_id);

end del;

function get_number (
  revision_id   in cr_revisions.revision_id%TYPE
) return number is

  cursor rev_cur is
    select
      revision_id
    from 
      cr_revisions r, acs_objects o
    where
      item_id = (select item_id from cr_revisions 
                      where revision_id = get_number.revision_id)
    and
      o.object_id = r.revision_id
    order by
      o.creation_date;

  v_number integer;
  v_revision cr_revisions.revision_id%TYPE;

begin

  open rev_cur;
  loop 

    fetch rev_cur into v_revision;

    if v_revision = get_number.revision_id then
      v_number := rev_cur%ROWCOUNT;
      exit;
    end if;

  end loop;
  close rev_cur;

  return v_number;

end get_number;

function revision_name(
  revision_id IN cr_revisions.revision_id%TYPE
) return varchar2 is

  v_text varchar2(500);
  v_sql  varchar2(500);

begin

  v_sql := 'select ''Revision '' || content_revision.get_number(r.revision_id) || '' of '' || (select count(*) from cr_revisions where item_id = r.item_id) || '' for item: '' || content_item.get_title(item_id)
  from cr_revisions r
  where r.revision_id = ' || revision_name.revision_id;

  execute immediate v_sql into v_text;

  return v_text;

end revision_name;

procedure index_attributes(
  revision_id IN cr_revisions.revision_id%TYPE
) is

  clob_loc clob;
  v_revision_id cr_revisions.revision_id%TYPE;

begin

  insert into cr_revision_attributes (
    revision_id, attributes
  ) values (
    revision_id, empty_clob()
  ) returning attributes into clob_loc;

  v_revision_id := write_xml(revision_id, clob_loc);  

end index_attributes;

function import_xml (
  item_id IN cr_items.item_id%TYPE,
  revision_id IN cr_revisions.revision_id%TYPE,
  doc_id IN number
) return cr_revisions.revision_id%TYPE is

  clob_loc clob;
  v_revision_id cr_revisions.revision_id%TYPE;

begin

  select doc into clob_loc from cr_xml_docs where doc_id = import_xml.doc_id;
  v_revision_id := read_xml(item_id, revision_id, clob_loc);  

  return v_revision_id;

end import_xml;

function export_xml (
  revision_id IN cr_revisions.revision_id%TYPE
) return cr_xml_docs.doc_id%TYPE is

  clob_loc clob;
  v_doc_id cr_xml_docs.doc_id%TYPE;
  v_revision_id cr_revisions.revision_id%TYPE;

begin

  insert into cr_xml_docs (doc_id, doc) 
    values (cr_xml_doc_seq.nextval, empty_clob())
    returning doc_id, doc into v_doc_id, clob_loc;

  v_revision_id := write_xml(revision_id, clob_loc);  

  return v_doc_id;

end export_xml;

procedure to_html (
  revision_id IN cr_revisions.revision_id%TYPE
) is

 tmp_clob clob;
 blob_loc blob;

begin

  ctx_doc.filter('cr_doc_filter_index', revision_id, tmp_clob, false);

  select 
    content into blob_loc
  from 
    cr_revisions 
  where 
    revision_id = to_html.revision_id
  for update;

 clob_to_blob(tmp_clob, blob_loc);

 dbms_lob.freetemporary(tmp_clob);

end to_html;

function is_live (
  revision_id in cr_revisions.revision_id%TYPE
) return varchar2
is
  v_ret varchar2(1);
begin

  select 't' into v_ret from cr_items
    where live_revision = is_live.revision_id;

  return v_ret;

exception when no_data_found then
  return 'f';
end is_live;

function is_latest (
  revision_id in cr_revisions.revision_id%TYPE
) return varchar2
is
  v_ret varchar2(1);
begin

  select 't' into v_ret from cr_items
    where latest_revision = is_latest.revision_id;

  return v_ret;

exception when no_data_found then
  return 'f';
end is_latest;

procedure to_temporary_clob (
  revision_id in cr_revisions.revision_id%TYPE
) is
  b blob;
  c clob;

begin

  insert into cr_content_text (
    revision_id, content
  ) values (
    revision_id, empty_clob()
  ) returning content into c;

  select content into b from cr_revisions 
    where revision_id = to_temporary_clob.revision_id;

  blob_to_clob(b, c);

end to_temporary_clob;




-- revision_id is the revision with the content that is to be copied
procedure content_copy (
  revision_id	       in cr_revisions.revision_id%TYPE,
  revision_id_dest     in cr_revisions.revision_id%TYPE default null
) is
  v_item_id             cr_items.item_id%TYPE;
  v_content_length	integer;
  v_revision_id_dest	cr_revisions.revision_id%TYPE;
  v_filename            cr_revisions.filename%TYPE;
  v_content             blob;
begin

  select
    content_length, item_id
  into
    v_content_length, v_item_id
  from
    cr_revisions
  where
    revision_id = content_copy.revision_id;

  -- get the destination revision
  if content_copy.revision_id_dest is null then
    select
      latest_revision into v_revision_id_dest
    from
      cr_items
    where
      item_id = v_item_id;
  else
    v_revision_id_dest := content_copy.revision_id_dest;
  end if;


  -- only copy the content if the source content is not null
  if v_content_length is not null and v_content_length > 0 then

    /* The internal LOB types - BLOB, CLOB, and NCLOB - use copy semantics, as 
       opposed to the reference semantics which apply to BFILEs.
       When a BLOB, CLOB, or NCLOB is copied from one row to another row in 
       the same table or in a different table, the actual LOB value is
       copied, not just the LOB locator. */

    select 
      filename, content_length
    into 
      v_filename, v_content_length
    from 
      cr_revisions
    where
      revision_id = content_copy.revision_id;

    -- need to update the file name after the copy,
    -- if this content item is in CR file storage.  The file name is based
    -- off of the item_id and revision_id and it will be invalid for the 
    -- copied revision.

    update cr_revisions       
      set content = (select content from cr_revisions where revision_id = content_copy.revision_id),
          filename = v_filename,
          content_length = v_content_length
      where revision_id = v_revision_id_dest;
  end if;

end content_copy;



end content_revision;
/
show errors

-- Data model to support content repository of the ArsDigita
-- Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

create or replace package body content_symlink
as

function new (
  name          in cr_items.name%TYPE default null,
  label		in cr_symlinks.label%TYPE default null,
  target_id	in cr_items.item_id%TYPE,
  parent_id     in cr_items.parent_id%TYPE,
  symlink_id	in cr_symlinks.symlink_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE default sysdate,
  creation_user	in acs_objects.creation_user%TYPE default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null
) return cr_symlinks.symlink_id%TYPE is
  v_symlink_id		cr_symlinks.symlink_id%TYPE;
  v_name		cr_items.name%TYPE;
  v_label		cr_symlinks.label%TYPE;
begin

  -- SOME CHECKS --

  -- 1) check that the target is now a symlink
  if content_symlink.is_symlink( target_id ) = 't' then
    raise_application_error(-20000,
        'Cannot create a symlink to a symlink ' || target_id);
  end if;

  -- 2) check that the parent is a folder
  if content_folder.is_folder(parent_id) = 'f' then
    raise_application_error(-20000,
        'The parent is not a folder');
  end if;

  -- 3) check that parent folder supports symlinks
  if content_folder.is_registered(parent_id,'content_symlink') = 'f' then
    raise_application_error(-20000, 
        'This folder does not allow symlinks to be created');
  end if;

  -- 4) check that the content folder supports the target item's content type
  if content_folder.is_registered(
    parent_id,content_item.get_content_type(target_id)) = 'f' then

    raise_application_error(-20000, 
        'This folder does not allow symlinks to items of type ' || 
        content_item.get_content_type(target_id) || ' to be created');
  end if;

  -- PASSED ALL CHECKS --



  -- Select default name if the name is null
  begin
    if name is null then
      select 
        'symlink_to_' || name into v_name
      from 
        cr_items
      where
         item_id = target_id;

    else
      v_name := name;
    end if;
  exception when no_data_found then 
    v_name := null;
  end;

  -- Select default label if the label is null
  if content_symlink.new.label is null then
    v_label := 'Symlink to ' || v_name;
  else
    v_label := content_symlink.new.label;
  end if;

  v_symlink_id := content_item.new(
      item_id       => content_symlink.new.symlink_id,
      name          => v_name, 
      content_type  => 'content_symlink', 
      creation_date => content_symlink.new.creation_date, 
      creation_user => content_symlink.new.creation_user, 
      creation_ip   => content_symlink.new.creation_ip, 
      parent_id     => content_symlink.new.parent_id
  );

  insert into cr_symlinks
    (symlink_id, target_id, label)
  values
    (v_symlink_id, content_symlink.new.target_id, v_label);

  return v_symlink_id;

end new;


procedure del (
  symlink_id	in cr_symlinks.symlink_id%TYPE
) is
begin

  delete from cr_symlinks
    where symlink_id = content_symlink.del.symlink_id;

  content_item.del(content_symlink.del.symlink_id);
end del;



function is_symlink (
  item_id	 in cr_items.item_id%TYPE
) return char
is
  v_symlink_p integer := 0;
begin


  select 
    count(*) into v_symlink_p
  from 
    cr_symlinks
  where 
    symlink_id = is_symlink.item_id;

  if v_symlink_p = 1 then
    return 't';
  else
    return 'f';
  end if;
  
end is_symlink;


procedure copy (
  symlink_id		in cr_symlinks.symlink_id%TYPE,
  target_folder_id	in cr_folders.folder_id%TYPE,
  creation_user		in acs_objects.creation_user%TYPE,
  creation_ip		in acs_objects.creation_ip%TYPE default null
) is
  v_current_folder_id   cr_folders.folder_id%TYPE;
  v_name		cr_items.name%TYPE;
  v_target_id		cr_items.item_id%TYPE;
  v_label		cr_symlinks.label%TYPE;
  v_symlink_id		cr_symlinks.symlink_id%TYPE;
begin

  if content_folder.is_folder(copy.target_folder_id) = 't' then
    select
      parent_id
    into
      v_current_folder_id
    from
      cr_items
    where
      item_id = copy.symlink_id;

    -- can't copy to the same folder
    if copy.target_folder_id ^= v_current_folder_id then

      select
        i.name, content_symlink.resolve(i.item_id), s.label
      into
        v_name, v_target_id, v_label
      from
        cr_symlinks s, cr_items i
      where
        s.symlink_id = i.item_id
      and
        s.symlink_id = copy.symlink_id;


      if content_folder.is_registered(copy.target_folder_id,
        'content_symlink') = 't' then
        if content_folder.is_registered(copy.target_folder_id,
          content_item.get_content_type(resolve(copy.symlink_id))) = 't' then

          v_symlink_id := content_symlink.new(
              parent_id     => copy.target_folder_id,
              name          => v_name,
	      label         => v_label,
              target_id     => v_target_id,
	      creation_user => copy.creation_user,
	      creation_ip   => copy.creation_ip
          );


	end if;
      end if;
    end if;
  end if;
end copy;


function resolve (
  item_id	in cr_items.item_id%TYPE
) return cr_items.item_id%TYPE
is
  v_target_id cr_items.item_id%TYPE;
begin

  select
    target_id into v_target_id
  from
    cr_symlinks
  where
    symlink_id = resolve.item_id;

  return v_target_id;

exception when no_data_found then
  return resolve.item_id;  
end resolve;


function resolve_content_type (
  item_id	in cr_items.item_id%TYPE
) return cr_items.content_type%TYPE
is
  v_content_type cr_items.content_type%TYPE;
begin

  select 
    content_item.get_content_type( target_id ) into v_content_type
  from
    cr_symlinks
  where
    symlink_id = resolve_content_type.item_id;

  return v_content_type;
  exception
    when NO_DATA_FOUND then
      return null;
end resolve_content_type;

end content_symlink;
/
show errors

-- Data model to support content repository of the ArsDigita Community
-- System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

create or replace package body content_template
as

function get_root_folder
return cr_folders.folder_id%TYPE
is
begin
  return c_root_folder_id;
end get_root_folder;

function new (
  name          in cr_items.name%TYPE,
  text          in varchar2 default null,
  parent_id     in cr_items.parent_id%TYPE default null,
  is_live 		in char default 't',
  template_id	in cr_templates.template_id%TYPE default null,
  creation_date	in acs_objects.creation_date%TYPE
			   default sysdate,
  creation_user	in acs_objects.creation_user%TYPE
			   default null,
  creation_ip	in acs_objects.creation_ip%TYPE default null
) return cr_templates.template_id%TYPE
is

  v_template_id		cr_templates.template_id%TYPE;
  v_parent_id		cr_items.parent_id%TYPE;

begin

  if parent_id is null then
    v_parent_id := c_root_folder_id;
  else
    v_parent_id := parent_id;
  end if;

  -- make sure we're allowed to create a template in this folder
  if content_folder.is_folder(parent_id) = 't' and
    content_folder.is_registered(parent_id,'content_template') = 'f' then

    raise_application_error(-20000, 
        'This folder does not allow templates to be created');

  else
    v_template_id := content_item.new (
        item_id       => content_template.new.template_id,
        name          => content_template.new.name, 
        text          => content_template.new.text, 
        parent_id     => v_parent_id,
        content_type  => 'content_template',
        is_live       => content_template.new.is_live, 
        creation_date => content_template.new.creation_date, 
        creation_user => content_template.new.creation_user, 
        creation_ip   => content_template.new.creation_ip
    );

    insert into cr_templates ( 
      template_id 
    ) values (
      v_template_id
    );

    return v_template_id;
  end if;
end new;                 

-- delete all template relations
procedure del (
  template_id	in cr_templates.template_id%TYPE
) is
begin

  delete from cr_type_template_map
    where template_id = content_template.del.template_id;

  delete from cr_item_template_map
    where template_id = content_template.del.template_id;
 
  delete from cr_templates
    where template_id = content_template.del.template_id;

  content_item.del(content_template.del.template_id);

end del;

function is_template (
  template_id	in cr_templates.template_id%TYPE
) return varchar2
is
  v_ret varchar2(1);
begin
  
  select 't' into v_ret from cr_templates
    where template_id = is_template.template_id;
  
  return v_ret; 

exception when no_data_found then
  return 'f';
end is_template;

function get_path (
  template_id    in cr_templates.template_id%TYPE,
  root_folder_id in cr_folders.folder_id%TYPE default c_root_folder_id
) return varchar2 is

begin

  return content_item.get_path(template_id, root_folder_id);

end get_path;

end content_template;
/
show errors


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
  drop_table_p		in char default 'f'

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
  --    @param min_n          The minimun number of relationships of this type
  --                          which an item must have to go live.
  --    @param max_n          The minimun number of relationships of this type
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
  --    @param min_n         The minimun number of parent-child
  --                          relationships of this type
  --                          which an item must have to go live.
  --    @param max_n         The minimun number of relationships of this type
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


end content_type;
/
show errors;

create or replace package content_item
as

--/** 
--Content items store the overview of the content published on a
--website. The actual content is stored in content revisions. It is
--implemented this way so that there can be mulitple versions of the
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
  --/** Determins whether an item is published or not.
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
  --    @return 't' if the item is publishable in it's present state, 
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

procedure rename (
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
  target_folder_id	in cr_folders.folder_id%TYPE
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
  creation_ip		in acs_objects.creation_ip%TYPE default null
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
  creation_ip		in acs_objects.creation_ip%TYPE default null
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
  filename	in cr_revisions.filename%TYPE default null
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
  creation_ip	in acs_objects.creation_ip%TYPE default null
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
  creation_ip	in acs_objects.creation_ip%TYPE default null
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
  --    @param creation_ip	 The IP address of the creation user (defualt null)
  --    @see {content_symlink.new}, {content_item.copy}
  --*/
  symlink_id		in cr_symlinks.symlink_id%TYPE,
  target_folder_id	in cr_folders.folder_id%TYPE,
  creation_user		in acs_objects.creation_user%TYPE,
  creation_ip		in acs_objects.creation_ip%TYPE default null
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
  creation_ip	in acs_objects.creation_ip%TYPE default null
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
  creation_ip		in acs_objects.creation_ip%TYPE default null
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
  folder_id	in cr_folders.folder_id%TYPE
);

procedure rename (
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
  target_folder_id	in cr_folders.folder_id%TYPE
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
  creation_ip		in acs_objects.creation_ip%TYPE default null
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
  creation_ip	in acs_objects.creation_ip%TYPE default null
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
  object_type   in acs_object_types.object_type%TYPE default 'content_keyword'
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



