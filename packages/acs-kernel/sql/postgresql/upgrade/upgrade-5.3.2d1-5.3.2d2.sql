-- 
-- packages/acs-kernel/sql/oracle/upgrade/upgrade-5.3.2d1-5.3.2d2.sql
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2007-05-24
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
    alter table apm_parameters add constraint apm_parameters_datatype_ck check(datatype in (''number'', ''string'',''text''));
    return null;
end;' language 'plpgsql';

select inline_0();
drop function inline_0();
