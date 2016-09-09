CREATE or REPLACE FUNCTION inline_0 ()
returns integer as $$
DECLARE
   v_dummy integer;
BEGIN
    SELECT 1 FROM pg_views WHERE viewname = 'anon_func_seq' INTO v_dummy;
    IF found THEN

        DROP VIEW IF EXISTS anon_func_seq;
        IF EXISTS (SELECT 0 FROM pg_class WHERE relname = 't_anon_func_seq' ) THEN
            ALTER SEQUENCE t_anon_func_seq RENAME TO anon_func_seq;
        END IF;

   END IF;
   return 1;
END;
$$ language plpgsql;

select inline_0();
drop function inline_0();
