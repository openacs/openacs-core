create table acs_sc_contracts (
    contract_id		     integer
			     constraint acs_sc_contracts_id_fk
			     references acs_objects(object_id) 
			     on delete cascade
			     constraint acs_sc_contracts_pk
			     primary key,
    contract_name	     varchar(1000)
			     constraint acs_sc_contracts_name_nn
			     not null
			     constraint acs_sc_contracts_name_un
			     unique,
    contract_desc	     text
			     constraint acs_sc_contracts_desc_nn
			     not null
);





create table acs_sc_operations (
    contract_id		      integer
			      constraint acs_sc_operations_cid_fk
			      references acs_sc_contracts(contract_id)
			      on delete cascade,
    operation_id	      integer
			      constraint acs_sc_operations_opid_fk
			      references acs_objects(object_id)
			      on delete cascade
			      constraint acs_sc_operations_pk
			      primary key,
    contract_name	      varchar(1000),
    operation_name	      varchar(100),
    operation_desc	      text
			      constraint acs_sc_operations_desc_nn
			      not null,
    operation_iscachable_p    boolean,
    operation_nargs	      integer,
    operation_inputtype_id    integer
			      constraint acs_sc_operations_intype_fk
			      references acs_sc_msg_types(msg_type_id),
    operation_outputtype_id   integer
			      constraint acs_sc_operations_outtype_fk
			      references acs_sc_msg_types(msg_type_id)
);



create table acs_sc_impls (
    impl_id		      integer
			      constraint acs_sc_impls_impl_id_fk
			      references acs_objects(object_id)
			      on delete cascade
			      constraint acs_sc_impls_impl_id_pk
			      primary key,
    impl_name		      varchar(100),
    impl_pretty_name          varchar(200),
    impl_owner_name	      varchar(1000),
    impl_contract_name	      varchar(1000)
);



create table acs_sc_impl_aliases (
    impl_id		      integer
			      constraint acs_sc_impl_aliases_impl_id_fk
			      references acs_sc_impls(impl_id)
			      on delete cascade,
    impl_name		      varchar(100),
    impl_contract_name	      varchar(1000),
    impl_operation_name	      varchar(100),
    impl_alias		      varchar(100),
    impl_pl		      varchar(100),
constraint acs_sc_impl_alias_un unique(impl_name,impl_contract_name,impl_operation_name)
);



create table acs_sc_bindings (
    contract_id		      integer
			      constraint acs_sc_bindings_contract_id_fk
			      references acs_sc_contracts(contract_id)
			      on delete cascade,
    impl_id		      integer
			      constraint acs_sc_bindings_impl_id_fk
			      references acs_sc_impls(impl_id)
			      on delete cascade
);











