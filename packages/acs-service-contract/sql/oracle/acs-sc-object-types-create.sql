-- $Id$
begin
    acs_object_type.create_type(
	object_type => 'acs_sc_contract',
	pretty_name => 'ACS SC Contract',
	pretty_plural => 'ACS SC Contracts',
	supertype => 'acs_object',
	table_name => 'ACS_SC_CONTRACTS',
	id_column => 'CONTRACT_ID'
    );

    acs_object_type.create_type(
	object_type => 'acs_sc_operation',
	pretty_name => 'ACS SC Operation',
	pretty_plural => 'ACS SC Operations',
	supertype => 'acs_object',
	table_name => 'ACS_SC_OPERATIONS',
	id_column => 'OPERATION_ID'
    );

    acs_object_type.create_type(
	object_type => 'acs_sc_implementation',
	pretty_name => 'ACS SC Implementation',
	pretty_plural => 'ACS SC Implementations',
	supertype => 'acs_object',
	table_name => 'ACS_SC_IMPLS',
	id_column => 'IMPL_ID'
    );
end;
/
show errors
