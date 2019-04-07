--
-- procedure acs_object_util__object_type_exist_p/1
--
CREATE OR REPLACE FUNCTION acs_object_util__object_type_exist_p(
   p_object_type varchar
) RETURNS boolean AS $$
DECLARE
    v_exist_p boolean;
BEGIN

    select true into v_exist_p
    from   acs_object_types 
    where  object_type = p_object_type;
 
    return FOUND;
END;
$$ LANGUAGE plpgsql stable;
