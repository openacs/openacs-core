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
create function content_revision__new (varchar,varchar,timestamp,varchar,varchar,integer,integer,integer,timestamp,integer,varchar)
returns integer as '
declare
  new__title                  alias for $1;  
  new__description            alias for $2;  
  new__publish_date           alias for $3;  
  new__mime_type              alias for $4;  
  new__nls_language           alias for $5;  
  -- blob id FIXME
  new__data                   alias for $6;  
  new__item_id                alias for $7;  
  new__revision_id            alias for $8;  
  new__creation_date          alias for $9;  
  new__creation_user          alias for $10; 
  new__creation_ip            alias for $11; 
  v_revision_id               integer;       
  v_content_type              acs_object_types.object_type%TYPE;
begin

  v_content_type := content_item__get_content_type(new__item_id);

  v_revision_id := acs_object__new(
      new__revision_id,
      v_content_type, 
      new__creation_date, 
      new__creation_user, 
      new__creation_ip, 
      new__item_id
  );

  insert into cr_revisions (
    revision_id, title, description, mime_type, publish_date,
    nls_language, content, item_id
  ) values (
    v_revision_id, new__title, new__description, new__mime_type, 
    new__publish_date, new__nls_language, new__data, new__item_id     
  );

  return v_revision_id;

end;' language 'plpgsql';


-- function new
create function content_revision__new (varchar,varchar,timestamp,varchar,varchar,text,integer,integer,timestamp,integer,varchar)
returns integer as '
declare
  title                  alias for $1;  
  description            alias for $2;  
  publish_date           alias for $3;  
  mime_type              alias for $4;  
  nls_language           alias for $5;  
  text                   alias for $6;  
  item_id                alias for $7;  
  revision_id            alias for $8;  
  creation_date          alias for $9;  
  creation_user          alias for $10; 
  creation_ip            alias for $11; 
  v_revision_id          integer;       
  blob_loc               cr_revisions.content%TYPE;
begin

  blob_loc := empty_blob();

  v_revision_id := content_revision__new(
      title,
      description,
      publish_date,
      mime_type,
      nls_language,
      blob_loc,
      item_id, 
      revision_id,
      creation_date,
      creation_user,
      creation_ip
  );

  select 
    content into blob_loc
  from 
    cr_revisions 
  where 
    revision_id = v_revision_id
  for update;

  PERFORM string_to_blob(text, blob_loc);

  return v_revision_id;
 
end;' language 'plpgsql';


-- procedure copy_attributes
create function content_revision__copy_attributes (varchar,integer,integer)
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

  execute ''insert into '' || v_table_name || '' select '' || copy_id || 
          '' as '' || v_id_column || cols || '' from '' || 
          v_table_name || '' where '' || v_id_column || '' = '' || 
          copy_attributes__revision_id;
  
  return 0; 
end;' language 'plpgsql';


-- function copy
create function content_revision__copy (integer,integer,integer,integer,varchar)
returns integer as '
declare
  copy__revision_id            alias for $1;  
  copy__copy_id                alias for $2;  
  copy__target_item_id         alias for $3;  
  copy__creation_user          alias for $4;  
  copy__creation_ip            alias for $5;  
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
    select acs_object_id_seq.nextval into v_copy_id from dual;
  else
    v_copy_id := copy__copy_id;
  end if;

  -- create the basic object
  insert into acs_objects 
       select 
         v_copy_id as object_id, 
         object_type, 
         context_id, 
         security_inherit_p, 
         copy__creation_user as creation_user, 
         now() as creation_date, 
         copy__creation_ip as creation_ip,
         now() as last_modified, 
         copy__creation_user as modifying_user, 
         copy__creation_ip as modifying_ip 
       from
         acs_objects 
       where 
         object_id = copy__revision_id;
  
  -- create the basic revision (using v_target_item_id)
  insert into cr_revisions 
      select 
        v_copy_id as revision_id, title, description, publish_date, 
        mime_type, nls_language, 
	content, v_target_item_id as item_id
      from 
        cr_revisions 
      where
        revision_id = copy__revision_id;

  -- iterate over the ancestor types and copy attributes
  for type_rec in select                                                
                    object_type
                  from                                                
                    acs_object_types                                  
                  where                                               
                    object_type <> ''acs_object''                       
                  and                                                 
                    object_type <> ''content_revision''                 
                  connect by                                          
                    prior supertype = object_type                     
                  start with                                          
                    object_type = (select object_type 
                                     from acs_objects 
                                    where object_id = copy__revision_id)
                  order by
                    level desc 
  LOOP
    PERFORM content_revision__copy_attributes(type_rec.object_type, 
                                              copy__revision_id, v_copy_id);
  end loop;

  return v_copy_id;
 
end;' language 'plpgsql';


-- procedure delete
create function content_revision__delete (integer)
returns integer as '
declare
  delete__revision_id    alias for $1;  
  v_item_id              cr_items.item_id%TYPE;
  v_latest_revision      cr_revisions.revision_id%TYPE;
  v_live_revision        cr_revisions.revision_id%TYPE;
                                        
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
          select r.revision_id into v_latest_revision 
            from cr_revisions r, acs_objects o
           where o.object_id = r.revision_id
             and r.item_id = v_item_id
             and r.revision_id <> delete__revision_id
        order by o.creation_date desc 
      LOOP

          v_latest_revision := v_rec.revision_id;
          exit;
      end LOOP;
  end if; 

  if NOT FOUND then
     v_latest_revision := null;        
  end if;

  update cr_items set latest_revision = v_latest_revision
  where item_id = v_item_id;
 
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


-- function get_number
create function content_revision__get_number (integer)
returns number as '
declare
  get_number__revision_id            alias for $1;  
  v_number                           integer;       
  v_revision                         cr_revisions.revision_id%TYPE;
  row_count                          integer default 0;
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
    row_count := row_count + 1;
    if v_revision = get_number__revision_id then 
       v_number := row_count;
       exit;
    end if;
  end LOOP;

  return v_number;
 
end;' language 'plpgsql';


-- procedure index_attributes
create function content_revision__index_attributes (integer)
returns integer as '
declare
  index_attributes__revision_id            alias for $1;  
  clob_loc                                 text;          
  v_revision_id                            cr_revisions.revision_id%TYPE;
begin

  insert into cr_revision_attributes 
    select index_attributes__revision_id as revision_id, 
           clob_loc as attributes 

  -- FIXME: need to find a way to deal with these xml calls
  v_revision_id := write_xml(revision_id, clob_loc);  

  return 0; 
end;' language 'plpgsql';


-- function import_xml
create function content_revision__import_xml (integer,integer,numeric)
returns integer as '
declare
  import_xml__item_id                alias for $1;  
  import_xml__revision_id            alias for $2;  
  import_xml__doc_id                 alias for $3;  
  clob_loc                           text;          
  v_revision_id                      cr_revisions.revision_id%TYPE;
begin

  select doc into clob_loc from cr_xml_docs where doc_id = import_xml__doc_id;
  v_revision_id := read_xml(import_xml__item_id, import_xml__revision_id, 
                            import_xml__clob_loc);  

  return v_revision_id;
 
end;' language 'plpgsql';


-- function export_xml
create function content_revision__export_xml (integer)
returns integer as '
declare
  revision_id            alias for $1;  
  clob_loc               clob;          
  v_doc_id               cr_xml_docs.doc_id%TYPE;
  v_revision_id          cr_revisions.revision_id%TYPE;
begin

  v_doc_id := cr_xml_doc_seq.nextval;

  insert into cr_xml_docs (doc_id, doc) 
    values (v_doc_id, empty_clob());

  -- FIXME: need a way to deal with this xml call.
  v_revision_id := write_xml(revision_id, clob_loc);  

  return v_doc_id;
 
end;' language 'plpgsql';


-- procedure to_html
create function content_revision__to_html (integer)
returns integer as '
declare
  to_html__revision_id            alias for $1;  
  tmp_clob                        text;          
  blob_loc                        integer;          
begin

  -- what is this? FIXME
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
create function content_revision__is_live (integer)
returns boolean as '
declare
  is_live__revision_id            alias for $1;  
begin

  select 1 from cr_items
    where live_revision = is_live__revision_id;

  if NOT FOUND then 
     return ''f'';
  else 
     return ''t'';
  end if;

end;' language 'plpgsql';


-- function is_latest
create function content_revision__is_latest (integer)
returns varchar as '
declare
  is_latest__revision_id            alias for $1;  
  v_ret                             varchar(1);    
begin

  select 1 from cr_items
    where latest_revision = is_latest__revision_id;

  if NOT FOUND then 
     return ''f'';
  else 
     return ''t'';
  end if;
 
end;' language 'plpgsql';


-- procedure to_temporary_clob
create function content_revision__to_temporary_clob (integer)
returns integer as '
declare
  to_temporary_clob__revision_id            alias for $1;  
  b                                         blob;          
  c                                         text;          
begin
  -- FIXME
  insert into cr_content_text (
    revision_id, content
  ) values (
    revision_id, empty_clob()
  ) returning content into c;

  select content into b from cr_revisions 
    where revision_id = to_temporary_clob__revision_id;

  PERFORM blob_to_clob(b, c);

  return 0; 
end;' language 'plpgsql';


-- procedure content_copy
create function content_revision__content_copy (integer,integer)
returns integer as '
declare
  content_copy__revision_id            alias for $1;  
  content_copy__revision_id_dest       alias for $2;  
  lobs                                 blob;          
  lobd                                 blob;          
  v_item_id                            cr_items.item_id%TYPE;
  v_content_length                     integer;       
  v_revision_id_dest                   cr_revisions.revision_id%TYPE;
begin
  -- FIXME
  select
    dbms_lob.getlength( content ), item_id
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
    update cr_revisions
      set content = ( select content from cr_revisions
                        where revision_id = content_copy__revision_id )
      where revision_id = v_revision_id_dest;
  end if;

  return 0; 
end;' language 'plpgsql';



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

