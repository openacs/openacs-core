<?xml version="1.0"?>
<queryset>

<fullquery name="application_data_link::delete_links.linked_objects">
    <querytext>
	    select rel_id
	    from acs_rels
	    where rel_type = 'application_data_link'
	    and (object_id_one = :object_id
		 or object_id_two = :object_id)
    </querytext>
</fullquery>

<fullquery name="application_data_link::get.linked_objects">
    <querytext>
	select object_id_two
	from acs_rels
	where object_id_one = :package_id
	and rel_type = 'application_data_link'
    </querytext>
</fullquery>

<fullquery name="application_data_link::get_linked.linked_object">
    <querytext>
	select o.object_id
	from acs_rels r, acs_objects o
	where r.object_id_one = :from_object_id
	and r.object_id_two = o.object_id
	and o.object_type = :to_object_type
	and r.rel_type = 'application_data_link'
    </querytext>
</fullquery>

<fullquery name="application_data_link::get_linked_content.linked_object">
    <querytext>
	select i.item_id
	from acs_rels r, cr_items i
	where r.object_id_one = :from_object_id
	and r.object_id_two = i.item_id
	and i.content_type = :to_content_type
	and r.rel_type = 'application_data_link'
    </querytext>
</fullquery>

</queryset>
