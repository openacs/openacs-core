---
--- Remove leftovers from earlier changes in the SQL API. The update
--- scripts did not care about function args, so orphaned entries
--- could cause confusions.
---
delete from acs_function_args where function = 'ACS_OBJECT__CHECK_CONTEXT_INDEX';

--
-- align function args with calling functions
--
select define_function_args('apm__get_value','package_id,parameter_name');
select define_function_args('apm__set_value','package_id,parameter_name,attr_value');
