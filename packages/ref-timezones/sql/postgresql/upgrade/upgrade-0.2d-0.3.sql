--
-- Upgrade script to add timezone__convert_to_local
--
-- @author Lars Pind (lars@collaboraid.biz)
-- @creation-date 2003-08-06
--

create or replace function timezone__convert_to_local (integer, varchar) returns timestamptz as '
declare
  p_tz_id alias for $1;
  p_utc_varchar alias for $2;
  v_base_time timestamptz;
begin

  select "timestamptz" (p_utc_varchar || substr(gmt_offset,1,5)) into v_base_time
  from timezones
  where tz_id = p_tz_id;

  if not found then
    return "timestamptz" (p_utc_varchar || ''+00'');
  end if;

  return "timestamptz" (p_utc_varchar) + "interval" (gmt_offset || ''seconds'')
  from   timezone_rules
  where  tz_id = p_tz_id and v_base_time between utc_start and utc_end;

end;' language 'plpgsql';


