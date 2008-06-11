-- Data model to support content repository of the ArsDigita
-- Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

create or replace view content_item_globals as 
select -100 as c_root_folder_id;

select define_function_args('content_item__get_root_folder','item_id');
create or replace function content_item__get_root_folder (integer)
returns integer as '
declare
  get_root_folder__item_id                alias for $1;  -- default null 
  v_folder_id                             cr_folders.folder_id%TYPE;
begin

  if get_root_folder__item_id is NULL or get_root_folder__item_id in (-4,-100,-200) then

    select c_root_folder_id from content_item_globals into v_folder_id;

  else

    select i2.item_id into v_folder_id
    from cr_items i1, cr_items i2
    where i2.parent_id = -4
    and i1.item_id = get_root_folder__item_id
    and i1.tree_sortkey between i2.tree_sortkey and tree_right(i2.tree_sortkey);

    if NOT FOUND then
       raise EXCEPTION '' -20000: Could not find a root folder for item ID %. Either the item does not exist or its parent value is corrupted.'', get_root_folder__item_id;
    end if;
  end if;    

  return v_folder_id;
 
end;' language 'plpgsql' stable;

-- new 19 param version of content_item__new (now its 20 with package_id)

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
  cr_items.storage_type%TYPE
) returns integer as '
declare
  new__name       alias for $1;
  new__parent_id  alias for $2;
  new__item_id    alias for $3;
  new__locale     alias for $4;
  new__creation_date alias for $5;
  new__creation_user alias for $6;
  new__context_id    alias for $7;
  new__creation_ip   alias for $8;
  new__item_subtype  alias for $9;
  new__content_type  alias for $10;
  new__title         alias for $11;
  new__description   alias for $12;
  new__mime_type     alias for $13;
  new__nls_language  alias for $14;
  new__text          alias for $15;
  new__data          alias for $16;
  new__relation_tag  alias for $17;
  new__is_live       alias for $18;
  new__storage_type  alias for $19;
  v_item_id        cr_items.item_id%TYPE;
begin
  v_item_id := content_item__new (new__name, new__parent_id, new__item_id, new__locale,
               new__creation_date, new__creation_user, new__context_id, new__creation_ip,
               new__item_subtype, new__content_type, new__title, new__description,
               new__mime_type, new__nls_language, new__text, new__data, new__relation_tag,
               new__is_live, new__storage_type, null);

  return v_item_id;

end;' language 'plpgsql';

--
create or replace function content_item__new (varchar,integer,integer,varchar,timestamptz,integer,integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer)
returns integer as '
declare
  new__name                   alias for $1;  
  new__parent_id              alias for $2;  -- default null  
  new__item_id                alias for $3;  -- default null
  new__locale                 alias for $4;  -- default null
  new__creation_date          alias for $5;  -- default now()
  new__creation_user          alias for $6;  -- default null
  new__context_id             alias for $7;  -- default null
  new__creation_ip            alias for $8;  -- default null
  new__item_subtype           alias for $9;  -- default ''content_item''
  new__content_type           alias for $10; -- default ''content_revision''
  new__title                  alias for $11; -- default null
  new__description            alias for $12; -- default null
  new__mime_type              alias for $13; -- default ''text/plain''
  new__nls_language           alias for $14; -- default null
  new__text                   alias for $15; -- default null
  new__storage_type           alias for $16; -- check in (''text'',''file'')
  new__package_id             alias for $17; -- default null
  new__relation_tag           varchar default null;
  new__is_live                boolean default ''f'';

  v_parent_id                 cr_items.parent_id%TYPE;
  v_parent_type               acs_objects.object_type%TYPE;
  v_item_id                   cr_items.item_id%TYPE;
  v_revision_id               cr_revisions.revision_id%TYPE;
  v_title                     cr_revisions.title%TYPE;
  v_rel_id                    acs_objects.object_id%TYPE;
  v_rel_tag                   cr_child_rels.relation_tag%TYPE;
  v_context_id                acs_objects.context_id%TYPE;
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

  if v_parent_id = -4 or 
    content_folder__is_folder(v_parent_id) = ''t'' then

    if v_parent_id != -4 and 
      content_folder__is_registered(
        v_parent_id, new__content_type, ''f'') = ''f'' then

      raise EXCEPTION ''-20000: This items content type % is not registered to this folder %'', new__content_type, v_parent_id;
    end if;

  else if v_parent_id != -4 then

     select object_type into v_parent_type from acs_objects
       where object_id = v_parent_id;

     if NOT FOUND then 
       raise EXCEPTION ''-20000: Invalid parent ID % specified in content_item.new'',  v_parent_id;
     end if;

     if content_item__is_subclass(v_parent_type, ''content_item'') = ''t'' and
	content_item__is_valid_child(v_parent_id, new__content_type) = ''f'' then

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
      coalesce(new__title,new__name),
      new__package_id
  );

  insert into cr_items (
    item_id, name, content_type, parent_id, storage_type
  ) values (
    v_item_id, new__name, new__content_type, v_parent_id, new__storage_type
  );

  -- if the parent is not a folder, insert into cr_child_rels
  if v_parent_id != -4 and
    content_folder__is_folder(v_parent_id) = ''f'' and 
    content_item__is_valid_child(v_parent_id, new__content_type) = ''t'' then

    if new__relation_tag is null then
      v_rel_tag := content_item__get_content_type(v_parent_id) 
        || ''-'' || new__content_type;
    else
      v_rel_tag := new__relation_tag;
    end if;

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

  -- use the name of the item if no title is supplied
  if new__title is null then
    v_title := new__name;
  else
    v_title := new__title;
  end if;

  if new__title is not null or 
     new__text is not null then

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

create or replace function content_item__new (varchar,integer,integer,varchar,timestamptz,integer,integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar)
returns integer as '
declare
  new__name                   alias for $1;  
  new__parent_id              alias for $2;  -- default null  
  new__item_id                alias for $3;  -- default null
  new__locale                 alias for $4;  -- default null
  new__creation_date          alias for $5;  -- default now()
  new__creation_user          alias for $6;  -- default null
  new__context_id             alias for $7;  -- default null
  new__creation_ip            alias for $8;  -- default null
  new__item_subtype           alias for $9;  -- default ''content_item''
  new__content_type           alias for $10; -- default ''content_revision''
  new__title                  alias for $11; -- default null
  new__description            alias for $12; -- default null
  new__mime_type              alias for $13; -- default ''text/plain''
  new__nls_language           alias for $14; -- default null
  new__text                   alias for $15; -- default null
  new__storage_type           alias for $16; -- check in (''text'',''file'')
  v_item_id                   cr_items.item_id%TYPE;
begin
  v_item_id := content_item__new (new__name, new__parent_id, new__item_id, new__locale,
               new__creation_date, new__creation_user, new__context_id, new__creation_ip,
               new__item_subtype, new__content_type, new__title, new__description,
               new__mime_type, new__nls_language, new__text, new__storage_type, null::integer);

  return v_item_id;
 
end;' language 'plpgsql';

create or replace function content_item__new (varchar,integer,integer,varchar,timestamptz,integer,integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer)
returns integer as '
declare
  new__name                   alias for $1;  
  new__parent_id              alias for $2;  -- default null  
  new__item_id                alias for $3;  -- default null
  new__locale                 alias for $4;  -- default null
  new__creation_date          alias for $5;  -- default now()
  new__creation_user          alias for $6;  -- default null
  new__context_id             alias for $7;  -- default null
  new__creation_ip            alias for $8;  -- default null
  new__item_subtype           alias for $9;  -- default ''content_item''
  new__content_type           alias for $10; -- default ''content_revision''
  new__title                  alias for $11; -- default null
  new__description            alias for $12; -- default null
  new__mime_type              alias for $13; -- default ''text/plain''
  new__nls_language           alias for $14; -- default null
-- changed to integer for blob_id
  new__data                   alias for $15; -- default null
  new__package_id             alias for $16; -- default null
  new__relation_tag           varchar default null;
  new__is_live                boolean default ''f'';

  v_parent_id                 cr_items.parent_id%TYPE;
  v_parent_type               acs_objects.object_type%TYPE;
  v_item_id                   cr_items.item_id%TYPE;
  v_revision_id               cr_revisions.revision_id%TYPE;
  v_title                     cr_revisions.title%TYPE;
  v_rel_id                    acs_objects.object_id%TYPE;
  v_rel_tag                   cr_child_rels.relation_tag%TYPE;
  v_context_id                acs_objects.context_id%TYPE;
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

     select object_type into v_parent_type from acs_objects
       where object_id = v_parent_id;

     if NOT FOUND then 
       raise EXCEPTION ''-20000: Invalid parent ID % specified in content_item.new'',  v_parent_id;
     end if;

     if content_item__is_subclass(v_parent_type, ''content_item'') = ''t'' and
	content_item__is_valid_child(v_parent_id, new__content_type) = ''f'' then

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
    v_item_id, new__name, new__content_type, v_parent_id, ''lob''
  );

  -- if the parent is not a folder, insert into cr_child_rels
  if v_parent_id != -4 and
    content_folder__is_folder(v_parent_id) = ''f'' and 
    content_item__is_valid_child(v_parent_id, new__content_type) = ''t'' then

    if new__relation_tag is null or new__relation_tag = '''' then
      v_rel_tag := content_item__get_content_type(v_parent_id) 
        || ''-'' || new__content_type;
    else
      v_rel_tag := new__relation_tag;
    end if;

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

  -- create the revision if data or title is not null

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

  elsif new__title is not null then

    v_revision_id := content_revision__new(
	v_title,
	new__description,
        now(),
	new__mime_type,
        null,
	null,
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

create or replace function content_item__new (varchar,integer,integer,varchar,timestamptz,integer,integer,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer)
returns integer as '
declare
  new__name                   alias for $1;  
  new__parent_id              alias for $2;  -- default null  
  new__item_id                alias for $3;  -- default null
  new__locale                 alias for $4;  -- default null
  new__creation_date          alias for $5;  -- default now()
  new__creation_user          alias for $6;  -- default null
  new__context_id             alias for $7;  -- default null
  new__creation_ip            alias for $8;  -- default null
  new__item_subtype           alias for $9;  -- default ''content_item''
  new__content_type           alias for $10; -- default ''content_revision''
  new__title                  alias for $11; -- default null
  new__description            alias for $12; -- default null
  new__mime_type              alias for $13; -- default ''text/plain''
  new__nls_language           alias for $14; -- default null
-- changed to integer for blob_id
  new__data                   alias for $15; -- default null
  v_item_id                   cr_items.item_id%TYPE;
begin
  v_item_id := content_item__new (new__name, new__parent_id, new__item_id, new__locale,
               new__creation_date, new__creation_user, new__context_id, new__creation_ip,
               new__item_subtype, new__content_type, new__title, new__description,
               new__mime_type, new__nls_language, new__data, null::integer);

  return v_item_id;
 
end;' language 'plpgsql';

create or replace function content_item__new(varchar,integer,varchar,text,text,integer) 
returns integer as '
declare
        new__name               alias for $1;
        new__parent_id          alias for $2;  -- default null
        new__title              alias for $3;  -- default null
        new__description        alias for $4;  -- default null
        new__text               alias for $5;  -- default null
        new__package_id         alias for $6;  -- default null
begin
        return content_item__new(new__name,
                                 new__parent_id,
                                 null,
                                 null,
                                 now(),
                                 null,
                                 null,
                                 null,
                                 ''content_item'',
                                 ''content_revision'',   
                                 new__title,
                                 new__description,
                                 ''text/plain'',
                                 null,
                                 new__text,
                                 ''text'',
                                 new__package_id
               );

end;' language 'plpgsql';

create or replace function content_item__new(varchar,integer,varchar,text,text) 
returns integer as '
declare
        new__name               alias for $1;
        new__parent_id          alias for $2;  -- default null
        new__title              alias for $3;  -- default null
        new__description        alias for $4;  -- default null
        new__text               alias for $5;  -- default null
begin
        return content_item__new(new__name, new__parent_id, new__title, new__description,
                                 new__text, null);

end;' language 'plpgsql';

create or replace function content_item__new(varchar,integer,integer) returns integer as '
declare
        new__name        alias for $1;
        new__parent_id   alias for $2;
        new__package_id  alias for $3;
begin
        return content_item__new(new__name, new__parent_id, null, null, null, new__package_id);
end;' language 'plpgsql';

create or replace function content_item__new(varchar,integer) returns integer as '
declare
        new__name       alias for $1;
        new__parent_id  alias for $2;
begin
        return content_item__new(new__name, new__parent_id, null, null, null, null);

end;' language 'plpgsql';

-- function new -- sets security_inherit_p to FALSE -DaveB

create or replace function content_item__new ( integer, varchar, integer, varchar, timestamptz, integer, integer, varchar, boolean, varchar, text, varchar, boolean, varchar,varchar,varchar,integer)
returns integer as '
declare
  new__item_id                alias for $1; --default null
  new__name                   alias for $2;  
  new__parent_id              alias for $3;  -- default null  
  new__title                  alias for $4; -- default null
  new__creation_date	      alias for $5; -- default now()
  new__creation_user	      alias for $6; -- default null
  new__context_id	      alias for $7; -- default null
  new__creation_ip	      alias for $8; -- default null
  new__is_live		      alias for $9; -- default ''f''
  new__mime_type	      alias for $10; 
  new__text		      alias for $11; -- default null
  new__storage_type	      alias for $12; -- check in (''text'', ''file'') 
  new__security_inherit_p     alias for $13; -- default ''t''
  new__storage_area_key       alias for $14; -- default ''CR_FILES''
  new__item_subtype	      alias for $15;
  new__content_type	      alias for $16; 
  new__package_id	      alias for $17; -- default null
  new__description	      varchar default null;
  new__relation_tag           varchar default null;
  new__nls_language	      varchar default null; 
  v_parent_id                 cr_items.parent_id%TYPE;
  v_parent_type               acs_objects.object_type%TYPE;
  v_item_id                   cr_items.item_id%TYPE;
  v_revision_id               cr_revisions.revision_id%TYPE;
  v_title                     cr_revisions.title%TYPE;
  v_rel_id                    acs_objects.object_id%TYPE;
  v_rel_tag                   cr_child_rels.relation_tag%TYPE;
  v_context_id                acs_objects.context_id%TYPE;
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

     select object_type into v_parent_type from acs_objects
       where object_id = v_parent_id;

     if NOT FOUND then 
       raise EXCEPTION ''-20000: Invalid parent ID % specified in content_item.new'',  v_parent_id;
     end if;

     if content_item__is_subclass(v_parent_type, ''content_item'') = ''t'' and
	content_item__is_valid_child(v_parent_id, new__content_type) = ''f'' then

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
      new__security_inherit_p,
      v_title,
      new__package_id
  );

  insert into cr_items (
    item_id, name, content_type, parent_id, storage_type, storage_area_key
  ) values (
    v_item_id, new__name, new__content_type, v_parent_id, new__storage_type,
    new__storage_area_key
  );

  -- if the parent is not a folder, insert into cr_child_rels
  if v_parent_id != -4 and
    content_folder__is_folder(v_parent_id) = ''f'' and 
    content_item__is_valid_child(v_parent_id, new__content_type) = ''t'' then

    if new__relation_tag is null then
      v_rel_tag := content_item__get_content_type(v_parent_id) 
        || ''-'' || new__content_type;
    else
      v_rel_tag := new__relation_tag;
    end if;

    v_rel_id := acs_object__new(
      null,
      ''cr_item_child_rel'',
      new__creation_date,
      null,
      null,
      v_parent_id,
      ''f'',
      v_rel_tag || '': '' || v_parent_id || '' - '' || v_item_id,
      new__package_id
    );

    insert into cr_child_rels (
      rel_id, parent_id, child_id, relation_tag, order_n
    ) values (
      v_rel_id, v_parent_id, v_item_id, v_rel_tag, v_item_id
    );

  end if;

  if new__title is not null or 
     new__text is not null then

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

create or replace function content_item__new ( integer, varchar, integer, varchar, timestamptz, integer, integer, varchar, boolean, varchar, text, varchar, boolean, varchar,varchar,varchar)
returns integer as '
declare
  new__item_id                alias for $1; --default null
  new__name                   alias for $2;  
  new__parent_id              alias for $3;  -- default null  
  new__title                  alias for $4; -- default null
  new__creation_date	      alias for $5; -- default now()
  new__creation_user	      alias for $6; -- default null
  new__context_id	      alias for $7; -- default null
  new__creation_ip	      alias for $8; -- default null
  new__is_live		      alias for $9; -- default ''f''
  new__mime_type	      alias for $10; 
  new__text		      alias for $11; -- default null
  new__storage_type	      alias for $12; -- check in (''text'', ''file'') 
  new__security_inherit_p     alias for $13; -- default ''t''
  new__storage_area_key       alias for $14; -- default ''CR_FILES''
  new__item_subtype	      alias for $15;
  new__content_type	      alias for $16; 
  v_item_id                   cr_items.item_id%TYPE;
begin
  v_item_id := content_item__new (new__item_id, new__name, new__parent_id, new__title,
               new__creation_date, new__creation_user, new__context_id, new__creation_ip,
               new__is_live, new__mime_type, new__text, new__storage_type,
               new__security_inherit_p, new__storage_area_key, new__item_subtype,
               new__content_type, null);

  return v_item_id;

end;' language 'plpgsql';

select define_function_args('content_item__is_published','item_id');
create or replace function content_item__is_published (integer)
returns boolean as '
declare
  is_published__item_id                alias for $1;  
begin

  return
    count(*) > 0
  from
    cr_items
  where
    live_revision is not null
  and
    publish_status = ''live''
  and
    item_id = is_published__item_id;
 
end;' language 'plpgsql' stable;

select define_function_args('content_item__is_publishable','item_id');
create or replace function content_item__is_publishable (integer)
returns boolean as '
declare
  is_publishable__item_id                alias for $1;  
  v_child_count                          integer;       
  v_rel_count                            integer;       
  v_content_type			 varchar;
  v_template_id                          cr_templates.template_id%TYPE;
  v_child_type                           record;
  v_rel_type                             record;
  -- v_pub_wf                               record;
begin
  -- check valid item_id
  select content_item__get_content_type(is_publishable__item_id) into v_content_type;

  if v_content_type is null then 
	raise exception ''content_item__is_publishable item_id % invalid'',is_publishable__item_id;
  end if;

  -- validate children
  -- make sure the # of children of each type fall between min_n and max_n
  for v_child_type in select
                        child_type, min_n, max_n
                      from
                        cr_type_children
                      where
                        parent_type = v_content_type 
	                and (min_n is not null or max_n is not null)
  LOOP
    select
      count(rel_id) into v_child_count
    from
      cr_child_rels
    where
      parent_id = is_publishable__item_id
    and
      content_item__get_content_type(child_id) = v_child_type.child_type;

    -- make sure # of children is in range
    if v_child_type.min_n is not null 
      and v_child_count < v_child_type.min_n then
      return ''f'';
    end if;
    if v_child_type.max_n is not null
      and v_child_count > v_child_type.max_n then
      return ''f'';
    end if;

  end LOOP;

  -- validate relations
  -- make sure the # of ext links of each type fall between min_n and max_n
  -- only check if one of min_n max_n not null
  for v_rel_type in select
                      target_type, min_n, max_n
                    from
                      cr_type_relations
                    where
                      content_type = v_content_type
		      and (max_n is not null or min_n is not null)
  LOOP
    select
      count(rel_id) into v_rel_count
    from
      cr_item_rels i, acs_objects o
    where
      i.related_object_id = o.object_id
    and
      i.item_id = is_publishable__item_id
    and
      coalesce(content_item__get_content_type(o.object_id),o.object_type) = v_rel_type.target_type;
      
    -- make sure # of object relations is in range
    if v_rel_type.min_n is not null 
      and v_rel_count < v_rel_type.min_n then
      return ''f'';
    end if;
    if v_rel_type.max_n is not null 
      and v_rel_count > v_rel_type.max_n then
      return ''f'';
    end if;
  end loop;

  -- validate publishing workflows
  -- make sure any ''publishing_wf'' associated with this item are finished
  -- KG: logic is wrong here.  Only the latest workflow matters, and even
  -- that is a little problematic because more than one workflow may be
  -- open on an item.  In addition, this should be moved to CMS.
  
  -- Removed this as having workflow stuff in the CR is just plain wrong.
  -- DanW, Aug 25th, 2001.

  --   for v_pub_wf in  select
  --                      case_id, state
  --                    from
  --                      wf_cases
  --                    where
  --                      workflow_key = ''publishing_wf''
  --                    and
  --                      object_id = is_publishable__item_id
  -- 
  --   LOOP
  --     if v_pub_wf.state != ''finished'' then
  --        return ''f'';
  --     end if;
  --   end loop;

  -- if NOT FOUND then 
  --   return ''f'';
  -- end if;

  return ''t'';
 
end;' language 'plpgsql' stable;

select define_function_args('content_item__is_valid_child','item_id,content_type,relation_tag');
create or replace function content_item__is_valid_child (integer,varchar,varchar)
returns boolean as '
declare
  is_valid_child__item_id                alias for $1;  
  is_valid_child__content_type           alias for $2;  
  is_valid_child__relation_tag                alias for $3;
  v_is_valid_child                       boolean;       
  v_max_children                         cr_type_children.max_n%TYPE;
  v_n_children                           integer;       
  v_null_exists				 boolean;
begin

  v_is_valid_child := ''f'';

  -- first check if content_type is a registered child_type
  select
    sum(max_n) into v_max_children
  from
    cr_type_children
  where
    parent_type = content_item__get_content_type(is_valid_child__item_id)
  and
    child_type = is_valid_child__content_type
    and 
      (is_valid_child__relation_tag is null 
       or is_valid_child__relation_tag = relation_tag);

  if NOT FOUND then 
      return ''f'';
  end if;

  -- if the max is null then infinite number is allowed
  if v_max_children is null then
    return ''t'';
  end if;
  
  -- next check if there are already max_n children of that content type
  select
    count(rel_id) into v_n_children
  from
    cr_child_rels
  where
    parent_id = is_valid_child__item_id
  and
    content_item__get_content_type(child_id) = is_valid_child__content_type
  and 
    (is_valid_child__relation_tag is null 
     or is_valid_child__relation_tag = relation_tag);

  if NOT FOUND then 
     return ''f'';
  end if;

  if v_n_children < v_max_children then
    v_is_valid_child := ''t'';
  end if;

  return v_is_valid_child;
 
end;' language 'plpgsql' stable;


create or replace function content_item__is_valid_child (integer,varchar)
returns boolean as '
declare
  is_valid_child__item_id                alias for $1;  
  is_valid_child__content_type           alias for $2;  
  v_is_valid_child                       boolean;       
  v_max_children                         cr_type_children.max_n%TYPE;
  v_n_children                           integer;       
begin

  v_is_valid_child := ''f'';

  -- first check if content_type is a registered child_type
  select
    sum(max_n) into v_max_children
  from
    cr_type_children
  where
    parent_type = content_item__get_content_type(is_valid_child__item_id)
  and
    child_type = is_valid_child__content_type;

  if NOT FOUND then 
     return ''f'';
  end if;

  -- if the max is null then infinite number is allowed
  if v_max_children is null then
    return ''t'';
  end if;

  -- next check if there are already max_n children of that content type
  select
    count(rel_id) into v_n_children
  from
    cr_child_rels
  where
    parent_id = is_valid_child__item_id
  and
    content_item__get_content_type(child_id) = is_valid_child__content_type;

  if NOT FOUND then 
     return ''f'';
  end if;

  if v_n_children < v_max_children then
    v_is_valid_child := ''t'';
  end if;

  return v_is_valid_child;
 
end;' language 'plpgsql' stable;


/* delete a content item
 1) delete all associated workflows
 2) delete all symlinks associated with this object
 3) delete any revisions for this item
 4) unregister template relations
 5) delete all permissions associated with this item
 6) delete keyword associations
 7) delete all associated comments */

select define_function_args('content_item__del','item_id');
create or replace function content_item__del (integer)
returns integer as '
declare
  delete__item_id                alias for $1;  
  -- v_wf_cases_val                 record;
  v_symlink_val                  record;
  v_revision_val                 record;
  v_rel_val                      record;
begin

  -- Removed this as having workflow stuff in the CR is just plain wrong.
  -- DanW, Aug 25th, 2001.

  --   raise NOTICE ''Deleting associated workflows...'';
  -- 1) delete all workflow cases associated with this item
  --   for v_wf_cases_val in select
  --                           case_id
  --                         from
  --                           wf_cases
  --                         where
  --                           object_id = delete__item_id 
  --   LOOP
  --     PERFORM workflow_case__delete(v_wf_cases_val.case_id);
  --   end loop;

  -- 2) delete all symlinks to this item
  for v_symlink_val in select 
                         symlink_id
                       from 
                         cr_symlinks
                       where 
                         target_id = delete__item_id 
  LOOP
    PERFORM content_symlink__delete(v_symlink_val.symlink_id);
  end loop;

  delete from cr_release_periods
    where item_id = delete__item_id;

  update cr_items set live_revision = null, latest_revision = null where item_id = delete__item_id;

  -- 3) delete all revisions of this item
  delete from cr_item_publish_audit
    where item_id = delete__item_id;

  for v_revision_val in select
                          revision_id 
                        from
                          cr_revisions
                        where
                          item_id = delete__item_id 
  LOOP
    PERFORM acs_object__delete(v_revision_val.revision_id);
  end loop;
  
  -- 4) unregister all templates to this item
  delete from cr_item_template_map
    where item_id = delete__item_id; 

  -- Delete all relations on this item
  for v_rel_val in select
                     rel_id
                   from
                     cr_item_rels
                   where
                     item_id = delete__item_id
                   or
                     related_object_id = delete__item_id 
  LOOP
    PERFORM acs_rel__delete(v_rel_val.rel_id);
  end loop;  

  for v_rel_val in select
                     rel_id
                   from
                     cr_child_rels
                   where
                     child_id = delete__item_id 
  LOOP
    PERFORM acs_rel__delete(v_rel_val.rel_id);
  end loop;  

  for v_rel_val in select
                     rel_id, child_id
                   from
                     cr_child_rels
                   where
                     parent_id = delete__item_id 
  LOOP
    PERFORM acs_rel__delete(v_rel_val.rel_id);
    PERFORM content_item__delete(v_rel_val.child_id);
  end loop;  

  -- 5) delete associated permissions
  delete from acs_permissions
    where object_id = delete__item_id;

  -- 6) delete keyword associations
  delete from cr_item_keyword_map
    where item_id = delete__item_id;

  -- 7) delete associated comments
  PERFORM journal_entry__delete_for_object(delete__item_id);

  -- context_id debugging loop
  --for v_error_val in c_error_cur loop
  --    || v_error_val.object_type);
  --end loop;

  PERFORM acs_object__delete(delete__item_id);

  return 0; 
end;' language 'plpgsql';

select define_function_args('content_item__delete','item_id');
create or replace function content_item__delete (integer)
returns integer as '
declare
  delete__item_id                alias for $1;  
begin
        PERFORM content_item__del (delete__item_id);
  return 0; 
end;' language 'plpgsql';

select define_function_args('content_item__edit_name','item_id,name');
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

    update acs_objects
      set title = edit_name__name
      where object_id = edit_name__item_id;
  else
    if exists_id != edit_name__item_id then
      raise EXCEPTION ''-20000: An item with the name % already exists in this directory.'', edit_name__name;
    end if;
  end if;

  return 0; 
end;' language 'plpgsql';

select define_function_args('content_item__get_id','item_path,root_folder_id,resolve_index;f');

create or replace function content_item__get_id (varchar,integer,boolean)
returns integer as '
declare
  get_id__item_path              alias for $1;  
  get_id__root_folder_id         alias for $2;  -- default null
  get_id__resolve_index          alias for $3;  -- default ''f''
  v_item_path                    varchar; 
  v_root_folder_id               cr_items.item_id%TYPE;
  get_id__parent_id              integer;       
  child_id                       integer;       
  start_pos                      integer default 1;        
  end_pos                        integer;       
  counter                        integer default 1;
  item_name                      varchar;  
begin

  if get_id__root_folder_id is null then
    select c_root_folder_id from content_item_globals into v_root_folder_id;
  else
    v_root_folder_id := get_id__root_folder_id;
  end if;

  -- If the request path is the root, then just return the root folder
  if get_id__item_path = ''/'' then
    return v_root_folder_id;
  end if;  

  -- Remove leading, trailing spaces, leading slashes
  v_item_path := rtrim(ltrim(trim(get_id__item_path), ''/''), ''/'');

  get_id__parent_id := v_root_folder_id;

  -- if parent_id is a symlink, resolve it
  get_id__parent_id := content_symlink__resolve(get_id__parent_id);

  LOOP

    end_pos := instr(v_item_path, ''/'', 1, counter);

    if end_pos = 0 then
      item_name := substr(v_item_path, start_pos);
    else
      item_name := substr(v_item_path, start_pos, end_pos - start_pos);
      counter := counter + 1;
    end if;

    select 
      item_id into child_id
    from 
      cr_items
    where
      parent_id = get_id__parent_id
    and
      name = item_name;

    if NOT FOUND then 
       return null;
    end if;

    exit when end_pos = 0;

    get_id__parent_id := child_id;

    -- if parent_id is a symlink, resolve it
    get_id__parent_id := content_symlink__resolve(get_id__parent_id);

    start_pos := end_pos + 1;
      
  end loop;

  if get_id__resolve_index = ''t'' then

    -- if the item is a folder and has an index page, then return

    if content_folder__is_folder(child_id ) = ''t'' and
      content_folder__get_index_page(child_id) is not null then 

      child_id := content_folder__get_index_page(child_id);
    end if;

  end if;

  return child_id;

end;' language 'plpgsql' stable;

-- create sequence content_item_gp_session_id;

-- create table get_path_cursors (
--        rel_cursor_pos         integer,
--        abs_cursor_pos         integer
-- );

-- insert into get_path_cursors values (0,0);

-- create table get_path_abs_cursor (
--        sid              integer,
--        pos              integer,
--        name             text,
--        parent_id        integer,
--        tree_level       integer,
--        primary key (sid,pos)
-- );

-- create table get_path_rel_cursor (
--        sid              integer,
--        pos              integer,
--        parent_id        integer,
--        tree_level       integer,
--        primary key (sid,pos)
-- );

-- create or replace function content_item__create_rel_cursor(integer,integer) 
-- returns integer as '
-- declare
--         v_item_id       alias for $1;
--         v_sid           alias for $2;
--         v_rec           record;
--         v_cur_pos       integer default 0;
-- begin
--         update get_path_cursors set rel_cursor_pos = 0;
--         for v_rec in select i2.name, 
--                             i2.parent_id, 
--                             tree_level(i2.tree_sortkey) as tree_level
--                      from (select * from cr_items where item_id = v_item_id) i1,
--                           cr_items i2
--                      where i2.parent_id <> 0
--                        and i1.tree_sortkey between i2.tree_sortkey and tree_right(i2.tree_sortkey)
--                   order by i2.tree_sortkey
                     
--         LOOP
--                 insert into get_path_rel_cursor 
--                 (sid,pos,parent_id,tree_level)
--                 values
--                 (v_sid,v_cur_pos,v_rec.parent_id,v_rec.tree_level);
--                 v_cur_pos := v_cur_pos + 1;
--         end LOOP;

--         return null;
-- end;' language 'plpgsql';

-- create or replace function content_item__create_abs_cursor(integer,integer) 
-- returns integer as '
-- declare
--         v_item_id       alias for $1;
--         v_sid           alias for $2;
--         v_rec           record;
--         v_cur_pos       integer default 0;
-- begin
--         update get_path_cursors set abs_cursor_pos = 0;
--         for v_rec in select i2.name, 
--                             i2.parent_id, 
--                             tree_level(i2.tree_sortkey) as tree_level
--                      from (select * from cr_items where item_id = v_item_id) i1,
--                           cr_items i2
--                      where i2.parent_id <> 0
--                        and i1.tree_sortkey between i2.tree_sortkey and tree_right(i2.tree_sortkey)
--                   order by i2.tree_sortkey
                     
--         LOOP
--                 insert into get_path_abs_cursor 
--                 (sid,pos,name,parent_id,tree_level)
--                 values
--                 (v_sid,v_cur_pos,v_rec.name,v_rec.parent_id,v_rec.tree_level);
--                 v_cur_pos := v_cur_pos + 1;
--         end LOOP;

--         return null;
-- end;' language 'plpgsql';

-- create or replace function content_item__abs_cursor_next_pos() returns integer as '
-- declare 
--         v_pos   integer;
-- begin
--         select abs_cursor_pos into v_pos from get_path_cursors;
--         update get_path_cursors set abs_cursor_pos = abs_cursor_pos + 1;

--         return v_pos;        
-- end;' language 'plpgsql';

-- create or replace function content_item__rel_cursor_next_pos() returns integer as '
-- declare 
--         v_pos   integer;
-- begin
--         select rel_cursor_pos into v_pos from get_path_cursors;
--         update get_path_cursors set rel_cursor_pos = rel_cursor_pos + 1;

--         return v_pos;        
-- end;' language 'plpgsql';

-- -- if called with null its a noop and returns null so strict.
-- create or replace function content_item__cleanup_cursors(integer) returns integer as '
-- declare
--         v_sid   alias for $1;
-- begin
--         delete from get_path_abs_cursor where sid = v_sid;
--         delete from get_path_rel_cursor where sid = v_sid;
        
--         return null;
-- end;' language 'plpgsql' strict;

-- old slow version
-- create or replace function content_item__get_path (integer,integer)
-- returns varchar as '
-- declare
--   get_path__item_id                alias for $1;  
--   get_path__root_folder_id         alias for $2;  -- default null  
--   v_count                          integer;       
--   v_name                           varchar;  
--   v_saved_name                     varchar;  
--   v_parent_id                      integer default 0;        
--   v_tree_level                     integer;       
--   v_resolved_root_id               integer;       
--   v_rel_parent_id                  integer default 0;        
--   v_rel_tree_level                 integer default 0;        
--   v_path                           text    default '''';  
--   v_rec                            record;
--   v_item_id                        integer;
--   v_rel_item_id                    integer;
--   v_session_id                     integer;
--   v_rel_found_p                    boolean;
--   v_abs_found_p                    boolean;
--   v_tmp                            integer;
-- begin

--   -- check that the item exists
--   select count(*) into v_count from cr_items where item_id = get_path__item_id;

--   if v_count = 0 then
--     raise EXCEPTION ''-20000: Invalid item ID: %'', get_path__item_id;
--   end if;

--   -- begin walking down the path to the item (from the repository root)
 
--   -- if the root folder is not null then prepare for a relative path

--   if get_path__root_folder_id is not null then

--     -- if root_folder_id is a symlink, resolve it (child items will point
--     -- to the actual folder, not the symlink)

--     v_resolved_root_id := content_symlink__resolve(get_path__root_folder_id);

--     v_session_id := nextval(''content_item_gp_session_id'');
--     PERFORM content_item__create_abs_cursor(get_path__item_id, v_session_id);
--     PERFORM content_item__create_rel_cursor(v_resolved_root_id, v_session_id);

--     -- begin walking down the path to the root folder.  Discard
--     -- elements of the item path as long as they are the same as the root
--     -- folder

--     while v_parent_id = v_rel_parent_id loop
--         v_tmp := content_item__abs_cursor_next_pos();
--         select name, parent_id, tree_level 
--         into v_name, v_parent_id, v_tree_level
--         from get_path_abs_cursor
--         where sid = v_session_id
--         and pos = v_tmp;

--         if NOT FOUND then 
--            v_name := v_saved_name;
--            v_abs_found_p := ''f'';
--         else 
--            v_saved_name := v_name;
--            v_abs_found_p := ''t'';
--         end if;

--         v_tmp := content_item__rel_cursor_next_pos();
--         select parent_id, tree_level 
--         into v_rel_parent_id, v_rel_tree_level
--         from get_path_rel_cursor
--         where sid = v_session_id
--         and pos = v_tmp;

--         if NOT FOUND then 
--            v_rel_found_p := ''f'';
--         else 
--            v_rel_found_p := ''t'';
--         end if;

--         exit when NOT v_rel_found_p or NOT v_abs_found_p;         
--     end loop;


--     -- walk the remainder of the relative path, add a ''..'' for each 
--     -- additional step

--     LOOP
--       exit when NOT v_rel_found_p;
--       v_path := v_path || ''../'';

--       v_tmp := content_item__rel_cursor_next_pos();
--       select parent_id, tree_level 
--       into v_rel_parent_id, v_rel_tree_level
--       from get_path_rel_cursor
--       where sid = v_session_id
--       and pos = v_tmp;
      
--       if NOT FOUND then 
--          v_rel_found_p := ''f'';
--       else 
--          v_rel_found_p := ''t'';
--       end if;
--     end loop;
--     -- an item relative to itself is ''../item''
--     if v_resolved_root_id = get_path__item_id then
-- 	v_path := ''../'';
--     end if;

--     -- loop over the remainder of the absolute path
--     LOOP

--       v_path := v_path || v_name;
--       v_tmp := content_item__abs_cursor_next_pos();
--       select name, parent_id, tree_level 
--       into v_name, v_parent_id, v_tree_level
--       from get_path_abs_cursor
--       where sid = v_session_id
--       and pos = v_tmp;

--       if NOT FOUND then 
--          v_abs_found_p := ''f'';
--       else 
--          v_abs_found_p := ''t'';
--       end if;

--       exit when NOT v_abs_found_p;
--       v_path := v_path || ''/'';

--     end LOOP;
--     PERFORM content_item__cleanup_cursors(v_session_id);
--   else

--     -- this is an absolute path so prepend a ''/''
--     -- loop over the absolute path

--     for v_rec in select i2.name, tree_level(i2.tree_sortkey) as tree_level
--                  from cr_items i1, cr_items i2
--                  where i2.parent_id <> 0
--                  and i1.item_id = get_path__item_id
--                  and i1.tree_sortkey between i2.tree_sortkey and tree_right(i2.tree_sortkey)
--                  order by tree_level
--     LOOP
--       v_path := v_path || ''/'' || v_rec.name;
--     end loop;

--   end if;

--   return v_path;
 
-- end;' language 'plpgsql';

select define_function_args('content_item__get_path','item_id,root_folder_id');
create or replace function content_item__get_path (integer,integer)
returns varchar as '
declare
  get_path__item_id                alias for $1;  
  get_path__root_folder_id         alias for $2;  -- default null  
  v_count                          integer;       
  v_resolved_root_id               integer;       
  v_path                           text    default '''';  
  v_rec                            record;
begin

  -- check that the item exists
  select count(*) into v_count from cr_items where item_id = get_path__item_id;

  if v_count = 0 then
    raise EXCEPTION ''-20000: Invalid item ID: %'', get_path__item_id;
  end if;

  -- begin walking down the path to the item (from the repository root)
 
  -- if the root folder is not null then prepare for a relative path

  if get_path__root_folder_id is not null then

    -- if root_folder_id is a symlink, resolve it (child items will point
    -- to the actual folder, not the symlink)

    v_resolved_root_id := content_symlink__resolve(get_path__root_folder_id);

    -- check to see if the item is under or out side the root_id
    PERFORM 1 from cr_items i, 
        (select tree_sortkey from cr_items where item_id = v_resolved_root_id) a
    where tree_ancestor_p(a.tree_sortkey, i.tree_sortkey) and i.item_id = get_path__item_id;

    if NOT FOUND then
        -- if not found then we need to go up the folder and append ../ until we have common ancestor

        for v_rec in select i1.name, i1.parent_id, tree_level(i1.tree_sortkey) as tree_level
                 from cr_items i1, (select tree_ancestor_keys(tree_sortkey) as tree_sortkey from cr_items where item_id = v_resolved_root_id) i2,
                 (select tree_sortkey from cr_items where item_id = get_path__item_id) i3
                 where 
                 i1.parent_id <> 0
                 and i2.tree_sortkey = i1.tree_sortkey
                 and not tree_ancestor_p(i2.tree_sortkey, i3.tree_sortkey)
                 order by tree_level desc
        LOOP
            v_path := v_path || ''../'';
        end loop;
        -- lets now assign the new root_id to be the last parent_id on the loop
        v_resolved_root_id := v_rec.parent_id;

    end if;

    -- go downwards the tree and append the name and /
    for v_rec in select i1.name, i1.item_id, tree_level(i1.tree_sortkey) as tree_level
             from cr_items i1, (select tree_sortkey from cr_items where item_id = v_resolved_root_id) i2,
            (select tree_ancestor_keys(tree_sortkey) as tree_sortkey from cr_items where item_id = get_path__item_id) i3
             where 
             i1.tree_sortkey = i3.tree_sortkey
             and i1.tree_sortkey > i2.tree_sortkey
             order by tree_level
    LOOP
        v_path := v_path || v_rec.name;
        if v_rec.item_id <> get_path__item_id then 
            -- put a / if we are still going down
            v_path := v_path || ''/'';
        end if;
    end loop;

  else

    -- this is an absolute path so prepend a ''/''
    -- loop over the absolute path

    for v_rec in select i2.name, tree_level(i2.tree_sortkey) as tree_level
                 from cr_items i1, cr_items i2
                 where i2.parent_id <> 0
                 and i1.item_id = get_path__item_id
                 and i1.tree_sortkey between i2.tree_sortkey and tree_right(i2.tree_sortkey)
                 order by tree_level
    LOOP
      v_path := v_path || ''/'' || v_rec.name;
    end loop;

  end if;

  return v_path;
 
end;' language 'plpgsql';

-- I hard code the content_item_globals.c_root_folder_id here
select define_function_args('content_item__get_virtual_path','item_id,root_folder_id;-100');

create or replace function content_item__get_virtual_path (integer,integer)
returns varchar as '
declare
  get_virtual_path__item_id               alias for $1;  
  get_virtual_path__root_folder_id        alias for $2; -- default content_item_globals.c_root_folder_id
  v_path                                  varchar; 
  v_item_id                               cr_items.item_id%TYPE;
  v_is_folder                             boolean;       
  v_index                                 cr_items.item_id%TYPE;
begin
  -- XXX possible bug: root_folder_id arg is ignored.

  -- first resolve the item
  v_item_id := content_symlink__resolve(get_virtual_path__item_id);

  v_is_folder := content_folder__is_folder(v_item_id);
  v_index := content_folder__get_index_page(v_item_id);

  -- if the folder has an index page
  if v_is_folder = ''t'' and v_index is not null then
    v_path := content_item__get_path(content_symlink__resolve(v_index),null);
  else
    v_path := content_item__get_path(v_item_id,null);
  end if;

  return v_path;
 
end;' language 'plpgsql';

create or replace function content_item__write_to_file (integer,varchar)
returns integer as '
declare
  item_id                alias for $1;  
  root_path              alias for $2;  
  -- blob_loc               cr_revisions.content%TYPE;
  -- v_revision             cr_items.live_revision%TYPE;
begin
  
  -- FIXME:
  raise NOTICE ''not implemented for postgresql'';
/*
  v_revision := content_item__get_live_revision(item_id);

  select content into blob_loc from cr_revisions 
    where revision_id = v_revision;

  if NOT FOUND then 
    raise EXCEPTION ''-20000: No live revision for content item % in content_item.write_to_file.'', item_id;    
  end if;
  
  PERFORM blob_to_file(root_path || content_item__get_path(item_id), blob_loc);
*/
  return 0; 
end;' language 'plpgsql';

select define_function_args('content_item__register_template','item_id,template_id,use_context');

create or replace function content_item__register_template (integer,integer,varchar)
returns integer as '
declare
  register_template__item_id                alias for $1;  
  register_template__template_id            alias for $2;  
  register_template__use_context            alias for $3;  
                                        
begin

 -- register template if it is not already registered
  insert into cr_item_template_map
  select
    register_template__item_id as item_id,
    register_template__template_id as template_id,
    register_template__use_context as use_context
  from
    dual
  where
    not exists ( select 1
                 from
                   cr_item_template_map
                 where
                   item_id = register_template__item_id
                 and
                   template_id = register_template__template_id
                 and
                   use_context = register_template__use_context );

  return 0; 
end;' language 'plpgsql';


select define_function_args('content_item__unregister_template','item_id,template_id,use_context');
create or replace function content_item__unregister_template (integer,integer,varchar)
returns integer as '
declare
  unregister_template__item_id                alias for $1;  
  unregister_template__template_id            alias for $2;  -- default null  
  unregister_template__use_context            alias for $3;  -- default null
                                        
begin

  if unregister_template__use_context is null and 
     unregister_template__template_id is null then

    delete from cr_item_template_map
      where item_id = unregister_template__item_id;

  else if unregister_template__use_context is null then

    delete from cr_item_template_map
      where template_id = unregister_template__template_id
      and item_id = unregister_template__item_id;

  else if unregister_template__template_id is null then

    delete from cr_item_template_map
      where item_id = unregister_template__item_id
      and use_context = unregister_template__use_context;

  else

    delete from cr_item_template_map
      where template_id = unregister_template__template_id
      and item_id = unregister_template__item_id
      and use_context = unregister_template__use_context;

  end if; end if; end if;

  return 0; 
end;' language 'plpgsql';

select define_function_args('content_item__get_template','item_id,use_context');

create or replace function content_item__get_template (integer,varchar)
returns integer as '
declare
  get_template__item_id                alias for $1;  
  get_template__use_context            alias for $2;  
  v_template_id                        cr_templates.template_id%TYPE;
  v_content_type                       cr_items.content_type%TYPE;
begin

  -- look for a template assigned specifically to this item
  select
    template_id 
  into 
     v_template_id
  from
    cr_item_template_map
  where
    item_id = get_template__item_id
  and
    use_context = get_template__use_context;
  -- otherwise get the default for the content type
  if NOT FOUND then
    select 
      m.template_id
    into 
      v_template_id
    from
      cr_items i, cr_type_template_map m
    where
      i.item_id = get_template__item_id
    and
      i.content_type = m.content_type
    and
      m.use_context = get_template__use_context
    and
      m.is_default = ''t'';

    if NOT FOUND then
       return null;
    end if;
  end if;

  return v_template_id;
 
end;' language 'plpgsql' stable strict;

select define_function_args('content_item__get_content_type','item_id');
create or replace function content_item__get_content_type (integer)
returns varchar as '
declare
  get_content_type__item_id                alias for $1;  
  v_content_type                           cr_items.content_type%TYPE;
begin

  select
    content_type into v_content_type
  from 
    cr_items
  where 
    item_id = get_content_type__item_id;  

  return v_content_type;
 
end;' language 'plpgsql' stable strict;

select define_function_args('content_item__get_live_revision','item_id');

select define_function_args('content_item__get_live_revision','item_id');

create or replace function content_item__get_live_revision (integer)
returns integer as '
declare
  get_live_revision__item_id                alias for $1;  
  v_revision_id                             acs_objects.object_id%TYPE;
begin

  select
    live_revision into v_revision_id
  from
    cr_items
  where
    item_id = get_live_revision__item_id;

  return v_revision_id;
 
end;' language 'plpgsql' stable strict;

select define_function_args('content_item__set_live_revision','revision_id,publish_status;ready');
create or replace function content_item__set_live_revision (integer) returns integer as '
declare
  set_live_revision__revision_id    alias for $1;  
  set_live_revision__publish_status cr_items.publish_status%TYPE default ''ready'';
begin

  update
    cr_items
  set
    live_revision = set_live_revision__revision_id,
    publish_status = set_live_revision__publish_status
  where
    item_id = (select
                 item_id
               from
                 cr_revisions
               where
                 revision_id = set_live_revision__revision_id);

  update
    cr_revisions
  set
    publish_date = now()
  where
    revision_id = set_live_revision__revision_id;

  return 0; 
end;' language 'plpgsql';

select define_function_args('content_item__set_live_revision','revision_id,publish_status;ready');
create or replace function content_item__set_live_revision (integer,varchar)
returns integer as '
declare
  set_live_revision__revision_id    alias for $1;  
  set_live_revision__publish_status alias for $2; -- default ''ready''
begin

  update
    cr_items
  set
    live_revision = set_live_revision__revision_id,
    publish_status = set_live_revision__publish_status
  where
    item_id = (select
                 item_id
               from
                 cr_revisions
               where
                 revision_id = set_live_revision__revision_id);

  update
    cr_revisions
  set
    publish_date = now()
  where
    revision_id = set_live_revision__revision_id;

  return 0; 
end;' language 'plpgsql';

select define_function_args('content_item__unset_live_revision','item_id');
create or replace function content_item__unset_live_revision (integer)
returns integer as '
declare
  unset_live_revision__item_id                alias for $1;  
begin

  update
    cr_items
  set
    live_revision = NULL
  where
    item_id = unset_live_revision__item_id;

  -- if an items publish status is "live", change it to "ready"
  update
    cr_items
  set
    publish_status = ''production''
  where
    publish_status = ''live''
  and
    item_id = unset_live_revision__item_id;

  return 0; 
end;' language 'plpgsql';

select define_function_args('content_item__set_release_period','item_id,start_when,end_when');

create or replace function content_item__set_release_period (integer, timestamptz, timestamptz)
returns integer as '
declare
  set_release_period__item_id                alias for $1;  
  set_release_period__start_when             alias for $2;  -- default null
  set_release_period__end_when               alias for $3;  -- default null
  v_count                                    integer;       
begin

  select count(*) into v_count from cr_release_periods 
    where item_id = set_release_period__item_id;

  if v_count = 0 then
    insert into cr_release_periods (
      item_id, start_when, end_when
    ) values (
      set_release_period__item_id, 
      set_release_period__start_when, 
      set_release_period__end_when
    );
  else
    update cr_release_periods
      set start_when = set_release_period__start_when,
      end_when = set_release_period__end_when
    where
      item_id = set_release_period__item_id;
  end if;

  return 0; 
end;' language 'plpgsql';

select define_function_args('content_item__get_revision_count','item_id');

select define_function_args('content_item__get_revision_count','item_id');

create or replace function content_item__get_revision_count (integer)
returns integer as '
declare
  get_revision_count__item_id   alias for $1;  
  v_count                       integer;       
begin

  select
    count(*) into v_count
  from 
    cr_revisions
  where
    item_id = get_revision_count__item_id;

  return v_count;
 
end;' language 'plpgsql' stable;

select define_function_args('content_item__get_context','item_id');
create or replace function content_item__get_context (integer)
returns integer as '
declare
  get_context__item_id                alias for $1;  
  v_context_id                        acs_objects.context_id%TYPE;
begin

  select
    context_id
  into
    v_context_id
  from
    acs_objects
  where
    object_id = get_context__item_id;

  if NOT FOUND then 
     raise EXCEPTION ''-20000: Content item % does not exist in content_item.get_context'', get_context__item_id;
  end if;

  return v_context_id;
 
end;' language 'plpgsql' stable;


-- 1) make sure we are not moving the item to an invalid location:
--   that is, the destination folder exists and is a valid folder
-- 2) make sure the content type of the content item is registered
--   to the target folder
-- 3) update the parent_id for the item
create or replace function content_item__move (integer,integer)
returns integer as '
declare
  move__item_id                alias for $1;  
  move__target_folder_id       alias for $2;
begin
  perform content_item__move(
	move__item_id,
	move__target_folder_id,
	NULL
	);
return null;
end;' language 'plpgsql';

select define_function_args('content_item__move','item_id,target_folder_id,name');
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

    PERFORM content_folder__move(move__item_id, move__target_folder_id);

  elsif content_folder__is_folder(move__target_folder_id) = ''t'' then
   

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

    if move__name is not null then
      update acs_objects
        set title = move__name
        where object_id = move__item_id;
    end if;

  end if;

  return 0; 
end;' language 'plpgsql';


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

select define_function_args('content_item__copy','item_id,target_folder_id,creation_user,creation_ip,name');
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
  v_old_live_revision_id             cr_revisions.revision_id%TYPE;
  v_new_live_revision_id             cr_revisions.revision_id%TYPE;
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
          latest_revision, live_revision into v_old_revision_id, v_old_live_revision_id
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

        -- copy the live revision (if there is one and it differs from the latest) to the new item
	if v_old_live_revision_id is not null then
          if v_old_live_revision_id <> v_old_revision_id then
            v_new_live_revision_id := content_revision__copy (
              v_old_live_revision_id,
              null,
              v_item_id,
              copy__creation_user,
              copy__creation_ip
            );
          else
            v_new_live_revision_id := v_new_revision_id;
          end if;
        end if;

        update cr_items set live_revision = v_new_live_revision_id, latest_revision = v_new_revision_id where item_id = v_item_id;

    end if;

  end if; end if; end if; end if;

  return v_item_id;

end;' language 'plpgsql';



select define_function_args('content_item__get_latest_revision','item_id');
create or replace function content_item__get_latest_revision (integer)
returns integer as '
declare
  get_latest_revision__item_id                alias for $1;
  v_revision_id                               integer;
  v_rec                                       record;
begin
  for v_rec in 
  select 
    r.revision_id 
  from 
    cr_revisions r, acs_objects o
  where 
    r.revision_id = o.object_id
  and 
    r.item_id = get_latest_revision__item_id
  order by 
    o.creation_date desc
  LOOP
      v_revision_id := v_rec.revision_id;
      exit;
  end LOOP;

  return v_revision_id;
 
end;' language 'plpgsql' strict stable;

select define_function_args('content_item__get_best_revision','item_id');
create or replace function content_item__get_best_revision (integer)
returns integer as '
declare
  get_best_revision__item_id                alias for $1;  
  v_revision_id                             cr_revisions.revision_id%TYPE;
begin
    
  select
    coalesce(live_revision, latest_revision )
  into
    v_revision_id
  from
    cr_items
  where
    item_id = get_best_revision__item_id;

  return v_revision_id;
 
end;' language 'plpgsql' stable strict;

select define_function_args('content_item__get_title','item_id,is_live;f');
create or replace function content_item__get_title (integer,boolean)
returns varchar as '
declare
  get_title__item_id                alias for $1;  
  get_title__is_live                alias for $2;  -- default ''f''  
  v_title                           cr_revisions.title%TYPE;
  v_content_type                    cr_items.content_type%TYPE;
begin
  
  select content_type into v_content_type from cr_items 
    where item_id = get_title__item_id;

  if v_content_type = ''content_folder'' then
    select label into v_title from cr_folders 
      where folder_id = get_title__item_id;
  else if v_content_type = ''content_symlink'' then
    select label into v_title from cr_symlinks 
      where symlink_id = get_title__item_id;
  else if v_content_type = ''content_extlink'' then
    select label into v_title from cr_extlinks
      where extlink_id = get_title__item_id;            
  else
    if get_title__is_live then
      select
	title into v_title
      from
	cr_revisions r, cr_items i
      where
        i.item_id = get_title__item_id
      and
        r.revision_id = i.live_revision;
    else
      select
	title into v_title
      from
	cr_revisions r, cr_items i
      where
        i.item_id = get_title__item_id
      and
        r.revision_id = i.latest_revision;
    end if;
  end if; end if; end if;

  return v_title;

end;' language 'plpgsql' stable;


create or replace function content_item__get_title (integer)
returns varchar as '
declare
  get_title__item_id                alias for $1;  
begin
  
  return content_item__get_title(get_title__item_id, ''f'');

end;' language 'plpgsql' stable strict;

select define_function_args('content_item__get_publish_date','item_id,is_live;f');
create or replace function content_item__get_publish_date (integer,boolean)
returns timestamptz as '
declare
  get_publish_date__item_id                alias for $1;  
  get_publish_date__is_live                alias for $2;  -- default ''f''  
  v_revision_id                            cr_revisions.revision_id%TYPE;
  v_publish_date                           cr_revisions.publish_date%TYPE;
begin

  if get_publish_date__is_live then
    select
	publish_date into v_publish_date
    from
	cr_revisions r, cr_items i
    where
      i.item_id = get_publish_date__item_id
    and
      r.revision_id = i.live_revision;
  else
    select
	publish_date into v_publish_date
    from
	cr_revisions r, cr_items i
    where
      i.item_id = get_publish_date__item_id
    and
      r.revision_id = i.latest_revision;
  end if;

  return v_publish_date;
 
end;' language 'plpgsql' stable;

select define_function_args('content_item__is_subclass','object_type,supertype');
create or replace function content_item__is_subclass (varchar,varchar)
returns boolean as '
declare
  is_subclass__object_type            alias for $1;  
  is_subclass__supertype              alias for $2;  
  v_subclass_p                        boolean;      
  v_inherit_val                       record;
begin
  select count(*) > 0 into v_subclass_p where exists (
	select 1
          from acs_object_types o, acs_object_types o2
         where o2.object_type = is_subclass__supertype
           and o.object_type = is_subclass__object_type
           and o.tree_sortkey between o2.tree_sortkey and tree_right(o2.tree_sortkey));

  return v_subclass_p;

end;' language 'plpgsql' stable;

select define_function_args('content_item__relate','item_id,object_id,relation_tag;generic,order_n,relation_type;cr_item_rel');
create or replace function content_item__relate (integer,integer,varchar,integer,varchar)
returns integer as '
declare
  relate__item_id                alias for $1;  
  relate__object_id              alias for $2;  
  relate__relation_tag           alias for $3;  -- default ''generic''  
  relate__order_n                alias for $4;  -- default null
  relate__relation_type          alias for $5;  -- default ''cr_item_rel''
  v_content_type                 cr_items.content_type%TYPE;
  v_object_type                  acs_objects.object_type%TYPE;
  v_is_valid                     integer;       
  v_rel_id                       integer;       
  v_package_id                   integer;       
  v_exists                       integer;       
  v_order_n                      cr_item_rels.order_n%TYPE;
begin

  -- check the relationship is valid
  v_content_type := content_item__get_content_type (relate__item_id);
  v_object_type := content_item__get_content_type (relate__object_id);

  select
    count(1) into v_is_valid
  from
    cr_type_relations
  where
    content_item__is_subclass( v_object_type, target_type ) = ''t''
  and
    content_item__is_subclass( v_content_type, content_type ) = ''t'';

  if v_is_valid = 0 then
    raise EXCEPTION ''-20000: There is no registered relation type matching this item relation.'';
  end if;

  if relate__item_id != relate__object_id then
    -- check that these two items are not related already
    --dbms_output.put_line( ''checking if the items are already related...'');
    
    select
      rel_id, 1 into v_rel_id, v_exists
    from
      cr_item_rels
    where
      item_id = relate__item_id
    and
      related_object_id = relate__object_id
    and
      relation_tag = relate__relation_tag;

    if NOT FOUND then
       v_exists := 0;
    end if;
    
    v_package_id := acs_object__package_id(relate__item_id);

    -- if order_n is null, use rel_id (the order the item was related)
    if relate__order_n is null then
      v_order_n := v_rel_id;
    else
      v_order_n := relate__order_n;
    end if;


    -- if relationship does not exist, create it
    if v_exists <> 1 then
      --dbms_output.put_line( ''creating new relationship...'');
      v_rel_id := acs_object__new(
        null,
        relate__relation_type,
        now(),
        null,
        null,
        relate__item_id,
        ''t'',
        relate__relation_tag || '': '' || relate__item_id || '' - '' || relate__object_id,
        v_package_id
      );

      insert into cr_item_rels (
        rel_id, item_id, related_object_id, order_n, relation_tag
      ) values (
        v_rel_id, relate__item_id, relate__object_id, v_order_n, 
        relate__relation_tag
      );

    -- if relationship already exists, update it
    else
      --dbms_output.put_line( ''updating existing relationship...'');
      update cr_item_rels set
        relation_tag = relate__relation_tag,
        order_n = v_order_n
      where
        rel_id = v_rel_id;

      update acs_objects set
        title = relate__relation_tag || '': '' || relate__item_id || '' - '' || relate__object_id
      where object_id = v_rel_id;
    end if;

  end if;

  return v_rel_id;
 
end;' language 'plpgsql';

select define_function_args('content_item__unrelate','rel_id');

select define_function_args('content_item__unrelate','rel_id');

create or replace function content_item__unrelate (integer)
returns integer as '
declare
  unrelate__rel_id      alias for $1;  
begin

  -- delete the relation object
  PERFORM acs_rel__delete(unrelate__rel_id);

  -- delete the row from the cr_item_rels table
  delete from cr_item_rels where rel_id = unrelate__rel_id;

  return 0; 
end;' language 'plpgsql';

select define_function_args('content_item__is_index_page','item_id,folder_id');

select define_function_args('content_item__is_index_page','item_id,folder_id');

create or replace function content_item__is_index_page (integer,integer)
returns boolean as '
declare
  is_index_page__item_id                alias for $1;  
  is_index_page__folder_id              alias for $2;  
begin
  if content_folder__get_index_page(is_index_page__folder_id) = is_index_page__item_id then
    return ''t'';
  else
    return ''f'';
  end if;
 
end;' language 'plpgsql' stable;

select define_function_args('content_item__get_parent_folder','item_id');

create or replace function content_item__get_parent_folder (integer)
returns integer as '
declare
  get_parent_folder__item_id               alias for $1;  
  v_folder_id                              cr_folders.folder_id%TYPE;
  v_parent_folder_p                        boolean default ''f'';       
begin
  v_folder_id := get_parent_folder__item_id;

  while NOT v_parent_folder_p and v_folder_id is not null LOOP

    select
      parent_id, content_folder__is_folder(parent_id) 
    into 
      v_folder_id, v_parent_folder_p
    from
      cr_items
    where
      item_id = v_folder_id;

  end loop; 

  return v_folder_id;
 
end;' language 'plpgsql' stable strict;



-- Trigger to maintain context_id in acs_objects
create function cr_items_update_tr () returns opaque as '
begin

  if new.parent_id <> old.parent_id then
    update acs_objects set context_id = new.parent_id
    where object_id = new.item_id;
  end if;

  return new;
end;' language 'plpgsql';

create trigger cr_items_update_tr after update on cr_items
for each row execute procedure cr_items_update_tr ();


-- Trigger to maintain publication audit trail
create function cr_items_publish_update_tr () returns opaque as '
begin
  if new.live_revision <> old.live_revision or
     new.publish_status <> old.publish_status
  then 

    insert into cr_item_publish_audit (
      item_id, old_revision, new_revision, old_status, new_status, publish_date
    ) values (
      new.item_id, old.live_revision, new.live_revision, 
      old.publish_status, new.publish_status,
      now()
    );

  end if;

  return new;

end;' language 'plpgsql';

create trigger cr_items_publish_update_tr before update on cr_items
for each row execute procedure cr_items_publish_update_tr ();

