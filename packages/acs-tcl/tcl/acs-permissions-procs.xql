<?xml version="1.0"?>
<queryset>

<fullquery name="ad_permission_p.n_privs">      
      <querytext>
      
      select count(*)
        from acs_privileges
       where privilege = :privilege
  
      </querytext>
</fullquery>

 
</queryset>
