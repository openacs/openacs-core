--
-- packages/language/sql/language-create.sql
--
-- @author Jeff Davis (davis@arsdigita.com)
-- @creation-date 2000-09-10
-- @cvs-id $Id$
--

-- ****************************************************************************
-- * Currency codes table is created as part of the core.
-- * But not yet defined in ACS 4.0
-- ****************************************************************************

begin;

create table currency_codes (
	iso			char(3) constraint currency_iso_pk primary key,
	currency_name		varchar(200),
	html_entity     	varchar(200),
	fractional_digits 	integer,
	supported_p		boolean default 'f' 
);

insert into currency_codes (iso, currency_name) values ('ZAR', 'South African Rand');
insert into currency_codes (iso, currency_name) values ('VEB', 'Venezualan Bolivar');
insert into currency_codes (iso, currency_name) values ('ISK', 'Iceland Krona');
insert into currency_codes (iso, currency_name) values ('CSK', 'Czech Koruna');
insert into currency_codes (iso, currency_name) values ('CLP', 'Chilean Peso');
insert into currency_codes (iso, currency_name) values ('ARP', 'Argentinian Peso');
insert into currency_codes (iso, currency_name) values ('USD', 'United States Dollar');
insert into currency_codes (iso, currency_name) values ('PHP', 'Philippine Peso');
insert into currency_codes (iso, currency_name) values ('NZD', 'New Zealand Dollar');
insert into currency_codes (iso, currency_name) values ('MXP', 'Mexican Peso');
insert into currency_codes (iso, currency_name) values ('LUF', 'Luxembourg Franc');
insert into currency_codes (iso, currency_name) values ('INR', 'Indian Rupee');
insert into currency_codes (iso, currency_name) values ('IEP', 'Irish Punt');
insert into currency_codes (iso, currency_name) values ('GBP', 'British Pound');
insert into currency_codes (iso, currency_name) values ('FRF', 'French Franc');
insert into currency_codes (iso, currency_name) values ('EUR', 'Euro');
insert into currency_codes (iso, currency_name) values ('ESP', 'Spanish Peseta');
insert into currency_codes (iso, currency_name) values ('DKK', 'Danish Krone');
insert into currency_codes (iso, currency_name) values ('DEM', 'Deutsche Mark');
insert into currency_codes (iso, currency_name) values ('CHF', 'Swiss Franc');
insert into currency_codes (iso, currency_name) values ('CAD', 'Canadian Dollar');
insert into currency_codes (iso, currency_name) values ('BRR', 'Brazilian Real');
insert into currency_codes (iso, currency_name) values ('BEF', 'Belgian Franc');
insert into currency_codes (iso, currency_name) values ('AUD', 'Australian Dollar');
insert into currency_codes (iso, currency_name) values ('ATS', 'Austrian Schilling');

--
-- Set up the list of "valid currencies" as a smaller more sane list.
--
update currency_codes set supported_p = 'f';

update currency_codes set supported_p = 't' where iso in ('ATS','AUD',
       'BEF','BRR','CAD','CHF','DEM','DKK','ESP','EUR','FRF','GBP',
       'IEP','INR','LUF','MXP','NZD','PHP','USD','ARP','CLP','CSK',
       'ISK','VEB','ZAR');


--
-- Currency entities. 
--
-- set define off;

-- taken from http://www.askphil.org/auct03.htm
update currency_codes set html_entity = '&Ouml;Sch',
 fractional_digits = '2'
 where iso = 'ATS';
update currency_codes set html_entity = '$A',
 fractional_digits = '2'
 where iso = 'AUD';
update currency_codes set html_entity = 'BFr',
 fractional_digits = '2'
 where iso = 'BEF';
update currency_codes set html_entity = 'R',
 fractional_digits = '2'
 where iso = 'BRR';
update currency_codes set html_entity = '$C',
 fractional_digits = '2'
 where iso = 'CAD';
update currency_codes set html_entity = 'SFr',
 fractional_digits = '2'
 where iso = 'CHF';
update currency_codes set html_entity = 'DM',
 fractional_digits = '2'
 where iso = 'DEM';
update currency_codes set html_entity = 'DKr',
 fractional_digits = '2'
 where iso = 'DKK';
update currency_codes set html_entity = 'Pta',
 fractional_digits = '0'
 where iso = 'ESP';
update currency_codes set html_entity = '&euro;',
 fractional_digits = '2'
 where iso = 'EUR';
update currency_codes set html_entity = 'FFr',
 fractional_digits = '2'
 where iso = 'FRF';
update currency_codes set html_entity = '&pound;',
 fractional_digits = '2'
 where iso = 'GBP';
update currency_codes set html_entity = 'P',
 fractional_digits = '2'
 where iso = 'IEP';
update currency_codes set html_entity = 'R',
 fractional_digits = '2'
 where iso = 'INR';
update currency_codes set html_entity = 'LFr',
 fractional_digits = '2'
 where iso = 'LUF';
update currency_codes set html_entity = 'P',
 fractional_digits = '0'
 where iso = 'MXP';
update currency_codes set html_entity = '$NZ',
 fractional_digits = '2'
 where iso = 'NZD';
update currency_codes set html_entity = 'P',
 fractional_digits = '2'
 where iso = 'PHP';
update currency_codes set html_entity = '$',
 fractional_digits = '2'
 where iso = 'USD';
update currency_codes set html_entity = '&euro;',
 fractional_digits = '2'
 where iso = 'EUR';
update currency_codes set html_entity = 'P',
 fractional_digits = '2'
 where iso = 'ARP';
update currency_codes set html_entity = 'P',
 fractional_digits = '2'
 where iso = 'CLP';
update currency_codes set html_entity = 'K',
 fractional_digits = '2'
 where iso = 'CSK';
update currency_codes set html_entity = 'IKr',
 fractional_digits = '2'
 where iso = 'ISK';
update currency_codes set html_entity = 'Bs',
 fractional_digits = '2'
 where iso = 'VEB';
update currency_codes set html_entity = 'R',
 fractional_digits = '2'
 where iso = 'ZAR';

end;

