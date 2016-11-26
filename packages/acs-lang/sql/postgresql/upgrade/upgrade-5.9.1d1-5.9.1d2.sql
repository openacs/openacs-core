

DO $$
DECLARE
        v_found boolean;
BEGIN
        --
        -- Was the index already created?
        --
        SELECT exists(
           SELECT relname from pg_class
           WHERE relname ='ad_locale_user_prefs_user_id_idx'
        ) into v_found;
        
        if v_found IS FALSE then
	   --
	   -- create index for user preferences for locales
	   --
           create index ad_locale_user_prefs_user_id_idx on ad_locale_user_prefs(user_id);
        end if;
END $$;
