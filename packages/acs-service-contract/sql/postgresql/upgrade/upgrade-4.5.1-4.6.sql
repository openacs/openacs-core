-- packages/acs-service-contract/sql/oracle/upgrade/upgrade-4.5-4.5.1.sql
--
-- @author Vinod Kurup (vinod@kurup.com)
-- @creation_date 2002-08-14
--
-- $Id$

-- UPGRADE ISSUE #1
-- add more verbose error message



-- added

-- old define_function_args('acs_sc_binding__new','contract_id,impl_id')
-- new
select define_function_args('acs_sc_binding__new','contract_id,impl_id');


--
-- procedure acs_sc_binding__new/2
--
CREATE OR REPLACE FUNCTION acs_sc_binding__new(
   p_contract_id integer,
   p_impl_id integer
) RETURNS integer AS $$
DECLARE
    v_contract_name		varchar;
    v_impl_name			varchar;
    v_count			integer;
BEGIN

    v_contract_name := acs_sc_contract__get_name(p_contract_id);
    v_impl_name := acs_sc_impl__get_name(p_impl_id);

    select count(*) into v_count
    from acs_sc_operations
    where contract_id = p_contract_id
    and operation_name not in (select impl_operation_name
		       	       from acs_sc_impl_aliases
			       where impl_contract_name = v_contract_name
			       and impl_id = p_impl_id);

    if v_count > 0 then
        raise exception 'Binding of % to % failed since certain operations are not implemented.', v_contract_name, v_impl_name;
    end if;

    insert into acs_sc_bindings (
        contract_id,
	impl_id
    ) values (
        p_contract_id,
	p_impl_id
    );

    return 0;

END;
$$ LANGUAGE plpgsql;

