-- alias missing from p_time decl.


-- added
select define_function_args('timezone__get_abbrev','tz_id,time');

--
-- procedure timezone__get_abbrev/2
--
CREATE OR REPLACE FUNCTION timezone__get_abbrev(
   p_tz_id integer,
   p_time timestamptz
) RETURNS varchar AS $$
DECLARE
  v_abbrev timezone_rules.abbrev%TYPE;
BEGIN
  v_abbrev := 'GMT';

  select abbrev into v_abbrev
  from   timezone_rules
  where  tz_id = p_tz_id and p_time between local_start and local_end;
	 
  return v_abbrev;
END;
$$ LANGUAGE plpgsql stable;
