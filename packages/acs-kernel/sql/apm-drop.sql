-- Uninstall file for the data model created by 'apm-create.sql'
-- 
-- @author Bryan Quinn (bquinn)
-- @creation-date Mon Sep 18 16:46:56 2000
--
-- $Id$
--

drop package apm_service;
drop package apm_application;
drop package apm_parameter_value;
drop package apm_package_type;
drop package apm_package_version;
drop package apm_package;
drop package apm;
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
drop table apm_services cascade constraints;
drop table apm_applications cascade constraints;
drop table apm_packages cascade constraints;
drop table apm_package_types cascade constraints;

begin
    acs_object_type.drop_type (
      object_type => 'apm_package'
    );

    acs_object_type.drop_type (
      object_type => 'apm_application'
    );

    acs_object_type.drop_type (
      object_type => 'apm_service'
    );

    acs_object_type.drop_type (
      object_type => 'apm_package_version'
    );

    acs_object_type.drop_type (
      object_type => 'apm_parameter_value'
    );

    acs_object_type.drop_type (
      object_type => 'apm_parameter'
    );
     commit;
end;
/
show errors;
