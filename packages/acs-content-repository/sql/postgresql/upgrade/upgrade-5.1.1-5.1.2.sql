create or replace function content_item__edit_name (integer,varchar)
returns integer as '
declare
  edit_name__item_id                alias for $1;  
  edit_name__name                   alias for $2;  
  exists_id                      integer;       
begin
  select
    item_id
  into 
    exists_id
  from 
    cr_items
  where
    name = edit_name__name
  and 
    parent_id = (select 
	           parent_id
		 from
		   cr_items
		 where
		   item_id = edit_name__item_id);
  if NOT FOUND then
    update cr_items
      set name = edit_name__name
      where item_id = edit_name__item_id;
  else
    if exists_id != edit_name__item_id then
      raise EXCEPTION ''-20000: An item with the name % already exists in this directory.'', edit_name__name;
    end if;
  end if;

  return 0; 
end;' language 'plpgsql';

create or replace function content_folder__edit_name (integer,varchar,varchar,varchar)
returns integer as '
declare
  edit_name__folder_id              alias for $1;  
  edit_name__name                   alias for $2;  -- default null  
  edit_name__label                  alias for $3;  -- default null
  edit_name__description            alias for $4;  -- default null
  v_name_already_exists_p        integer;
begin

  if edit_name__name is not null and edit_name__name != '''' then
    PERFORM content_item__edit_name(edit_name__folder_id, edit_name__name);
  end if;

  if edit_name__label is not null and edit_name__label != '''' and 
     edit_name__description is not null and edit_name__description != '''' then 

    update cr_folders
      set label = edit_name__label,
      description = edit_name__description
      where folder_id = edit_name__folder_id;

  else if(edit_name__label is not null and edit_name__label != '''') and 
         (edit_name__description is null or edit_name__description = '''') then  
    update cr_folders
      set label = edit_name__label
      where folder_id = edit_name__folder_id;

  end if; end if;

  return 0; 
end;' language 'plpgsql';
