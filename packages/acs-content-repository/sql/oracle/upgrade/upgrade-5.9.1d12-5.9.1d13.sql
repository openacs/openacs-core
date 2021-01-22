--
-- Update mime_type to official content type as registered by IANA.
-- The changes have to be performed in a transaction, therefore the inline function.
--

create or replace function inline_0 (
    p_label in varchar,
    p_extension in varchar,
    p_old_mime_type in varchar,
    p_new_mime_type in varchar
)
return integer 
as
begin
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
  return 1;
end;
/

select inline_0('Javascript','js','application/x-javascript','application/javascript') from dual;
select inline_0('JSON','json','-- dummy --','application/json') from dual;

drop function inline_0;
