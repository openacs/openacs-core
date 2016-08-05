create or replace function inline_0 ()
returns integer as $$
DECLARE
   v_dummy integer;
BEGIN
   select setting from pg_settings where name='server_version_num' and setting::int >= 90200 into v_dummy;
   IF found THEN

        select 1 from pg_views where viewname = 'anon_func_seq' into v_dummy;
	IF found THEN
      	   drop view IF EXISTS anon_func_seq;
   	   ALTER SEQUENCE IF EXISTS t_anon_func_seq RENAME TO anon_func_seq;
	END IF;

   ELSE
	-- verison earlier than 9.2, no "IF EXISTS" for ALTER SEQUENCE
        select 1 from pg_views where viewname = 'anon_func_seq' into v_dummy;
	IF found THEN
	   drop view anon_func_seq;
      	   ALTER SEQUENCE t_anon_func_seq RENAME TO anon_func_seq;
	END IF;

   END IF;
   return 1;
END;
$$ language 'plpgsql';

select inline_0();
drop function inline_0();

