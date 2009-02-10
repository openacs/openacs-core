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
create function acs_log__notice (varchar,varchar)
returns integer as '
declare
  notice__log_key                alias for $1;  
  notice__message                alias for $2;  
begin
    insert into acs_logs
     (log_id, log_level, log_key, message)
    values
     (nextval(''t_acs_log_id_seq''), ''notice'', notice__log_key, notice__message);

    return 0; 
end;' language 'plpgsql';


-- procedure warn
create function acs_log__warn (varchar,varchar)
returns integer as '
declare
  warn__log_key                alias for $1;  
  warn__message                alias for $2;  
begin
    insert into acs_logs
     (log_id, log_level, log_key, message)
    values
     (nextval(''t_acs_log_id_seq''), ''warn'', warn__log_key, warn__message);

    return 0; 
end;' language 'plpgsql';


-- procedure error
create function acs_log__error (varchar,varchar)
returns integer as '
declare
  error__log_key                alias for $1;  
  error__message                alias for $2;  
begin
    insert into acs_logs
     (log_id, log_level, log_key, message)
    values
     (nextval(''t_acs_log_id_seq''), ''error'', error__log_key, error__message);

    return 0; 
end;' language 'plpgsql';


-- procedure debug
create function acs_log__debug (varchar,varchar)
returns integer as '
declare
  debug__log_key                alias for $1;  
  debug__message                alias for $2;  
begin
    insert into acs_logs
     (log_id, log_level, log_key, message)
    values
     (nextval(''t_acs_log_id_seq''), ''debug'', debug__log_key, debug__message);

    return 0; 
end;' language 'plpgsql';



-- show errors
