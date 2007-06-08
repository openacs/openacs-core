-- / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / / /
-- This upgrade provides for the registering
-- of ACS SC db procedures with the PostgreSQL
-- 'package' infrastructure (acs_function_args).
-- $Id$

-- // acs-sc-packages-create.sql //

-- acs_sc_contract__new(varchar,text)
select define_function_args('acs_sc_contract__new','contract_name,contract_desc');
-- acs_sc_contract__get_id(varchar)
select define_function_args('acs_sc_contract__get_id','contract_name');

-- acs_sc_contract__get_name(integer)
select define_function_args('acs_sc_contract__get_name','contract_id');

-- acs_sc_contract__delete(varchar)
select define_function_args('acs_sc_contract__delete','contract_name');

-- acs_sc_operation__new(varchar,varchar,text,boolean,integer,varchar,varchar)
select define_function_args('acs_sc_operation__new','contract_name,operation_name,operation_desc,operation_iscachable_p;f,operation_nargs,operation_inputtype,operation_outputtype');

-- acs_sc_operation__get_id(varchar,varchar)
select define_function_args('acs_sc_operation__get_id','contract_name,operation_name');

-- acs_sc_operation__delete(integer)
select define_function_args('acs_sc_operation__delete','operation_id');

-- acs_sc_impl__new(varchar,varchar,varchar,varchar)
select define_function_args('acs_sc_impl__new','impl_contract_name,impl_name,impl_pretty_name,impl_owner_name');

-- acs_sc_impl__get_id(varchar,varchar)
select define_function_args('acs_sc_impl__get_id','impl_contract_name,impl_name');

-- acs_sc_impl__get_name(integer)
select define_function_args('acs_sc_impl__get_name','impl_id');

-- acs_sc_impl__delete(varchar,varchar)
select define_function_args('acs_sc_impl__delete','impl_contract_name,impl_name');

-- acs_sc_impl_alias__new(varchar,varchar,varchar,varchar,varchar)
select define_function_args('acs_sc_impl_alias__new','impl_contract_name,impl_name,impl_operation_name,impl_alias,impl_pl');

--  acs_sc_impl_alias__delete(varchar,varchar,varchar)
select define_function_args('acs_sc_impl_alias__delete','impl_contract_name,impl_name,impl_operation_name');

-- acs_sc_binding__new(varchar,varchar)
select define_function_args('acs_sc_binding__new','contract_name,impl_name');

-- acs_sc_binding__delete(varchar,varchar)
select define_function_args('acs_sc_binding__delete','contract_name,impl_name');

-- acs_sc_binding__exists_p(varchar,varchar)
select define_function_args('acs_sc_binding__exists_p','contract_name,impl_name');

-- // acs-sc-msg-types-create.sql //

-- acs_sc_msg_type__new(varchar,varchar)
select define_function_args('acs_sc_msg_type__new','msg_type_name,msg_type_spec');

-- acs_sc_msg_type__get_id(varchar)
select define_function_args('acs_sc_msg_type__get_id','msg_type_name');

-- acs_sc_msg_type__get_name(integer)
select define_function_args('acs_sc_msg_type__get_name','msg_type_id');

-- acs_sc_msg_type__delete(varchar)
select define_function_args('acs_sc_msg_type__delete','msg_type_name');

-- acs_sc_msg_type__new_element(varchar,varchar,varchar,boolean,integer)
select define_function_args('acs_sc_msg_type__new_element','msg_type_name,element_name,element_msg_type_name,element_msg_type_isset_p;f,element_pos');

-- acs_sc_msg_type__parse_spec(varchar,varchar)
select define_function_args('acs_sc_msg_type__parse_spec','msg_type_name,msg_type_spec');