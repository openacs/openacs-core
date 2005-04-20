-- 
-- 
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2004-12-22
-- @arch-tag: f76ec7ce-6834-4bff-b134-ad1953aad38e
-- @cvs-id $Id$
--

-- add package_id. for some reason content_folder__new did not support setting
-- cr_folders.package_id

create or replace function content_folder__new (varchar,varchar,varchar,integer,integer,integer,timestamptz,integer,varchar, boolean)
returns integer as '
declare
  new__name                   alias for $1;  
  new__label                  alias for $2;  
  new__description            alias for $3;  -- default null
  new__parent_id              alias for $4;  -- default null
  new__context_id             alias for $5;  -- default null
  new__folder_id              alias for $6;  -- default null
  new__creation_date          alias for $7;  -- default now()
  new__creation_user          alias for $8;  -- default null
  new__creation_ip            alias for $9;  -- default null
  new__security_inherit_p     alias for $10;  -- default true	
  v_folder_id                 cr_folders.folder_id%TYPE;
  v_context_id                acs_objects.context_id%TYPE;
begin

        perform content_folder__new (
                new__name,
                new__label,
                new__description,
                new__parent_id,
                new__context_id,
                new__folder_id,
                new__creation_date,
                new__creation_user,
                new__creation_ip,
                new__security_inherit_p,
                null
        );

  return null; 
end;' language 'plpgsql';

select define_function_args('content_folder__new','name,label,description,parent_id,context_id,folder_id,creation_date;now,creation_user,creation_ip,security_inherit_p;t,package_id');

create or replace function content_folder__new (varchar,varchar,varchar,integer,integer,integer,timestamptz,integer,varchar, boolean,integer)
returns integer as '
declare
  new__name                   alias for $1;  
  new__label                  alias for $2;  
  new__description            alias for $3;  -- default null
  new__parent_id              alias for $4;  -- default null
  new__context_id             alias for $5;  -- default null
  new__folder_id              alias for $6;  -- default null
  new__creation_date          alias for $7;  -- default now()
  new__creation_user          alias for $8;  -- default null
  new__creation_ip            alias for $9;  -- default null
  new__security_inherit_p     alias for $10;  -- default true
  new__package_id             alias for $11; -- default null
  v_folder_id                 cr_folders.folder_id%TYPE;
  v_context_id                acs_objects.context_id%TYPE;
begin

  -- set the context_id
  if new__context_id is null then
    v_context_id := new__parent_id;
  else
    v_context_id := new__context_id;
  end if;

  -- parent_id = 0 means that this is a mount point
  if new__parent_id != 0 and 
     content_folder__is_registered(new__parent_id,''content_folder'',''f'') = ''f'' then

    raise EXCEPTION ''-20000: This folder does not allow subfolders to be created'';
    return null;

  else

    v_folder_id := content_item__new(
	new__folder_id,
	new__name, 
        new__parent_id,
        null,
        new__creation_date, 
        new__creation_user, 
	new__context_id,
	new__creation_ip, 
	''f'',
	''text/plain'',
	null,
	''text'',
	new__security_inherit_p,
	''CR_FILES'',
	''content_folder'',
        ''content_folder'');

    insert into cr_folders (
      folder_id, label, description, package_id
    ) values (
      v_folder_id, new__label, new__description, new__package_id
    );

    -- inherit the attributes of the parent folder
    if new__parent_id is not null then
    
      insert into cr_folder_type_map
        select
          v_folder_id as folder_id, content_type
        from
          cr_folder_type_map

where
          folder_id = new__parent_id;
    end if;

    -- update the child flag on the parent
    update cr_folders set has_child_folders = ''t''
      where folder_id = new__parent_id;

    return v_folder_id;

  end if;

  return null; 
end;' language 'plpgsql';
