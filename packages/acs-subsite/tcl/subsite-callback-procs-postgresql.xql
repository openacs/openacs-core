<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>9.6</version></rdbms>
   

<fullquery name="subsite::callback.get_callbacks">      
<querytext>
        with recursive object_hierarchy(object_type, supertype) as (
            select object_type, supertype
              from acs_object_types
             where object_type = coalesce(:object_type, (select object_type
                                                         from acs_objects
                                                         where object_id = :object_id))

            union all

            select t.object_type, t.supertype
            from acs_object_types t,
                 object_hierarchy s
            where t.object_type = s.supertype
        )
        select distinct callback, callback_type as type
          from subsite_callbacks
        where event_type = :event_type
          and object_type in (select object_type from object_hierarchy)
</querytext>
</fullquery>

</queryset>
