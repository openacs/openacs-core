declare
    foo                             integer;
begin

    --
    -- ACS-SC Contract: FtsEngineDriver
    --

    foo := acs_sc_contract.new(
        contract_name => 'FtsEngineDriver',
        contract_desc => 'Full Text Search Engine Driver'
    );

    foo := acs_sc_msg_type.new(
        msg_type_name => 'FtsEngineDriver.Search.InputType',
        msg_type_spec => 'query:string,offset:integer,limit:integer,user_id:integer,df:timestamp,dt:timestamp'
    );

    foo := acs_sc_msg_type.new(
        msg_type_name => 'FtsEngineDriver.Search.OutputType',
        msg_type_spec => 'ids:integer[],stopwords:string[]'
    );

    foo := acs_sc_operation.new(
        contract_name => 'FtsEngineDriver',
        operation_name => 'search',
        operation_desc => 'Search',
        operation_iscachable_p => 'f',
        operation_nargs => 6,
        operation_inputtype => 'FtsEngineDriver.Search.InputType',
        operation_outputtype => 'FtsEngineDriver.Search.OutputType'
    );

    foo := acs_sc_msg_type.new(
        msg_type_name => 'FtsEngineDriver.Index.InputType',
        msg_type_spec => 'object_id:integer,txt:string,title:string,keywords:string'
    );

    foo := acs_sc_msg_type.new(
        msg_type_name => 'FtsEngineDriver.Index.OutputType',
        msg_type_spec => ''
    );

    foo := acs_sc_operation.new(
        contract_name => 'FtsEngineDriver',
        operation_name => 'index',
        operation_desc => 'Index',
        operation_iscachable_p => 'f',
        operation_nargs => 4,
        operation_inputtype => 'FtsEngineDriver.Index.InputType',
        operation_outputtype => 'FtsEngineDriver.Index.OutputType'
    );

    foo := acs_sc_msg_type.new(
        msg_type_name => 'FtsEngineDriver.Unindex.InputType',
        msg_type_spec => 'object_id:integer'
    );

    foo := acs_sc_msg_type.new(
        msg_type_name => 'FtsEngineDriver.Unindex.OutputType',
        msg_type_spec => ''
    );

    foo := acs_sc_operation.new(
        contract_name => 'FtsEngineDriver',
        operation_name => 'unindex',
        operation_desc => 'Unindex',
        operation_iscachable_p => 'f',
        operation_nargs => 1,
        operation_inputtype => 'FtsEngineDriver.Unindex.InputType',
        operation_outputtype => 'FtsEngineDriver.Unindex.OutputType'
    );

    foo := acs_sc_msg_type.new(
        msg_type_name => 'FtsEngineDriver.UpdateIndex.InputType',
        msg_type_spec => 'object_id:integer,txt:string,title:string,keywords:string'
    );

    foo := acs_sc_msg_type.new(
        msg_type_name => 'FtsEngineDriver.UpdateIndex.OutputType',
        msg_type_spec => ''
    );

    foo := acs_sc_operation.new(
        contract_name => 'FtsEngineDriver',
        operation_name => 'update_index',
        operation_desc => 'Update Index',
        operation_iscachable_p => 'f',
        operation_nargs => 4,
        operation_inputtype => 'FtsEngineDriver.UpdateIndex.InputType',
        operation_outputtype => 'FtsEngineDriver.UpdateIndex.OutputType'
    );

    foo := acs_sc_msg_type.new(
        msg_type_name => 'FtsEngineDriver.Summary.InputType',
        msg_type_spec => 'query:string,txt:string'
    );

    foo := acs_sc_msg_type.new(
        msg_type_name => 'FtsEngineDriver.Summary.OutputType',
        msg_type_spec => 'summary:string'
    );

    foo := acs_sc_operation.new(
        contract_name => 'FtsEngineDriver',
        operation_name => 'summary',
        operation_desc => 'Summary',
        operation_iscachable_p => 'f',
        operation_nargs => 2,
        operation_inputtype => 'FtsEngineDriver.Summary.InputType',
        operation_outputtype => 'FtsEngineDriver.Summary.OutputType'
    );

    foo := acs_sc_msg_type.new(
        msg_type_name => 'FtsEngineDriver.Info.InputType',
        msg_type_spec => ''
    );

    foo := acs_sc_msg_type.new(
        msg_type_name => 'FtsEngineDriver.Info.OutputType',
        msg_type_spec => 'package_key:string,version:version,automatic_and_queries_p:boolean,stopwords_p:boolean'
    );

    foo := acs_sc_operation.new(
        contract_name => 'FtsEngineDriver',
        operation_name => 'info',
        operation_desc => 'Information about the driver',
        operation_iscachable_p => 'f',
        operation_nargs => 1,
        operation_inputtype => 'FtsEngineDriver.Info.InputType',
        operation_outputtype => 'FtsEngineDriver.Info.OutputType'
    );

    --
    -- ACS-SC Contract: FtsContentProvider
    --

    foo := acs_sc_contract.new(
        contract_name => 'FtsContentProvider',
        contract_desc => 'Full Text Search Content Provider'
    );

    foo := acs_sc_msg_type.new(
        msg_type_name => 'FtsContentProvider.Datasource.InputType',
        msg_type_spec => 'object_id:integer'
    );

    foo := acs_sc_msg_type.new(
        msg_type_name => 'FtsContentProvider.Datasource.OutputType',
        msg_type_spec => 'object_id:integer,title:string,content:string,mime:string,storage_type:string'
    );

    foo := acs_sc_operation.new(
        contract_name => 'FtsContentProvider',
        operation_name => 'datasource',
        operation_desc => 'Data Source',
        operation_iscachable_p => 'f',
        operation_nargs => 1,
        operation_inputtype => 'FtsContentProvider.Datasource.InputType',
        operation_outputtype => 'FtsContentProvider.Datasource.OutputType'
    );

    foo := acs_sc_msg_type.new(
        msg_type_name => 'FtsContentProvider.Url.InputType',
        msg_type_spec => 'object_id:integer'
    );

    foo := acs_sc_msg_type.new(
        msg_type_name => 'FtsContentProvider.Url.OutputType',
        msg_type_spec => 'url:uri'
    );

    foo := acs_sc_operation.new(
        contract_name => 'FtsContentProvider',
        operation_name => 'url',
        operation_desc => 'URL',
        operation_iscachable_p => 'f',
        operation_nargs => 1,
        operation_inputtype => 'FtsContentProvider.Url.InputType',
        operation_outputtype => 'FtsContentProvider.Url.OutputType'
    );

end;
/
show errors
