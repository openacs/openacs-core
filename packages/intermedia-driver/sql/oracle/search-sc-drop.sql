declare
begin

    acs_sc_contract.del(contract_name => 'FtsContentProvider');
    acs_sc_msg_type.del(msg_type_name => 'FtsContentProvider.Datasource.InputType');
    acs_sc_msg_type.del(msg_type_name => 'FtsContentProvider.Datasource.OutputType');
    acs_sc_msg_type.del(msg_type_name => 'FtsContentProvider.Url.InputType');
    acs_sc_msg_type.del(msg_type_name => 'FtsContentProvider.Url.OutputType');

    acs_sc_contract.del(contract_name => 'FtsEngineDriver');
    acs_sc_msg_type.del(msg_type_name => 'FtsEngineDriver.Search.InputType');
    acs_sc_msg_type.del(msg_type_name => 'FtsEngineDriver.Search.OutputType');
    acs_sc_msg_type.del(msg_type_name => 'FtsEngineDriver.Index.InputType');
    acs_sc_msg_type.del(msg_type_name => 'FtsEngineDriver.Index.OutputType');
    acs_sc_msg_type.del(msg_type_name => 'FtsEngineDriver.Unindex.InputType');
    acs_sc_msg_type.del(msg_type_name => 'FtsEngineDriver.Unindex.OutputType');
    acs_sc_msg_type.del(msg_type_name => 'FtsEngineDriver.UpdateIndex.InputType');
    acs_sc_msg_type.del(msg_type_name => 'FtsEngineDriver.UpdateIndex.OutputType');
    acs_sc_msg_type.del(msg_type_name => 'FtsEngineDriver.Summary.InputType');
    acs_sc_msg_type.del(msg_type_name => 'FtsEngineDriver.Summary.OutputType');
    acs_sc_msg_type.del(msg_type_name => 'FtsEngineDriver.Info.InputType');
    acs_sc_msg_type.del(msg_type_name => 'FtsEngineDriver.Info.OutputType');

end;
/
show errors
