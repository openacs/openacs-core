<?xml version="1.0"?>
<queryset>
<rdbms><type>oracle</type><version>8.0</version></rdbms>

<fullquery name="application_data_link::new.create_forward_link">
    <querytext>
		    begin
		    :1 = acs_rel.new (
				      rel_id => null,
				      rel_type => 'application_data_link',
				      object_id_one => :this_object_id,
				      object_id_two => :target_object_id,
				      context_id => :this_object_id,
				      creation_user => :user_id,
				      creation_ip => :id_addr
				      );
		    end;
    </querytext>
</fullquery>

<fullquery name="application_data_link::new.create_backward_link">
    <querytext>
		    begin
		    :1 = acs_rel.new (
				      rel_id => null,
				      rel_type => 'application_data_link',
				      object_id_one => :target_object_id,
				      object_id_two => :this_object_id,
				      context_id => :this_object_id,
				      creation_user => :user_id,
				      creation_ip => :id_addr
				      );
		    end;
    </querytext>
</fullquery>

</queryset>
