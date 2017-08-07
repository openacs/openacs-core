-- 
-- 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2005-12-26
-- @arch-tag: c141278e-3359-4f40-8d61-3b8e940c633c
-- @cvs-id $Id$
--

-- New installs were not setting parent_id to security_context_root (-4)
-- but 0 so the CR root folders have the wrong info
-- re-run these upgrades.

-- Content Repository sets parent_id to security_context_root
-- for content modules


update acs_objects
set context_id = -4
where context_id = 0;

update cr_items
set parent_id = -4
where parent_id = 0;


-- now we need to recreate all the functions that assume 0
-- we use acs_magic_object('security_context_root') instead of 0
-- for future flexibility


-- Data model to support content repository of the ArsDigita
-- Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html
set serveroutput on size 1000000 format wrapped

create or replace view content_item_globals as
    select -100 as c_root_folder_id
    from dual;

-- package body content_item

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
--package body content folder
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
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  security_inherit_p in acs_objects.security_inherit_p%TYPE default 't',
  package_id	in acs_objects.package_id%TYPE default null
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

  -- parent_id = security context root means that this is a mount point
  if parent_id ^= -4 and 
    content_folder.is_folder(parent_id) = 'f' and
    content_folder.is_registered(parent_id,'content_folder') = 'f' then

    raise_application_error(-20000, 
        'This folder does not allow subfolders to be created');
  else

    v_folder_id := content_item.new(
        name          => new.name, 
        parent_id     => new.parent_id,
        item_id       => new.folder_id,
        creation_date => new.creation_date, 
        creation_user => new.creation_user, 
		context_id    => v_context_id,
        creation_ip   => new.creation_ip, 
        item_subtype  => 'content_folder',
        content_type  => 'content_folder',
		security_inherit_p => new.security_inherit_p,
        package_id    => new.package_id
    );

    insert into cr_folders (
      folder_id, label, description, package_id
    ) values (
      v_folder_id, label, description, package_id
    );

    -- set the correct object title
    update acs_objects
    set title = new.label
    where object_id = v_folder_id;

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

  if label is not null then
    update acs_objects
    set title = edit_name.label
    where object_id = edit_name.folder_id;
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

  v_parent_id integer := -4;
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

-- Refresh the attribute triggers

begin

  for type_rec in (select object_type,table_name from acs_object_types
    connect by supertype = prior object_type 
    start with object_type = 'content_revision') loop
        if table_exists(type_rec.table_name) then
            content_type.refresh_view(type_rec.object_type);
        end if; 
  end loop;

  -- DRB: The EVIL acs_message_revision names CR_REVISIONS as its table name.  This replaces
  -- the cr_revision trigger on cr_revisionsi which doesn't set item_id.  This causes an
  -- "can't insert NULL item_id" error when inserting on the view.  This took me like
  -- THREE FUCKING DAYS to figure out (well, there were other errors I had to fix with
  -- upgrades before I could fix this one).

  content_type.refresh_view('content_revision');

end;
/
show errors;

-- recreate content keyword package for package_id

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

-- recreate content keyword package body for package_id

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

  update acs_objects
  set title = set_heading.heading
  where object_id = set_heading.keyword_id;

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
  object_type   in acs_object_types.object_type%TYPE default 'content_keyword',
  package_id    in acs_objects.package_id%TYPE default null
) return cr_keywords.keyword_id%TYPE
is
  v_id integer;
  v_package_id acs_objects.package_id%TYPE;
begin

  if package_id is null then
    v_package_id := acs_object.package_id(new.parent_id);
  else
    v_package_id := package_id;
  end if;

  v_id := acs_object.new (object_id => keyword_id,
                          context_id => parent_id,
                          object_type => object_type,
                          title => heading,
                          package_id => v_package_id,
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
