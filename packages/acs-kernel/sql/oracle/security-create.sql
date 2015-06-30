--
-- /packages/acs-kernel/sql/security-create.sql
--
-- ACS Security data model
--
-- @author Jon Salz (jsalz@mit.edu)
-- @author Kai Wu (kai@arsdigita.com)
-- @author Richard Li (richardl@arsdigita.com)
--
-- @creation-date 2000/02/02
-- @cvs-id $Id$

create table sec_session_properties (
    session_id     integer
                   constraint sec_session_prop_session_id_nn
                   not null,
    module         varchar2(50)
                   constraint sec_session_prop_module_nn
                   not null,
    property_name  varchar2(50) 
                   constraint sec_session_prop_prop_name_nn
                   not null,
    property_value varchar2(4000),
    property_clob  clob default null,
    -- transmitted only across secure connections?
    secure_p       char(1) 
                   constraint sec_session_prop_secure_p_ck
                   check(secure_p in ('t','f')),
    last_hit	   integer
                   constraint sec_session_date_nn
                   not null,
    constraint sec_session_prop_pk primary key(session_id, module, property_name)
) nologging storage (
      initial 50m
      next 50m
      pctincrease 0) 
  parallel;

create index sec_property_names on sec_session_properties(property_name);

create table secret_tokens (
    token_id                    integer
                                constraint secret_tokens_token_id_pk primary key,
    token                       char(40),
    token_timestamp		date
);

create sequence sec_security_token_id_seq cache 100;

-- Due to the nature of DDL, the increment by 100 parameter needs to
-- be hard-coded into the sec_allocate_session procedure. Don't change
-- the increment here without changing the procedure!

create sequence sec_id_seq cache 100 increment by 100;


create or replace package sec_session_property
as
    procedure upsert (
       p_session_id in sec_session_properties.session_id%TYPE,
       p_module     in sec_session_properties.module%TYPE,
       p_name       in sec_session_properties.property_name%TYPE,
       p_value      in sec_session_properties.property_value%TYPE,
       p_secure_p   in sec_session_properties.secure_p%TYPE,
       p_last_hit   in sec_session_properties.last_hit%TYPE
    );
end sec_session_property;
/
show errors

create or replace package body sec_session_property
as
    procedure upsert(
       p_session_id in sec_session_properties.session_id%TYPE,
       p_module     in sec_session_properties.module%TYPE,
       p_name       in sec_session_properties.property_name%TYPE,
       p_value      in sec_session_properties.property_value%TYPE,
       p_secure_p   in sec_session_properties.secure_p%TYPE,
       p_last_hit   in sec_session_properties.last_hit%TYPE
    )
    is
    BEGIN
	insert into sec_session_properties
		(session_id, module, property_name, secure_p, last_hit)
	values (p_session_id, p_module, p_name, p_secure_p, p_last_hit);
    exception
        when dup_val_on_index then
	     update sec_session_properties
             set property_value = p_value,
	           secure_p = p_secure_p,
		   last_hit = p_last_hit 
             where
		session_id = p_session_id and
		module = p_module and
		property_name = p_name;
   END upsert;

end sec_session_property;
/
show errors
