<?xml version="1.0"?>
<queryset>

<fullquery name="permissions_in_db">      
      <querytext>

        select grantee_id, privilege
        from   acs_permissions
        where  object_id = :object_id
        and    privilege in ('[join $privs "', '"]')

      </querytext>
</fullquery>
 
</queryset>
