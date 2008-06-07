-- packages/acs-lang/sql/postgresql/upgrade/upgrade-5.4.1d2-5.4.1d3.sql
--

alter table user_preferences add constraint user_preferences_locale_fk foreign key (locale) references ad_locales(locale);
