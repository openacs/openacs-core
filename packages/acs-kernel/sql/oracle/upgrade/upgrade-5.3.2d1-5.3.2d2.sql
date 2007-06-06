-- 
-- packages/acs-kernel/sql/oracle/upgrade/upgrade-5.3.2d1-5.3.2d2.sql
-- 
-- @author Dave Bauer (dave@thedesignexperience.org)
-- @creation-date 2007-05-24
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
execute immediate 'alter table apm_parameters add constraint apm_parameters_datatype_ck check(datatype in (''number'', ''string'',''text''))';
end;
/
show errors

