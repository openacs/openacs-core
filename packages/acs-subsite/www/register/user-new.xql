<?xml version="1.0"?>
<queryset>

<fullquery name="find_person">      
   <querytext>
      select parties.party_id as user_id, persons.first_names, persons.last_name
      from parties, persons
      where parties.party_id = persons.person_id
        and parties.email = lower(:email)
   </querytext>
</fullquery>
 
</queryset>
