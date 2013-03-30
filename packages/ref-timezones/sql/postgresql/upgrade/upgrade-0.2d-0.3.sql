--
-- Upgrade script to add timezone__convert_to_local
--
-- @author Lars Pind (lars@collaboraid.biz)
-- @creation-date 2003-08-06
--



-- added
select define_function_args('timezone__convert_to_local','tz_id,utc_varchar');

--
-- procedure timezone__convert_to_local/2
--
CREATE OR REPLACE FUNCTION timezone__convert_to_local(
   p_tz_id integer,
   p_utc_varchar varchar
) RETURNS timestamptz AS $$
DECLARE
  v_base_time timestamptz;
BEGIN

  select "timestamptz" (p_utc_varchar || substr(gmt_offset,1,5)) into v_base_time
  from timezones
  where tz_id = p_tz_id;

  if not found then
    return "timestamptz" (p_utc_varchar || '+00');
  end if;

  return "timestamptz" (p_utc_varchar) + "interval" (gmt_offset || 'seconds')
  from   timezone_rules
  where  tz_id = p_tz_id and v_base_time between utc_start and utc_end;

END;
$$ LANGUAGE plpgsql;


