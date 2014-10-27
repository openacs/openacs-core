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
    session_id     bigint
                   constraint sec_session_prop_session_id_nn
                   not null,
    module         varchar(50)
                   constraint sec_session_prop_module_nn
                   not null,
    property_name  varchar(50) 
                   constraint sec_session_prop_prop_name_nn
                   not null,
    property_value text,
    -- transmitted only across secure connections?
    secure_p       boolean,
    last_hit	   integer
                   constraint sec_session_date_nn
                   not null,
    constraint sec_session_prop_pk primary key(session_id, module, property_name)
);

create index sec_property_names on sec_session_properties(property_name);

create table secret_tokens (
    token_id                    integer
                                constraint secret_tokens_token_id_pk primary key,
    token                       char(40),
    token_timestamp             timestamptz
);

create sequence t_sec_security_token_id_seq cache 100;
create view sec_security_token_id_seq as
select nextval('t_sec_security_token_id_seq') as nextval;

-- Due to the nature of DDL, the increment by 100 parameter needs to
-- be hard-coded into the sec_allocate_session procedure. Don't change
-- the increment here without changing the procedure!

create sequence t_sec_id_seq cache 100 increment 100;
create view sec_id_seq as
select nextval('t_sec_id_seq') as nextval;
