--
-- procedure content_template__new/6
--
CREATE OR REPLACE FUNCTION content_template__new(
   new__name varchar,
   new__parent_id integer,         -- default null
   new__template_id integer,       -- default null
   new__creation_date timestamptz, -- default now()
   new__creation_user integer,     -- default null
   new__creation_ip varchar        -- default null

) RETURNS integer AS $$
--
-- content_template__new/6 maybe obsolete, when we define proper defaults for /8
--
DECLARE
  v_template_id               cr_templates.template_id%TYPE;
  v_parent_id                 cr_items.parent_id%TYPE;
BEGIN

  if new__parent_id is null then
    select c_root_folder_id into v_parent_id from content_template_globals;
  else
    v_parent_id := new__parent_id;
  end if;

  -- make sure we're allowed to create a template in this folder
  if content_folder__is_folder(new__parent_id) = 't' and
    content_folder__is_registered(new__parent_id,'content_template','f') = 'f' then

    raise EXCEPTION '-20000: This folder does not allow templates to be created';

  else
    v_template_id := content_item__new (
        new__name, 
        v_parent_id,
        new__template_id,
        null,
        new__creation_date, 
        new__creation_user, 
        null,
        new__creation_ip,
        'content_item',
        'content_template',
        null,   -- title
        null,   -- description
        'text/plain',
        null,   -- nls_language
        null,   -- text
        null,   -- data
        null,   -- relation_tag
        'f',    -- is_live
        'text', -- storage_type
        null,   -- package_id
        't'     -- with_child_rels
    );

    insert into cr_templates ( 
      template_id 
    ) values (
      v_template_id
    );

    return v_template_id;

  end if;
 
END;
$$ LANGUAGE plpgsql;

