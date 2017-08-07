<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="all_subprograms">      
      <querytext>

    select object_type as type, object_name as name, 0 as nargs
    from user_objects
    where object_type in ('PACKAGE', 'PROCEDURE', 'FUNCTION')
    order by
    decode(object_type, 'PACKAGE', 0, 'PROCEDURE', 1, 'FUNCTION', 2) asc
    
      </querytext>
</fullquery>

 
</queryset>
