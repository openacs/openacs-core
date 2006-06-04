create or replace function timezone__add_rule (varchar, varchar, integer, varchar, varchar, varchar, varchar, varchar) returns integer as '
declare
  p_tz alias for $1;
  p_abbrev alias for $2;
  p_isdst_p alias for $3;
  p_gmt_offset alias for $4;
  p_utc_start alias for $5;
  p_utc_end alias for $6;
  p_local_start alias for $7;
  p_local_end alias for $8;
begin
  insert into timezone_rules
    (tz_id, abbrev, utc_start, utc_end, local_start, local_end, gmt_offset, isdst_p)
  select timezone__get_id(p_tz), p_abbrev, rdbms_date(p_utc_start),
    rdbms_date(p_utc_end), rdbms_date(p_local_start),
    to_date(p_local_end),
    p_gmt_offset,
    case p_isdst_p when 0 then ''f'' else ''t''end;
end;' language 'plpgsql';
