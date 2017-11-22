<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="user_contributions">      
      <querytext>
      select at.pretty_name, at.pretty_plural, a.creation_date, acs_object.name(a.object_id) object_name
from acs_objects a, acs_object_types at
where a.object_type = at.object_type
and a.creation_user = :user_id
order by pretty_name, creation_date desc, object_name
      </querytext>
</fullquery>
 
</queryset>
