<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="rel_type_info">      
      <querytext>
      
    select object_type as ancestor_rel_type
      from acs_object_types
     where supertype = 'relationship'
       and object_type in (
               select object_type from acs_object_types
               start with object_type = :add_with_rel_type
               connect by object_type = prior supertype
           )

      </querytext>
</fullquery>

 
</queryset>
