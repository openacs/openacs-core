-- packages/acs-reference/sql/common/currency.sql
--
-- @author jon@jongriffin.com
-- @creation-date 2000-11-29
-- @cvs-id $Id$


create table currencies (
    -- since currencies 
    -- 3 char alphabetic
    codeA char(3)
        constraint currencies_code_a_pk
        primary key,
    -- this is the currency #
    codeN number,
    -- this is the minor unit
    -- not sure of the use but it is in the standar
    minor_unit char(1),
    -- explanation per iso
    note varchar(4000),
    -- this violates 3nf but is used for 2 reasons
    -- 1. to help efficiency
    -- 2. to make querys not fail if no translation exists yet
    default_name varchar(100)
        constraint currencies_default_name_nn
        not null
);

comment on table currencies is '
    This is the currency code/english name table from ISO 4217.
';

-- add this table into the reference repository
declare
    v_id integer;
begin
    v_id := acs_reference.new(
        table_name     => 'CURRENCIES',
        source         => 'ISO 4217',
        source_url     => 'http://www.iso.ch',
        last_update    => to_date('2000-10-30','YYYY-MM-DD'),
        effective_date => sysdate
    );
commit;
end;
/

-- This is the translated mapping of country names

create table currency_names (
    -- lookup into the countries table
    codeA char(3)
        constraint currency_names_iso_fk
        references currencies (codeA),
    -- lookup into the language_codes table
    language_code 
        constraint currency_names_lang_code_fk
        references language_codes (language_id),
    -- the translated name
    name varchar(100)
);

comment on table currency_names is ' 
    This is the translated mapping of currency names and language codes.
';

comment on column currency_names.language_code is '
    This is a lookup into the iso languages table.
';

-- map from currencies to country
create table currency_country_map (
    codeA char(3)
        constraint currency_country_map_code_fk
        references currencies (codeA),
    -- foreign key to relate country to currency
    -- this can by one => many therefor can't be unique
    -- i.e. Cuba has USD and CUP
    country_code char(2)
        constraint curr_cntry_map_country_fk
        references countries (iso)
);

-- I will add a view to join this stuff later.

-- initial data for currencies
@@../common/currency-data.sql






