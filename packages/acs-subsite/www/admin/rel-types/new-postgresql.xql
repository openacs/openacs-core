<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_supertypes">      
      <querytext>
      FIX ME CONNECT BY

    select replace(lpad(' ', (level - 1) * 4), ' ', '&nbsp;') || t.pretty_name as name,
           t.object_type
      from acs_object_types t
   connect by prior t.object_type = t.supertype
     start with t.object_type in ('membership_rel','composition_rel')

      </querytext>
</fullquery>

 
</queryset>
