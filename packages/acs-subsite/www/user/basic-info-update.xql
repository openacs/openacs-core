<?xml version="1.0"?>
<queryset>

<fullquery name="general_info">      
      <querytext>
      select first_names, last_name, email, 
      case when url is null then 'http://' else url end as url,
      screen_name
      from cc_users 
      where user_id=:user_id
      </querytext>
</fullquery>

 
<fullquery name="biography">      
      <querytext>
      
select attr_value
from acs_attribute_values
where object_id = :user_id
and attribute_id =
   (select attribute_id
    from acs_attributes
    where object_type = 'person'
    and attribute_name = 'bio')
      </querytext>
</fullquery>

 
</queryset>
