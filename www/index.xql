<?xml version="1.0"?>
<queryset>
  <fullquery name="user_name_select">
    <querytext>

	select first_names || ' ' || last_name as name, email
	from persons, parties
	where person_id = :user_id
	and person_id = party_id

    </querytext>
  </fullquery>

</queryset>
