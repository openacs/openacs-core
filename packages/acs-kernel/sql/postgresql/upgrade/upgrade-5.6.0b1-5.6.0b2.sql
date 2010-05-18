create index acs_objects_package_idx on acs_objects (package_id);
drop index acs_objects_package_object_idx;

-- This is necessary because a previous upgrade script didn't recreate these views.
-- The bio code didn't use this views, but they should be created for future use
-- and consistency.

-- Unfortunately, there are some obscure views build on cc_users, so it can not
-- be dropped.  PG replace view does not allow for changing the view columns so
-- we can not replace it, either.

drop view acs_users_all;
create view acs_users_all
as
select pa.*, pe.*, u.*
from  parties pa, persons pe, users u
where  pa.party_id = pe.person_id
and pe.person_id = u.user_id;

