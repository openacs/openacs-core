<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="ad_permission_p.result">
<querytext>
    select count(*)
      from dual
     where acs_permission__permission_p(:object_id, :user_id, :privilege) =
't'
</querytext>
</fullquery>

<fullquery name="ad_require_permission.name">      
      <querytext>
      select acs_object__name(:object_id)
      </querytext>
</fullquery>

 
</queryset>
