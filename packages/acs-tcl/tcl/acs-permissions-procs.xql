<?xml version="1.0"?>

<queryset>

    <fullquery name="permission::inherit_p.select_inherit_p">
        <querytext>
            select case when security_inherit_p = 't' then 1 else 0 end
            from acs_objects
            where object_id = :object_id
        </querytext>
    </fullquery>
 
    <fullquery name="permission::set_inherit.set_inherit">
        <querytext>
            update acs_objects
            set security_inherit_p = 't'
            where object_id = :object_id
        </querytext>
    </fullquery>
 
    <fullquery name="permission::set_not_inherit.set_not_inherit">
        <querytext>
            update acs_objects
            set security_inherit_p = 'f'
            where object_id = :object_id
        </querytext>
    </fullquery>
 
</queryset>
