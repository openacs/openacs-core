-- Change the trigger so if last_modified is null on the update the old modified date is
-- preserved.

drop function acs_objects_last_mod_update_tr() cascade;

create function acs_objects_last_mod_update_tr () returns opaque as '
begin
  if new.last_modified is null then
     new.last_modified := old.last_modified;
  elsif new.last_modified = old.last_modified then
     new.last_modified := now();
  end if;
  return new;
end;' language 'plpgsql';

create trigger acs_objects_last_mod_update_tr before update on acs_objects
for each row execute procedure acs_objects_last_mod_update_tr ();
