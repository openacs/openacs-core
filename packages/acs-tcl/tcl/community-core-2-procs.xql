<?xml version="1.0"?>
<queryset>

<fullquery name="oacs::user::get.select_user">
<querytext>
select user_id, screen_name, last_visit, second_to_last_visit,
first_names, last_name, email, first_names || ' ' || last_name as full_name
from users, parties, persons
where 
users.user_id = parties.party_id and
users.user_id = persons.person_id and
user_id= :user_id
</querytext>
</fullquery>
 
</queryset>
