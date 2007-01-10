-- 
-- packages/acs-content-repository/sql/postgresql/upgrade/upgrade-5.3.0b2-5.3.0b3.sql
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2007-01-10
-- @cvs-id $Id$
--


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
