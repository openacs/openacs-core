<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="permission::grant.grant_permission">
        <querytext>
            declare
            begin
                acs_permission.grant_permission(
                    object_id => :object_id,
                    grantee_id => :party_id,
                    privilege => :privilege
                );
            end;
        </querytext>
    </fullquery>

    <fullquery name="permission::revoke.revoke_permission">
        <querytext>
            declare
            begin
                acs_permission.revoke_permission(
                    object_id => :object_id,
                    grantee_id => :party_id,
                    privilege => :privilege
                );
            end;
        </querytext>
    </fullquery>

    <fullquery name="permission::require_permission.name">      
        <querytext>
            select acs_object.name(:object_id)
            from dual
        </querytext>
    </fullquery>

    <fullquery name="permission::toggle_inherit.toggle_inherit">
        <querytext>
            update acs_objects
            set security_inherit_p = case when security_inherit_p = 't'
                                          then 'f'
                                          else 't'
                                     end
            where object_id = :object_id
        </querytext>
    </fullquery>

</queryset>
