-- packages/ref-country/sql/postgresql/ref-country-create.sql
--
-- @author jon@jongriffin.com.com
-- @creation-date 2001-08-27
-- @cvs-id $Id$

-- country is taken from ISO 3166

-- probably ought to add a note about analyze for efficiency on non-integer primary keys

create table countries (
    iso char(2)
        constraint countries_iso_pk
        primary key,
    -- this is the three letter abbreviation - hardly used
    a3  char(3),
    -- this is the numeric code - hardly used
    -- it is a char because of leading zeros so it isn't really a number
    numeric char(3),
    -- this violates 3nf but is used for 2 reasons
    -- 1. to help efficiency
    -- 2. to make querys not fail if no translation exists yet
    default_name varchar(100)
        constraint countries_default_name_nn
        not null
        constraint countries_default_name_uq
        unique
);

comment on table countries is '
    This is the country code/english name table from ISO 3166.
';

comment on column countries.default_name is '
    This is admittedly a violation of 3NF but it is more efficient and helps with non-translated values.
See country.sql for more comments.
';
 
comment on column countries.a3 is '
   This is the three letter abbreviation - hardly used.
';

comment on column countries.numeric is ' 
    This is the numeric code - hardly used.
';

-- add this table into the reference repository

create function inline_0 ()
returns integer as '
begin
    PERFORM acs_reference__new (
        ''COUNTRIES'', -- table_name
        ''ISO 3166'', -- source
        ''http://www.din.de/gremien/nas/nabd/iso3166ma/codlstp1/db_en.html'', -- source_url
        to_date('2000-08-21','YYYY-MM-DD'), -- last_update
        sysdate() -- effective_date
    );

    return 0
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

-- This is the translated mapping of country names

create table country_names (
    -- lookup into the countries table
    iso char(2)
        constraint country_names_iso_fk
        references countries (iso),
    -- lookup into the language_codes table
    language_code 
        constraint country_names_language_code_fk
        references language_codes (language_id),
    -- the translated name
    name varchar(100)
);

comment on table country_names is ' 
    This is the translated mapping of country names and language codes.
';

comment on column country_names.language_code is '
    This is a lookup into the iso languages table.
';

-- I need to know the easy way to add extended chars in sqlplus then I can add french and spanish

-- ISO country codes
/i ../common/ref-country-data.sql



