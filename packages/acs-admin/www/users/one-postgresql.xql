<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="user_contributions">      
      <querytext>
      select at.pretty_name, at.pretty_plural, to_char(a.creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date,
          acs_object__name(a.object_id) as object_name
      from acs_objects a, acs_object_types at
      where a.object_type = at.object_type
          and a.creation_user = :user_id
      order by pretty_name, creation_date desc, object_name
      </querytext>
</fullquery>

 
</queryset>
