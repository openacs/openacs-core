select acs_object_type__create_type (
    'acs_sc_contract',		        -- object_type
    'ACS SC Contract',			-- pretty_name
    'ACS SC Contracts',			-- pretty_plural
    'acs_object',		        -- supertype 
    'acs_sc_contracts',		        -- table_name
    'contract_id',		        -- id_column
    null,			        -- package_name
    'f',			        -- abstract_p
    null,			        -- type_extension_table
    null			        -- name_method
);



select acs_object_type__create_type (
    'acs_sc_operation',			-- object_type
    'ACS SC Operation',			-- pretty_name
    'ACS SC Operations',		-- pretty_plural
    'acs_object',			-- supertype 
    'acs_sc_operations',		-- table_name
    'operation_id',			-- id_column
    null,				-- package_name
    'f',				-- abstract_p
    null,				-- type_extension_table
    null				-- name_method
);


select acs_object_type__create_type (
    'acs_sc_implementation',		-- object_type
    'ACS SC Implementation',		-- pretty_name
    'ACS SC Implementations',		-- pretty_plural
    'acs_object',			-- supertype 
    'acs_sc_impls',			-- table_name
    'impl_id',				-- id_column
    null,				-- package_name
    'f',				-- abstract_p
    null,				-- type_extension_table
    null				-- name_method
);





