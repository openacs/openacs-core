<?xml version="1.0"?>
<queryset>

<fullquery name="name_get">      
      <querytext>
      select first_names, last_name, email, url from persons, parties where persons.person_id = parties.party_id and party_id =:user_id
      </querytext>
</fullquery>

 
</queryset>
