-- checking if the privilege annotate is created, if not then just create it

create or replace function inline_0() returns integer as '

begin
    if (select count(*) from acs_privileges where privilege = ''annotate'') < 1 then
         perform acs_privilege__create_privilege(''annotate'', null, null);
    end if;
    return null;
end;' language 'plpgsql';

select inline_0();
drop function inline_0();

select acs_privilege__add_child('admin', 'annotate');
