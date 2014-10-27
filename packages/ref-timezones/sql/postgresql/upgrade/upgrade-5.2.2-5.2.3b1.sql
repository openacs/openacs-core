
--
-- procedure timezone__add_rule/8
--

select define_function_args('timezone__add_rule','tz,abbrev,isdst_p,gmt_offset,utc_start,utc_end,local_start,local_end');

CREATE OR REPLACE FUNCTION timezone__add_rule(
   p_tz varchar,
   p_abbrev varchar,
   p_isdst_p integer,
   p_gmt_offset varchar,
   p_utc_start varchar,
   p_utc_end varchar,
   p_local_start varchar,
   p_local_end varchar
) RETURNS integer AS $$
DECLARE
BEGIN
  insert into timezone_rules
    (tz_id, abbrev, utc_start, utc_end, local_start, local_end, gmt_offset, isdst_p)
  select timezone__get_id(p_tz), p_abbrev, rdbms_date(p_utc_start),
    rdbms_date(p_utc_end), rdbms_date(p_local_start),
    to_date(p_local_end),
    p_gmt_offset,
    case p_isdst_p when 0 then 'f' else 't'end;
END;
$$ LANGUAGE plpgsql;
