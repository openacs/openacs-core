<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.2</version></rdbms>

<fullquery name="application_data_link::new.create_forward_link">
    <querytext>
		    select acs_rel__new (
					 null,
					 'application_data_link',
					 :this_object_id,
					 :target_object_id,
					 :this_object_id,
					 :user_id,
					 :id_addr
					 )
    </querytext>
</fullquery>

<fullquery name="application_data_link::new.create_backward_link">
    <querytext>
		    select acs_rel__new (
					 null,
					 'application_data_link',
					 :target_object_id,
					 :this_object_id,
					 :this_object_id,
					 :user_id,
					 :id_addr
					 )
    </querytext>
</fullquery>

</queryset>
