<?xml version="1.0"?>

<queryset>

    <fullquery name="get_notif_type">
    	<querytext>
	    select impl_name 
	    from acs_sc_impls, notification_types 
	    where type_id=:type_id 
	    and acs_sc_impls.impl_id=notification_types.sc_impl_id
	</querytext>
    </fullquery>
</queryset>