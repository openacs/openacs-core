--
-- @author Simon Carstensen (simon@collaboraid.biz)
-- @creation_date 2003-09-10
--
-- $Id$

-- add column impl_pretty_name
alter table acs_sc_impls add column impl_pretty_name varchar(200);

update acs_sc_impls set impl_pretty_name = impl_name;

create or replace function acs_sc_impl__new(varchar,varchar,varchar,varchar)
returns integer as '
declare
    p_impl_contract_name        alias for $1;
    p_impl_name                 alias for $2;
    p_impl_pretty_name          alias for $3;
    p_impl_owner_name           alias for $4;
    v_impl_id                   integer;
begin

    v_impl_id := acs_object__new(
                null,
                ''acs_sc_implementation'',
                now(),
                null,
                null,
                null
            );

    insert into acs_sc_impls (
        impl_id,
        impl_name,
        impl_pretty_name,
        impl_owner_name,
        impl_contract_name
    ) values (
        v_impl_id,
        p_impl_name,
        p_impl_pretty_name,
        p_impl_owner_name,
        p_impl_contract_name
    );

    return v_impl_id;

end;' language 'plpgsql';


drop view valid_uninstalled_bindings;
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



drop view invalid_uninstalled_bindings;
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


drop view orphan_implementations;
create view orphan_implementations as
    select i.impl_id, i.impl_name, i.impl_owner_name, i.impl_contract_name, i.impl_pretty_name
    from acs_sc_impls i
    where not exists (select 1
                      from acs_sc_bindings b
                      where b.impl_id = i.impl_id)
    and not exists (select 1
                    from acs_sc_contracts c
                    where c.contract_name = i.impl_contract_name);
