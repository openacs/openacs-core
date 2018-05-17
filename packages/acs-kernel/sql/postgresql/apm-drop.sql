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
drop view apm_enabled_package_versions;
drop view apm_package_version_info;
drop table apm_package_owners;
drop table apm_package_versions;
drop table apm_services;
drop table apm_applications;
drop table apm_packages;
drop table apm_package_types;

CREATE OR REPLACE FUNCTION inline_0 () RETURNS integer AS $$
BEGIN
    PERFORM acs_object_type__drop_type (
      'apm_package', 'f'
    );

    PERFORM acs_object_type__drop_type (
      'apm_application', 'f'
    );

    PERFORM acs_object_type__drop_type (
      'apm_service', 'f'
    );

    PERFORM acs_object_type__drop_type (
      'apm_package_version', 'f'
    );

    PERFORM acs_object_type__drop_type (
      'apm_parameter_value', 'f'
    );

    PERFORM acs_object_type__drop_type (
      'apm_parameter', 'f'
    );

    return null;
END;
$$ LANGUAGE plpgsql;

select inline_0 ();

drop function inline_0 ();
drop function apm__register_package (varchar,varchar,varchar,varchar,varchar,boolean,boolean,varchar,integer);
drop function apm__update_package (varchar,varchar,varchar,varchar,varchar,boolean,boolean,varchar,integer);
drop function apm__unregister_package (varchar,boolean);
drop function apm__register_p (varchar);
drop function apm__register_application (varchar,varchar,varchar,varchar,boolean,boolean,varchar,integer);
drop function apm__unregister_application (varchar,boolean);
drop function apm__register_service (varchar,varchar,varchar,varchar,boolean,boolean,varchar,integer);
drop function apm__unregister_service (varchar,boolean);
drop function apm__register_parameter (integer,varchar,varchar,varchar,varchar,varchar,varchar,integer,integer);
drop function apm__update_parameter (integer,varchar,varchar,varchar,varchar,varchar,integer,integer);
drop function apm__parameter_p (varchar,varchar);
drop function apm__unregister_parameter (integer);
drop function apm__id_for_name (integer,varchar);
drop function apm__id_for_name (varchar,varchar);
drop function apm__get_value (varchar,varchar);
drop function apm__get_value (integer,varchar);
drop function apm__set_value (integer,varchar,varchar);
drop function apm__set_value (varchar,varchar,varchar);
drop function apm_package__initialize_parameters (integer,varchar);
drop function apm_package__new (integer,varchar,varchar,varchar,timestamptz,integer,varchar,integer);
drop function apm_package__delete (integer);
drop function apm_package__initial_install_p (varchar);
drop function apm_package__singleton_p (varchar);
drop function apm_package__num_instances (varchar);
drop function apm_package__name (integer);
drop function apm_package__enable (integer);
drop function apm_package__disable (integer);
drop function apm_package__highest_version (varchar);
drop function apm_package_version__new (integer,varchar,varchar,varchar,varchar,varchar,varchar,timestamptz,varchar,varchar,boolean,boolean);
drop function apm_package_version__delete (integer);
drop function apm_package_version__enable (integer);
drop function apm_package_version__disable (integer);
drop function apm_package_version__copy (integer,integer,varchar,varchar);
drop function apm_package_version__edit (integer,integer,varchar,varchar,varchar,varchar,varchar,timestamptz,varchar,varchar,boolean,boolean);
drop function apm_package_version__add_file (integer,integer,varchar,varchar, varchar);
drop function apm_package_version__remove_file (integer,varchar);
drop function apm_package_version__add_interface (integer,integer,varchar,varchar);
drop function apm_package_version__remove_interface (integer);
drop function apm_package_version__remove_interface (varchar,varchar,integer);
drop function apm_package_version__add_dependency (integer,integer,varchar,varchar);
drop function apm_package_version__remove_dependency (integer);
drop function apm_package_version__remove_dependency (varchar,varchar,integer);
drop function apm_package_version__sortable_version_name (varchar);
drop function apm_package_version__version_name_greater (varchar,varchar);
drop function apm_package_version__upgrade_p (varchar,varchar,varchar);
drop function apm_package_version__upgrade (integer);
drop function apm_package_type__create_type (varchar,varchar,varchar,varchar,varchar,boolean,boolean,varchar,integer);
drop function apm_package_type__update_type (varchar,varchar,varchar,varchar,varchar,boolean,boolean,varchar,integer);
drop function apm_package_type__drop_type (varchar,boolean);
drop function apm_package_type__num_parameters (varchar);
drop function apm_parameter_value__new (integer,integer,integer,varchar);
drop function apm_parameter_value__delete (integer);
drop function apm_application__new (integer,varchar,varchar,varchar,timestamptz,integer,varchar,integer);
drop function apm_application__delete (integer);
drop function apm_service__new (integer,varchar,varchar,varchar,timestamptz,integer,varchar,integer);
drop function apm_service__delete (integer);

\t

