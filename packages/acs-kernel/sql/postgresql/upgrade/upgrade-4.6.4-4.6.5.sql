-- Add user id and IP address to update_last_modified()
-- $Id

create or replace function acs_object__update_last_modified (integer, integer, integer)
returns integer as '
declare
    acs_object__update_last_modified__object_id          alias for $1;
    acs_object__update_last_modified__modifying_user     alias for $2;
    acs_object__update_last_modified__modifying_ip       alias for $3;
begin
    return acs_object__update_last_modified(acs_object__update_last_modified__object_id, acs_object__update_last_modified__modifying_user, acs_object__update_last_modified__modifying_ip, now());
end;' language 'plpgsql';

create or replace function acs_object__update_last_modified (integer, integer, integer, timestamptz)
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

