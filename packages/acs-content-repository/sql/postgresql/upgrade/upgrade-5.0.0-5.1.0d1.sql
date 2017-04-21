-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2004-01-22
-- @cvs-id $Id

-- add optional name parameter to copy and move functions

create or replace function content_item__copy (integer,integer,integer,varchar)
returns integer as '
declare
  item_id                alias for $1;  
  target_folder_id       alias for $2;  
  creation_user          alias for $3;  
  creation_ip            alias for $4;  -- default null  
  copy_id                cr_items.item_id%TYPE;
begin

  copy_id := content_item__copy2(item_id, target_folder_id, creation_user, creation_ip);

  return 0; 
end;' language 'plpgsql';

-- copy a content item to a target folder
-- 1) make sure we are not copying the item to an invalid location:
--   that is, the destination folder exists, is a valid folder,
--   and is not the current folder
-- 2) make sure the content type of the content item is registered
--   with the current folder
-- 3) create a new item with no revisions in the target folder
-- 4) copy the latest revision from the original item to the new item (if any)

create or replace function content_item__copy2 (integer,integer,integer,varchar)
returns integer as '
declare
  copy2__item_id                alias for $1;  
  copy2__target_folder_id       alias for $2;  
  copy2__creation_user          alias for $3;  
  copy2__creation_ip            alias for $4;  -- default null  
  v_current_folder_id           cr_folders.folder_id%TYPE;
  v_num_revisions               integer;       
  v_name                        cr_items.name%TYPE;
  v_content_type                cr_items.content_type%TYPE;
  v_locale                      cr_items.locale%TYPE;
  v_item_id                     cr_items.item_id%TYPE;
  v_revision_id                 cr_revisions.revision_id%TYPE;
  v_is_registered               boolean;       
  v_old_revision_id             cr_revisions.revision_id%TYPE;
  v_new_revision_id             cr_revisions.revision_id%TYPE;
  v_storage_type                cr_items.storage_type%TYPE;
begin

        perform content_item__copy (
                copy2__item_id,
                copy2__target_folder_id,
                copy2__creation_user,
                copy2__creation_ip,
                null
                );
        return copy2__item_id;

end;' language 'plpgsql';

create or replace function content_item__copy (
        integer,
        integer,
        integer,
        varchar,
        varchar
) returns integer as '
declare
  copy__item_id                alias for $1;  
  copy__target_folder_id       alias for $2;  
  copy__creation_user          alias for $3;  
  copy__creation_ip            alias for $4;  -- default null  
  copy__name                   alias for $5; -- default null
  v_current_folder_id           cr_folders.folder_id%TYPE;
  v_num_revisions               integer;       
  v_name                        cr_items.name%TYPE;
  v_content_type                cr_items.content_type%TYPE;
  v_locale                      cr_items.locale%TYPE;
  v_item_id                     cr_items.item_id%TYPE;
  v_revision_id                 cr_revisions.revision_id%TYPE;
  v_is_registered               boolean;       
  v_old_revision_id             cr_revisions.revision_id%TYPE;
  v_new_revision_id             cr_revisions.revision_id%TYPE;
  v_storage_type                cr_items.storage_type%TYPE;
begin

  -- call content_folder.copy if the item is a folder
  if content_folder__is_folder(copy__item_id) = ''t'' then
    PERFORM content_folder__copy(
        copy__item_id,
        copy__target_folder_id,
        copy__creation_user,
        copy__creation_ip,
	copy__name
    ); 
  -- call content_symlink.copy if the item is a symlink
  else if content_symlink__is_symlink(copy__item_id) = ''t'' then
    PERFORM content_symlink__copy(
        copy__item_id,
        copy__target_folder_id,
        copy__creation_user,
        copy__creation_ip,
	copy__name
    );
  -- call content_extlink.copy if the item is an url
  else if content_extlink__is_extlink(copy__item_id) = ''t'' then
    PERFORM content_extlink__copy(
        copy__item_id,
        copy__target_folder_id,
        copy__creation_user,
        copy__creation_ip,
	copy__name
    );
  -- make sure the target folder is really a folder
  else if content_folder__is_folder(copy__target_folder_id) = ''t'' then

    select
      parent_id
    into
      v_current_folder_id
    from
      cr_items
    where
      item_id = copy__item_id;

    select
      content_type, name, locale,
      coalesce(live_revision, latest_revision), storage_type
    into
      v_content_type, v_name, v_locale, v_revision_id, v_storage_type
    from
      cr_items
    where
      item_id = copy__item_id;

-- copy to a different folder, or allow copy to the same folder
-- with a different name

    if copy__target_folder_id != v_current_folder_id  or ( v_name != copy__name and copy__name is not null ) then
      -- make sure the content type of the item is registered to the folder
      v_is_registered := content_folder__is_registered(
          copy__target_folder_id,
          v_content_type,
          ''f''
      );

      if v_is_registered = ''t'' then
        -- create the new content item
        v_item_id := content_item__new(
            coalesce (copy__name, v_name),
            copy__target_folder_id,
            null,
            v_locale,
            now(),
            copy__creation_user,
            null,
            copy__creation_ip,
            ''content_item'',            
            v_content_type,
            null,
            null,
            ''text/plain'',
            null,
            null,
            v_storage_type
        );

	select
          latest_revision into v_old_revision_id
        from
       	  cr_items
        where
       	  item_id = copy__item_id;
	end if;

        -- copy the latest revision (if any) to the new item
	if v_old_revision_id is not null then
          v_new_revision_id := content_revision__copy (
              v_old_revision_id,
              null,
              v_item_id,
              copy__creation_user,
              copy__creation_ip
          );
        end if;

    end if;

  end if; end if; end if; end if;

  return v_item_id;

end;' language 'plpgsql';


create or replace function content_item__move (integer,integer)
returns integer as '
declare
  move__item_id                alias for $1;  
  move__target_folder_id       alias for $2;
begin
  perform content_item__move(
        move__item_id,
        move__target_folder_id,
        move__name
        );
return null;
end;' language 'plpgsql';

create or replace function content_item__move (integer,integer,varchar)
returns integer as '
declare
  move__item_id                alias for $1;  
  move__target_folder_id       alias for $2;
  move__name                   alias for $3;
begin

  if move__target_folder_id is null then 
        raise exception ''attempt to move item_id % to null folder_id'', move__item_id;
  end if;

  if content_folder__is_folder(move__item_id) = ''t'' then

    PERFORM content_folder__move(move__item_id, move__target_folder_id,move__name);

  else if content_folder__is_folder(move__target_folder_id) = ''t'' then
   

    if content_folder__is_registered(move__target_folder_id,
          content_item__get_content_type(move__item_id),''f'') = ''t'' and
       content_folder__is_registered(move__target_folder_id,
          content_item__get_content_type(content_symlink__resolve(move__item_id)),''f'') = ''t''
      then
    -- update the parent_id for the item

    update cr_items 
      set parent_id = move__target_folder_id,
          name = coalesce(move__name, name)
      where item_id = move__item_id;
    end if;

  end if; end if;

  return 0; 
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
            copy__creation_ip
        );

      end if;
    end if;
  end if;

  return 0; 
end;' language 'plpgsql' stable;

create or replace function content_folder__copy (integer,integer,integer,varchar)
returns integer as '
declare
  copy__folder_id              alias for $1;  
  copy__target_folder_id       alias for $2;  
  copy__creation_user          alias for $3;  
  copy__creation_ip            alias for $4;  -- default null  
  v_valid_folders_p            integer;        
  v_current_folder_id          cr_folders.folder_id%TYPE;
  v_name                       cr_items.name%TYPE;
  v_label                      cr_folders.label%TYPE;
  v_description                cr_folders.description%TYPE;
  v_new_folder_id              cr_folders.folder_id%TYPE;
  v_folder_contents_val        record;
begin
        v_new_folder_id := content_folder__copy (
                        copy__folder_id,
                        copy__target_folder_id,
                        copy__creation_user,
                        copy_creation_ip,
                        NULL
                        );
        return v_new_folder_id;
end;' language 'plpgsql';

create or replace function content_folder__copy (integer,integer,integer,varchar,varchar)
returns integer as '
declare
  copy__folder_id              alias for $1;  
  copy__target_folder_id       alias for $2;  
  copy__creation_user          alias for $3;  
  copy__creation_ip            alias for $4;  -- default null
  copy__name                   alias for $5; -- default null
  v_valid_folders_p            integer;        
  v_current_folder_id          cr_folders.folder_id%TYPE;
  v_name                       cr_items.name%TYPE;
  v_label                      cr_folders.label%TYPE;
  v_description                cr_folders.description%TYPE;
  v_new_folder_id              cr_folders.folder_id%TYPE;
  v_folder_contents_val        record;
begin

  select 
    count(*)
  into 
    v_valid_folders_p
  from 
    cr_folders
  where
    folder_id = copy__target_folder_id
  or 
    folder_id = copy__folder_id;

  select
    parent_id
  into
    v_current_folder_id
  from
    cr_items
  where
    item_id = copy__folder_id;  

  if copy__folder_id = content_item__get_root_folder(null) 
     or copy__folder_id = content_template__get_root_folder() 
     or copy__target_folder_id = copy__folder_id then
	    v_valid_folders_p := 0;
  end if;

    -- get the source folder info
    select
      name, label, description
    into
      v_name, v_label, v_description
    from 
      cr_items i, cr_folders f
    where
      f.folder_id = i.item_id
    and
      f.folder_id = copy__folder_id;

  if v_valid_folders_p = 2 then 

    if content_folder__is_sub_folder(copy__folder_id, copy__target_folder_id) != ''t'' or v_current_folder_id != copy__target_folder_id or (v_name != copy__name and copy__name is not null) then 

      -- create the new folder
      v_new_folder_id := content_folder__new(
          coalesce (copy__name, v_name),
          v_label,
          v_description,
          copy__target_folder_id,
          null,
          null,
          now(),
          copy__creation_user,
          copy__creation_ip
      );

      -- copy attributes of original folder
      insert into cr_folder_type_map
        select 
          v_new_folder_id as folder_id, content_type
        from
          cr_folder_type_map map
        where
          folder_id = copy__folder_id
        and
          -- do not register content_type if it is already registered
          not exists ( select 1 from cr_folder_type_map
                       where folder_id = v_new_folder_id 
                       and content_type = map.content_type ) ;

      -- for each item in the folder, copy it
      for v_folder_contents_val in select
                                     item_id
                                   from
                                     cr_items
                                   where
                                     parent_id = copy__folder_id 
      LOOP
        raise notice ''COPYING item %'',v_folder_contents_val.item_id;
        PERFORM content_item__copy(
            v_folder_contents_val.item_id,
            v_new_folder_id,
            copy__creation_user,
            copy__creation_ip    
        );

      end loop;
    end if;
  end if;

  return 0; 
end;' language 'plpgsql';

create or replace function content_folder__delete (integer, boolean)
returns integer as '
declare
  delete__folder_id              alias for $1;  
  p_cascade_p                    alias for $2;
  v_count                        integer;       
  v_child_row                    record;
  v_parent_id                    integer;  
  v_path                         varchar;     
  v_folder_sortkey               varbit;
begin

  if p_cascade_p = ''f'' then
    select count(*) into v_count from cr_items 
     where parent_id = delete__folder_id;
    -- check if the folder contains any items
    if v_count > 0 then
      v_path := content_item__get_path(delete__folder_id, null);
      raise EXCEPTION ''-20000: Folder ID % (%) cannot be deleted because it is not empty.'', delete__folder_id, v_path;
    end if;  
  else 
  -- delete children
    select into v_folder_sortkey tree_sortkey
    from cr_items where item_id=delete__folder_id;

    for v_child_row in select
        item_id, tree_sortkey, name
        from cr_items
        where tree_sortkey between v_folder_sortkey and tree_right(v_folder_sortkey)   
        and tree_sortkey != v_folder_sortkey
        order by tree_sortkey desc
    loop
        if content_folder__is_folder(v_child_row.item_id) then
          perform content_folder__delete(v_child_row.item_id);
        else
         perform content_item__delete(v_child_row.item_id);
        end if;
    end loop;
  end if;

  PERFORM content_folder__unregister_content_type(
      delete__folder_id,
      ''content_revision'',
      ''t'' 
  );

  delete from cr_folder_type_map
    where folder_id = delete__folder_id;

  select parent_id into v_parent_id from cr_items 
    where item_id = delete__folder_id;
  raise notice ''deleteing folder %'',delete__folder_id;
  PERFORM content_item__delete(delete__folder_id);

  -- check if any folders are left in the parent
  update cr_folders set has_child_folders = ''f'' 
    where folder_id = v_parent_id and not exists (
      select 1 from cr_items 
        where parent_id = v_parent_id and content_type = ''content_folder'');

  return 0; 
end;' language 'plpgsql';


create or replace function content_folder__delete (integer)
returns integer as '
declare
  delete__folder_id              alias for $1;  
  v_count                        integer;       
  v_parent_id                    integer;  
  v_path                         varchar;     
begin
        return content_folder__delete(
                delete__folder_id,
                ''f''
                );
end;' language 'plpgsql';

create or replace function content_folder__move (integer,integer)
returns integer as '
declare
  move__folder_id              alias for $1;  
  move__target_folder_id       alias for $2;  
begin

  perform content_folder__move (
                                move__folder_id,
                                move__target_folder_id,
                                NULL
                               );
  return null;
end;' language 'plpgsql';

create or replace function content_folder__move (integer,integer,varchar)
returns integer as '
declare
  move__folder_id              alias for $1;  
  move__target_folder_id       alias for $2;
  move__name                   alias for $3;
  v_source_folder_id           integer;       
  v_valid_folders_p            integer;
begin

  select 
    count(*)
  into 
    v_valid_folders_p
  from 
    cr_folders
  where
    folder_id = move__target_folder_id
  or 
    folder_id = move__folder_id;

  if v_valid_folders_p != 2 then
    raise EXCEPTION ''-20000: content_folder.move - Not valid folder(s)'';
  end if;

  if move__folder_id = content_item__get_root_folder(null) or
    move__folder_id = content_template__get_root_folder() then
    raise EXCEPTION ''-20000: content_folder.move - Cannot move root folder'';
  end if;
  
  if move__target_folder_id = move__folder_id then
    raise EXCEPTION ''-20000: content_folder.move - Cannot move a folder to itself'';
  end if;

  if content_folder__is_sub_folder(move__folder_id, move__target_folder_id) = ''t'' then
    raise EXCEPTION ''-20000: content_folder.move - Destination folder is subfolder'';
  end if;

  if content_folder__is_registered(move__target_folder_id,''content_folder'',''f'') != ''t'' then
    raise EXCEPTION ''-20000: content_folder.move - Destination folder does not allow subfolders'';
  end if;

  select parent_id into v_source_folder_id from cr_items 
    where item_id = move__folder_id;

   -- update the parent_id for the folder
   update cr_items 
     set parent_id = move__target_folder_id,
         name = coalesce ( move__name, name )
     where item_id = move__folder_id;

  -- update the has_child_folders flags

  -- update the source
  update cr_folders set has_child_folders = ''f'' 
    where folder_id = v_source_folder_id and not exists (
      select 1 from cr_items 
        where parent_id = v_source_folder_id 
          and content_type = ''content_folder'');

  -- update the destination
  update cr_folders set has_child_folders = ''t''
    where folder_id = move__target_folder_id;

  return 0; 
end;' language 'plpgsql';


select define_function_args('content_extlink__new','name,url,label,description,parent_id,extlink_id,creation_date;now,creation_user,creation_ip');

select define_function_args('content_folder__new','name,label,description,parent_id,context_id,folder_id,creation_date;now,creation_user,creation_ip,security_inherit_p');

select define_function_args('content_item__new','name,parent_id,item_id,locale,creation_date;now,creation_user,context_id,creation_ip,item_subtype;content_item,content_type;content_revision,title,description,mime_type;text/plain,nls_language,text,data,relation_tag,is_live;f,storage_type;lob');

select define_function_args('content_keyword__new','heading,description,parent_id,keyword_id,creation_date;now,creation_user,creation_ip,object_type;content_keyword');

select define_function_args('content_symlink__new','name,label,target_id,parent_id,symlink_id,creation_date;now,creation_user,creation_ip');

select define_function_args('content_template__new','name,parent_id,template_id,creation_date,creation_user,creation_ip');

select define_function_args('content_type__create_type','content_type,supertype;content_revision,pretty_name,pretty_plural,table_name,id_colum;XXX,name_method');

select define_function_args('content_type__create_attribute','content_type,attribute_name,datatype,pretty_name,pretty_plural,sort_order,default_value,column_spec;text');

-- DRB: PG version now verifies that the new content_type's supertype is indeed content_revision
-- or one of its descendants.

create or replace function content_type__create_type (varchar,varchar,varchar,varchar,varchar,varchar,varchar)
returns integer as '
declare
  create_type__content_type           alias for $1;  
  create_type__supertype              alias for $2;  -- default ''content_revision''  
  create_type__pretty_name            alias for $3;  
  create_type__pretty_plural          alias for $4;  
  create_type__table_name             alias for $5;
  create_type__id_column              alias for $6;  -- default ''XXX''
  create_type__name_method            alias for $7;  -- default null
  v_temp_p                            boolean;       
  v_supertype_table                   acs_object_types.table_name%TYPE;
                                        
begin

  if (create_type__supertype <> ''content_revision'')
      and (create_type__content_type <> ''content_revision'') then
    select count(*) > 0 into v_temp_p
    from  acs_object_type_supertype_map
    where object_type = create_type__supertype
    and ancestor_type = ''content_revision'';

    if not v_temp_p then
      raise EXCEPTION ''-20000: supertype % must be a subtype of content_revision'', create_type__supertype;
    end if;
  end if;

 -- create the attribute table if not already created

  select count(*) > 0 into v_temp_p 
    from pg_class
   where relname = lower(create_type__table_name);

  if NOT v_temp_p then
    select table_name into v_supertype_table from acs_object_types
      where object_type = create_type__supertype;

    execute ''create table '' || create_type__table_name || '' ('' ||
      create_type__id_column  || '' integer primary key references '' || 
      v_supertype_table || '')'';
  end if;

  PERFORM acs_object_type__create_type (
    create_type__content_type,
    create_type__pretty_name,
    create_type__pretty_plural,
    create_type__supertype,
    create_type__table_name,
    create_type__id_column,
    null,
    ''f'',
    null,
    create_type__name_method
  );

  PERFORM content_type__refresh_view(create_type__content_type);

  return 0; 
end;' language 'plpgsql';

select define_function_args('content_type__drop_type','content_type,drop_children_p;f,drop_table_p;f');

select define_function_args('content_type__drop_attribute','content_type,attribute_name,drop_column;f');

-- PG 7.3 now supports drop column ...

create or replace function content_type__drop_attribute (varchar,varchar,boolean)
returns integer as '
declare
  drop_attribute__content_type           alias for $1;  
  drop_attribute__attribute_name         alias for $2;  
  drop_attribute__drop_column            alias for $3;  -- default ''f''  
  v_attr_id                              acs_attributes.attribute_id%TYPE;
  v_table                                acs_object_types.table_name%TYPE;
begin

  -- Get attribute information 
  select 
    upper(t.table_name), a.attribute_id 
  into 
    v_table, v_attr_id
  from 
    acs_object_types t, acs_attributes a
  where 
    t.object_type = drop_attribute__content_type
  and 
    a.object_type = drop_attribute__content_type
  and
    a.attribute_name = drop_attribute__attribute_name;
    
  if NOT FOUND then
    raise EXCEPTION ''-20000: Attribute %:% does not exist in content_type.drop_attribute'', drop_attribute__content_type, drop_attribute__attribute_name;
  end if;

  -- Drop the attribute
  PERFORM acs_attribute__drop_attribute(drop_attribute__content_type, 
                                        drop_attribute__attribute_name);

  -- FIXME: postgresql does not support drop column.
  -- Drop the column if necessary
  if drop_attribute__drop_column then
      execute ''alter table '' || v_table || '' drop column '' ||
	drop_attribute__attribute_name || ''cascade'';

--    exception when others then
--      raise_application_error(-20000, ''Unable to drop column '' || 
--       v_table || ''.'' || attribute_name || '' in content_type.drop_attribute'');  
  end if;  

  PERFORM content_type__refresh_view(drop_attribute__content_type);

  return 0; 
end;' language 'plpgsql';

create or replace function content_type__is_content_type (varchar)
returns boolean as '
declare
  is_content_type__object_type            alias for $1;  
  v_is_content_type                       boolean;
begin

  if is_content_type__object_type = ''content_revision'' then

    v_is_content_type := ''t'';

  else    
    select count(*) > 0 into v_is_content_type
    from acs_object_type_supertype_map
    where object_type = is_content_type__object_type 
    and ancestor_type = ''content_revision'';
  end if;
  
  return v_is_content_type;
 
end;' language 'plpgsql' stable;



/***********************************************************************/
/* Lars: Make trigger handle parent_id's that are not cr_items         */
/***********************************************************************/

drop trigger cr_items_tree_insert_tr on cr_items;
drop function cr_items_tree_insert_tr();

create function cr_items_tree_insert_tr () returns opaque as '
declare
    v_parent_sk      varbit default null;
    v_max_value      integer;
    v_parent_id      integer;
begin
    -- Lars: If the parent is not a cr_item, we treat it as if it was null.
    select item_id
    into   v_parent_id
    from   cr_items
    where  item_id = new.parent_id;

    if v_parent_id is null then 

        -- Lars: Treat all items with a non-cr_item parent as one big pool wrt tree_sortkeys
        -- The old algorithm had tree_sortkeys start from zero for each different parent

        select max(tree_leaf_key_to_int(child.tree_sortkey)) into v_max_value 
          from cr_items child
         where child.parent_id not in (select item_id from cr_items);
    else 
        select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value 
          from cr_items 
         where parent_id = new.parent_id;

        select tree_sortkey into v_parent_sk 
          from cr_items 
         where item_id = new.parent_id;
    end if;

    new.tree_sortkey := tree_next_key(v_parent_sk, v_max_value);

    return new;
end;' language 'plpgsql';

create trigger cr_items_tree_insert_tr before insert
on cr_items for each row 
execute procedure cr_items_tree_insert_tr ();



drop trigger cr_items_tree_update_tr on cr_items;
drop function cr_items_tree_update_tr();

create function cr_items_tree_update_tr () returns opaque as '
declare
        v_parent_sk     varbit default null;
        v_max_value     integer;
        p_id            integer;
        v_rec           record;
        clr_keys_p      boolean default ''t'';
begin
        if new.item_id = old.item_id and 
           ((new.parent_id = old.parent_id) or
            (new.parent_id is null and old.parent_id is null)) then

           return new;

        end if;

        for v_rec in select item_id
                       from cr_items 
                      where tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey)
                   order by tree_sortkey
        LOOP
            if clr_keys_p then
               update cr_items set tree_sortkey = null
               where tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey);
               clr_keys_p := ''f'';
            end if;
            
            -- Lars: If the parent is not a cr_item, we treat it as if it was null.
            select parent.item_id 
              into p_id
              from cr_items parent, 
                   cr_items child
             where child.item_id = v_rec.item_id
             and   parent.item_id = child.parent_id;

            if p_id is null then 

                -- Lars: Treat all items with a non-cr_item parent as one big pool wrt tree_sortkeys
                -- The old algorithm had tree_sortkeys start from zero for each different parent

                select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value
                  from cr_items child
                 where child.parent_id not in (select item_id from cr_items);
            else 
                select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value
                  from cr_items 
                 where parent_id = p_id;

                select tree_sortkey into v_parent_sk 
                  from cr_items 
                 where item_id = p_id;
            end if;

            update cr_items 
               set tree_sortkey = tree_next_key(v_parent_sk, v_max_value)
             where item_id = v_rec.item_id;

        end LOOP;

        return new;

end;' language 'plpgsql';

create trigger cr_items_tree_update_tr after update 
on cr_items
for each row 
execute procedure cr_items_tree_update_tr ();


-- Now update all the existing tree_sortkeys
-- This will cause the entire set of values to be shifted,
-- i.e. it will no longer start at zero, but at max(tree_sortkey)+1.
-- Don't know how to avoid this.
update cr_items set parent_id = parent_id;


-- OpenOffice MIME types

insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Spreadsheet'   , 'application/vnd.sun.xml.calc', 'sxc');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Spreadsheet Template', 'application/vnd.sun.xml.calc.template', 'stc');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Draw', 'application/vnd.sun.xml.draw', 'sxd');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Draw Template', 'application/vnd.sun.xml.draw.template', 'std');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Impress', 'application/vnd.sun.xml.impress', 'sxi');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Impress Template', 'application/vnd.sun.xml.impress.template', 'sti');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Math', 'application/vnd.sun.xml.math', 'sxm');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Writer', 'application/vnd.sun.xml.writer', 'sxw');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Writer Global', 'application/vnd.sun.xml.writer.global', 'sxg');
insert into cr_mime_types (label,mime_type,file_extension) values ('OpenOffice Writer Template', 'application/vnd.sun.xml.writer.template', 'stw');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxc', 'application/vnd.sun.xml.calc');
insert into cr_extension_mime_type_map (extension, mime_type) values ('stc', 'application/vnd.sun.xml.calc.template');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxd', 'application/vnd.sun.xml.draw');
insert into cr_extension_mime_type_map (extension, mime_type) values ('std', 'application/vnd.sun.xml.draw.template');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxi', 'application/vnd.sun.xml.impress');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sti', 'application/vnd.sun.xml.impress.template');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxm', 'application/vnd.sun.xml.math');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxw', 'application/vnd.sun.xml.writer');
insert into cr_extension_mime_type_map (extension, mime_type) values ('sxg', 'application/vnd.sun.xml.writer.global');
insert into cr_extension_mime_type_map (extension, mime_type) values ('stw', 'application/vnd.sun.xml.writer.template');
