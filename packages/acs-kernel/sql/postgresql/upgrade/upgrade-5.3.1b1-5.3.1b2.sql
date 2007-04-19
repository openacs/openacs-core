create or replace function inline_0() returns integer as '
declare v_exists integer;
begin
select into v_exists count(*) from pg_class where relname = ''acs_permissions_object_id_idx'';
if v_exists = 0 then
create index acs_permissions_object_id_idx on acs_permissions(object_id);
end if;
return null;
end;' language 'plpgsql';
select inline_0();
drop function inline_0();

