-- @author Victor Guerra (vguerra@gmail.com)
-- @creation-date 2010-09-29
-- 


-- The following function get's rid of the foreign key constraint between cr_folders(folder_id) and cr_items(item_id), 
-- at somepoint ( upgrade-5.4.2d1-5.42d2 ) it was added using the statement "alter table add foreign key .. " 
-- which will add a constraint with name $1, since this is not for sure ( could have also other name assigned), we better look for the right constraint name
-- to be deleted using pg_constraint and pg_class table

create function inline_0 ()
returns integer as '
declare
    constraints RECORD;
begin
  for constraints in select conname 
      from pg_constraint con ,pg_class cla1, pg_class cla2 
      where con.contype = ''f'' and con.conrelid = cla1.oid and cla1.relname = ''cr_folders'' 
      and con.confrelid = cla2.oid and cla2.relname = ''cr_items''
  loop
	EXECUTE ''alter table cr_folders drop constraint '' || constraints.conname;
  end loop;
  return null;
end;' language 'plpgsql';

select inline_0();
drop function inline_0();

-- Now we create the foreign key constraint with the right name
alter table cr_folders add constraint cr_folders_folder_id_fk foreign key (folder_id) references cr_items(item_id) on delete cascade; 


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
    select c_root_folder_id into v_parent_id from content_template_globals;
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
    select c_root_folder_id into v_parent_id from content_template_globals;
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
