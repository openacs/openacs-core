--
-- packages/acs-kernel/sql/acs-logs-create.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-10-02
-- @cvs-id $Id$
--

create sequence t_acs_log_id_seq;
create view acs_log_id_seq as
select nextval('t_acs_log_id_seq') as nextval;

create table acs_logs (
	log_id		integer
			constraint acs_logs_log_id_pk
			primary key,
	log_date	timestamptz default current_timestamp not null,
	log_level	varchar(20) not null
			constraint acs_logs_log_level_ck
			check (log_level in ('notice', 'warn', 'error',
					     'debug')),
	log_key		varchar(100) not null,
	message		text not null
);

-- create or replace package acs_log
-- as
-- 
--   procedure notice (
--     log_key	in acs_logs.log_key%TYPE,
--     message	in acs_logs.message%TYPE
--   );
-- 
--   procedure warn (
--     log_key	in acs_logs.log_key%TYPE,
--     message	in acs_logs.message%TYPE
--   );
-- 
--   procedure error (
--     log_key	in acs_logs.log_key%TYPE,
--     message	in acs_logs.message%TYPE
--   );
-- 
--   procedure debug (
--     log_key	in acs_logs.log_key%TYPE,
--     message	in acs_logs.message%TYPE
--   );
-- 
-- end;

-- show errors

-- create or replace package body acs_log
-- procedure notice


-- added
select define_function_args('acs_log__notice','log_key,message');

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


-- procedure warn


-- added
select define_function_args('acs_log__warn','log_key,message');

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


-- procedure error


-- added
select define_function_args('acs_log__error','log_key,message');

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


-- procedure debug


-- added
select define_function_args('acs_log__debug','log_key,message');

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



-- show errors
