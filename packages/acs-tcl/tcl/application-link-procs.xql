<?xml version="1.0"?>
<queryset>

<fullquery name="application_link::delete_links.linked_packages">
    <querytext>
	    select rel_id
	    from acs_rels
	    where rel_type = 'application_link'
	    and (object_id_one = :package_id
		 or object_id_two = :package_id)
    </querytext>
</fullquery>

<fullquery name="application_link::get.linked_packages">
    <querytext>
	select object_id_two
	from acs_rels
	where object_id_one = :package_id
	and rel_type = 'application_link'
    </querytext>
</fullquery>

<fullquery name="application_link::get_linked.linked_package">
    <querytext>
	select p.package_id
	from acs_rels r, apm_packages p
	where r.object_id_one = :from_package_id
	and r.object_id_two = p.package_id
	and p.package_key = :to_package_key
	and r.rel_type = 'application_link'
    </querytext>
</fullquery>

</queryset>
