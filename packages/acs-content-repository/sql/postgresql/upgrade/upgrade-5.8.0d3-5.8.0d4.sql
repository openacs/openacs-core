-- providing upgrade for content_extlink__new and content_revision__copy
-- in order to get next values of sequences using nextval()

--
-- procedure content_extlink__new/10
--
CREATE OR REPLACE FUNCTION content_extlink__new(
   new__name varchar,              -- default null
   new__url varchar,
   new__label varchar,             -- default null
   new__description varchar,       -- default null
   new__parent_id integer,
   new__extlink_id integer,        -- default null
   new__creation_date timestamptz, -- default now() -- default 'now'
   new__creation_user integer,     -- default null
   new__creation_ip varchar,       -- default null
   new__package_id integer         -- default null

) RETURNS integer AS $$
DECLARE
  v_extlink_id                cr_extlinks.extlink_id%TYPE;
  v_package_id                acs_objects.package_id%TYPE;
  v_label                     cr_extlinks.label%TYPE;
  v_name                      cr_items.name%TYPE;
BEGIN

  if new__label is null then
    v_label := new__url;
  else
    v_label := new__label;
  end if;

  if new__name is null then
    select nextval('t_acs_object_id_seq') into v_extlink_id from dual;
    v_name := 'link' || v_extlink_id;
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
      'content_item',
      'content_extlink', 
      null,
      null,
      'text/plain',
      null,
      null,
      'text',
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

END;
$$ LANGUAGE plpgsql;



--
-- procedure content_revision__copy/5
--
CREATE OR REPLACE FUNCTION content_revision__copy(
   copy__revision_id integer,
   copy__copy_id integer,        -- default null
   copy__target_item_id integer, -- default null
   copy__creation_user integer,  -- default null
   copy__creation_ip varchar     -- default null

) RETURNS integer AS $$
DECLARE
  v_copy_id                    cr_revisions.revision_id%TYPE;
  v_target_item_id             cr_items.item_id%TYPE;
  type_rec                     record;
BEGIN
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
    select nextval('t_acs_object_id_seq') into v_copy_id from dual;
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
                  where ot2.object_type <> 'acs_object'                       
                    and ot2.object_type <> 'content_revision'
                    and o.object_id = copy__revision_id 
                    and ot1.object_type = o.object_type 
                    and ot1.tree_sortkey between ot2.tree_sortkey and tree_right(ot2.tree_sortkey)
                  order by level desc
  LOOP
    PERFORM content_revision__copy_attributes(type_rec.object_type, 
                                              copy__revision_id, v_copy_id);
  end loop;

  return v_copy_id;
 
END;
$$ LANGUAGE plpgsql;
