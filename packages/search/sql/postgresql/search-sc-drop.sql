select acs_sc_contract__delete('FtsContentProvider');
select acs_sc_msg_type__delete ('FtsContentProvider.Datasource.InputType');
select acs_sc_msg_type__delete ('FtsContentProvider.Datasource.OutputType');
select acs_sc_msg_type__delete ('FtsContentProvider.Url.InputType');
select acs_sc_msg_type__delete ('FtsContentProvider.Url.OutputType');



select acs_sc_contract__delete('FtsEngineDriver');
select acs_sc_msg_type__delete ('FtsEngineDriver.Search.InputType');
select acs_sc_msg_type__delete ('FtsEngineDriver.Search.OutputType');
select acs_sc_msg_type__delete ('FtsEngineDriver.Index.InputType');
select acs_sc_msg_type__delete ('FtsEngineDriver.Index.OutputType');
select acs_sc_msg_type__delete ('FtsEngineDriver.Unindex.InputType');
select acs_sc_msg_type__delete ('FtsEngineDriver.Unindex.OutputType');
select acs_sc_msg_type__delete ('FtsEngineDriver.UpdateIndex.InputType');
select acs_sc_msg_type__delete ('FtsEngineDriver.UpdateIndex.OutputType');
select acs_sc_msg_type__delete ('FtsEngineDriver.Summary.InputType');
select acs_sc_msg_type__delete ('FtsEngineDriver.Summary.OutputType');
select acs_sc_msg_type__delete ('FtsEngineDriver.Info.InputType');
select acs_sc_msg_type__delete ('FtsEngineDriver.Info.OutputType');

