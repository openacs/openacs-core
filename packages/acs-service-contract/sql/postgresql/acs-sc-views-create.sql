create view valid_uninstalled_binding as
    select c.contract_id, c.contract_name, i.impl_id, i.impl_name
    from acs_sc_contract c, acs_sc_impl i
    where c.contract_name = i.impl_contract_name
    and not exists (select 1
		    from acs_sc_binding b
		    where b.contract_id = c.contract_id
		    and b.impl_id = i.impl_id)
    and not exists (select 1
		    from acs_sc_operation o
		    where o.contract_id = c.contract_id
		    and not exists (select 1
				    from acs_sc_impl_alias a
				    where a.impl_contract_name = c.contract_name
				    and a.impl_id = i.impl_id
				    and a.impl_operation_name = o.operation_name));



create view invalid_uninstalled_binding as
    select c.contract_id, c.contract_name, i.impl_id, i.impl_name
    from acs_sc_contract c, acs_sc_impl i
    where c.contract_name = i.impl_contract_name
    and not exists (select 1
		    from acs_sc_binding b
		    where b.contract_id = c.contract_id
		    and b.impl_id = i.impl_id)
    and exists (select 1
	        from acs_sc_operation o
		where o.contract_id = c.contract_id
		and not exists (select 1
			        from acs_sc_impl_alias a
				where a.impl_contract_name = c.contract_name
				and a.impl_id = i.impl_id
				and a.impl_operation_name = o.operation_name));


create view orphan_implementation as
    select i.impl_id, i.impl_name, i.impl_contract_name
    from acs_sc_impl i
    where not exists (select 1
		      from acs_sc_binding b
		      where b.impl_id = i.impl_id)
    and not exists (select 1
		    from acs_sc_contract c
		    where c.contract_name = i.impl_contract_name);