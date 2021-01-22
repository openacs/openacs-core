-- Add on delete cascade to the notifications.response_id column foreign key constraint
-- see Bug http://openacs.org/bugtracker/openacs/bug?filter%2estatus=resolved&filter%2eactionby=6815&bug%5fnumber=260
-- @author Peter Marklund



-- added
select define_function_args('safe_drop_cosntraint','table_name,constraint_name');

--
-- procedure safe_drop_cosntraint/2
--
CREATE OR REPLACE FUNCTION safe_drop_cosntraint(
   p_table_name name,
   p_constraint_name name
) RETURNS integer AS $$
DECLARE
    v_constraint_p        integer;
BEGIN
    select count(*)
    into   v_constraint_p
    from   pg_constraint con, pg_class c
    where  con.conname = p_constraint_name
    and    c.oid = con.conrelid
    and    c.relname = p_table_name;

    if v_constraint_p > 0 then
        execute 'alter table ' || p_table_name || ' drop constraint ' || p_constraint_name;
    end if;

    return 0;
END;
$$ LANGUAGE plpgsql;

select safe_drop_cosntraint('notifications', 'notif_response_id_fk');

alter table notifications add constraint notif_response_id_fk
                              foreign key (response_id)
                              references acs_objects (object_id)
                              on delete cascade;

-- Add on delete cascade to notification_user_map.notification_in foreign key constraint

select safe_drop_cosntraint('notification_user_map', 'notif_user_map_notif_id_fk');

alter table notification_user_map add constraint notif_user_map_notif_id_fk 
                                      foreign key (notification_id) 
                                      references notifications(notification_id) 
                                      on delete cascade;

drop function safe_drop_cosntraint(name, name);

