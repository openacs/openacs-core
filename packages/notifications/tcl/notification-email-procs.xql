<?xml version="1.0"?>
<queryset>

  <fullquery name="notification::email::send.get_person">
    <querytext>
       select first_names, last_name
       from persons
       where person_id = :from_user_id
    </querytext>
  </fullquery>

</queryset>

