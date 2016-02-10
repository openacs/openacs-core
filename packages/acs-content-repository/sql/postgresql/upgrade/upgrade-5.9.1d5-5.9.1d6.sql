--
-- reduce number of versions of content_revision__new from 7 to 4 by using defaults
-- commented differences
-- marking on version of content_revision__new/7 as deprecated
--
-- let automatically generated functions call directly content_revision__new/13
-- remove space from automatically generated functions
-- updated automatically generated functions for all types of the content repository
--

-- content_revision__new/13
DROP FUNCTION IF EXISTS content_revision__new(varchar,varchar,timestamptz,varchar,varchar,text,integer,integer,timestamptz,integer,varchar,integer,integer);
DROP FUNCTION IF EXISTS content_revision__new(varchar,varchar,timestamptz,varchar,varchar,text,integer,integer,timestamptz,integer,varchar,integer);
DROP FUNCTION IF EXISTS content_revision__new(varchar,varchar,timestamptz,varchar,varchar,text,integer,integer,timestamptz,integer,varchar);

-- content_revision__new/12
DROP FUNCTION IF EXISTS content_revision__new(varchar,varchar,timestamptz,varchar,varchar,integer,integer,integer,timestamptz,integer,varchar,integer);
DROP FUNCTION IF EXISTS content_revision__new(varchar,varchar,timestamptz,varchar,varchar,integer,integer,integer,timestamptz,integer,varchar);

-- content_revision__new/7
DROP FUNCTION IF EXISTS content_revision__new(varchar,varchar,timestamptz,varchar,text,integer,integer);
DROP FUNCTION IF EXISTS content_revision__new(varchar,varchar,timestamptz,varchar,text,integer);


--
-- procedure content_revision__new/13
--
-- We can't use for the last two argments "default null", since
-- otherwise calls with provided package_id but no content_length
-- would lead to a wrong interpretation of the package_id as
-- content_length.
--
CREATE OR REPLACE FUNCTION content_revision__new(
   new__title varchar,
   new__description varchar,       -- default null
   new__publish_date timestamptz,  -- default now()
   new__mime_type varchar,         -- default 'text/plain'
   new__nls_language varchar,      -- default null
   new__text text,                 -- default ' '
   new__item_id integer,
   new__revision_id integer,       -- default null
   new__creation_date timestamptz, -- default now()
   new__creation_user integer,     -- default null
   new__creation_ip varchar,       -- default null
   new__content_length integer,    -- default null
   new__package_id integer         -- default null

) RETURNS integer AS $$
DECLARE
  v_revision_id               integer;       
  v_package_id                acs_objects.package_id%TYPE;
  v_content_type              acs_object_types.object_type%TYPE;
  v_storage_type              cr_items.storage_type%TYPE;
  v_length                    cr_revisions.content_length%TYPE;
BEGIN

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
      't',
      new__title,
      v_package_id
  );

  select storage_type into v_storage_type
    from cr_items
   where item_id = new__item_id;

  if v_storage_type = 'text' then 
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
 
END;
$$ LANGUAGE plpgsql;

--
-- procedure content_revision__new/11 content_revision__new/12
--
-- text/file version
--
CREATE OR REPLACE FUNCTION content_revision__new(
   new__title varchar,
   new__description varchar,       -- default null
   new__publish_date timestamptz,  -- default now()
   new__mime_type varchar,         -- default 'text/plain'
   new__nls_language varchar,      -- default null
   new__text text,                 -- default ' '
   new__item_id integer,
   new__revision_id integer,       -- default null
   new__creation_date timestamptz, -- default now()
   new__creation_user integer,     -- default null
   new__creation_ip varchar,       -- default null
   new__package_id integer default null

) RETURNS integer AS $$   
DECLARE
BEGIN
	raise NOTICE 'content_revision__new/12 is deprecated, call content_revision__new/13 instead';

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
                                     null,               -- content_length
                                     new__package_id
		);
END
$$ LANGUAGE plpgsql;


--
-- procedure content_revision__new/11 content_revision__new/12
--
-- lob version
--
CREATE OR REPLACE FUNCTION content_revision__new(
   new__title varchar,
   new__description varchar,       -- default null
   new__publish_date timestamptz,  -- default now()
   new__mime_type varchar,         -- default 'text/plain'
   new__nls_language varchar,      -- default null
   new__data integer,
   new__item_id integer,
   new__revision_id integer,       -- default null
   new__creation_date timestamptz, -- default now()
   new__creation_user integer,     -- default null
   new__creation_ip varchar,       -- default null
   new__package_id integer default null

) RETURNS integer AS $$
DECLARE
  v_revision_id               integer;       
  v_package_id                acs_objects.package_id%TYPE;
  v_content_type              acs_object_types.object_type%TYPE;
BEGIN

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
      't',
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

END;
$$ LANGUAGE plpgsql;


--
-- procedure content_revision__new/7
--
CREATE OR REPLACE FUNCTION content_revision__new(
   new__title varchar,
   new__description varchar,      -- default null
   new__publish_date timestamptz, -- default now()
   new__mime_type varchar,        -- default 'text/plain'
   new__text text,                -- default ' '
   new__item_id integer,
   new__package_id integer default null

) RETURNS integer AS $$
DECLARE
BEGIN
	raise NOTICE 'content_revision__new/7 is deprecated, call content_revision__new/13 instead';

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

END;
$$ LANGUAGE plpgsql;

--
-- procedure content_type__refresh_trigger/1
--
CREATE OR REPLACE FUNCTION content_type__refresh_trigger(
   refresh_trigger__content_type varchar
) RETURNS integer AS $$
DECLARE
  rule_text                               text default '';
  function_text                           text default '';
  v_table_name                            acs_object_types.table_name%TYPE;
  type_rec                                record;
BEGIN

  -- get the table name for the content type (determines view name)
  raise NOTICE 'refresh trigger for % ', refresh_trigger__content_type;

    -- Since we allow null table name use object type if table name is null so
  -- we still can have a view.
  select coalesce(table_name,object_type)
    into v_table_name
    from acs_object_types 
   where object_type = refresh_trigger__content_type;

  --=================== start building rule code =======================

  function_text := function_text ||
             'create or replace function ' || v_table_name || '_f (p_new '|| v_table_name || 'i)
             returns void as ''
             declare
               v_revision_id integer;
             begin

               select content_revision__new(
                                     p_new.title,
                                     p_new.description,
                                     p_new.publish_date,
                                     p_new.mime_type,
                                     p_new.nls_language,
                                     case when p_new.text is null 
                                              then p_new.data 
                                              else p_new.text
                                           end,
                                     content_symlink__resolve(p_new.item_id),
                                     p_new.revision_id,
                                     now(),
                                     p_new.creation_user, 
                                     p_new.creation_ip,
                                     null,                    -- content_length
                                     p_new.object_package_id
                ) into v_revision_id;
                ';

  -- add an insert statement for each subtype in the hierarchy for this type

  for type_rec in select ot2.object_type, tree_level(ot2.tree_sortkey) as level
                  from acs_object_types ot1, acs_object_types ot2
                  where ot2.object_type <> 'acs_object'                       
                    and ot2.object_type <> 'content_revision'
                    and ot1.object_type = refresh_trigger__content_type
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                    and ot1.table_name is not null
                  order by level asc
  LOOP
    function_text := function_text || content_type__trigger_insert_statement(type_rec.object_type) || ';
    ';
  end loop;

  function_text := function_text || '
   return;
   end;'' language plpgsql; 
   ';
  -- end building the rule definition code

  -- create the new function
  execute function_text;

  rule_text := 'create rule ' || v_table_name || '_r as on insert to ' ||
               v_table_name || 'i do instead SELECT ' || v_table_name || '_f(new); ' ;
  --================== done building rule code =======================

  -- drop the old rule
  if rule_exists(v_table_name || '_r', v_table_name || 'i') then 
     execute 'drop rule ' || v_table_name || '_r ' || 'on ' || v_table_name || 'i';
  end if;

  -- create the new rule for inserts on the content type
  execute rule_text;

  return null; 

END;
$$ LANGUAGE plpgsql;

-- upgrade types

WITH RECURSIVE cr_types as (
    select object_type from acs_object_types where object_type = 'content_revision'
UNION ALL
    select ot.object_type from acs_object_types ot,cr_types 
    where ot.supertype = cr_types.object_type
) select object_type, content_type__refresh_view(object_type) from cr_types;

