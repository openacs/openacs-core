--
-- @author Simon Carstensen (simon@collaboraid.biz)
-- @creation_date 2003-09-10
--
-- $Id$

-- add column impl_pretty_name
alter table acs_sc_impls add column impl_pretty_name varchar(200);

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
