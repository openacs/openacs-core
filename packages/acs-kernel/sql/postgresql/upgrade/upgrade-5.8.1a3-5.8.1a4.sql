
select define_function_args('acs_object__initialize_attributes','object_id');
select define_function_args('acs_object__name','object_id');
select define_function_args('acs_object__default_name','object_id');
select define_function_args('acs_object__check_context_index','object_id,ancestor_id,n_generations');
select define_function_args('acs_object__check_path','object_id,ancestor_id');
select define_function_args('acs_object__check_representation','object_id');
select define_function_args('acs_object__update_last_modified','object_id,modifying_user,modifying_ip,last_modified;now()');
