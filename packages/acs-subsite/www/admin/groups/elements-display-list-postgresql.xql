<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="rel_type_info">      
      <querytext>
      FIX ME CONNECT BY

    select object_type as ancestor_rel_type
      from acs_object_types
     where supertype = 'relationship'
       and object_type in (
               select object_type from acs_object_types
               start with object_type = :rel_type
               connect by object_type = prior supertype
           )

      </querytext>
</fullquery>

 
</queryset>
