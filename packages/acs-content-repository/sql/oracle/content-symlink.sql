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
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  package_id    in acs_objects.package_id%TYPE default null
) return cr_symlinks.symlink_id%TYPE is
  v_symlink_id		cr_symlinks.symlink_id%TYPE;
  v_package_id		acs_objects.package_id%TYPE;
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

  if package_id is null then
    v_package_id := acs_object.package_id(new.parent_id);
  else
    v_package_id := package_id;
  end if;

  v_symlink_id := content_item.new(
      item_id       => content_symlink.new.symlink_id,
      name          => v_name,
      package_id    => v_package_id,
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

  update acs_objects
  set title = v_label
  where object_id = v_symlink_id;

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
  creation_ip		in acs_objects.creation_ip%TYPE default null,
  name                  in cr_items.name%TYPE default null
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

-- can't copy to the same folder
    if copy.target_folder_id ^= v_current_folder_id or (v_name != copy.name and copy.name is not null) then

    if copy.name is not null then
      v_name := copy.name;
    end if;
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

-- Convenience view to simply access to symlink targets

create or replace view cr_resolved_items as
  select
    i.parent_id, i.item_id, i.name, 
    decode(s.target_id, NULL, 'f', 't') is_symlink,
    nvl(s.target_id, i.item_id) resolved_id, s.label
  from
    cr_items i, cr_symlinks s
  where
    i.item_id = s.symlink_id (+);
