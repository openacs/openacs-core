-- Uninstall file for the data model created by 'apm-create.sql'
-- 
-- @author Bryan Quinn (bquinn)
-- @creation-date Mon Sep 18 16:46:56 2000
--
-- apm-drop.sql,v 1.6 2000/10/24 22:26:19 bquinn Exp
--
\t
select drop_package('apm_service');
select drop_package('apm_application');
select drop_package('apm_parameter_value');
select drop_package('apm_package_type');
select drop_package('apm_package_version');
select drop_package('apm_package');
select drop_package('apm');
drop table apm_package_dependencies;
drop table apm_parameter_values;
drop table apm_parameters;
drop view apm_file_info;
drop index apm_package_files_by_version;
drop index apm_package_files_by_path;
drop table apm_package_files;
drop table apm_package_file_types;
drop view apm_enabled_package_versions;
drop view apm_package_version_info;
drop table apm_package_owners;
drop table apm_package_versions;
drop table apm_services;
drop table apm_applications;
drop table apm_packages;
drop table apm_package_types;

create function inline_0 () returns integer as '
begin
    PERFORM acs_object_type__drop_type (
      ''apm_package'', ''f''
    );

    PERFORM acs_object_type__drop_type (
      ''apm_application'', ''f''
    );

    PERFORM acs_object_type__drop_type (
      ''apm_service'', ''f''
    );

    PERFORM acs_object_type__drop_type (
      ''apm_package_version'', ''f''
    );

    PERFORM acs_object_type__drop_type (
      ''apm_parameter_value'', ''f''
    );

    PERFORM acs_object_type__drop_type (
      ''apm_parameter'', ''f''
    );

    return null;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();
\t
