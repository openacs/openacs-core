-- @author Lars Pind (lars@collaboraid.biz)
-- @creation-date 2003-10-14
-- @cvs-id $Id$

select define_function_args('content_folder__new','name,label,description,parent_id,context_id,folder_id,creation_date,creation_user,creation_ip');

create or replace function image__new_revision(integer, integer, varchar, varchar, timestamptz, varchar, varchar,
                                    integer, varchar, integer, integer) returns integer as '
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
    -- We will let the caller fill in the LOB data or file path.

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
      p_creation_ip
    );

    insert into images
    (image_id, height, width)
    values
    (v_revision_id, p_height, p_width);

    return v_revision_id;
end;' language 'plpgsql';

