<?xml version="1.0"?>
<queryset>

<fullquery name="application_data_link::new_from.create_forward_link">
    <querytext>
	    insert into acs_data_links (rel_id, object_id_one, object_id_two, relation_tag)
	    values (:forward_rel_id, :object_id, :to_object_id, :relation_tag)
    </querytext>
</fullquery>

<fullquery name="application_data_link::new_to.create_backward_link">
    <querytext>
	    insert into acs_data_links (rel_id, object_id_one, object_id_two, relation_tag)
	    values (:backward_rel_id, :from_object_id, :object_id, :relation_tag)
    </querytext>
</fullquery>

<fullquery name="application_data_link::delete_links.linked_objects">
    <querytext>
	    select rel_id
	    from acs_data_links
	    where (object_id_one = :object_id
		 or object_id_two = :object_id)
         [application_data_link::relation_tag_where_clause -relation_tag $relation_tag]
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
      [application_data_link::relation_tag_where_clause -relation_tag $relation_tag]
	order by object_id_two
    </querytext>
</fullquery>

<fullquery name="application_data_link::get_linked_not_cached.linked_object">
    <querytext>
    	select o.object_id
	from acs_objects o
	where o.object_type = :to_object_type
	and o.object_id in (select object_id_two 
                          from acs_data_links 
                         where object_id_one = :from_object_id
                         [application_data_link::relation_tag_where_clause -relation_tag $relation_tag])
	order by o.object_id
    </querytext>
</fullquery>

<fullquery name="application_data_link::get_linked_content_not_cached.linked_object">
    <querytext>
	select i.item_id
	from cr_items i
	where i.content_type = :to_content_type
	and i.item_id in (select object_id_two 
                        from acs_data_links 
                       where object_id_one = :from_object_id
                       [application_data_link::relation_tag_where_clause -relation_tag $relation_tag])
	order by i.item_id
    </querytext>
</fullquery>

<fullquery name="application_data_link::get_links_from.links_from">
    <querytext>
        select object_id_two
        from acs_data_links,
        acs_objects
	$content_type_from_clause
        where object_id_one = :object_id
	and object_id = object_id_two
    [application_data_link::relation_tag_where_clause -relation_tag $relation_tag]
	$to_type_where_clause
    </querytext>
</fullquery>

<partialquery name="application_data_link::get_links_from.to_type_clause">
    <querytext>
	and object_type = :to_type
    </querytext>
</partialquery>

<partialquery name="application_data_link::get_links_from.content_type_from_clause">
    <querytext>
	, cr_items
    </querytext>
</partialquery>

<partialquery name="application_data_link::get_links_from.content_type_where_clause">
    <querytext>
	and content_type = :object_type
    </querytext>
</partialquery>

<fullquery name="application_data_link::get_links_to.links_to">
    <querytext>
        select object_id_one
        from acs_data_links,
        acs_objects
	$content_type_from_clause
        where object_id_two = :object_id
	and object_id = object_id_one
    [application_data_link::relation_tag_where_clause -relation_tag $relation_tag]
	$from_type_where_clause
    </querytext>
</fullquery>

<partialquery name="application_data_link::get_links_to.from_type_clause">
    <querytext>
	and object_type = :from_type
    </querytext>
</partialquery>

<partialquery name="application_data_link::get_links_to.content_type_from_clause">
    <querytext>
	, cr_items
    </querytext>
</partialquery>

<partialquery name="application_data_link::get_links_to.content_type_where_clause">
    <querytext>
	and content_type = :object_type
    </querytext>
</partialquery>

<fullquery name="application_data_link::delete_from_list.delete_links">
    <querytext>
  	delete from acs_data_links where object_id_one=:object_id
        and object_id_two in 
          ([template::util::tcl_to_sql_list $link_object_id_list])
        [application_data_link::relation_tag_where_clause -relation_tag $relation_tag]
    </querytext>
</fullquery>

<fullquery name="application_data_link::link_exists.link_exists">
    <querytext>
	select 1 from acs_data_links
	where object_id_one = :from_object_id
	and object_id_two = :to_object_id
    [application_data_link::relation_tag_where_clause -relation_tag $relation_tag]
    </querytext>
</fullquery>

<fullquery name="application_data_link::scan_for_links.confirm_object_ids">
    <querytext>
	select object_id from acs_objects where object_id in ([template::util::tcl_to_sql_list $refs])
    </querytext>
</fullquery>	

<partialquery name="application_data_link::relation_tag_where_clause.where_clause">
    <querytext>
    and relation_tag = :relation_tag
    </querytext>
</partialquery>
</queryset>
