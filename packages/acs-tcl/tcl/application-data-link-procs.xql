<?xml version="1.0"?>
<queryset>

<fullquery name="application_data_link::new.create_forward_link">
    <querytext>
	    insert into acs_data_links (rel_id, object_id_one, object_id_two)
	    values (:forward_rel_id, :this_object_id, :target_object_id)
    </querytext>
</fullquery>

<fullquery name="application_data_link::new.create_backward_link">
    <querytext>
	    insert into acs_data_links (rel_id, object_id_one, object_id_two)
	    values (:backward_rel_id, :target_object_id, :this_object_id)
    </querytext>
</fullquery>

<fullquery name="application_data_link::delete_links.linked_objects">
    <querytext>
	    select rel_id
	    from acs_data_links
	    where (object_id_one = :object_id
		 or object_id_two = :object_id)
    </querytext>
</fullquery>

<fullquery name="application_data_link::delete_links.delete_link">
    <querytext>
	    delete from acs_data_links
	    where rel_id = :rel_id
    </querytext>
</fullquery>

<fullquery name="application_data_link::get.linked_objects">
    <querytext>
	select object_id_two
	from acs_data_links
	where object_id_one = :object_id
	order by object_id_two
    </querytext>
</fullquery>

<fullquery name="application_data_link::get_linked.linked_object">
    <querytext>
	select o.object_id
	from acs_data_links r, acs_objects o
	where r.object_id_one = :from_object_id
	and r.object_id_two = o.object_id
	and o.object_type = :to_object_type
	order by r.object_id_two
    </querytext>
</fullquery>

<fullquery name="application_data_link::get_linked_content.linked_object">
    <querytext>
	select i.item_id
	from acs_data_links r, cr_items i
	where r.object_id_one = :from_object_id
	and r.object_id_two = i.item_id
	and i.content_type = :to_content_type
	order by r.object_id_two
    </querytext>
</fullquery>

</queryset>
