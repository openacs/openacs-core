-- Drop all_users since it masks the oracle all_users view (used by
-- third party admin tools among other things)

drop view all_users;

create or replace view acs_users_all
as
select pa.*, pe.*, u.*
from  parties pa, persons pe, users u
where  pa.party_id = pe.person_id
and pe.person_id = u.user_id;


-- we do case folded searches on these...
create index users_username_lower_idx on users(lower(username));
create index users_screenname_lower_idx on users(lower(screen_name));
create index parties_email_lower_idx on parties(lower(email));
