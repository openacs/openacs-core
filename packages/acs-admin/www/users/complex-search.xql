<?xml version="1.0"?>
<queryset>
  
  <partialquery name="registration_before_days">      
    <querytext>
      date(creation_date) < current_date - cast(:registration_before_days as integer)
    </querytext>
  </partialquery>

  <partialquery name="registration_after_days">      
    <querytext>
      date(creation_date) >= current_date - cast(:registration_after_days as integer)
    </querytext>
  </partialquery>

  <partialquery name="last_visit_before_days">      
    <querytext>
      date(last_visit) < current_date - cast(:last_visit_before_days as integer)
    </querytext>
  </partialquery>

  <partialquery name="last_visit_after_days">      
    <querytext>
      date(last_visit) >= current_date - cast(:last_visit_after_days as integer)
    </querytext>
  </partialquery>
  
  <fullquery name="user_group_name_from_id">      
    <querytext>
      select group_name from groups where group_id = :limit_to_users_in_group_id
    </querytext>
  </fullquery>
 
</queryset>
