-- alias missing from p_time decl.
create or replace function timezone__get_abbrev (integer, timestamptz) returns varchar as '
declare
  p_tz_id alias for $1;
  p_time alias for $2;
  v_abbrev timezone_rules.abbrev%TYPE;
begin
  v_abbrev := ''GMT'';

  select abbrev into v_abbrev
  from   timezone_rules
  where  tz_id = p_tz_id and p_time between local_start and local_end;
	 
  return v_abbrev;
end;' language 'plpgsql' stable;
