-- 
-- Upgrade script from 5.0d6 to 5.0d7
--
-- Adds auth_token to users table
-- Recreating acs_object__update_last_modified triggers
--
-- @author Lars Pind (lars@collaboraid.biz)
--
-- @cvs-id $Id$
--

alter table users add auth_token varchar(100);

create or replace function acs_object__update_last_modified (integer, integer, varchar)
returns integer as '
declare
    acs_object__update_last_modified__object_id          alias for $1;
    acs_object__update_last_modified__modifying_user     alias for $2;
    acs_object__update_last_modified__modifying_ip       alias for $3;
begin
    return acs_object__update_last_modified(acs_object__update_last_modified__object_id, acs_object__update_last_modified__modifying_user, acs_object__update_last_modified__modifying_ip, now());
end;' language 'plpgsql';

create or replace function acs_object__update_last_modified (integer, integer, varchar, timestamptz)
returns integer as '
declare
    acs_object__update_last_modified__object_id          alias for $1; 
    acs_object__update_last_modified__modifying_user     alias for $2;
    acs_object__update_last_modified__modifying_ip       alias for $3;
    acs_object__update_last_modified__last_modified      alias for $4; -- default now()
    v_parent_id                                          integer;
    v_last_modified                                      timestamptz;
begin
    if acs_object__update_last_modified__last_modified is null then
        v_last_modified := now();
    else
        v_last_modified := acs_object__update_last_modified__last_modified;
    end if;

    update acs_objects
    set last_modified = v_last_modified,
        modifying_user = acs_object__update_last_modified__modifying_user,
        modifying_ip = acs_object__update_last_modified__modifying_ip
    where object_id = acs_object__update_last_modified__object_id;

    select context_id
    into v_parent_id
    from acs_objects
    where object_id = acs_object__update_last_modified__object_id;

    if v_parent_id is not null and v_parent_id != 0 then
        perform acs_object__update_last_modified(v_parent_id, acs_object__update_last_modified__modifying_user, acs_object__update_last_modified__modifying_ip, v_last_modified);
    end if;

    return acs_object__update_last_modified__object_id;
end;' language 'plpgsql';

