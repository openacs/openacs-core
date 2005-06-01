<?xml version="1.0"?>
<queryset>
<rdbms><type>oracle</type><version>8.0</version></rdbms>

<fullquery name="application_link::new.create_forward_link">
    <querytext>
		    begin
		    :1 = acs_rel.new (
				      rel_id => null,
				      rel_type => 'application_link',
				      object_id_one => :this_package_id,
				      object_id_two => :target_package_id,
				      context_id => :this_package_id,
				      creation_user => :user_id,
				      creation_ip => :id_addr
				      );
		    end;
    </querytext>
</fullquery>

<fullquery name="application_link::new.create_backward_link">
    <querytext>
		    begin
		    :1 = acs_rel.new (
				      rel_id => null,
				      rel_type => 'application_link',
				      object_id_one => :target_package_id,
				      object_id_two => :this_package_id,
				      context_id => :this_package_id,
				      creation_user => :user_id,
				      creation_ip => :id_addr
				      );
		    end;
    </querytext>
</fullquery>

</queryset>
