-- Make two new versions of content_template__new() and make the one that is a wrapper
-- (the first one) take two new params; new__text and new__is_live.
-- With this version, a revision of the template will be created automatically.
-- You thus avoid calling content_revision.new() in a separate step ...
-- (ola@polyxena.net)

create or replace function content_template__new(varchar,text,bool) returns integer as '
declare
        new__name       alias for $1;
        new__text       alias for $2;
        new__is_live    alias for $3;
begin
        return content_template__new(new__name,
                                     null,
                                     null,
                                     now(),
                                     null,
                                     null,
                                     new__text,
                                     new__is_live
        );

end;' language 'plpgsql';


create or replace function content_template__new (varchar,integer,integer,timestamptz,integer,varchar,text,bool)
returns integer as '
declare
  new__name                   alias for $1;  
  new__parent_id              alias for $2;  -- default null  
  new__template_id            alias for $3;  -- default null
  new__creation_date          alias for $4;  -- default now()
  new__creation_user          alias for $5;  -- default null
  new__creation_ip            alias for $6;  -- default null
  new__text                   alias for $7;  -- default null
  new__is_live                alias for $8;  -- default ''f''
  v_template_id               cr_templates.template_id%TYPE;
  v_parent_id                 cr_items.parent_id%TYPE;
begin

  if new__parent_id is null then
    v_parent_id := content_template_globals.c_root_folder_id;
  else
    v_parent_id := new__parent_id;
  end if;

  -- make sure we''re allowed to create a template in this folder
  if content_folder__is_folder(new__parent_id) = ''t'' and
    content_folder__is_registered(new__parent_id,''content_template'',''f'') = ''f'' then

    raise EXCEPTION ''-20000: This folder does not allow templates to be created'';

  else
    v_template_id := content_item__new (
        new__template_id,     -- new__item_id
        new__name,            -- new__name
        v_parent_id,          -- new__parent_id
        null,                 -- new__title
        new__creation_date,   -- new__creation_date
        new__creation_user,   -- new__creation_user
        null,                 -- new__context_id
        new__creation_ip,     -- new__creation_ip
        new__is_live,         -- new__is_live
        ''text/plain'',       -- new__mime_type
        new__text,            -- new__text
        ''text'',             -- new__storage_type
        ''t'',                -- new__security_inherit_p
        ''CR_FILES'',         -- new__storage_area_key
        ''content_item'',     -- new__item_subtype
        ''content_template''  -- new__content_type
    );

    insert into cr_templates ( 
      template_id 
    ) values (
      v_template_id
    );

    return v_template_id;

  end if;
 
end;' language 'plpgsql';
