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

procedure delete (
  extlink_id	in cr_extlinks.extlink_id%TYPE
) is
begin

  delete from cr_extlinks
    where extlink_id = content_extlink.delete.extlink_id;

  content_item.delete(content_extlink.delete.extlink_id);

end delete;

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

end content_extlink;
/
show errors


