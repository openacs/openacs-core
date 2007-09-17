-- Data model to support content repository of the ArsDigita Community
-- System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

create view content_template_globals as 
select -200 as c_root_folder_id;

create or replace function content_template__get_root_folder() returns integer as '
declare
  v_folder_id                 integer;
begin
  select c_root_folder_id from content_template_globals into v_folder_id;
  return v_folder_id;
end;' language 'plpgsql' immutable;

-- create or replace package body content_template

create or replace function content_template__new(varchar) returns integer as '
declare
        new__name       alias for $1;
begin
        return content_template__new(new__name,
                                     null,
                                     null,
                                     now(),
                                     null,
                                     null
        );

end;' language 'plpgsql';

-- function new

create or replace function content_template__new (varchar,integer,integer,timestamptz,integer,varchar)
returns integer as '
declare
  new__name                   alias for $1;  
  new__parent_id              alias for $2;  -- default null  
  new__template_id            alias for $3;  -- default null
  new__creation_date          alias for $4;  -- default now()
  new__creation_user          alias for $5;  -- default null
  new__creation_ip            alias for $6;  -- default null
  v_template_id               cr_templates.template_id%TYPE;
  v_parent_id                 cr_items.parent_id%TYPE;
begin

  if new__parent_id is null then
    v_parent_id := content_template_globals.c_root_folder_id;
  else
    v_parent_id := new__parent_id;
  end if;

  -- make sure we''re allowed to create a template in this folder
  if content_folder__is_folder(new__parent_id) = ''t'' and
    content_folder__is_registered(new__parent_id,''content_template'',''f'') = ''f'' then

    raise EXCEPTION ''-20000: This folder does not allow templates to be created'';

  else
    v_template_id := content_item__new (
        new__name, 
        v_parent_id,
        new__template_id,
        null,
        new__creation_date, 
        new__creation_user, 
        null,
        new__creation_ip,
        ''content_item'',
        ''content_template'',
        null,
        null,
        ''text/plain'',
        null,
        null,
        ''text''
    );

    insert into cr_templates ( 
      template_id 
    ) values (
      v_template_id
    );

    return v_template_id;

  end if;
 
end;' language 'plpgsql';


create or replace function content_template__new(varchar,text,bool) returns integer as '
declare
        new__name       alias for $1;
        new__text       alias for $2;
        new__is_live    alias for $3;
begin
        return content_template__new(new__name,
                                     null,
                                     null,
                                     now(),
                                     null,
                                     null,
                                     new__text,
                                     new__is_live
        );

end;' language 'plpgsql';

select define_function_args('content_template__new','name,parent_id,template_id,creation_date;now,creation_user,creation_ip,text,is_live;f');

create or replace function content_template__new (varchar,integer,integer,timestamptz,integer,varchar,text,bool)
returns integer as '
declare
  new__name                   alias for $1;  
  new__parent_id              alias for $2;  -- default null  
  new__template_id            alias for $3;  -- default null
  new__creation_date          alias for $4;  -- default now()
  new__creation_user          alias for $5;  -- default null
  new__creation_ip            alias for $6;  -- default null
  new__text                   alias for $7;  -- default null
  new__is_live                alias for $8;  -- default ''f''
  v_template_id               cr_templates.template_id%TYPE;
  v_parent_id                 cr_items.parent_id%TYPE;
begin

  if new__parent_id is null then
    v_parent_id := content_template_globals.c_root_folder_id;
  else
    v_parent_id := new__parent_id;
  end if;

  -- make sure we''re allowed to create a template in this folder
  if content_folder__is_folder(new__parent_id) = ''t'' and
    content_folder__is_registered(new__parent_id,''content_template'',''f'') = ''f'' then

    raise EXCEPTION ''-20000: This folder does not allow templates to be created'';

  else
    v_template_id := content_item__new (
        new__template_id,     -- new__item_id
        new__name,            -- new__name
        v_parent_id,          -- new__parent_id
        null,                 -- new__title
        new__creation_date,   -- new__creation_date
        new__creation_user,   -- new__creation_user
        null,                 -- new__context_id
        new__creation_ip,     -- new__creation_ip
        new__is_live,         -- new__is_live
        ''text/plain'',       -- new__mime_type
        new__text,            -- new__text
        ''text'',             -- new__storage_type
        ''t'',                -- new__security_inherit_p
        ''CR_FILES'',         -- new__storage_area_key
        ''content_item'',     -- new__item_subtype
        ''content_template''  -- new__content_type
    );

    insert into cr_templates ( 
      template_id 
    ) values (
      v_template_id
    );

    return v_template_id;

  end if;
 
end;' language 'plpgsql';


-- procedure delete
select define_function_args('content_template__del','template_id');
create or replace function content_template__del (integer)
returns integer as '
declare
  delete__template_id            alias for $1;  
begin

  delete from cr_type_template_map
    where template_id = delete__template_id;

  delete from cr_item_template_map
    where template_id = delete__template_id;
 
  delete from cr_templates
    where template_id = delete__template_id;

  PERFORM content_item__delete(delete__template_id);

  return 0; 
end;' language 'plpgsql';

select define_function_args('content_template__delete','template_id');
create or replace function content_template__delete (integer)
returns integer as '
declare
  delete__template_id            alias for $1;  
begin
  PERFORM content_template__delete(delete__template_id);

  return 0; 
end;' language 'plpgsql';

-- function is_template
select define_function_args('content_template__is_template','template_id');
create or replace function content_template__is_template (integer)
returns boolean as '
declare
  is_template__template_id            alias for $1;  
begin
  
  return count(*) > 0 from cr_templates
    where template_id = is_template__template_id;
 
end;' language 'plpgsql' stable;

-- function get_path
select define_function_args('content_template__get_path','template_id,root_folder_id');
create or replace function content_template__get_path (integer,integer)
returns varchar as '
declare
  template_id            alias for $1;  
  root_folder_id         alias for $2; -- default content_template_globals.c_root_folder_id
                                        
begin

  return content_item__get_path(template_id, root_folder_id);

end;' language 'plpgsql' stable;



-- show errors
