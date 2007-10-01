--- the update script below was added between d7 and d8 half a day after the change.
--- In case, one missed the upgrade, we add it to the current update again.

create or replace function content_folder__del (integer, boolean)
returns integer as '
declare
  delete__folder_id              alias for $1;  
  p_cascade_p                    alias for $2; -- default ''f''
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

create or replace function content_folder__delete (integer, boolean)
returns integer as '
declare
  delete__folder_id              alias for $1;  
  p_cascade_p                    alias for $2;  -- default ''f''
begin
        PERFORM content_folder__del(delete__folder_id,p_cascade_p);
  return 0; 
end;' language 'plpgsql';

select define_function_args('content_folder__move','folder_id,target_folder_id,name;null');

create or replace function content_folder__move (integer,integer,varchar)
returns integer as '
declare
  move__folder_id              alias for $1;  
  move__target_folder_id       alias for $2;
  move__name                   alias for $3; -- default null
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

select define_function_args('content_type__unregister_relation_type','content_type,target_type,relation_tag;null');

-- make it same as in oracle
select define_function_args('content_type__rotate_template','template_id,v_content_type,use_context');

-- new changes: documenting defaults for the arguments
--
-- note, that i changed the default value in function_args from  "lob" to null,
-- since apprarently the default in cr_items is "text" (therefore, "lob" was incorrect). 
-- However, the default in Oracle is "lob", i changed this here to "null"


select define_function_args('content_item__new','name,parent_id,item_id,locale,creation_date;now,creation_user,context_id,creation_ip,item_subtype;content_item,content_type;content_revision,title,description,mime_type;text/plain,nls_language,text,data,relation_tag,is_live;f,storage_type;null,package_id');

create or replace function content_item__new (
  cr_items.name%TYPE,
  cr_items.parent_id%TYPE,
  acs_objects.object_id%TYPE,
  cr_items.locale%TYPE,
  acs_objects.creation_date%TYPE,
  acs_objects.creation_user%TYPE,
  acs_objects.context_id%TYPE,
  acs_objects.creation_ip%TYPE,
  acs_object_types.object_type%TYPE,
  acs_object_types.object_type%TYPE, 
  cr_revisions.title%TYPE,
  cr_revisions.description%TYPE,
  cr_revisions.mime_type%TYPE,
  cr_revisions.nls_language%TYPE,
  varchar,
  cr_revisions.content%TYPE,
  cr_child_rels.relation_tag%TYPE,
  boolean,
  cr_items.storage_type%TYPE,
  acs_objects.package_id%TYPE
) returns integer as '
declare
  new__name       alias for $1;
  new__parent_id  alias for $2;  -- default null 
  new__item_id    alias for $3;  -- default null 
  new__locale     alias for $4;  -- default null 
  new__creation_date alias for $5;  -- default now
  new__creation_user alias for $6;  -- default null
  new__context_id    alias for $7;  -- default null
  new__creation_ip   alias for $8;  -- default null
  new__item_subtype  alias for $9;  -- default ''content_item''
  new__content_type  alias for $10; -- default ''content_revision''
  new__title         alias for $11; -- default null
  new__description   alias for $12; -- default null
  new__mime_type     alias for $13; -- default ''text/plain''
  new__nls_language  alias for $14; -- default null
  new__text          alias for $15; -- default null
  new__data          alias for $16; -- default null
  new__relation_tag  alias for $17; -- default null
  new__is_live       alias for $18; -- default ''f''
  new__storage_type  alias for $19; -- default null
  new__package_id    alias for $20; -- default null
  v_parent_id      cr_items.parent_id%TYPE;
  v_parent_type    acs_objects.object_type%TYPE;
  v_item_id        cr_items.item_id%TYPE;
  v_title          cr_revisions.title%TYPE;
  v_revision_id    cr_revisions.revision_id%TYPE;
  v_rel_id         acs_objects.object_id%TYPE;
  v_rel_tag        cr_child_rels.relation_tag%TYPE;
  v_context_id     acs_objects.context_id%TYPE;
  v_storage_type   cr_items.storage_type%TYPE;
begin

  -- place the item in the context of the pages folder if no
  -- context specified 

  if new__parent_id is null then
    select c_root_folder_id from content_item_globals into v_parent_id;
  else
    v_parent_id := new__parent_id;
  end if;

  -- Determine context_id
  if new__context_id is null then
    v_context_id := v_parent_id;
  else
    v_context_id := new__context_id;
  end if;

  -- use the name of the item if no title is supplied
  if new__title is null or new__title = '''' then
    v_title := new__name;
  else
    v_title := new__title;
  end if;

  if v_parent_id = -4 or 
    content_folder__is_folder(v_parent_id) = ''t'' then

    if v_parent_id != -4 and 
      content_folder__is_registered(
        v_parent_id, new__content_type, ''f'') = ''f'' then

      raise EXCEPTION ''-20000: This items content type % is not registered to this folder %'', new__content_type, v_parent_id;
    end if;

  else if v_parent_id != -4 then

     if new__relation_tag is null then
       v_rel_tag := content_item__get_content_type(v_parent_id) 
         || ''-'' || new__content_type;
     else
       v_rel_tag := new__relation_tag;
     end if;

     select object_type into v_parent_type from acs_objects
       where object_id = v_parent_id;

     if NOT FOUND then 
       raise EXCEPTION ''-20000: Invalid parent ID % specified in content_item.new'',  v_parent_id;
     end if;

     if content_item__is_subclass(v_parent_type, ''content_item'') = ''t'' and
        content_item__is_valid_child(v_parent_id, new__content_type, v_rel_tag) = ''f'' then

       raise EXCEPTION ''-20000: This items content type % is not allowed in this container %'', new__content_type, v_parent_id;
     end if;

  end if; end if;

  -- Create the object

  v_item_id := acs_object__new(
      new__item_id,
      new__item_subtype, 
      new__creation_date, 
      new__creation_user, 
      new__creation_ip, 
      v_context_id,
      ''t'',
      v_title,
      new__package_id
  );


  insert into cr_items (
    item_id, name, content_type, parent_id, storage_type
  ) values (
    v_item_id, new__name, new__content_type, v_parent_id, new__storage_type
  );

  -- if the parent is not a folder, insert into cr_child_rels
  if v_parent_id != -4 and
    content_folder__is_folder(v_parent_id) = ''f'' then

    v_rel_id := acs_object__new(
      null,
      ''cr_item_child_rel'',
      now(),
      null,
      null,
      v_parent_id,
      ''t'',
      v_rel_tag || '': '' || v_parent_id || '' - '' || v_item_id,
      new__package_id
    );

    insert into cr_child_rels (
      rel_id, parent_id, child_id, relation_tag, order_n
    ) values (
      v_rel_id, v_parent_id, v_item_id, v_rel_tag, v_item_id
    );

  end if;

  if new__data is not null then

    v_revision_id := content_revision__new(
        v_title,
	new__description,
        now(),
	new__mime_type,
	new__nls_language,
	new__data,
        v_item_id,
        null,
        new__creation_date, 
        new__creation_user, 
        new__creation_ip,
        new__package_id
        );

  elsif new__text is not null or new__title is not null then

    v_revision_id := content_revision__new(
        v_title,
	new__description,
        now(),
	new__mime_type,
        null,
	new__text,
	v_item_id,
        null,
        new__creation_date, 
        new__creation_user, 
        new__creation_ip,
        new__package_id
    );

  end if;

  -- make the revision live if is_live is true
  if new__is_live = ''t'' then
    PERFORM content_item__set_live_revision(v_revision_id);
  end if;

  return v_item_id;

end;' language 'plpgsql';

