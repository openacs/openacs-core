-- add package_id to defined args for content_folder__new
select define_function_args('content_folder__new','name,label,description,parent_id,context_id,folder_id,creation_date;now,creation_user,creation_ip,security_inherit_p;t,package_id');


-- this one had a rename__label as rename_label so replace it.
create or replace function content_folder__rename (integer,varchar,varchar,varchar)
returns integer as '
declare
  rename__folder_id              alias for $1;  
  rename__name                   alias for $2;  -- default null  
  rename__label                  alias for $3;  -- default null
  rename__description            alias for $4;  -- default null
  v_name_already_exists_p        integer;
begin

  if rename__name is not null and rename__name != '''' then
    PERFORM content_item__rename(rename__folder_id, rename__name);
  end if;

  if rename__label is not null and rename__label != '''' then
    update acs_objects
    set title = rename__label
    where object_id = rename__folder_id;
  end if;

  if rename__label is not null and rename__label != '''' and 
     rename__description is not null and rename__description != '''' then 

    update cr_folders
      set label = rename__label,
      description = rename__description
      where folder_id = rename__folder_id;

  else if(rename__label is not null and rename__label != '''') and 
         (rename__description is null or rename__description = '''') then  
    update cr_folders
      set label = rename__label
      where folder_id = rename__folder_id;

  end if; end if;

  return 0; 
end;' language 'plpgsql';

