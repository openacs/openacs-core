-- Fixing bug 895 by making acs__remove_user do what the Oracle version already does, i.e.
-- remove records referencing the user record before attempting to delete it.
--
-- @author Peter Marklund

-- Should have been added earlier, at least now we save the 4.6.3 - 5.0 upgrade
create view all_users
as
select pa.*, pe.*, u.*
from  parties pa, persons pe, users u
where  pa.party_id = pe.person_id
and pe.person_id = u.user_id;

drop function acs__remove_user (integer);
create function acs__remove_user (integer)
returns integer as '
declare
  remove_user__user_id                alias for $1;  
  v_rec           record;
begin
    delete
    from acs_permissions
    where grantee_id = remove_user__user_id;

    for v_rec in select rel_id
                 from acs_rels
                 where object_id_two = remove_user__user_id
    loop
        perform acs_rel__delete(v_rec.rel_id);
    end loop;

    perform acs_user__delete(remove_user__user_id);

    return 0; 
end;' language 'plpgsql';
