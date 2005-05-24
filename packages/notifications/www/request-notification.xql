<?xml version="1.0"?>
<queryset>

    <fullquery name="notify_users">
        <querytext>
        select p.first_names || ' ' || p.last_name as name,nr.request_id,
        (select name from notification_intervals where interval_id=
        nr.interval_id) as interval_name ,(select short_name from
        notification_delivery_methods where
        delivery_method_id=nr.delivery_method_id) as delivery_name
                                  from persons p, notification_requests nr
                                  where p.person_id = nr.user_id and
                                  nr.object_id = :object_id and
				  nr.type_id = :type_id

        </querytext>
    </fullquery>
    
    <fullquery name="get_user">
        <querytext>
           select party_approved_member_map.member_id as user_id 
	   from party_approved_member_map, group_member_map 
	   where group_member_map.member_id = party_approved_member_map.member_id 
	   and party_id = :party_id
        </querytext>
    </fullquery>
    
     <fullquery name="get_type_object">
        <querytext>
           select object_type 
	   from acs_objects 
	   where object_id = :object_id
        </querytext>
    </fullquery>
    
    <fullquery name="get_name_notification">
        <querytext>
           select pretty_name 
	   from notification_types 
	   where type_id = :type_id
        </querytext>
    </fullquery>
    
    <fullquery name="get_member_id">
        <querytext>
           select member_id as user_id 
	   from group_member_map 
	   where group_id = :group_id
        </querytext>
    </fullquery>
    
    <fullquery name="get_user_name">
        <querytext>
           select username 
	   from users 
	   where user_id = :party_id
        </querytext>
    </fullquery>
</queryset>
