--
-- Add extension to an existing mime type.
-- The changes have to be performed in a transaction, therefore the inline function.
--
create or replace function inline_0 (
    p_extension varchar,
    p_mime_type varchar
)
returns integer as $$
begin
    SET CONSTRAINTS ALL DEFERRED;

    if exists (select 1 from cr_extension_mime_type_map where extension = p_extension) then
        update cr_extension_mime_type_map set mime_type = p_mime_type where extension = p_extension;
    else
        insert into cr_extension_mime_type_map (extension, mime_type)
            select p_extension, p_mime_type from dual;
    end if;

    return 0;
end;
$$ language 'plpgsql';

select inline_0('mjs','application/javascript');

drop function inline_0(varchar,varchar);
