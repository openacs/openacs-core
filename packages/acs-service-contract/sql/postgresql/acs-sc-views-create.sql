-- $Id$

create view valid_uninstalled_bindings as
    select c.contract_id, c.contract_name, i.impl_id, i.impl_name, i.impl_owner_name, i.impl_pretty_name
    from acs_sc_contracts c, acs_sc_impls i
    where c.contract_name = i.impl_contract_name
    and not exists (select 1
                    from acs_sc_bindings b
                    where b.contract_id = c.contract_id
                    and b.impl_id = i.impl_id)
    and not exists (select 1
                    from acs_sc_operations o
                    where o.contract_id = c.contract_id
                    and not exists (select 1
                                    from acs_sc_impl_aliases a
                                    where a.impl_contract_name = c.contract_name
                                    and a.impl_id = i.impl_id
                                    and a.impl_operation_name = o.operation_name));



create view invalid_uninstalled_bindings as
    select c.contract_id, c.contract_name, i.impl_id, i.impl_name, i.impl_owner_name, i.impl_pretty_name
    from acs_sc_contracts c, acs_sc_impls i
    where c.contract_name = i.impl_contract_name
    and not exists (select 1
                    from acs_sc_bindings b
                    where b.contract_id = c.contract_id
                    and b.impl_id = i.impl_id)
    and exists (select 1
                from acs_sc_operations o
                where o.contract_id = c.contract_id
                and not exists (select 1
                                from acs_sc_impl_aliases a
                                where a.impl_contract_name = c.contract_name
                                and a.impl_id = i.impl_id
                                and a.impl_operation_name = o.operation_name));


create view orphan_implementations as
    select i.impl_id, i.impl_name, i.impl_owner_name, i.impl_contract_name, i.impl_pretty_name
    from acs_sc_impls i
    where not exists (select 1
                      from acs_sc_bindings b
                      where b.impl_id = i.impl_id)
    and not exists (select 1
                    from acs_sc_contracts c
                    where c.contract_name = i.impl_contract_name);
