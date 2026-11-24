-- Add names only to signatures verified against the current install SQL.
-- Prefix names to avoid collisions with the aliases in legacy bodies.
do $$
declare
    target record;
    definition text;
begin
    for target in
        with expected(function_name, input_types, input_names) as (
            values
            ('apm_application__delete', 'integer', 'application_id'),
            ('apm_application__new', 'integer,varchar,varchar,varchar,timestamptz,integer,varchar,integer', 'application_id,instance_name,package_key,object_type,creation_date,creation_user,creation_ip,context_id'),
            ('apm_package_type__create_type', 'varchar,varchar,varchar,varchar,varchar,boolean,boolean,boolean,boolean,varchar,integer', 'package_key,pretty_name,pretty_plural,package_uri,package_type,initial_install_p,singleton_p,implements_subsite_p,inherit_templates_p,spec_file_path,spec_file_mtime'),
            ('apm_package_type__drop_type', 'varchar,boolean', 'package_key,cascade_p'),
            ('apm_package_type__num_parameters', 'varchar', 'package_key'),
            ('apm_package_type__update_type', 'varchar,varchar,varchar,varchar,varchar,boolean,boolean,boolean,boolean,varchar,integer', 'package_key,pretty_name,pretty_plural,package_uri,package_type,initial_install_p,singleton_p,implements_subsite_p,inherit_templates_p,spec_file_path,spec_file_mtime'),
            ('apm_package_version__add_dependency', 'varchar,integer,integer,varchar,varchar', 'dependency_type,dependency_id,version_id,dependency_uri,dependency_version'),
            ('apm_package_version__add_interface', 'integer,integer,varchar,varchar', 'interface_id,version_id,interface_uri,interface_version'),
            ('apm_package_version__copy', 'integer,integer,varchar,varchar,boolean', 'version_id,new_version_id,new_version_name,new_version_uri,copy_owners_p'),
            ('apm_package_version__delete', 'integer', 'version_id'),
            ('apm_package_version__disable', 'integer', 'version_id'),
            ('apm_package_version__edit', 'integer,integer,varchar,varchar,varchar,varchar,varchar,timestamptz,varchar,varchar,varchar,boolean,boolean', 'new_version_id,version_id,version_name,version_uri,summary,description_format,description,release_date,vendor,vendor_uri,auto_mount,installed_p,data_model_loaded_p'),
            ('apm_package_version__enable', 'integer', 'version_id'),
            ('apm_package_version__new', 'integer,varchar,varchar,varchar,varchar,varchar,varchar,timestamptz,varchar,varchar,varchar,boolean,boolean', 'version_id,package_key,version_name,version_uri,summary,description_format,description,release_date,vendor,vendor_uri,auto_mount,installed_p,data_model_loaded_p'),
            ('apm_package_version__remove_dependency', 'varchar,varchar,integer', 'dependency_uri,dependency_version,version_id'),
            ('apm_package_version__remove_interface', 'varchar,varchar,integer', 'interface_uri,interface_version,version_id'),
            ('apm_package_version__sortable_version_name', 'varchar', 'version_name'),
            ('apm_package_version__upgrade', 'integer', 'version_id'),
            ('apm_package_version__upgrade_p', 'varchar,varchar,varchar', 'path,initial_version_name,final_version_name'),
            ('apm_package_version__version_name_greater', 'varchar,varchar', 'version_name_one,version_name_two'),
            ('apm_package__delete', 'integer', 'package_id'),
            ('apm_package__highest_version', 'varchar', 'package_key'),
            ('apm_package__initialize_parameters', 'integer,varchar', 'package_id,package_key'),
            ('apm_package__initial_install_p', 'varchar', 'package_key'),
            ('apm_package__is_child', 'varchar,varchar', 'parent_package_key,child_package_key'),
            ('apm_package__name', 'integer', 'package_id'),
            ('apm_package__new', 'integer,varchar,varchar,varchar,timestamptz,integer,varchar,integer', 'package_id,instance_name,package_key,object_type,creation_date,creation_user,creation_ip,context_id'),
            ('apm_package__num_instances', 'varchar', 'package_key'),
            ('apm_package__parent_id', 'integer', 'parent_id__package_id'),
            ('apm_package__singleton_p', 'varchar', 'package_key'),
            ('apm_parameter_value__delete', 'integer', 'value_id'),
            ('apm_parameter_value__new', 'integer,integer,integer,varchar', 'value_id,package_id,parameter_id,attr_value'),
            ('apm_service__delete', 'integer', 'service_id'),
            ('apm_service__new', 'integer,varchar,varchar,varchar,timestamptz,integer,varchar,integer', 'service_id,instance_name,package_key,object_type,creation_date,creation_user,creation_ip,context_id'),
            ('apm__parameter_p', 'varchar,varchar', 'package_key,parameter_name'),
            ('apm__register_application', 'varchar,varchar,varchar,varchar,boolean,boolean,boolean,boolean,varchar,integer', 'package_key,pretty_name,pretty_plural,package_uri,initial_install_p,singleton_p,implements_subsite_p,inherit_templates_p,spec_file_path,spec_file_mtime'),
            ('apm__register_p', 'varchar', 'package_key'),
            ('apm__register_package', 'varchar,varchar,varchar,varchar,varchar,boolean,boolean,boolean,boolean,varchar,integer', 'package_key,pretty_name,pretty_plural,package_uri,package_type,initial_install_p,singleton_p,implements_subsite_p,inherit_templates_p,spec_file_path,spec_file_mtime'),
            ('apm__register_service', 'varchar,varchar,varchar,varchar,boolean,boolean,boolean,boolean,varchar,integer', 'package_key,pretty_name,pretty_plural,package_uri,initial_install_p,singleton_p,implements_subsite_p,inherit_templates_p,spec_file_path,spec_file_mtime'),
            ('apm__unregister_application', 'varchar,boolean', 'package_key,cascade_p'),
            ('apm__unregister_package', 'varchar,boolean', 'package_key,cascade_p'),
            ('apm__unregister_parameter', 'integer', 'parameter_id'),
            ('apm__unregister_service', 'varchar,boolean', 'package_key,cascade_p'),
            ('apm__update_package', 'varchar,varchar,varchar,varchar,varchar,boolean,boolean,boolean,boolean,varchar,integer', 'package_key,pretty_name,pretty_plural,package_uri,package_type,initial_install_p,singleton_p,implements_subsite_p,inherit_templates_p,spec_file_path,spec_file_mtime'),
            ('apm__update_parameter', 'integer,varchar,varchar,varchar,varchar,varchar,integer,integer', 'parameter_id,parameter_name,description,datatype,default_value,section_name,min_n_values,max_n_values')
        )
        select p.oid, n.nspname, p.proname, arguments.signature
          from expected e
          join pg_proc p on p.oid = to_regprocedure(
              format('%I.%I(%s)', current_schema(), e.function_name, e.input_types))
          join pg_namespace n on n.oid = p.pronamespace
          cross join lateral (
              select string_agg(
                         format('%I %s', 'arg_' || a.arg_name, format_type(a.type_oid, null)),
                         ', ' order by a.position) as signature
                from unnest(p.proargtypes::oid[], string_to_array(e.input_names, ','))
                     with ordinality as a(type_oid, arg_name, position)
          ) arguments
         where p.prokind = 'f'
           and p.proargnames is null
           and p.proargmodes is null
           and p.pronargdefaults = 0
           and p.pronargs = cardinality(string_to_array(e.input_names, ','))
           and p.pronargs = (
               select count(*) from acs_function_args a
                where a.function = upper(e.function_name)
           )
           and e.input_names = (
               select string_agg(lower(a.arg_name), ',' order by a.arg_seq)
                 from acs_function_args a
                where a.function = upper(e.function_name)
           )
           and not exists (
               select 1 from pg_proc other
                where other.proname = p.proname
                  and other.pronargs = p.pronargs
                  and other.oid <> p.oid
           )
    loop
        definition := pg_get_functiondef(target.oid);
        execute format('CREATE OR REPLACE FUNCTION %I.%I(%s)',
                       target.nspname, target.proname, target.signature)
                || substr(definition, strpos(definition, chr(10)));
    end loop;
end;
$$;
