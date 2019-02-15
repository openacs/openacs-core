--
-- packages/acs-kernel/sql/postgresql/upgrade/upgrade-5.10.0d12-5.10.0d13.sql
--
-- @author Hector Romojaro <hector.romojaro@gmail.com>
-- @creation-date 2019-02-15
-- @cvs-id $Id$
--
create or replace function inline_0() returns integer as '

begin
    if (select count(*) from pg_constraint where conname=''apm_parameters_datatype_ck'') > 0 then
        alter table apm_parameters drop constraint apm_parameters_datatype_ck;
    end if;
    if (select count(*) from pg_constraint where conname=''apm_parameter_datatype_ck'') > 0 then
        alter table apm_parameters drop constraint apm_parameter_datatype_ck;
    end if;
    alter table apm_parameters add constraint apm_parameters_datatype_ck check(datatype in (''number'',''boolean'',''string'',''text''));
    return null;
end;' language 'plpgsql';

select inline_0();
drop function inline_0();
