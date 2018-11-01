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

  -- call content_extlink.copy if the item is a URL
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

select define_function_args('content_folder__is_folder','item_id');


-- add image__ procs that support package_id

create or replace function image__new (varchar,integer,integer,integer,varchar,integer,varchar,varchar,varchar,varchar,boolean,timestamptz,varchar,integer,integer,integer,integer)
returns integer as '
  declare
    new__name		alias for $1;
    new__parent_id	alias for $2; -- default null
    new__item_id	alias for $3; -- default null
    new__revision_id	alias for $4; -- default null
    new__mime_type	alias for $5; -- default jpeg
    new__creation_user  alias for $6; -- default null
    new__creation_ip    alias for $7; -- default null
    new__relation_tag	alias for $8; -- default null
    new__title          alias for $9; -- default null
    new__description    alias for $10; -- default null
    new__is_live        alias for $11; -- default f
    new__publish_date	alias for $12; -- default now()
    new__path   	alias for $13; 
    new__file_size   	alias for $14; 
    new__height    	alias for $15;
    new__width		alias for $16; 
    new__package_id     alias for $17; -- default null

    new__locale          varchar default null;
    new__nls_language	 varchar default null;
    new__creation_date	 timestamptz default current_timestamp;
    new__context_id      integer;	

    v_item_id		 cr_items.item_id%TYPE;
    v_package_id	 acs_objects.package_id%TYPE;
    v_revision_id	 cr_revisions.revision_id%TYPE;
  begin
    new__context_id := new__parent_id;

    if new__package_id is null then
      v_package_id := acs_object__package_id(new__parent_id);
    else
      v_package_id := new__package_id;
    end if;

    v_item_id := content_item__new (
      new__name,
      new__parent_id,
      new__item_id,
      new__locale,
      new__creation_date,
      new__creation_user,	
      new__context_id,
      new__creation_ip,
      ''content_item'',
      ''image'',
      null,
      new__description,
      new__mime_type,
      new__nls_language,
      null,
      ''file'', -- storage_type
      v_package_id
    );

    -- update cr_child_rels to have the correct relation_tag
    update cr_child_rels
    set relation_tag = new__relation_tag
    where parent_id = new__parent_id
    and child_id = new__item_id
    and relation_tag = content_item__get_content_type(new__parent_id) || ''-'' || ''image'';

    v_revision_id := content_revision__new (
      new__title,
      new__description,
      new__publish_date,
      new__mime_type,
      new__nls_language,
      null,
      v_item_id,
      new__revision_id,
      new__creation_date,
      new__creation_user,
      new__creation_ip,
      v_package_id
    );

    insert into images
    (image_id, height, width)
    values
    (v_revision_id, new__height, new__width);

    -- update revision with image file info
    update cr_revisions
    set content_length = new__file_size,
    content = new__path
    where revision_id = v_revision_id;

    -- is_live => ''t'' not used as part of content_item.new
    -- because content_item.new does not let developer specify revision_id,
    -- revision_id is determined in advance 

    if new__is_live = ''t'' then
       PERFORM content_item__set_live_revision (v_revision_id);
    end if;

    return v_item_id;
end; ' language 'plpgsql';

create or replace function image__new (varchar,integer,integer,integer,varchar,integer,varchar,varchar,varchar,varchar,boolean,timestamptz,varchar,integer,integer,integer
  ) returns integer as '
  declare
    new__name		alias for $1;
    new__parent_id	alias for $2; -- default null
    new__item_id	alias for $3; -- default null
    new__revision_id	alias for $4; -- default null
    new__mime_type	alias for $5; -- default jpeg
    new__creation_user  alias for $6; -- default null
    new__creation_ip    alias for $7; -- default null
    new__relation_tag	alias for $8; -- default null
    new__title          alias for $9; -- default null
    new__description    alias for $10; -- default null
    new__is_live        alias for $11; -- default f
    new__publish_date	alias for $12; -- default now()
    new__path   	alias for $13; 
    new__file_size   	alias for $14; 
    new__height    	alias for $15;
    new__width		alias for $16; 
  begin
    return image__new(new__name,
                      new__parent_id,
                      new__item_id,
                      new__revision_id,
                      new__mime_type,
                      new__creation_user,
                      new__creation_ip,
                      new__relation_tag,
                      new__title,
                      new__description,
                      new__is_live,
                      new__publish_date,
                      new__path,
                      new__file_size,
                      new__height,
                      new__width,
                      null
    );
end; ' language 'plpgsql';

-- DRB's version

create or replace function image__new (varchar,integer,integer,integer,varchar,integer,varchar,varchar,varchar,varchar,varchar,
                            varchar,timestamptz,integer, integer, integer) returns integer as '
  declare
    p_name              alias for $1;
    p_parent_id         alias for $2; -- default null
    p_item_id           alias for $3; -- default null
    p_revision_id       alias for $4; -- default null
    p_mime_type         alias for $5; -- default jpeg
    p_creation_user     alias for $6; -- default null
    p_creation_ip       alias for $7; -- default null
    p_title             alias for $8; -- default null
    p_description       alias for $9; -- default null
    p_storage_type      alias for $10;
    p_content_type      alias for $11;
    p_nls_language      alias for $12;
    p_publish_date      alias for $13;
    p_height            alias for $14;
    p_width             alias for $15;
    p_package_id        alias for $16; -- default null

    v_item_id		 cr_items.item_id%TYPE;
    v_revision_id	 cr_revisions.revision_id%TYPE;
    v_package_id	 acs_objects.package_id%TYPE;
  begin

     if content_item__is_subclass(p_content_type, ''image'') = ''f'' then
       raise EXCEPTION ''-20000: image__new can only be called for an image type''; 
     end if;

    if p_package_id is null then
      v_package_id := acs_object__package_id(p_parent_id);
    else
      v_package_id := p_package_id;
    end if;

    v_item_id := content_item__new (
      p_name,
      p_parent_id,
      p_item_id,
      null,
      current_timestamp,
      p_creation_user,	
      p_parent_id,
      p_creation_ip,
      ''content_item'',
      p_content_type,
      null,
      null,
      null,
      null,
      null,
      p_storage_type,
      v_package_id
    );

    -- We will let the caller fill in the LOB data or file path.

    v_revision_id := content_revision__new (
      p_title,
      p_description,
      p_publish_date,
      p_mime_type,
      p_nls_language,
      null,
      v_item_id,
      p_revision_id,
      current_timestamp,
      p_creation_user,
      p_creation_ip,
      v_package_id
    );

    insert into images
    (image_id, height, width)
    values
    (v_revision_id, p_height, p_width);

    return v_item_id;
end; ' language 'plpgsql';

create or replace function image__new (varchar,integer,integer,integer,varchar,integer,varchar,varchar,varchar,varchar,varchar,
                            varchar,timestamptz,integer, integer) returns integer as '
  declare
    p_name              alias for $1;
    p_parent_id         alias for $2; -- default null
    p_item_id           alias for $3; -- default null
    p_revision_id       alias for $4; -- default null
    p_mime_type         alias for $5; -- default jpeg
    p_creation_user     alias for $6; -- default null
    p_creation_ip       alias for $7; -- default null
    p_title             alias for $8; -- default null
    p_description       alias for $9; -- default null
    p_storage_type      alias for $10;
    p_content_type      alias for $11;
    p_nls_language      alias for $12;
    p_publish_date      alias for $13;
    p_height            alias for $14;
    p_width             alias for $15;
  begin
    return image__new(p_name,
                      p_parent_id,
                      p_item_id,
                      p_revision_id,
                      p_mime_type,
                      p_creation_user,
                      p_creation_ip,
                      p_title,
                      p_description,
                      p_storage_type,
                      p_content_type,
                      p_nls_language,
                      p_publish_date,
                      p_height,
                      p_width,
                      null
    );
end; ' language 'plpgsql';


create or replace function image__new_revision(integer, integer, varchar, varchar, timestamptz, varchar, varchar,
                                    integer, varchar, integer, integer, integer) returns integer as '
declare
   p_item_id          alias for $1;
   p_revision_id      alias for $2;
   p_title            alias for $3;
   p_description      alias for $4;
   p_publish_date     alias for $5;
   p_mime_type        alias for $6;
   p_nls_language     alias for $7;
   p_creation_user    alias for $8;
   p_creation_ip      alias for $9;
   p_height           alias for $10;
   p_width            alias for $11;
   p_package_id       alias for $12;
   v_revision_id      integer;
   v_package_id       acs_objects.package_id%TYPE;
begin
    -- We will let the caller fill in the LOB data or file path.

    if p_package_id is null then
      v_package_id := acs_object__package_id(p_item_id);
    else
      v_package_id := p_package_id;
    end if;

    v_revision_id := content_revision__new (
      p_title,
      p_description,
      p_publish_date,
      p_mime_type,
      p_nls_language,
      null,
      p_item_id,
      p_revision_id,
      current_timestamp,
      p_creation_user,
      p_creation_ip,
      v_package_id
    );

    insert into images
    (image_id, height, width)
    values
    (v_revision_id, p_height, p_width);

    return v_revision_id;
end;' language 'plpgsql';

create or replace function image__new_revision(integer,integer,varchar,varchar,timestamptz,varchar,varchar,
                                    integer,varchar,integer,integer) returns integer as '
declare
   p_item_id          alias for $1;
   p_revision_id      alias for $2;
   p_title            alias for $3;
   p_description      alias for $4;
   p_publish_date     alias for $5;
   p_mime_type        alias for $6;
   p_nls_language     alias for $7;
   p_creation_user    alias for $8;
   p_creation_ip      alias for $9;
   p_height           alias for $10;
   p_width            alias for $11;
   v_revision_id      integer;
begin
   return image__new_revision(p_item_id,
                              p_revision_id,
                              p_title,
                              p_description,
                              p_publish_date,
                              p_mime_type,
                              p_nls_language,
                              p_creation_user,
                              p_creation_ip,
                              p_height,
                              p_width,
                              p_revision_id,
                              null
   );

end;' language 'plpgsql';
