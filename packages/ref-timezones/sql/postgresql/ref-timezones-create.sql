-- packages/ref-timezones/sql/postgresql/ref-timezones-create.sql
--
-- This package provides both the reference data for timezones and an
-- API for doing simple operations on timezones.  The data provided is
-- a combination of the NIH timezone database and the Unix zoneinfo
-- database (conversion rules).
--
-- @author jon@jongriffin.com, dhogaza@pacifier.com
-- @creation-date 2001-09-02
-- @cvs-id $Id$

-- DRB: PostgreSQL has its own ideas about timezones and input/output conversions.
-- It natively supports a subset of the Unix timezone database, and external
-- representations are always in server-local time unless overridden by explicit
-- time zone information on input or converted to varchar with an "at timezone"
-- suffix in a select statement.

-- While useful for applications that can live with the restrictions, it's not
-- quite general enough for our usage.  This package provides the generality
-- we need in a style that's very close to that of its Oracle equivalent.

-- PG stores all dates shifted to UTC and does all computations in Julian
-- dates.  This package provides some very simple utilities:

-- timezone__convert_to_utc(timezone, input_string) returns timestamp
--   Takes an input string (which must NOT have any explicit timezone
--   information embedded) and converts it to a timestamp, shifting it
--   to UTC using the timezone information.   In other words, input_string
--   is a date/time local to the given timezone while the returned timestamp
--   is the same date/time shifted to UTC.

-- timezone__get_date(timezone, timestamp, format string) returns varchar
--   Converts the timestamp to a pretty date in the given timezone using "to_char"
--   and appends the timezone abbreviation.

-- timezone__get_offset(timezone, timestamp) returns interval
--   Returns a PostgreSQL interval (which can be added or substracted from
--   a UTC timestamp) for the timestamp in the given timezone.

-- timezone__get_rawoffset(timezone, timestamp) returns interval
--   Returns the raw (i.e. not adjusted for daylight savings time) offset
--   for the timestamp in the timezone (those reading the code for the first
--   time may think these definitions are backwards, but they're not)

-- Currently if timezone can't be found UTC is assumed.  Server local time
-- might make more sense but the Oracle version assumes UTC so we'll use that
-- for now...

create sequence timezone_seq;

-- Primary table for storing timezone names and standard offsets

create table timezones (
    tz_id	   integer
		   constraint timezones_tz_id_pk primary key,
    -- Unix-style TZ environment variable string, e.g. 'America/Los_Angeles'
    tz		   varchar(100) not null,
    -- the standard time offset from UTC as (+-)hhmiss
    gmt_offset	   text not null
);

-- add this table into the reference repository

select acs_reference__new(
          'TIMEZONES',
          '2000-08-21',
          'National Institute of Health (USA)',
          'ftp://elsie.nci.nih.gov/pub',
          now()
    );

-- The following table stores the rules for converting between
-- local and UTC time. Each rule is specified by timezone, its
-- gmt_offset, and the times during which it applies. 
    
create table timezone_rules (
    -- which timezone does this rule apply to?
    tz_id		integer
			constraint timezone_rules_tz_id_fk references timezones
			on delete cascade,
    -- abbreviation for local time, e.g. EST, EDT
    abbrev		varchar(10) not null,
    -- UTC start/end time of this rule
    utc_start		timestamp not null,
    utc_end		timestamp not null,
    -- local start/end time of this rule
    local_start		timestamp not null,
    local_end		timestamp not null,
    -- GMT offset in seconds
    gmt_offset		text not null,
    -- is Daylight Savings Time in effect for this rule?
    isdst_p		boolean
);

create index timezone_rules_idx1 on timezone_rules(tz_id, utc_start,   utc_end);
create index timezone_rules_idx2 on timezone_rules(tz_id, local_start, local_end);

-------------------------------------------------------------------------------
-- TimeZone package
-------------------------------------------------------------------------------

create function rdbms_date(varchar) returns timestamp as '
declare
  p_raw_date alias for $1;
begin
  return "timestamp" (p_raw_date || ''+00'');
end;' language 'plpgsql';

create function timezone__new (varchar, varchar) returns integer as '
declare
  p_tz alias for $1;
  p_gmt_offset alias for $2;
begin
  insert into timezones
    (tz_id, tz, gmt_offset)
  values
    (nextval(''timezone_seq''), p_tz, gmt_offset);
  return 0;
end;' language 'plpgsql';
	 
create function timezone__delete (integer) returns integer as '
declare
  p_tz_id alias for $1;
begin
  delete from timezone_rules where tz_id = p_tz_id;
  delete from timezones      where tz_id = p_tz_id;
  return 0;
end;' language 'plpgsql';

-- private function for looking up timezone id's

create function timezone__get_id (varchar) returns integer as '
declare
  p_tz alias for $1;
  v_tz_id integer;
begin
  select tz_id into v_tz_id 
  from   timezones
  where  tz = p_tz;
  return v_tz_id;
end;' language 'plpgsql';

create function timezone__add_rule (varchar, varchar, integer, varchar, varchar, varchar, varchar, varchar) returns integer as '
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
  select timezone__get_id(tz), abbrev, rdbms_date(utc_start),
    rdbms_date(utc_end), rdbms_date(local_start),
    to_date(local_end),
    gmt_offset,
    case isdst_p isdst_p when 0 then ''f'' else ''t''end;
end;' language 'plpgsql';

create function timezone__convert_to_utc (integer, varchar) returns timestamp as '
declare
  p_tz_id alias for $1;
  p_local_varchar alias for $2;
  v_base_time timestamp;
foo varchar;
begin

  select "timestamp" (p_local_varchar || substr(gmt_offset,1,5)) into v_base_time
  from timezones
  where tz_id = p_tz_id;

  if not found then
    return "timestamp" (p_local_varchar || ''+00'');
  end if;

  return "timestamp" (p_local_varchar || ''+00'') - "interval" (gmt_offset || ''seconds'')
  from   timezone_rules
  where  tz_id = p_tz_id and v_base_time between utc_start and utc_end;

end;' language 'plpgsql';

create function timezone__get_offset (integer, timestamp) returns interval as '
declare
  p_tz_id alias for $1;
  p_time alias for $2;
  v_offset integer;
begin
  v_offset := ''0'';

  select gmt_offset into v_offset
  from timezone_rules
  where  tz_id = p_tz_id and p_time between utc_start and utc_end;

  return "interval" (v_offset || ''seconds'');
end;' language 'plpgsql';
    
create function timezone__get_rawoffset (integer, timestamp) returns interval as '
declare
  p_tz_id alias for $1;
  p_time alias for $2;
  v_offset varchar;
begin
  v_offset := ''0'';

  select
    case isdst_p
    when ''t'' then "interval" (gmt_offset || ''seconds'') - ''3600 seconds''
    else "interval" (gmt_offset || ''seconds'')
    end
  into v_offset
  from   timezone_rules
  where  tz_id  = p_tz_id and p_time between utc_start and utc_end;

  return v_offset;
end;' language 'plpgsql';

create function timezone__get_abbrev (integer, timestamp) returns varchar as '
declare
  p_tz_id alias for $1;
  p_time for $2;
  v_abbrev timezone_rules.abbrev%TYPE;
begin
  v_abbrev := ''GMT'';

  select abbrev into v_abbrev
  from   timezone_rules
  where  tz_id = p_tz_id and p_time between local_start and local_end;
	 
  return v_abbrev;
end;' language 'plpgsql';

-- Returns a formatted date with timezone info appended  

create function timezone__get_date (integer, timestamp, varchar, boolean) returns varchar as '
declare
  p_tz_id alias for $1;
  p_timestamp alias for $2;
  p_format alias for $3;
  p_append_timezone_p alias for $4;
  v_timestamp timestamp;
  v_abbrev text;
  v_date text;
begin

  v_abbrev := '''';
  if p_append_timezone_p then
    select abbrev into v_abbrev
    from   timezone_rules
    where  tz_id = p_tz_id and p_timestamp between utc_start and utc_end;
  end if;

  select to_char(p_timestamp + "interval" (
     (extract(timezone_hour from p_timestamp) * 3600 + extract(timezone_minute from p_timestamp) * 60) || ''seconds'') +
         "interval" (gmt_offset || ''seconds''), p_format) || '' '' || v_abbrev
    into v_date 
  from   timezone_rules
  where  tz_id = p_tz_id and p_timestamp between utc_start and utc_end;

  if not found then
    select to_char(p_timestamp + "interval" ((extract(timezone_hour from p_timestamp) * 3600 + extract(timezone_minute from p_timestamp) * 60) || ''seconds''), p_format)
      into v_date;
  end if;

  return v_date;

end;' language 'plpgsql';

-- Returns 't' if timezone is currently using DST
create function timezone__isdst_p (integer, timestamp) returns boolean as '
declare
  p_tz_id alias for $1;
  p_time alias for $2;
  v_isdst_p boolean;
begin
  v_isdst_p := ''f'';

  select isdst_p into v_isdst_p
  from   timezone_rules
  where  tz_id = p_tz_id and p_time between local_start and local_end;

  return v_isdst_p;
end;' language 'plpgsql';

create function timezone__get_zone_offset (integer, integer, timestamp) returns interval as '
declare
  p_tz_this alias for $1;
  p_tz_other alias for $2;
  p_time alias for $3;
begin
  return timezone__get_offset(p_tz_this, timezone__utc_to_local(p_tz_this, p_time)) -
	 timezone__get_offset(p_tz_other, timezone__utc_to_local(p_tz_other, p_time));
end;' language 'plpgsql';
    
-------------------------------------------------------------------------------
-- TimeZone data
-------------------------------------------------------------------------------
\i ../common/ref-timezones-data.sql
\i ../common/ref-timezones-rules.sql
