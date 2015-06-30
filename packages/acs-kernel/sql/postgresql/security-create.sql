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


select define_function_args('sec_session_property__upsert','session_id,module,name,secure_p,last_hit');

CREATE OR REPLACE FUNCTION sec_session_property__upsert(
       p_session_id bigint,
       p_module varchar,
       p_name varchar,
       p_value varchar,
       p_secure_p boolean,
       p_last_hit integer
) RETURNS void as
$$
BEGIN
    LOOP
        -- first try to update the key
    update sec_session_properties
        set   property_value = p_value, secure_p = p_secure_p, last_hit = p_last_hit 
        where session_id = p_session_id and module = p_module and property_name = p_name;
        IF found THEN
            return;
        END IF;
        -- not there, so try to insert the key
        -- if someone else inserts the same key concurrently,
        -- we could get a unique-key failure
        BEGIN
            insert into sec_session_properties
                   (session_id,   module,   property_name, secure_p,   last_hit)
            values (p_session_id, p_module, p_name,        p_secure_p, p_last_hit);
            RETURN;
            EXCEPTION WHEN unique_violation THEN
            -- Do nothing, and loop to try the UPDATE again.
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql;







