<?xml version="1.0"?>
<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="permission::grant.grant_permission">
        <querytext>
                select acs_permission__grant_permission(
                    :object_id,
                    :party_id,
                    :privilege
                );
        </querytext>
    </fullquery>

    <fullquery name="permission::revoke.revoke_permission">
        <querytext>
             select acs_permission__revoke_permission(
                    :object_id,
                    :party_id,
                    :privilege
                );
        </querytext>
    </fullquery>

    <fullquery name="permission::toggle_inherit.toggle_inherit">
        <querytext>
            update acs_objects
            set security_inherit_p = not security_inherit_p
            where object_id = :object_id
        </querytext>
    </fullquery>

    <fullquery name="permission::get_parties_with_permission.get_parties">
      <querytext>
        select distinct o.title, p.party_id
        from acs_permission.parties_with_object_privilege(:object_id, :privilege) p, acs_objects o
        where p.party_id = o.object_id
      </querytext>
    </fullquery>
    
</queryset>
