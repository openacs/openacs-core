declare
  v_table_exists_p integer;
begin
	select count(*) into v_table_exists_p 
	from user_objects 
        where object_name = 'AD_LOCALE_USER_PREFS';

	if v_table_exists_p = 0 then
                -- Need to create table
                execute immediate 'create table ad_locale_user_prefs (
                  user_id               integer
                                        constraint ad_locale_user_prefs_users_fk
                                        references users (user_id) on delete cascade,
                  package_id            integer
                                        constraint lang_package_l_u_package_id_fk
                                        references apm_packages(package_id) on delete cascade,
                  locale                varchar(30) not null
                                        constraint trb_language_preference_lid_fk
                                        references ad_locales (locale) on delete cascade
                )';                              
	end if;

end;
/
show errors
