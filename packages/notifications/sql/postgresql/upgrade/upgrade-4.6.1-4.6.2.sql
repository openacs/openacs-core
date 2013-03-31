--
-- Upgrade script
-- 
-- Adds a dynamic_p column to notification_requests
--
-- @author Lars Pind (lars@pinds.com)
-- @creation-date 2003-02-06
--


-- add the column
alter table notification_requests add dynamic_p bool;

alter table notification_requests alter dynamic_p set default 'f';

update notification_requests set dynamic_p = 'f';



-- First, drop the old __new function
delete from acs_function_args where function = upper('notification_request__new');

drop function notification_request__new (
       integer,                       -- request_id
       varchar,                       -- object_type
       integer,                       -- type_id
       integer,                       -- user_id
       integer,                       -- object_id
       integer,                       -- interval_id
       integer,                       -- delivery_method_id
       varchar,                       -- format
       timestamp with time zone,      -- creation_date
       integer,                       -- creation_user
       varchar,                       -- creation_ip
       integer                        -- context_id
);

-- Then define the new one
select define_function_args ('notification_request__new','request_id,object_type;notification_request,type_id,user_id,object_id,interval_id,delivery_method_id,format,dynamic_p;f,creation_date,creation_user,creation_ip,context_id');

create or replace function notification_request__new (
       p_request_id integer,
       p_object_type varchar,
       p_type_id integer,
       p_user_id integer,
       p_object_id integer,
       p_interval_id integer,
       p_delivery_method_id integer,
       p_format varchar,
       p_dynamic_p bool,
       p_creation_date timestamp with time zone,
       p_creation_user integer,
       p_creation_ip varchar,
       p_context_id integer
) returns integer as $$
DECLARE
        v_request_id                            integer;
BEGIN
        v_request_id:= acs_object__new (
                                       p_request_id,
                                       p_object_type,
                                       p_creation_date,
                                       p_creation_user,
                                       p_creation_ip,
                                       p_context_id);

      insert into notification_requests
      (request_id, type_id, user_id, object_id, interval_id, delivery_method_id, format, dynamic_p) values
      (v_request_id, p_type_id, p_user_id, p_object_id, p_interval_id, p_delivery_method_id, p_format, p_dynamic_p);

      return v_request_id;                          
END;
$$ LANGUAGE plpgsql;


