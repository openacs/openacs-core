-- packages/ref-timezones/sql/oracle/ref-timezones-create.sql
--
-- This package provides both the reference data for timezones and an
-- API for doing simple operations on timezones.  The data provided is
-- a combination of the NIH timezone database and the Unix zoneinfo
-- database (conversion rules).
--
-- @author jon@jongriffin.com
-- @author ron@arsdigita.com
-- @creation-date 2000-11-30
-- @cvs-id $Id$

-- we don't need this anymore. all data should be updated from the source
 create sequence timezone_seq;

-- Primary table for storing timezone names and standard offsets

create table timezones (
    tz_id	   integer
		   constraint timezones_tz_id_pk primary key,
    -- Unix-style TZ environment variable string, e.g. 'America/Los_Angeles'
    tz		   varchar2(100) not null,
    -- the standard time offset from UTC as (+-)hhmiss
    gmt_offset	   char(7) not null
);

-- add this table into the reference repository

declare
    v_id integer;
begin
    v_id := acs_reference.new(
        table_name     => 'TIMEZONES',
        package_name   => 'TIMEZONE',
        source         => 'Reference Portal.org (USA)',
        source_url     => 'www.referenceportal.org',
        last_update    => to_date('2001-08-21','YYYY-MM-DD'),
        effective_date => sysdate
    );
commit;
end;
/

-- The following table stores the rules for converting between
-- local and UTC time. Each rule is specified by timezone, its
-- gmt_offset in seconds, and the times during which it applies. 
    
create table timezone_rules (
    -- which timezone does this rule apply to?
    tz_id		integer
			constraint timezone_rules_tz_id_fk references timezones
			on delete cascade,
    -- abbreviation for local time, e.g. EST, EDT
    abbrev		varchar2(10),
    -- UTC start/end time of this rule
    utc_start		date,
    utc_end		date,
    -- local start/end time of this rule
    local_start		date,
    local_end		date,
    -- GMT offset in seconds
    gmt_offset		numeric,
    -- is Daylight Savings Time in effect for this rule?
    isdst		char(1) 
			constraint timezone_rules_isdist_ck
			check (isdst in ('t','f'))
);

create index timezone_rules_idx1 on timezone_rules(tz_id, utc_start,   utc_end);
create index timezone_rules_idx2 on timezone_rules(tz_id, local_start, local_end);

-- DRB: This is declared as a function outside the timezones package so we can 
-- use the same data inserts for both PG and Oracle.

create or replace function rdbms_date(
         raw_date	in varchar
) return date
is
     new_date date;
begin
     select to_date(raw_date, 'Mon DD YYYY HH:MI:SS') into new_date from dual;
     return new_date;
end rdbms_date;
/
show errors;

-------------------------------------------------------------------------------
-- TimeZone package
-------------------------------------------------------------------------------

create or replace package timezone
as
-- deprecated
    procedure new (
        tz         in timezones.tz%TYPE,
        gmt_offset in timezones.gmt_offset%type
    );

    procedure del (
	 tz_id	   in timezones.tz_id%TYPE
    );

    function get_id (
	 -- Gets the ID number of the given timezone
	 tz in timezones.tz%TYPE
    ) return integer;

    procedure add_rule (
	 -- Adds a new conversion rule to the timezone_rules database
	 tz		in timezones.tz%TYPE,
	 abbrev		in timezone_rules.abbrev%TYPE,
	 isdst		in integer,
	 gmt_offset	in integer,
	 utc_start	in varchar,
	 utc_end	in varchar,
	 local_start	in varchar,
	 local_end	in varchar
    );

    -- The following are the primary time conversion functions

    function utc_to_local (
	 -- Returns utc_time converted to local time
	 tz_id        in timezones.tz_id%TYPE,
	 utc_time  in date
    ) return date;

    function local_to_utc (
	 tz_id      in timezones.tz_id%TYPE,
	 local_time in date
    ) return date;

    -- The following provide access to the current offset information

    function get_offset (
	 -- Gets the timezone offset in seconds, for the current date,
	 -- modified in case of DST.
	 tz_id      in timezones.tz_id%TYPE,
	 local_time in date default sysdate
    ) return integer;

    function get_rawoffset (
	 -- Gets the timezone offset NOT modified for DST
	 tz_id      in timezones.tz_id%TYPE,
	 local_time in date default sysdate
    ) return integer;

    function get_abbrev (
	 -- Returns abbreviation for the coversion rule
	 tz_id	     in timezones.tz_id%TYPE,
	 local_time  in date default sysdate
    ) return varchar;

    function get_zone_offset (
    	 -- Returns the relative offset between two zones at a
	 -- particular UTC time. 
	 tz_this     in timezones.tz_id%TYPE,
	 tz_other    in timezones.tz_id%TYPE,
	 utc_time    in date default sysdate
    ) return integer;

    -- Access to flags

    function isdst_p (
	 -- Returns 't' if timezone is currently using DST
	 tz_id	     in timezones.tz_id%TYPE,
	 local_time  in date default sysdate
    ) return char;	 

    -- Special formatting functions

    function get_date (
	 -- Returns a formatted date with timezone info appended  
	 tz_id	     in timezones.tz_id%TYPE,
	 local_time  in date,
	 format	     in varchar default 'yyyy-mm-ss hh24:mi:ss',
         append_timezone_p in char default 't'
    ) return varchar;

end timezone;
/
show errors

--
--
--

create or replace package body timezone
as
    procedure new (
	 tz         in timezones.tz%TYPE,
	 gmt_offset in timezones.gmt_offset%type
    ) 
    is
    begin
	 insert into timezones
	      (tz_id, tz, gmt_offset)
	 values
	      (timezone_seq.nextval, tz, gmt_offset);
    end;
	 
    procedure del (
	 tz_id	   in timezones.tz_id%TYPE
    )
    is
    begin
	 delete from timezone_rules where tz_id = tz_id;
	 delete from timezones      where tz_id = tz_id;
    end;

    -- private function for looking up timezone id's

    function get_id (
	 tz in timezones.tz%TYPE
    ) return integer
    is
	 tz_id integer;
    begin
	 select tz_id into tz_id 
	 from   timezones
	 where  tz = get_id.tz;

	 return tz_id;
    end;

    procedure add_rule (
	 tz		in timezones.tz%TYPE,
	 abbrev		in timezone_rules.abbrev%TYPE,
	 isdst		in integer,
	 gmt_offset	in integer,
	 utc_start	in varchar,
	 utc_end	in varchar,
	 local_start	in varchar,
	 local_end	in varchar
    )
    is
    begin
	 insert into timezone_rules
	      (tz_id,
	       abbrev,
	       utc_start,
               utc_end,
	       local_start,
	       local_end,
	       gmt_offset,
	       isdst)
	 values
	      (get_id(tz),
	       abbrev,
	       to_date(utc_start,'Mon dd hh24:mi:ss yyyy'),
	       to_date(utc_end,  'Mon dd hh24:mi:ss yyyy'),
	       to_date(local_start,'Mon dd hh24:mi:ss yyyy'),
	       to_date(local_end,'Mon dd hh24:mi:ss yyyy'),
	       gmt_offset,
	       decode(isdst,0,'f',1,'t'));
    end;

    function utc_to_local (
	 tz_id     in timezones.tz_id%TYPE,
	 utc_time  in date
    ) return date
    is
	 local_time date;
    begin
	 select utc_time + gmt_offset/86400 into local_time
	 from   timezone_rules
	 where  tz_id  = utc_to_local.tz_id
	 and    utc_time between utc_start and utc_end
	 and	rownum = 1;

	 return local_time;
    exception
	 when no_data_found then
	      return utc_time;
    end utc_to_local;

    function local_to_utc (
	 tz_id      in timezones.tz_id%TYPE,
	 local_time in date
    ) return date
    is
	 utc_time date;
    begin
	 select local_time - gmt_offset/86400 into utc_time
	 from   timezone_rules
	 where  tz_id = local_to_utc.tz_id
	 and    local_time between local_start and local_end
	 and    rownum = 1;

	 return utc_time;
    exception
	 when no_data_found then
	      return local_time;
    end;

    function get_offset (
	 tz_id      in timezones.tz_id%TYPE,
	 local_time in date default sysdate
    ) return integer
    is
	 v_offset integer;
    begin
	 select gmt_offset into v_offset
	 from   timezone_rules
	 where  tz_id = get_offset.tz_id
	 and    local_time between local_start and local_end
	 and    rownum = 1;

	 return v_offset;
    exception
	 when no_data_found then
	      return 0;
    end;

    function get_rawoffset (
	 tz_id      in timezones.tz_id%TYPE,
	 local_time in date default sysdate
    ) return integer
    is
	 v_offset number;
    begin
	 select decode (isdst,'t', gmt_offset - 3600, 
                              'f', gmt_offset) into v_offset
	 from   timezone_rules
	 where  tz_id  = get_rawoffset.tz_id
	 and    local_time between local_start and local_end
	 and    rownum = 1;

	 return v_offset;
    exception
	 when no_data_found then
	      return 0;
    end;

    function get_abbrev (
	 tz_id	     in timezones.tz_id%TYPE,
	 local_time  in date default sysdate
    ) return varchar
    is
	 v_abbrev timezone_rules.abbrev%TYPE;
    begin
	 select abbrev into v_abbrev
	 from   timezone_rules
	 where  tz_id = get_abbrev.tz_id
	 and    local_time between local_start and local_end;
	 
	 return v_abbrev;
    exception
	 when no_data_found then
	      return 'GMT';
    end;

    function get_date (
	 -- Returns a formatted date with timezone info appended  
	 tz_id	     in timezones.tz_id%TYPE,
	 local_time  in date,
	 format	     in varchar default 'yyyy-mm-ss hh24:mi:ss',
         append_timezone_p in char default 't'
    ) return varchar
    is
	 v_date varchar(1000);
    begin
         if append_timezone_p = 't' then
             select to_char(local_time,format) || ' ' || abbrev into v_date 
             from   timezone_rules
             where  tz_id = get_date.tz_id
             and    local_time between local_start and local_end
             and    rownum = 1;
         else
             select to_char(local_time,format) into v_date 
             from   dual;
         end if;

	 return v_date;
    exception
	 when no_data_found then
	      select to_char(local_time,format) into v_date from dual;
	      return v_date;
    end;

    function isdst_p (
	 -- Returns 't' if timezone is currently using DST
	 tz_id	     in timezones.tz_id%TYPE,
	 local_time  in date default sysdate
    ) return char
    is
	 v_isdst char;
    begin
	 select isdst into v_isdst
	 from   timezone_rules
	 where  tz_id = isdst_p.tz_id
	 and    local_time between local_start and local_end
	 and    rownum = 1;

	 return v_isdst;
    exception
	 when no_data_found then
	      return 'f';
    end;

    function get_zone_offset (
	 tz_this     in timezones.tz_id%TYPE,
	 tz_other    in timezones.tz_id%TYPE,
	 utc_time    in date default sysdate
    ) return integer
    is
    begin
	 return get_offset(tz_this, utc_to_local(tz_this, utc_time)) -
	        get_offset(tz_other,utc_to_local(tz_other,utc_time));
    end;
    
end timezone; 
/
show errors

