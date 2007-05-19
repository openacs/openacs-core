-- packages/ref-country/sql/postgresql/ref-country-create.sql
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

select acs_reference__new (
        'COUNTRIES', -- table_name
        '2000-08-21',
        'ISO 3166', -- source
        'http://www.din.de/gremien/nas/nabd/iso3166ma/codlstp1/db_en.html', -- source_url
        now() -- effective_date
    );

