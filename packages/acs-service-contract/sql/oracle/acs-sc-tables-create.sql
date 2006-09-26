-- $Id$

create table acs_sc_contracts (
    contract_id		     integer
			     constraint acs_sc_contract_id_fk
			     references acs_objects(object_id) 
			     on delete cascade
			     constraint acs_sc_contract_pk
			     primary key,
    contract_name	     varchar2(1000)
			     constraint acs_sc_contract_name_nn
			     not null
			     constraint acs_sc_contract_name_un
			     unique,
    contract_desc	     varchar2(4000)
			     constraint acs_sc_contract_desc_nn
			     not null
);


create table acs_sc_operations (
    contract_id		      integer
			      constraint acs_sc_operation_cid_fk
			      references acs_sc_contracts(contract_id)
			      on delete cascade,
    operation_id	      integer
			      constraint acs_sc_operation_opid_fk
			      references acs_objects(object_id)
			      on delete cascade
			      constraint acs_sc_operation_pk
			      primary key,
    contract_name	      varchar2(1000),
    operation_name	      varchar2(100),
    operation_desc	      varchar2(4000)
			      constraint acs_sc_operation_desc_nn
			      not null,
    operation_iscachable_p    char(1) constraint acs_sc_operation_cache_p_ck
			      check (operation_iscachable_p in ('t', 'f')),
    operation_nargs	      integer,
    operation_inputtype_id    integer
			      constraint acs_sc_operation_intype_fk
			      references acs_sc_msg_types(msg_type_id),
    operation_outputtype_id   integer
			      constraint acs_sc_operation_outtype_fk
			      references acs_sc_msg_types(msg_type_id)
);



create table acs_sc_impls (
    impl_id		      integer
			      constraint acs_sc_impls_impl_id_fk
			      references acs_objects(object_id)
			      on delete cascade
			      constraint acs_sc_impl_pk
			      primary key,
    impl_name		      varchar2(100),
    impl_pretty_name          varchar2(200),
    impl_owner_name	      varchar2(1000),
    impl_contract_name	      varchar2(1000)
);

create table acs_sc_impl_aliases (
    impl_id		      integer
			      constraint acs_sc_impl_aliases_impl_id_fk
			      references acs_sc_impls(impl_id)
			      on delete cascade,
    impl_name		      varchar2(100),
    impl_contract_name	      varchar2(1000),
    impl_operation_name	      varchar2(100),
    impl_alias		      varchar2(100),
    impl_pl		      varchar2(100),
constraint acs_sc_impl_aliases_un unique(impl_name,impl_contract_name,impl_operation_name)
);

create table acs_sc_bindings (
    contract_id		      integer
			      constraint acs_sc_binding_contract_id_fk
			      references acs_sc_contracts(contract_id)
			      on delete cascade,
    impl_id		      integer
			      constraint acs_sc_binding_impl_id_fk
			      references acs_sc_impls(impl_id)
			      on delete cascade
);
