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

-- timezone__convert_to_utc(timezone, input_string) returns timestamptz
--   Takes an input string (which must NOT have any explicit timezone
--   information embedded) and converts it to a timestamptz, shifting it
--   to UTC using the timezone information.   In other words, input_string
--   is a date/time local to the given timezone while the returned timestamptz
--   is the same date/time shifted to UTC *if* you ignore the timezone information
--   by for instance extracting the information with to_char().

-- timezone__get_date(timezone, timestamptz, format string) returns varchar
--   Converts the timestamptz to a pretty date in the given timezone using "to_char"
--   and appends the timezone abbreviation.

-- timezone__get_offset(timezone, timestamptz) returns interval
--   Returns a PostgreSQL interval (which can be added or substracted from
--   a UTC timestamp) for the timestamp in the given timezone.

-- timezone__get_rawoffset(timezone, timestamptz) returns interval
--   Returns the raw (i.e. not adjusted for daylight savings time) offset
--   for the timestamp in the timezone (those reading the code for the first
--   time may think these definitions are backwards, but they're not)

-- Currently if timezone can't be found UTC is assumed.  Server local time
-- might make more sense but the Oracle version assumes UTC so we'll use that
-- for now...

-- DRB: Additional note ...

-- As of version 7.3, PostgreSQL's default timestamp type no longer includes timezone
-- information.  If we were starting from scratch, these functions could be simplified
-- but ... we have existing OpenACS 4.x installations running PG 7.2.  pg_dump dumps
-- the old timestamp type as timestamp with time zone explicitly, and the values include
-- timezone information, so we're pretty much stuck using timestamptz indefinitely it
-- appears.

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
    utc_start		timestamptz not null,
    utc_end		timestamptz not null,
    -- local start/end time of this rule
    local_start		timestamptz not null,
    local_end		timestamptz not null,
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

create or replace function rdbms_date(varchar) returns timestamptz as '
declare
  p_raw_date alias for $1;
begin
  return "timestamptz" (p_raw_date || ''+00'');
end;' language 'plpgsql' stable strict;

create or replace function timezone__new (varchar, varchar) returns integer as '
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
	 
create or replace function timezone__delete (integer) returns integer as '
declare
  p_tz_id alias for $1;
begin
  delete from timezone_rules where tz_id = p_tz_id;
  delete from timezones      where tz_id = p_tz_id;
  return 0;
end;' language 'plpgsql';

-- private function for looking up timezone id's

create or replace function timezone__get_id (varchar) returns integer as '
declare
  p_tz alias for $1;
  v_tz_id integer;
begin

  return tz_id
  from   timezones
  where  tz = p_tz;

end;' language 'plpgsql' stable strict;

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

create or replace function timezone__convert_to_utc (integer, varchar) returns timestamptz as '
declare
  p_tz_id alias for $1;
  p_local_varchar alias for $2;
  v_base_time timestamptz;
begin

  select "timestamptz" (p_local_varchar || substr(gmt_offset,1,5)) into v_base_time
  from timezones
  where tz_id = p_tz_id;

  if not found then
    return "timestamptz" (p_local_varchar || ''+00'');
  end if;

  return "timestamptz" (p_local_varchar) - "interval" (gmt_offset || ''seconds'')
  from   timezone_rules
  where  tz_id = p_tz_id and v_base_time between utc_start and utc_end;

end;' language 'plpgsql';


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

end;' language 'plpgsql' stable;


create or replace function timezone__get_offset (integer, timestamptz) returns interval as '
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
end;' language 'plpgsql' stable;
    
create or replace function timezone__get_rawoffset (integer, timestamptz) returns interval as '
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
end;' language 'plpgsql' stable;

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

-- Returns a formatted date with timezone info appended  

create or replace function timezone__get_date (integer, timestamptz, varchar, boolean) returns varchar as '
declare
  p_tz_id alias for $1;
  p_timestamp alias for $2;
  p_format alias for $3;
  p_append_timezone_p alias for $4;
  v_timestamp timestamptz;
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

end;' language 'plpgsql' stable;

-- Returns 't' if timezone is currently using DST
create or replace function timezone__isdst_p (integer, timestamptz) returns boolean as '
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
end;' language 'plpgsql' stable;
