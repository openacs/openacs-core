-- packages/acs-reference/sql/common/us-states.sql
--
-- @author jon@jongriffin.com
-- @creation-date 2000-11-28
-- @cvs-id $Id$

create table us_states (
    abbrev          char(2)
                    constraint us_states_abbrev_pk primary key,
    state_name      varchar2(100)
	            constraint us_states_state_name_nn not null
                    constraint us_states_state_name_uq unique,
    fips_state_code char(2)
                    constraint us_states_fips_state_code_uq unique
);

comment on table us_states is '
This is the US states table.
';

comment on column us_states.abbrev is '
This is the 2 letter abbreviation for states.
';

comment on column us_states.fips_state_code is '
The FIPS code used by the USPS for certain delivery types.
';

-- add this table into the reference repository
select acs_reference__new (
    table_name      => 'US_STATES',
    source          => 'Internal',
    source_url      => '',
    last_update     => sysdate,
    internal_data_p => 't',
    effective_date  => sysdate
);

-- load the data
\i ../common/us-states-data
