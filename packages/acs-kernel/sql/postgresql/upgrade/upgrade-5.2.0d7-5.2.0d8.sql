select define_function_args('acs_object__initialize_attributes','initialize_attributes__object_id');

select define_function_args('acs_object__new','new__object_id,new__object_type;acs_object,new__creation_date,new__creation_user,new__creation_ip,new__context_id,new__security_inherit_p;t,new__title,new__package_id');

select define_function_args('acs_object__delete','delete__object_id');

select define_function_args('acs_object__name','name__object_id');

select define_function_args('acs_object__default_name','default_name__object_id');

select define_function_args('acs_object__object_id','p_object_id');

select define_function_args('acs_object__get_attribute_storage','object_id_in,attribute_name_in');

select define_function_args('acs_object__get_attr_storage_column','v_vals');

select define_function_args('acs_object__get_attr_storage_table','v_vals');

select define_function_args('acs_object__get_attr_storage_sql','v_vals');

select define_function_args('acs_object__get_attribute','object_id_in,attribute_name_in');

select define_function_args('acs_object__set_attribute','object_id_in,attribute_name_in,value_in');

select define_function_args('acs_object__check_context_index','check_context_index__object_id,check_context_index__ancestor_id,check_context_index__n_generations');

select define_function_args('acs_object__check_path','check_path__object_id,check_path__ancestor_id');

select define_function_args('acs_object__check_representation','check_representation__object_id');
