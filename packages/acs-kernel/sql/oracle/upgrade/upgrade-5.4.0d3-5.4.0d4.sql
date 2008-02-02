-- checking if the privilege annotate is created, if not then just create it

declare v_result integer;
begin
 select count(*) into v_result from acs_privileges where privilege = 'annotate';
 if v_result < 1 then
     acs_privilege.create_privilege('annotate');
 end if;
 acs_privilege.add_child('admin', 'annotate');
 commit;
end;
/
show errors
