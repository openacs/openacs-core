--
-- packages/acs-kernel/sql/postgresql/upgrade/upgrade-5.10.0d12-5.10.0d13.sql
--
-- @author Hector Romojaro <hector.romojaro@gmail.com>
-- @creation-date 2019-02-15
-- @cvs-id $Id$
--

declare v_result integer;
begin
select count(*) into v_result from user_constraints where constraint_name = 'apm_parameters_datatype_ck';
if v_result > 0 then
    execute immediate 'alter table apm_parameters drop constraint ''apm_parameters_datatype_ck''';
end if;
select count(*) into v_result from user_constraints where constraint_name = 'apm_parameter_datatype_ck';
if v_result > 0 then
execute immediate 'alter table apm_parameters drop constraint ''apm_parameter_datatype_ck''';
end if;
execute immediate 'alter table apm_parameters add constraint apm_parameters_datatype_ck check(datatype in (''number'',''boolean'',''string'',''text''))';
end;
/
show errors

