-- $Id$
begin
    acs_object_type.create_type(
	object_type => 'acs_sc_contract',
	pretty_name => 'ACS SC Contract',
	pretty_plural => 'ACS SC Contracts',
	supertype => 'acs_object',
	table_name => 'acs_sc_contracts',
	id_column => 'contract_id'
    );

    acs_object_type.create_type(
	object_type => 'acs_sc_operation',
	pretty_name => 'ACS SC Operation',
	pretty_plural => 'ACS SC Operations',
	supertype => 'acs_object',
	table_name => 'acs_sc_operations',
	id_column => 'operation_id'
    );

    acs_object_type.create_type(
	object_type => 'acs_sc_implementation',
	pretty_name => 'ACS SC Implementation',
	pretty_plural => 'ACS SC Implementations',
	supertype => 'acs_object',
	table_name => 'acs_sc_impls',
	id_column => 'impl_id'
    );
end;
/
show errors
