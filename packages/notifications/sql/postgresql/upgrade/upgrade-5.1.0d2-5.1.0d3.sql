-- 
-- packages/notifications/sql/postgresql/upgrade/upgrade-5.1.0d2-5.1.0d3.sql
-- 
-- @author Stan Kaufman (skaufman@epimetrics.com)
-- @creation-date 2004-07-08
-- @cvs-id $Id$
--
-- based on Peter's upgrade script:
-- Add on delete cascade foreign key constraints
-- see Bug http://openacs.org/bugtracker/openacs/bug?filter%2estatus=resolved&filter%2eactionby=6815&bug%5fnumber=260
-- @author Peter Marklund

create or replace function safe_drop_cosntraint(name, name)
returns integer as '
declare
    p_table_name          alias for $1;
    p_constraint_name     alias for $2;
    v_constraint_p        integer;
begin
    select count(*)
    into   v_constraint_p
    from   pg_constraint con, pg_class c
    where  con.conname = p_constraint_name
    and    c.oid = con.conrelid
    and    c.relname = p_table_name;

    if v_constraint_p > 0 then
        execute ''alter table '' || p_table_name || '' drop constraint '' || p_constraint_name;
    end if;

    return 0;
end;' language 'plpgsql';

-- Add on delete cascade to notifications.notif_notif_id_fk foreign key constraint

select safe_drop_cosntraint('notifications', 'notif_notif_id_fk');

alter table notifications add constraint notif_notif_id_fk
                              foreign key (object_id)
                              references acs_objects (object_id)
                              on delete cascade;

-- Add on delete cascade to notification_requests.notif_request_id_fk foreign key constraint

select safe_drop_cosntraint('notification_requests', 'notif_request_id_fk');

alter table notification_requests add constraint notif_request_id_fk
                              foreign key (object_id)
                              references acs_objects (object_id)
                              on delete cascade;

drop function safe_drop_cosntraint(name, name);

