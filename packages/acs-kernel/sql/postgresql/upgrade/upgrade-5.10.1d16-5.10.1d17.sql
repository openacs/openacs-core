--
-- Added function to expire a membership
--

-- added
select define_function_args('membership_rel__expire','rel_id');

--
-- procedure membership_rel__expire/1
--
CREATE OR REPLACE FUNCTION membership_rel__expire(
   expire__rel_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
    update membership_rels
    set member_state = 'expired'
    where rel_id = expire__rel_id;

    return 0;
END;
$$ LANGUAGE plpgsql;
