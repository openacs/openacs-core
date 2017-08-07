
-- Before we were forgetting to delete acs_object. Now we exploit
-- cascade constraint on service contract table. TODO: put cascade
-- constraints on other tables referencing service contracts (like
-- authorities table)

CREATE OR REPLACE FUNCTION acs_sc_impl__delete(
   p_impl_contract_name varchar,
   p_impl_name varchar
) RETURNS integer AS $$
DECLARE
   v_impl_id integer;
BEGIN

    v_impl_id := acs_sc_impl__get_id(p_impl_contract_name,p_impl_name);

    perform acs_object__delete(v_impl_id);

    return 0;

END;
$$ LANGUAGE plpgsql;
