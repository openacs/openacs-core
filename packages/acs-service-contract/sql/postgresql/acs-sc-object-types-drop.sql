delete from acs_objects where object_type = 'acs_sc_implementation';
select acs_object_type__drop_type ('acs_sc_implementation', 'f');

delete from acs_objects where object_type = 'acs_sc_operation';
select acs_object_type__drop_type ('acs_sc_operation', 'f');

delete from acs_objects where object_type = 'acs_sc_contract';
select acs_object_type__drop_type ('acs_sc_contract', 'f');

