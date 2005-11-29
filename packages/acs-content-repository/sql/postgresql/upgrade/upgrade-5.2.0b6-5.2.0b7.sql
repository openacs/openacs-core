-- 
-- packages/acs-content-repository/sql/postgresql/upgrade/upgrade-5.2.0b6-5.2.0b7.sql
-- 
-- @author sussdorff aolserver (sussdorff@ipxserver.de)
-- @creation-date 2005-11-29
-- @arch-tag: 6c315b82-708f-4c42-8c66-297d27dcb2a0
-- @cvs-id $Id$
--


create or replace function content_extlink__new (varchar,varchar,varchar,varchar,integer,integer,timestamptz,integer,varchar,integer)
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
  new__package_id             alias for $10; -- default null
  v_extlink_id                cr_extlinks.extlink_id%TYPE;
  v_package_id                acs_objects.package_id%TYPE;
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

  if new__package_id is null then
    v_package_id := acs_object__package_id(new__parent_id);
  else
    v_package_id := new__package_id;
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
      ''text'',
      v_package_id
  );

  insert into cr_extlinks
    (extlink_id, url, label, description)
  values
    (v_extlink_id, new__url, v_label, new__description);

  update acs_objects
  set title = v_label
  where object_id = v_extlink_id;

  return v_extlink_id;

end;' language 'plpgsql';

create or replace function content_extlink__new (varchar,varchar,varchar,varchar,integer,integer,timestamptz,integer,varchar)
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
begin
  return content_extlink__new(new__name,
                              new__url,
                              new__label,
                              new__description,
                              new__parent_id,
                              new__extlink_id,
                              new__creation_date,
                              new__creation_user,
                              new__creation_ip,
                              null
  );

end;' language 'plpgsql';

select define_function_args('content_extlink__delete','extlink_id');

create or replace function content_extlink__delete (integer)
returns integer as '
declare
  delete__extlink_id             alias for $1;  
begin

  delete from cr_extlinks
    where extlink_id = delete__extlink_id;

  PERFORM content_item__delete(delete__extlink_id);

return 0; 
end;' language 'plpgsql';

select define_function_args('content_extlink__is_extlink','item_id');
create or replace function content_extlink__is_extlink (integer)
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

create or replace function content_extlink__copy (
	integer,
	integer,
	integer,
	varchar)
returns integer as '
declare
  copy__extlink_id             alias for $1;  
  copy__target_folder_id       alias for $2;  
  copy__creation_user          alias for $3;  
  copy__creation_ip            alias for $4;  -- default null
  v_extlink_id                 cr_extlinks.extlink_id%TYPE;
begin
	v_extlink_id := content_extlink__copy (
		copy__extlink_id,
		copy__target_folder_id,
		copy__creation_user,
		copy__creation_ip,
		NULL
	);
	return 0;
end;' language 'plpgsql' stable;

select define_function_args('content_extlink__copy','extlink_id,target_folder_id,creation_user,creation_ip,name');
create or replace function content_extlink__copy (
	integer,
	integer,
	integer,
	varchar,
	varchar)
returns integer as '
declare
  copy__extlink_id             alias for $1;  
  copy__target_folder_id       alias for $2;  
  copy__creation_user          alias for $3;  
  copy__creation_ip            alias for $4;  -- default null
  copy__name                   alias for $5;
  v_current_folder_id          cr_folders.folder_id%TYPE;
  v_name                       cr_items.name%TYPE;
  v_url                        cr_extlinks.url%TYPE;
  v_description                cr_extlinks.description%TYPE;
  v_label                      cr_extlinks.label%TYPE;
  v_extlink_id                 cr_extlinks.extlink_id%TYPE;
begin

  if content_folder__is_folder(copy__target_folder_id) = ''t'' then
    select
      parent_id
    into
      v_current_folder_id
    from
      cr_items
    where
      item_id = copy__extlink_id;

    -- can''t copy to the same folder

    select
      i.name, e.url, e.description, e.label
    into
      v_name, v_url, v_description, v_label
    from
      cr_extlinks e, cr_items i
    where
      e.extlink_id = i.item_id
    and
      e.extlink_id = copy__extlink_id;
	
	-- copy to a different folder, or same folder if name
	-- is different
    if copy__target_folder_id != v_current_folder_id  or ( v_name <> copy_name and copy_name is not null ) then

      if content_folder__is_registered(copy__target_folder_id,
        ''content_extlink'',''f'') = ''t'' then

        v_extlink_id := content_extlink__new(
            coalesce (copy__name, v_name),
            v_url,
            v_label,
            v_description,
            copy__target_folder_id,
            null,
            current_timestamp,
	    copy__creation_user,
	    copy__creation_ip,
            null
        );

      end if;
    end if;
  end if;

  return 0; 
end;' language 'plpgsql' stable;
