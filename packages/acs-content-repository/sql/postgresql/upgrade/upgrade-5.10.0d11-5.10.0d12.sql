--
-- Update mime types.
-- The changes have to be performed in a transaction, therefore the inline function.
--
create or replace function inline_0 (
    p_label varchar,
    p_extension varchar,
    p_old_mime_type varchar,
    p_new_mime_type varchar
)
returns integer as $$
begin
    SET CONSTRAINTS ALL DEFERRED;
    delete from cr_extension_mime_type_map where mime_type = p_old_mime_type;

    insert into cr_mime_types(label, mime_type, file_extension)
        select p_label, p_new_mime_type, p_extension from dual
        where not exists (select 1 from cr_mime_types where mime_type = p_new_mime_type);

    update cr_content_mime_type_map   set mime_type = p_new_mime_type where mime_type = p_old_mime_type;
    update cr_revisions               set mime_type = p_new_mime_type where mime_type = p_old_mime_type;

    if exists (select 1 from cr_extension_mime_type_map where extension = p_extension) then
        update cr_extension_mime_type_map set mime_type = p_new_mime_type where extension = p_extension;
    else
        insert into cr_extension_mime_type_map (extension, mime_type)
            select p_extension, p_new_mime_type from dual
            where not exists (select 1 from cr_extension_mime_type_map where mime_type = p_new_mime_type);
    end if;

    delete from cr_mime_types where mime_type = p_old_mime_type;
    return 0;
end;
$$ language 'plpgsql';

select inline_0('Image - HEIC'          ,'heic'  ,'' ,'image/heic');
select inline_0('Image - HEIC sequence' ,'heics' ,'' ,'image/heic-sequence');
select inline_0('Image - HEIF'          ,'heif'  ,'' ,'image/heif');
select inline_0('Image - HEIF sequence' ,'heifs' ,'' ,'image/heif-sequence');

drop function inline_0(varchar,varchar,varchar,varchar);
