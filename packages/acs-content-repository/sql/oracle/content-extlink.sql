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
  creation_ip	in acs_objects.creation_ip%TYPE default null,
  package_id    in acs_objects.package_id%TYPE default null
) return cr_extlinks.extlink_id%TYPE is

  v_extlink_id		cr_extlinks.extlink_id%TYPE;
  v_package_id		acs_objects.package_id%TYPE;
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

  if package_id is null then
    v_package_id := acs_object.package_id(new.parent_id);
  else
    v_package_id := package_id;
  end if;

  v_extlink_id := content_item.new(
      item_id       => content_extlink.new.extlink_id,
      name          => v_name,
      package_id    => v_package_id,
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

  update acs_objects
  set title = v_label
  where object_id = v_extlink_id;

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
  creation_ip		in acs_objects.creation_ip%TYPE default null,
  name                  in cr_items.name%TYPE default null
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

  -- can't copy to the same folder
    if copy.target_folder_id ^= v_current_folder_id or (v_name != copy.name and copy.name is not null) then
      if copy.name is not null then
	v_name := copy.name;
      end if;

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

