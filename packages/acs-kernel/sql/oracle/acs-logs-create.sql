--
-- packages/acs-kernel/sql/acs-logs-create.sql
--
-- @author rhs@mit.edu
-- @creation-date 2000-10-02
-- @cvs-id $Id$
--

create sequence acs_log_id_seq;

create table acs_logs (
	log_id		integer
			constraint acs_logs_pk
			primary key,
	log_date	date default sysdate not null,
	log_level	varchar2(20)
			constraint acs_logs_log_level_ck
			check (log_level in ('notice', 'warn', 'error',
					     'debug')),
	log_key		varchar2(100) not null,
	message		varchar2(4000) not null
);

create or replace package acs_log
as

  procedure notice (
    log_key	in acs_logs.log_key%TYPE,
    message	in acs_logs.message%TYPE
  );

  procedure warn (
    log_key	in acs_logs.log_key%TYPE,
    message	in acs_logs.message%TYPE
  );

  procedure error (
    log_key	in acs_logs.log_key%TYPE,
    message	in acs_logs.message%TYPE
  );

  procedure debug (
    log_key	in acs_logs.log_key%TYPE,
    message	in acs_logs.message%TYPE
  );

end;
/
show errors

create or replace package body acs_log
as

  procedure notice (
    log_key	in acs_logs.log_key%TYPE,
    message	in acs_logs.message%TYPE
  )
  is
  begin
    insert into acs_logs
     (log_id, log_level, log_key, message)
    values
     (acs_log_id_seq.nextval, 'notice', notice.log_key, notice.message);
  end;

  procedure warn (
    log_key	in acs_logs.log_key%TYPE,
    message	in acs_logs.message%TYPE
  )
  is
  begin
    insert into acs_logs
     (log_id, log_level, log_key, message)
    values
     (acs_log_id_seq.nextval, 'warn', warn.log_key, warn.message);
  end;

  procedure error (
    log_key	in acs_logs.log_key%TYPE,
    message	in acs_logs.message%TYPE
  )
  is
  begin
    insert into acs_logs
     (log_id, log_level, log_key, message)
    values
     (acs_log_id_seq.nextval, 'error', error.log_key, error.message);
  end;

  procedure debug (
    log_key	in acs_logs.log_key%TYPE,
    message	in acs_logs.message%TYPE
  )
  is
  begin
    insert into acs_logs
     (log_id, log_level, log_key, message)
    values
     (acs_log_id_seq.nextval, 'debug', debug.log_key, debug.message);
  end;

end;
/
show errors
