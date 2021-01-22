--
-- Update mime_type to official content type as registered by IANA.
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

  insert into cr_extension_mime_type_map (extension, mime_type)
    select p_extension, p_new_mime_type from dual
    where not exists (select 1 from cr_extension_mime_type_map where mime_type = p_new_mime_type);

  delete from cr_mime_types where mime_type = p_old_mime_type;
  return 0;
end;
$$ language 'plpgsql';

select inline_0('Macromedia Shockwave','swf','application/x-shockwave-flash','application/vnd.adobe.flash-movie');

drop function inline_0(varchar,varchar,varchar,varchar);

