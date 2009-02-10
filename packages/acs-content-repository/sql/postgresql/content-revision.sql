-- Data model to support content repository of the ArsDigita
-- Community System

-- Copyright (C) 1999-2000 ArsDigita Corporation
-- Author: Karl Goldstein (karlg@arsdigita.com)

-- $Id$

-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

-- create or replace package body content_revision

-- function new

-- DRB: BLOB issues make it impractical to use package_instantiate_object to create
-- new revisions that contain binary data so a higher-level Tcl API is required rather
-- than the standard package_instantiate_object.  So we don't bother calling define_function_args
-- here.

create or replace function content_revision__new (varchar,varchar,timestamptz,varchar,varchar,integer,integer,integer,timestamptz,integer,varchar,integer)
returns integer as '
declare
  new__title                  alias for $1;  
  new__description            alias for $2;  -- default null 
  new__publish_date           alias for $3;  -- default now()
  new__mime_type              alias for $4;  -- default ''text/plain''
  new__nls_language           alias for $5;  -- default null
  -- lob id 
  new__data                   alias for $6;  
  new__item_id                alias for $7;  
  new__revision_id            alias for $8;  -- default null
  new__creation_date          alias for $9;  -- default now()
  new__creation_user          alias for $10; -- default null
  new__creation_ip            alias for $11; -- default null
  new__package_id             alias for $12; -- default null  
  v_revision_id               integer;       
  v_package_id                acs_objects.package_id%TYPE;
  v_content_type              acs_object_types.object_type%TYPE;
begin

  v_content_type := content_item__get_content_type(new__item_id);

  if new__package_id is null then
    v_package_id := acs_object__package_id(new__item_id);
  else
    v_package_id := new__package_id;
  end if;

  v_revision_id := acs_object__new(
      new__revision_id,
      v_content_type, 
      new__creation_date, 
      new__creation_user, 
      new__creation_ip, 
      new__item_id,
      ''t'',
      new__title,
      v_package_id
  );

  -- binary data is stored in cr_revisions using Dons lob hack.
  -- This routine only inserts the lob id.  It would need to be followed by 
  -- ns_pg blob_dml from within a tcl script to actually insert the lob data.

  -- After the lob data is inserted, the content_length needs to be updated 
  -- as well.
  -- DanW, 2001-05-10.

  insert into cr_revisions (
    revision_id, title, description, mime_type, publish_date,
    nls_language, lob, item_id, content_length
  ) values (
    v_revision_id, new__title, new__description,
    new__mime_type, 
    new__publish_date, new__nls_language, new__data, 
    new__item_id, 0
  );

  return v_revision_id;

end;' language 'plpgsql';

create or replace function content_revision__new (varchar,varchar,timestamptz,varchar,varchar,integer,integer,integer,timestamptz,integer,varchar)
returns integer as '
declare
  new__title                  alias for $1;  
  new__description            alias for $2;  -- default null 
  new__publish_date           alias for $3;  -- default now()
  new__mime_type              alias for $4;  -- default ''text/plain''
  new__nls_language           alias for $5;  -- default null
  -- lob id 
  new__data                   alias for $6;  
  new__item_id                alias for $7;  
  new__revision_id            alias for $8;  -- default null
  new__creation_date          alias for $9;  -- default now()
  new__creation_user          alias for $10; -- default null
  new__creation_ip            alias for $11; -- default null
begin
        return content_revision__new(new__title,
                                     new__description,
                                     new__publish_date,
                                     new__mime_type,
                                     new__nls_language,
                                     new__data,
                                     new__item_id,
                                     new__revision_id,
                                     new__creation_date,
                                     new__creation_user,
                                     new__creation_ip,
                                     null
               );
end;' language 'plpgsql';

create or replace function content_revision__new(varchar,varchar,timestamptz,varchar,text,integer,integer) returns integer as '
declare
        new__title              alias for $1;
        new__description        alias for $2;  -- default null
        new__publish_date       alias for $3;  -- default now()
        new__mime_type          alias for $4;  -- default ''text/plain''
        new__text               alias for $5;  -- default '' ''
        new__item_id            alias for $6;
        new__package_id         alias for $7;  -- default null
begin
        return content_revision__new(new__title,
                                     new__description,
                                     new__publish_date,
                                     new__mime_type,
                                     null,
                                     new__text,
                                     new__item_id,
                                     null,
                                     now(),
                                     null,
                                     null,
                                     null,
                                     new__package_id
               );

end;' language 'plpgsql';

create or replace function content_revision__new(varchar,varchar,timestamptz,varchar,text,integer) returns integer as '
declare
        new__title              alias for $1;
        new__description        alias for $2;  -- default null
        new__publish_date       alias for $3;  -- default now()
        new__mime_type          alias for $4;  -- default ''text/plain''
        new__text               alias for $5;  -- default '' ''
        new__item_id            alias for $6;
begin
        return content_revision__new(new__title,
                                     new__description,
                                     new__publish_date,
                                     new__mime_type,
                                     null,
                                     new__text,
                                     new__item_id,
                                     null,
                                     now(),
                                     null,
                                     null,
                                     null,
                                     null
               );

end;' language 'plpgsql';

create or replace function content_revision__new (varchar,varchar,timestamptz,varchar,varchar,text,integer,integer,timestamptz,integer,varchar)
returns integer as '
declare
  new__title                  alias for $1;  
  new__description            alias for $2;  -- default null  
  new__publish_date           alias for $3;  -- default now()
  new__mime_type              alias for $4;  -- default ''text/plain''
  new__nls_language           alias for $5;  -- default null
  new__text                   alias for $6;  -- default '' ''
  new__item_id                alias for $7;  
  new__revision_id            alias for $8;  -- default null
  new__creation_date          alias for $9;  -- default now()
  new__creation_user          alias for $10; -- default null
  new__creation_ip            alias for $11; -- default null
begin
        return content_revision__new(new__title,
                                     new__description,
                                     new__publish_date,
                                     new__mime_type,
                                     new__nls_language,
                                     new__text,
                                     new__item_id,
                                     new__revision_id,
                                     new__creation_date,
                                     new__creation_user,
                                     new__creation_ip,
                                     null,
                                     null
                                     );
end;' language 'plpgsql';

create or replace function content_revision__new (varchar,varchar,timestamptz,varchar,varchar,text,integer,integer,timestamptz,integer,varchar,integer)
returns integer as '
declare
  new__title                  alias for $1;  
  new__description            alias for $2;  -- default null  
  new__publish_date           alias for $3;  -- default now()
  new__mime_type              alias for $4;  -- default ''text/plain''
  new__nls_language           alias for $5;  -- default null
  new__text                   alias for $6;  -- default '' ''
  new__item_id                alias for $7;  
  new__revision_id            alias for $8;  -- default null
  new__creation_date          alias for $9;  -- default now()
  new__creation_user          alias for $10; -- default null
  new__creation_ip            alias for $11; -- default null
  new__content_length         alias for $12; -- default null
begin
        return content_revision__new(new__title,
                                     new__description,
                                     new__publish_date,
                                     new__mime_type,
                                     new__nls_language,
                                     new__text,
                                     new__item_id,
                                     new__revision_id,
                                     new__creation_date,
                                     new__creation_user,
                                     new__creation_ip,
                                     new__content_length,
                                     null
                                     );
end;' language 'plpgsql';

-- function new
create or replace function content_revision__new (varchar,varchar,timestamptz,varchar,varchar,text,integer,integer,timestamptz,integer,varchar,integer,integer)
returns integer as '
declare
  new__title                  alias for $1;  
  new__description            alias for $2;  -- default null  
  new__publish_date           alias for $3;  -- default now()
  new__mime_type              alias for $4;  -- default ''text/plain''
  new__nls_language           alias for $5;  -- default null
  new__text                   alias for $6;  -- default '' ''
  new__item_id                alias for $7;  
  new__revision_id            alias for $8;  -- default null
  new__creation_date          alias for $9;  -- default now()
  new__creation_user          alias for $10; -- default null
  new__creation_ip            alias for $11; -- default null
  new__content_length         alias for $12; -- default null
  new__package_id             alias for $13; -- default null  
  v_revision_id               integer;       
  v_package_id                acs_objects.package_id%TYPE;
  v_content_type              acs_object_types.object_type%TYPE;
  v_storage_type              cr_items.storage_type%TYPE;
  v_length                    cr_revisions.content_length%TYPE;
begin

  v_content_type := content_item__get_content_type(new__item_id);

  if new__package_id is null then
    v_package_id := acs_object__package_id(new__item_id);
  else
    v_package_id := new__package_id;
  end if;

  v_revision_id := acs_object__new(
      new__revision_id,
      v_content_type, 
      new__creation_date, 
      new__creation_user, 
      new__creation_ip, 
      new__item_id,
      ''t'',
      new__title,
      v_package_id
  );

  select storage_type into v_storage_type
    from cr_items
   where item_id = new__item_id;

  if v_storage_type = ''text'' then 
     v_length := length(new__text);
  else
     v_length := coalesce(new__content_length,0);
  end if;

  -- text data is stored directly in cr_revisions using text datatype.

  insert into cr_revisions (
    revision_id, title, description, mime_type, publish_date,
    nls_language, content, item_id, content_length
  ) values (
    v_revision_id, new__title, new__description,
     new__mime_type, 
    new__publish_date, new__nls_language, 
    new__text, new__item_id, v_length
  );

  return v_revision_id;
 
end;' language 'plpgsql';


-- procedure copy_attributes
select define_function_args('content_revision__copy_attributes','content_type,revision_id,copy_id');
create or replace function content_revision__copy_attributes (varchar,integer,integer)
returns integer as '
declare
  copy_attributes__content_type           alias for $1;  
  copy_attributes__revision_id            alias for $2;  
  copy_attributes__copy_id                alias for $3;  
  v_table_name                            acs_object_types.table_name%TYPE;
  v_id_column                             acs_object_types.id_column%TYPE;
  cols                                    varchar default ''''; 
  attr_rec                                record;
begin

  if copy_attributes__content_type is null or copy_attributes__revision_id is null or copy_attributes__copy_id is null then 
     raise exception ''content_revision__copy_attributes called with null % % %'',copy_attributes__content_type,copy_attributes__revision_id, copy_attributes__copy_id;
  end if;

  select table_name, id_column into v_table_name, v_id_column
  from acs_object_types where object_type = copy_attributes__content_type;

  for attr_rec in select
                    attribute_name
                  from
                    acs_attributes
                  where
                    object_type = copy_attributes__content_type 
  LOOP
    cols := cols || '', '' || attr_rec.attribute_name;
  end loop;

    execute ''insert into '' || v_table_name || ''('' || v_id_column || cols || '')'' || '' select '' || copy_attributes__copy_id || 
          '' as '' || v_id_column || cols || '' from '' || 
          v_table_name || '' where '' || v_id_column || '' = '' || 
          copy_attributes__revision_id;

  return 0; 

end;' language 'plpgsql';


-- function copy
select define_function_args('content_revision__copy','revision_id,copy_id,target_item_id,creation_user,creation_ip');
create or replace function content_revision__copy (integer,integer,integer,integer,varchar)
returns integer as '
declare
  copy__revision_id            alias for $1;  
  copy__copy_id                alias for $2;  -- default null  
  copy__target_item_id         alias for $3;  -- default null
  copy__creation_user          alias for $4;  -- default null
  copy__creation_ip            alias for $5;  -- default null
  v_copy_id                    cr_revisions.revision_id%TYPE;
  v_target_item_id             cr_items.item_id%TYPE;
  type_rec                     record;
begin
  -- use the specified item_id or the item_id of the original revision 
  --   if none is specified
  if copy__target_item_id is null then
    select item_id into v_target_item_id from cr_revisions 
      where revision_id = copy__revision_id;
  else
    v_target_item_id := copy__target_item_id;
  end if;

  -- use the copy_id or generate a new copy_id if none is specified
  --   the copy_id is a revision_id
  if copy__copy_id is null then
    select nextval(''t_acs_object_id_seq'') into v_copy_id from dual;
  else
    v_copy_id := copy__copy_id;
  end if;

  -- create the basic object
  insert into acs_objects (
                 object_id,
                 object_type,
                 context_id,
                 security_inherit_p,
                 creation_user,
                 creation_date,
                 creation_ip,
                 last_modified,
                 modifying_user,
                 modifying_ip,
                 title,
                 package_id)
       select
         v_copy_id as object_id,
         object_type,
         v_target_item_id,
         security_inherit_p,
         copy__creation_user as creation_user,
         now() as creation_date,
         copy__creation_ip as creation_ip,
         now() as last_modified,
         copy__creation_user as modifying_user,
         copy__creation_ip as modifying_ip,
         title,
         package_id
       from
         acs_objects
       where
         object_id = copy__revision_id;

  -- create the basic revision (using v_target_item_id)
  insert into cr_revisions 
      select 
        v_copy_id as revision_id, 
        v_target_item_id as item_id, 
        title, 
        description, 
        publish_date, 
        mime_type, 
        nls_language, 
        lob,
	content,
        content_length
      from 
        cr_revisions 
      where
        revision_id = copy__revision_id;

  -- iterate over the ancestor types and copy attributes
  for type_rec in select ot2.object_type, tree_level(ot2.tree_sortkey) as level
                  from acs_object_types ot1, acs_object_types ot2, acs_objects o
                  where ot2.object_type <> ''acs_object''                       
                    and ot2.object_type <> ''content_revision''
                    and o.object_id = copy__revision_id 
                    and ot1.object_type = o.object_type 
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                  order by level desc
  LOOP
    PERFORM content_revision__copy_attributes(type_rec.object_type, 
                                              copy__revision_id, v_copy_id);
  end loop;

  return v_copy_id;
 
end;' language 'plpgsql';


-- procedure delete
select define_function_args('content_revision__del','revision_id');
create or replace function content_revision__del (integer)
returns integer as '
declare
  delete__revision_id    alias for $1;  
  v_item_id              cr_items.item_id%TYPE;
  v_latest_revision      cr_revisions.revision_id%TYPE;
  v_live_revision        cr_revisions.revision_id%TYPE;
  v_rec                  record;                                      
begin

  -- Get item id and latest/live revisions
  select item_id into v_item_id from cr_revisions 
    where revision_id = delete__revision_id;

  select 
    latest_revision, live_revision
  into 
    v_latest_revision, v_live_revision
  from 
    cr_items
  where 
    item_id = v_item_id;

  -- Recalculate latest revision
  if v_latest_revision = delete__revision_id then
      for v_rec in 
          select r.revision_id
            from cr_revisions r, acs_objects o
           where o.object_id = r.revision_id
             and r.item_id = v_item_id
             and r.revision_id <> delete__revision_id
        order by o.creation_date desc 
      LOOP

          v_latest_revision := v_rec.revision_id;
          exit;
      end LOOP;
      if NOT FOUND then
         v_latest_revision := null;        
      end if;
      
      update cr_items set latest_revision = v_latest_revision
      where item_id = v_item_id;    
  end if; 
 
  -- Clear live revision
  if v_live_revision = delete__revision_id then
    update cr_items set live_revision = null
      where item_id = v_item_id;   
  end if; 

  -- Clear the audit
  delete from cr_item_publish_audit
    where old_revision = delete__revision_id
       or new_revision = delete__revision_id;

  -- Delete the revision
  PERFORM acs_object__delete(delete__revision_id);

  return 0; 
end;' language 'plpgsql';

select define_function_args('content_revision__delete','revision_id');

create or replace function content_revision__delete (integer)
returns integer as '
declare
  delete__revision_id    alias for $1;  
begin
        PERFORM content_revision__del(delete__revision_id);
  return 0; 
end;' language 'plpgsql';

-- function get_number
select define_function_args('content_revision__get_number','revision_id');
create or replace function content_revision__get_number (integer)
returns integer as '
declare
  get_number__revision_id            alias for $1;  
  v_revision                         cr_revisions.revision_id%TYPE;
  v_row_count                        integer default 0;
  rev_cur                            record;
begin
  for rev_cur in select
                   revision_id
                 from 
                   cr_revisions r, acs_objects o
                 where
                   item_id = (select item_id from cr_revisions 
                               where revision_id = get_number__revision_id)
                 and
                   o.object_id = r.revision_id
                 order by
                   o.creation_date
  LOOP
    v_row_count := v_row_count + 1;
    if rev_cur.revision_id = get_number__revision_id then 
       return v_row_count;
       exit;
    end if;
  end LOOP;

  return null;
 
end;' language 'plpgsql' stable strict;

select define_function_args('content_revision__revision_name','revision_id');
create or replace function content_revision__revision_name(integer)
returns text as '
declare
        p_revision_id   alias for $1;
begin
        return ''Revision '' || content_revision__get_number(revision_id) || 
               '' of '' || (select count(*) from cr_revisions where item_id = r.item_id) || '' for item: '' 
               || content_item__get_title(item_id)
               from cr_revisions r where r.revision_id = p_revision_id;
end;' language 'plpgsql' stable strict;

-- procedure to_html
select define_function_args('content_revision__to_html','revision_id');
create or replace function content_revision__to_html (integer)
returns integer as '
declare
  to_html__revision_id            alias for $1;  
  tmp_clob                        text;          
  blob_loc                        integer;          
begin

  -- FIXME
  -- ctx_doc.filter(''cr_doc_filter_index'', revision_id, tmp_clob);

  select 
    content into blob_loc
  from 
    cr_revisions 
  where 
    revision_id = to_html__revision_id
  for update;

 PERFORM clob_to_blob(tmp_clob, blob_loc);

 PERFORM dbms_lob__freetemporary(tmp_clob);

 return 0; 
end;' language 'plpgsql';


-- function is_live
select define_function_args('content_revision__is_live','revision_id');
create or replace function content_revision__is_live (integer)
returns boolean as '
declare
  is_live__revision_id            alias for $1;  
begin

  return count(*) > 0 from cr_items
   where live_revision = is_live__revision_id;

end;' language 'plpgsql' strict;


-- function is_latest
select define_function_args('content_revision__is_latest','revision_id');
create or replace function content_revision__is_latest (integer)
returns boolean as '
declare
  is_latest__revision_id            alias for $1;  
begin

  return count(*) > 0 from cr_items
    where latest_revision = is_latest__revision_id;
 
end;' language 'plpgsql' stable;


-- procedure to_temporary_clob
create or replace function content_revision__to_temporary_clob (integer)
returns integer as '
declare
  to_temporary_clob__revision_id            alias for $1;  
  -- b                                         blob;          
  -- c                                         text;          
begin
  -- FIXME:  I cannot find an instance in the 4.2 beta code where this
  --         is used so I am not worrying about porting it for now.
  --         DCW - 2001-03-28.

  raise EXCEPTION ''not implemented content_revision.to_temporary_clob'';
/*
  insert into cr_content_text (
    revision_id, content
  ) values (
    revision_id, empty_clob()
  ) returning content into c;

  select content into b from cr_revisions 
    where revision_id = to_temporary_clob__revision_id;

  PERFORM blob_to_clob(b, c);
*/
  return 0; 
end;' language 'plpgsql';


-- procedure content_copy
select define_function_args('content_revision__content_copy','revision_id,revision_id_dest');
create or replace function content_revision__content_copy (integer,integer)
returns integer as '
declare
  content_copy__revision_id            alias for $1;  
  content_copy__revision_id_dest       alias for $2;  -- default null  
  v_item_id                            cr_items.item_id%TYPE;
  v_content_length                     cr_revisions.content_length%TYPE;
  v_revision_id_dest                   cr_revisions.revision_id%TYPE;
  v_content                            cr_revisions.content%TYPE;
  v_lob                                cr_revisions.lob%TYPE;
  v_new_lob                            cr_revisions.lob%TYPE;
  v_storage_type                       varchar;
begin
  if content_copy__revision_id is null then 
	raise exception ''content_revision__content_copy attempt to copy a null revision_id'';
  end if;

  select
    content_length, item_id
  into
    v_content_length, v_item_id
  from
    cr_revisions
  where
    revision_id = content_copy__revision_id;

  -- get the destination revision
  if content_copy__revision_id_dest is null then
    select
      latest_revision into v_revision_id_dest
    from
      cr_items
    where
      item_id = v_item_id;
  else
    v_revision_id_dest := content_copy__revision_id_dest;
  end if;


  -- only copy the content if the source content is not null
  if v_content_length is not null and v_content_length > 0 then

    /* The internal LOB types - BLOB, CLOB, and NCLOB - use copy semantics, as 
       opposed to the reference semantics which apply to BFILEs.
       When a BLOB, CLOB, or NCLOB is copied from one row to another row in 
       the same table or in a different table, the actual LOB value is
       copied, not just the LOB locator. */

    select r.content, r.content_length, r.lob, i.storage_type 
      into v_content, v_content_length, v_lob, v_storage_type
      from cr_revisions r, cr_items i 
     where r.item_id = i.item_id 
       and r.revision_id = content_copy__revision_id;

    if v_storage_type = ''lob'' then
        v_new_lob := empty_lob();

	PERFORM lob_copy(v_lob, v_new_lob);

        update cr_revisions
           set content = null,
               content_length = v_content_length,
               lob = v_new_lob
         where revision_id = v_revision_id_dest;
	-- this call has to be before the above instruction,
	-- because lob references the v_new_lob 
	--        PERFORM lob_copy(v_lob, v_new_lob);
    else 
        -- this will work for both file and text types... well sort of.
        -- this really just creates a reference to the first file which is
        -- wrong since, the item_id, revision_id uniquely describes the 
        -- location of the file in the content repository file system.  
        -- after copy is called, the content attribute needs to be updated 
        -- with the new relative file path:

        -- update cr_revisions
        -- set content = ''[cr_create_content_file $item_id $revision_id [cr_fs_path]$old_rel_path]''
        -- where revision_id = :revision_id
        
        -- old_rel_path is the content attribute value of the content revision
        -- that is being copied.
        update cr_revisions
           set content = v_content,
               content_length = v_content_length,
               lob = null
         where revision_id = v_revision_id_dest;
    end if;

  end if;

  return 0; 
end;' language 'plpgsql';


-- procedure content__get_content
select define_function_args('content_revision__get_content','revision_id');
create or replace function content_revision__get_content (integer)
returns text as '
declare
  get_content__revision_id            alias for $1;  
  v_storage_type                      varchar;
  v_lob_id                            integer;
  v_data                              text;
begin
       select i.storage_type, r.lob 
         into v_storage_type, v_lob_id
         from cr_items i, cr_revisions r
        where i.item_id = r.item_id 
          and r.revision_id = get_content__revision_id;
        
        if v_storage_type = ''lob'' then
           return v_lob_id::text;
        else 
           return content
             from cr_revisions
            where revision_id = get_content__revision_id;
        end if;

end;' language 'plpgsql' stable strict;

-- show errors

-- Trigger to maintain latest_revision in cr_items

create function cr_revision_latest_tr () returns opaque as '
begin
  update cr_items set latest_revision = new.revision_id
  where item_id = new.item_id;
  return new;
end;' language 'plpgsql';

create trigger cr_revision_latest_tr after insert on cr_revisions
for each row execute procedure cr_revision_latest_tr ();

-- show errors

