--
-- Make sure that patch 
-- http://cvs.openacs.org/browse/OpenACS/openacs-4/packages/acs-kernel/sql/postgresql/apm-create.sql?r2=1.74&r1=1.73
-- is applied for sites upgrading (use v_parameter_id and not get_value__parameter_id)
--
--
CREATE OR REPLACE FUNCTION apm__get_value(
   get_value__package_id integer,
   get_value__parameter_name varchar
) RETURNS varchar AS $$
DECLARE
  v_parameter_id                    apm_parameter_values.parameter_id%TYPE;
  value                             apm_parameter_values.attr_value%TYPE;
BEGIN
    v_parameter_id := apm__id_for_name (get_value__package_id, get_value__parameter_name);

    select attr_value into value from apm_parameter_values v
    where v.package_id = get_value__package_id
    and parameter_id = v_parameter_id;

    return value;
   
END;
$$ LANGUAGE plpgsql stable strict;

CREATE OR REPLACE FUNCTION apm__get_value(
   get_value__package_key varchar,
   get_value__parameter_name varchar
) RETURNS varchar AS $$
DECLARE
  v_parameter_id                    apm_parameter_values.parameter_id%TYPE;
  value                             apm_parameter_values.attr_value%TYPE;
BEGIN
    v_parameter_id := apm__id_for_name (get_value__package_key, get_value__parameter_name);

    select attr_value into value from apm_parameter_values v
    where v.package_id is null
    and parameter_id = v_parameter_id;

    return value;
   
END;
$$ LANGUAGE plpgsql stable strict;
