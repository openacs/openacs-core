-- providing missing upgrade script in order to get rid of 
-- syntax seq_foo.nextval

--
-- procedure acs_log__notice/2
--
CREATE OR REPLACE FUNCTION acs_log__notice(
   notice__log_key varchar,
   notice__message varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    insert into acs_logs
     (log_id, log_level, log_key, message)
    values
     (nextval('t_acs_log_id_seq'), 'notice', notice__log_key, notice__message);

    return 0; 
END;
$$ LANGUAGE plpgsql;


--
-- procedure acs_log__warn/2
--
CREATE OR REPLACE FUNCTION acs_log__warn(
   warn__log_key varchar,
   warn__message varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    insert into acs_logs
     (log_id, log_level, log_key, message)
    values
     (nextval('t_acs_log_id_seq'), 'warn', warn__log_key, warn__message);

    return 0; 
END;
$$ LANGUAGE plpgsql;


--
-- procedure acs_log__error/2
--
CREATE OR REPLACE FUNCTION acs_log__error(
   error__log_key varchar,
   error__message varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    insert into acs_logs
     (log_id, log_level, log_key, message)
    values
     (nextval('t_acs_log_id_seq'), 'error', error__log_key, error__message);

    return 0; 
END;
$$ LANGUAGE plpgsql;


--
-- procedure acs_log__debug/2
--
CREATE OR REPLACE FUNCTION acs_log__debug(
   debug__log_key varchar,
   debug__message varchar
) RETURNS integer AS $$
DECLARE
BEGIN
    insert into acs_logs
     (log_id, log_level, log_key, message)
    values
     (nextval('t_acs_log_id_seq'), 'debug', debug__log_key, debug__message);

    return 0; 
END;
$$ LANGUAGE plpgsql;
