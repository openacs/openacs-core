--
-- ACS-SC Contract: FtsEngineDriver
--

select acs_sc_contract__new (
           'FtsEngineDriver',			-- contract_name
	   'Full Text Search Engine Driver'	-- contract_desc
);


select acs_sc_msg_type__new (
           'FtsEngineDriver.Search.InputType',
	   'query:string,offset:integer,limit:integer,user_id:integer,df:timestamp,dt:timestamp'
);
select acs_sc_msg_type__new (
           'FtsEngineDriver.Search.OutputType',
	   'ids:integer[],stopwords:string[]'
);
select acs_sc_operation__new (
           'FtsEngineDriver',			-- contract_name
           'search',				-- operation_name
	   'Search',                		-- operation_desc
	   'f',					-- operation_iscachable_p
	   6,					-- operation_nargs
	   'FtsEngineDriver.Search.InputType',	-- operation_inputtype
	   'FtsEngineDriver.Search.OutputType'	-- operation_outputtype
);



select acs_sc_msg_type__new (
           'FtsEngineDriver.Index.InputType',
	   'object_id:integer,txt:string,title:string,keywords:string'
);
select acs_sc_msg_type__new (
           'FtsEngineDriver.Index.OutputType',
	   ''
);
select acs_sc_operation__new (
           'FtsEngineDriver',			-- contract_name
           'index', 				-- operation_name
	   'Index',                 		-- operation_desc
	   'f',					-- operation_iscachable_p
	   4,					-- operation_nargs
	   'FtsEngineDriver.Index.InputType',	-- operation_inputtype
	   'FtsEngineDriver.Index.OutputType'	-- operation_outputtype
);



select acs_sc_msg_type__new (
           'FtsEngineDriver.Unindex.InputType',
	   'object_id:integer'
);
select acs_sc_msg_type__new (
           'FtsEngineDriver.Unindex.OutputType',
	   ''
);
select acs_sc_operation__new (
           'FtsEngineDriver',			-- contract_name
           'unindex',				-- operation_name
	   'Unindex',               		-- operation_desc
	   'f',					-- operation_iscachable_p
	   1,					-- operation_nargs
	   'FtsEngineDriver.Unindex.InputType',	-- operation_inputtype
	   'FtsEngineDriver.Unindex.OutputType'	-- operation_outputtype
);



select acs_sc_msg_type__new (
           'FtsEngineDriver.UpdateIndex.InputType',
	   'object_id:integer,txt:string,title:string,keywords:string'
);
select acs_sc_msg_type__new (
           'FtsEngineDriver.UpdateIndex.OutputType',
	   ''
);
select acs_sc_operation__new (
           'FtsEngineDriver',			-- contract_name
           'update_index',			-- operation_name
	   'Update Index',             		-- operation_desc
	   'f',					-- operation_iscachable_p
	   4,					-- operation_nargs
	   'FtsEngineDriver.UpdateIndex.InputType',	-- operation_inputtype
	   'FtsEngineDriver.UpdateIndex.OutputType'	-- operation_outputtype
);



select acs_sc_msg_type__new (
           'FtsEngineDriver.Summary.InputType',
	   'query:string,txt:string'
);
select acs_sc_msg_type__new (
           'FtsEngineDriver.Summary.OutputType',
	   'summary:string'
);
select acs_sc_operation__new (
           'FtsEngineDriver',			-- contract_name
           'summary',				-- operation_name
	   'Summary',               		-- operation_desc
	   'f',					-- operation_iscachable_p
	   2,					-- operation_nargs
	   'FtsEngineDriver.Summary.InputType',	-- operation_inputtype
	   'FtsEngineDriver.Summary.OutputType'	-- operation_outputtype
);


select acs_sc_msg_type__new (
           'FtsEngineDriver.Info.InputType',
	   ''
);
select acs_sc_msg_type__new (
           'FtsEngineDriver.Info.OutputType',
	   'package_key:string,version:version,automatic_and_queries_p:boolean,stopwords_p:boolean'
);
select acs_sc_operation__new (
           'FtsEngineDriver',				-- contract_name
           'info',					-- operation_name
	   'Information about the driver',		-- operation_desc
	   'f',						-- operation_iscachable_p
	   1,						-- operation_nargs
	   'FtsEngineDriver.Info.InputType',		-- operation_inputtype
	   'FtsEngineDriver.Info.OutputType'		-- operation_outputtype
);


--
-- ACS-SC Contract: FtsContentProvider
--

select acs_sc_contract__new (
           'FtsContentProvider',			-- contract_name
	   'Full Text Search Content Provider'		-- contract_desc
);

select acs_sc_msg_type__new (
           'FtsContentProvider.Datasource.InputType',
	   'object_id:integer'
);
select acs_sc_msg_type__new (
           'FtsContentProvider.Datasource.OutputType',
	   'object_id:integer,title:string,content:string,mime:string,storage_type:string'
);
select acs_sc_operation__new (
           'FtsContentProvider',			-- contract_name
           'datasource',				-- operation_name
	   'Data Source',				-- operation_desc
	   'f',						-- operation_iscachable_p
	   1,						-- operation_nargs
	   'FtsContentProvider.Datasource.InputType',	-- operation_inputtype
	   'FtsContentProvider.Datasource.OutputType'	-- operation_outputtype
);



select acs_sc_msg_type__new (
           'FtsContentProvider.Url.InputType',
	   'object_id:integer'
);
select acs_sc_msg_type__new (
           'FtsContentProvider.Url.OutputType',
	   'url:uri'
);
select acs_sc_operation__new (
           'FtsContentProvider',			-- contract_name
           'url',					-- operation_name
	   'URL',					-- operation_desc
	   'f',						-- operation_iscachable_p
	   1,						-- operation_nargs
	   'FtsContentProvider.Url.InputType',		-- operation_inputtype
	   'FtsContentProvider.Url.OutputType'		-- operation_outputtype
);
