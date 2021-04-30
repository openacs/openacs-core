
-- Replace the proc name in the service contracts
update acs_sc_impl_aliases set
 impl_alias = 'tsearch2::index'
where impl_name = 'tsearch2-driver'
  and impl_contract_name = 'FtsEngineDriver'
  and impl_operation_name = 'update_index';
