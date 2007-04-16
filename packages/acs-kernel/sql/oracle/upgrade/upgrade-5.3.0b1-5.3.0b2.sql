declare v_exists integer;

begin
select count(*) into v_exists from user_indexes where lower(index_name)='acs_permissions_object_id_idx';
if v_exists = 0 then
    execute immediate 'create index acs_permissions_object_id_idx on acs_permissions(object_id)';
end if;

end;
/
show errors

