<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="package_exists">      
      <querytext>
      
    select case when exists (select 1 
                               from user_objects o
                              where o.object_type='PACKAGE' 
                                and o.object_name = upper(:package_name))
           then 1 else 0 end
      

      </querytext>
</fullquery>

 
<fullquery name="type_exists">      
      <querytext>
      
    select case when exists (select 1 from acs_object_types t where t.object_type = :group_type)
                then 1
                else 0
           end
      

      </querytext>
</fullquery>

 
</queryset>
