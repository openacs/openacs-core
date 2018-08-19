-- added
select define_function_args('timezone__add_rule','tz,abbrev,isdst_p,gmt_offset,utc_start,utc_end,local_start,local_end');

--
-- procedure timezone__add_rule/8
--
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
$$ LANGUAGE plpgsql stable;


-- added
select define_function_args('timezone__convert_to_utc','tz_id,local_varchar');

--
-- procedure timezone__convert_to_utc/2
--
CREATE OR REPLACE FUNCTION timezone__convert_to_utc(
   p_tz_id integer,
   p_local_varchar varchar
) RETURNS timestamptz AS $$
DECLARE
  v_base_time timestamptz;
BEGIN

  select "timestamptz" (p_local_varchar || substr(gmt_offset,1,5)) into v_base_time
  from timezones
  where tz_id = p_tz_id;

  if not found then
    return "timestamptz" (p_local_varchar || '+00');
  end if;

  return "timestamptz" (p_local_varchar) - "interval" (gmt_offset || 'seconds')
  from   timezone_rules
  where  tz_id = p_tz_id and v_base_time between utc_start and utc_end;

END;
$$ LANGUAGE plpgsql;



-- added
select define_function_args('timezone__delete','tz_id');

--
-- procedure timezone__delete/1
--
CREATE OR REPLACE FUNCTION timezone__delete(
   p_tz_id integer
) RETURNS integer AS $$
DECLARE
BEGIN
  delete from timezone_rules where tz_id = p_tz_id;
  delete from timezones      where tz_id = p_tz_id;
  return 0;
END;
$$ LANGUAGE plpgsql;


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


-- added
select define_function_args('timezone__get_date','tz_id,timestamp,format,append_timezone_p');

--
-- procedure timezone__get_date/4
--
CREATE OR REPLACE FUNCTION timezone__get_date(
   p_tz_id integer,
   p_timestamp timestamptz,
   p_format varchar,
   p_append_timezone_p boolean
) RETURNS varchar AS $$
DECLARE
  v_timestamp timestamptz;
  v_abbrev text;
  v_date text;
BEGIN

  v_abbrev := '';
  if p_append_timezone_p then
    select abbrev into v_abbrev
    from   timezone_rules
    where  tz_id = p_tz_id and p_timestamp between utc_start and utc_end;
  end if;

  select to_char(p_timestamp + "interval" (
     (extract(timezone_hour from p_timestamp) * 3600 + extract(timezone_minute from p_timestamp) * 60) || 'seconds') +
         "interval" (gmt_offset || 'seconds'), p_format) || ' ' || v_abbrev
    into v_date 
  from   timezone_rules
  where  tz_id = p_tz_id and p_timestamp between utc_start and utc_end;

  if not found then
    select to_char(p_timestamp + "interval" ((extract(timezone_hour from p_timestamp) * 3600 + extract(timezone_minute from p_timestamp) * 60) || 'seconds'), p_format)
      into v_date;
  end if;

  return v_date;

END;
$$ LANGUAGE plpgsql stable;


-- added
select define_function_args('timezone__get_id','tz');

--
-- procedure timezone__get_id/1
--
CREATE OR REPLACE FUNCTION timezone__get_id(
   p_tz varchar
) RETURNS integer AS $$
DECLARE
  v_tz_id integer;
BEGIN

  return tz_id
  from   timezones
  where  tz = p_tz;

END;
$$ LANGUAGE plpgsql stable strict;

-- added
select define_function_args('timezone__get_offset','tz_id,time');

--
-- procedure timezone__get_offset/2
--
CREATE OR REPLACE FUNCTION timezone__get_offset(
   p_tz_id integer,
   p_time timestamptz
) RETURNS interval AS $$
DECLARE
  v_offset integer;
BEGIN
  v_offset := '0';

  select gmt_offset into v_offset
  from timezone_rules
  where  tz_id = p_tz_id and p_time between utc_start and utc_end;

  return "interval" (v_offset || 'seconds');
END;
$$ LANGUAGE plpgsql stable;
    


-- added
select define_function_args('timezone__get_rawoffset','tz_id,time');

--
-- procedure timezone__get_rawoffset/2
--
CREATE OR REPLACE FUNCTION timezone__get_rawoffset(
   p_tz_id integer,
   p_time timestamptz
) RETURNS interval AS $$
DECLARE
  v_offset varchar;
BEGIN
  v_offset := '0';

  select
    case isdst_p
    when 't' then "interval" (gmt_offset || 'seconds') - '3600 seconds'
    else "interval" (gmt_offset || 'seconds')
    end
  into v_offset
  from   timezone_rules
  where  tz_id  = p_tz_id and p_time between utc_start and utc_end;

  return v_offset;
END;
$$ LANGUAGE plpgsql stable;

-- added
select define_function_args('timezone__isdst_p','tz_id,time');

--
-- procedure timezone__isdst_p/2
--
CREATE OR REPLACE FUNCTION timezone__isdst_p(
   p_tz_id integer,
   p_time timestamptz
) RETURNS boolean AS $$
DECLARE
  v_isdst_p boolean;
BEGIN
  v_isdst_p := 'f';

  select isdst_p into v_isdst_p
  from   timezone_rules
  where  tz_id = p_tz_id and p_time between local_start and local_end;

  return v_isdst_p;
END;
$$ LANGUAGE plpgsql stable;

-- added
select define_function_args('timezone__new','tz,gmt_offset');

--
-- procedure timezone__new/2
--
CREATE OR REPLACE FUNCTION timezone__new(
   p_tz varchar,
   p_gmt_offset varchar
) RETURNS integer AS $$
DECLARE
BEGIN
  insert into timezones
    (tz_id, tz, gmt_offset)
  values
    (nextval('timezone_seq'), p_tz, gmt_offset);
  return 0;
END;
$$ LANGUAGE plpgsql;
	 

-- added
select define_function_args('rdbms_date','raw_date');

--
-- procedure rdbms_date/1
--
CREATE OR REPLACE FUNCTION rdbms_date(
   p_raw_date varchar
) RETURNS timestamptz AS $$
DECLARE
BEGIN
  return "timestamptz" (p_raw_date || '+00');
END;
$$ LANGUAGE plpgsql stable strict;
