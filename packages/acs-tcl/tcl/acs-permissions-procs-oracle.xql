<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="ad_permission_p.result">      
      <querytext>
      
    select count(*) 
      from dual
     where acs_permission.permission_p(:object_id, :user_id, :privilege) = 't'
  
      </querytext>
</fullquery>

 
<fullquery name="ad_require_permission.name">      
      <querytext>
      select acs_object.name(:object_id) from dual
      </querytext>
</fullquery>

 
</queryset>
