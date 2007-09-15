-- acs-kernel: acs-metadata-create.sql

select define_function_args('acs_object_type__create_type','object_type,pretty_name,pretty_plural,supertype,table_name;null,id_column;null,package_name;null,abstract_p;f,type_extension_table;null,name_method;null');
select define_function_args('acs_object_type__drop_type','object_type,cascade_p;f');
select define_function_args('acs_attribute__create_attribute','object_type,attribute_name,datatype,pretty_name,pretty_plural;null,table_name;null,column_name;null,default_value;null,min_n_values;1,max_n_values;1,sort_order;null,storage;type_specific,static_p;f');
select define_function_args('acs_attribute__add_description','object_type,attribute_name,description_key,description');
select define_function_args('acs_attribute__drop_description','object_type,attribute_name,description_key');

-- acs-kernel: acs-objects-create.sql

select define_function_args('acs_object__new','object_id;null,object_type;acs_object,creation_date;now(),creation_user;null,creation_ip;null,context_id;null,security_inherit_p;t,title;null,package_id;null');
select define_function_args('acs_object__delete','object_id');

