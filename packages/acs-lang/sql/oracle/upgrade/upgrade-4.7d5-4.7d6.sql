-- We forgot to add the package_id column in the Oracle version of this
-- table
alter table ad_locale_user_prefs add  package_id integer
                                      constraint lang_package_l_u_package_id_fk
                                      references apm_packages(package_id) on delete cascade;
