-- We now allow for three character language codes
create table temp as select * from ad_locales;
drop table ad_locales;
create table ad_locales (
  locale		varchar(30)
                        constraint ad_locale_abbrev_pk
                        primary key,
  language		char(3) 
                        constraint ad_language_name_nil
			not null,
  country		char(2) 
                        constraint ad_country_name_nil
			not null,
  variant		varchar(30),
  label			varchar(200)
                        constraint ad_locale_name_nil
			not null
                        constraint ad_locale_name_unq
                        unique,
  nls_language		varchar(30)
                        constraint ad_locale_nls_lang_nil
			not null,
  nls_territory		varchar(30),
  nls_charset		varchar(30),
  mime_charset		varchar(30),
  -- is this the default locale for its language
  default_p             boolean default 'f'
);
insert into ad_locales select * from temp;
drop table temp;
