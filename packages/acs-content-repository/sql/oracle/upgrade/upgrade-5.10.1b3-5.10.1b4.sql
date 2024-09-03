--
-- Add extension to an existing mime type.
-- The changes have to be performed in a transaction, therefore the inline function.
--

create or replace function inline_0 (
    p_extension in varchar,
    p_mime_type in varchar
)
return integer
as
begin
  v_extension_exists integer default 0;

  select 1 into v_extension_exists 
    from cr_extension_mime_type_map 
    where extension = p_extension;

  if v_extension_exists = 1 then
    update cr_extension_mime_type_map set mime_type = p_mime_type where extension = p_extension;
  else
    insert into cr_extension_mime_type_map (extension, mime_type)
      select p_extension, p_mime_type from dual;
  end if;

  return 1;
end;
/

select inline_0('mjs','application/javascript') from dual;

drop function inline_0;
