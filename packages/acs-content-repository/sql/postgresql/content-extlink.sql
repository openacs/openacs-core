-- Data model to support content repository of the ArsDigita
-- Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- create or replace package body content_extlink
-- function new
create function content_extlink__new (varchar,varchar,varchar,varchar,integer,integer,timestamptz,integer,varchar)
returns integer as '
declare
  new__name                   alias for $1;  -- default null  
  new__url                    alias for $2;  
  new__label                  alias for $3;  -- default null
  new__description            alias for $4;  -- default null
  new__parent_id              alias for $5;  
  new__extlink_id             alias for $6;  -- default null
  new__creation_date          alias for $7;  -- default now()
  new__creation_user          alias for $8;  -- default null
  new__creation_ip            alias for $9;  -- default null
  v_extlink_id                cr_extlinks.extlink_id%TYPE;
  v_label                     cr_extlinks.label%TYPE;
  v_name                      cr_items.name%TYPE;
begin

  if new__label is null then
    v_label := new__url;
  else
    v_label := new__label;
  end if;

  if new__name is null then
    select acs_object_id_seq.nextval into v_extlink_id from dual;
    v_name := ''link'' || v_extlink_id;
  else
    v_name := new__name;
  end if;

  v_extlink_id := content_item__new(
      v_name, 
      new__parent_id,
      new__extlink_id,
      null,
      new__creation_date, 
      new__creation_user, 
      null,
      new__creation_ip, 
      ''content_item'',
      ''content_extlink'', 
      null,
      null,
      ''text/plain'',
      null,
      null,
      ''text''
  );

  insert into cr_extlinks
    (extlink_id, url, label, description)
  values
    (v_extlink_id, new__url, v_label, new__description);

  return v_extlink_id;

end;' language 'plpgsql';


-- procedure delete
create function content_extlink__delete (integer)
returns integer as '
declare
  delete__extlink_id             alias for $1;  
begin

  delete from cr_extlinks
    where extlink_id = delete__extlink_id;

  PERFORM content_item__delete(delete__extlink_id);

return 0; 
end;' language 'plpgsql';


-- function is_extlink
create function content_extlink__is_extlink (integer)
returns boolean as '
declare
  is_extlink__item_id                alias for $1;  
  v_extlink_p                        boolean;
begin

  select 
    count(1) = 1 into v_extlink_p
  from 
    cr_extlinks
  where 
    extlink_id = is_extlink__item_id;
  
  return v_extlink_p;
 
end;' language 'plpgsql';



-- show errors


