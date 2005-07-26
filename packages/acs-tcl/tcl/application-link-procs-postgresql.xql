<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.2</version></rdbms>

<fullquery name="application_link::new.create_forward_link">
    <querytext>
		    select acs_rel__new (
					 null,
					 'application_link',
					 :this_package_id,
					 :target_package_id,
					 :this_package_id,
					 :user_id,
					 :id_addr
					 )
    </querytext>
</fullquery>

<fullquery name="application_link::new.create_backward_link">
    <querytext>
		    select acs_rel__new (
					 null,
					 'application_link',
					 :target_package_id,
					 :this_package_id,
					 :this_package_id,
					 :user_id,
					 :id_addr
					 )
    </querytext>
</fullquery>

</queryset>
