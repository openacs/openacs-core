-- packages/ref-country/sql/oracle/ref-countries-create.sql
--
-- @author jon@jongriffin.com.com
-- @creation-date 2001-08-27
-- @cvs-id $Id$

-- country is taken from ISO 3166

-- probably ought to add a note about analyze for efficiency on non-integer primary keys

create table countries (
    -- this violates 3nf but is used for 2 reasons
    -- 1. to help efficiency
    -- 2. to make querys not fail if no translation exists yet
    default_name varchar(100)
        constraint countries_default_name_nn
        not null
        constraint countries_default_name_uq
        unique,
    iso char(2)
        constraint countries_iso_pk
        primary key
);

comment on table countries is '
    This is the country code/english name table from ISO 3166.
';

comment on column countries.default_name is '
    This is admittedly a violation of 3NF but it is more efficient and helps with non-translated values.
See country.sql for more comments.
';

-- add this table into the reference repository
declare
    v_id integer;
begin
    v_id := acs_reference.new(
        table_name     => 'COUNTRIES',
        source         => 'ISO 3166',
        source_url     => 'http://www.din.de/gremien/nas/nabd/iso3166ma/codlstp1/db_en.html',
        last_update    => to_date('2000-08-21','YYYY-MM-DD'),
        effective_date => sysdate
    );
commit;
end;
/

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

-- add this table into the reference repository
declare
    v_id integer;
begin
    v_id := acs_reference.new(
        table_name     => 'COUNTRY_NAMES',
        source         => 'Internal',
        source_url     => '',
        effective_date => sysdate
    );
commit;
end;
/
