<?xml version="1.0"?>

<queryset>
<fullquery name="resource_list">
    <querytext>
			select 
			lro.lr_object_id, 
				lro.lr_title, 
				lro.restype, 
				lro.shortname, 
				lro.last_modified, 
				lro.is_active, 
				lro.pretty_name,
				dcc.community_key as area
			from 
				lr_objects_developers_view lro inner join dotlrn_communities_core dcc
				on lro.community_id = dcc.community_id        
			where
			  lro.lr_object_id [template::list::page_where_clause -name "resource_list"]
      	order by lro.lr_title     
     </querytext>
</fullquery>

<fullquery name="resource_list_pagination">
    <querytext>
			select 
				lro.lr_object_id
			from 
				lr_objects_developers_view lro        
				[expr {[exists_and_not_null cs]?" ,lr_concept__all_objects lrc":""}]
			where
				lro.community_id = :c
				and lro.restype = :restype
				and lro.is_active = :is_active
				[expr {[exists_and_not_null q]?"and (lower(lro.lr_title) like '%' || :q || '%' or lower(lro.shortname) like '%' || :q || '%')":"" }]
				[expr {[exists_and_not_null cs]?" and lrc.lr_object_id  = lro.lr_object_id and lrc.lr_concept_id = :cs":""}]
			 	[template::list::filter_where_clauses -and -name "resource_list"]
			 	order by lro.lr_title
    </querytext>
</fullquery>


</queryset>
