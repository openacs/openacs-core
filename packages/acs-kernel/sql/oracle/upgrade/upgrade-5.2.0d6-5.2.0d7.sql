-- Change the trigger so if last_modified is null on the update the old modified date is
-- preserved.

create or replace trigger acs_objects_last_mod_update_tr
before update on acs_objects
for each row
begin
  if :new.last_modified is null then
     :new.last_modified := :old.last_modified;
  elsif :new.last_modified = :old.last_modified then
     :new.last_modified := sysdate;
  end if;
end acs_objects_last_mod_update_tr;
/
show errors
