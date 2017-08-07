ad_proc content_search__datasource {
    object_id
} {
    Provides data source for search interface.  Used to access content items
    after search.
} {
    db_0or1row revisions_datasource "
	select r.revision_id as object_id, 
	       r.title,
               case i.storage_type
                    when 'lob' then r.lob::text
                    when 'file' then '[cr_fs_path]' || r.content
                    else r.content
               end as content,
	       r.mime_type as mime,
           '' as keywords,
	       i.storage_type
	from cr_revisions r, cr_items i
	where revision_id = :object_id
        and i.item_id = r.item_id
    " -column_array datasource

    return [array get datasource]
}


ad_proc content_search__url {
    object_id
} {
    Provides a url for linking to content items which show up in a search
    result set.
} {

    set package_id [apm_package_id_from_key acs-content-repository]
    db_1row get_url_stub "
        select site_node__url(node_id) as root_url,
               (select content_item__get_path(item_id,content_item__get_root_folder(null)) 
                  from cr_revisions
                 where revision_id = :object_id) as url
          from site_nodes n
         where n.object_id = :package_id        
    "
    
    return "[ad_url]$root_url$url?revision_id=$object_id"
}

ad_proc image_search__datasource {
    object_id
} {
    Provides data source for search interface.  Used to access content items
    after search.
} {
    db_0or1row revisions_datasource {
	select r.revision_id as object_id, 
	       r.title as title, 
	       r.description as content,
	       r.mime_type as mime,
	       '' as keywords,
           'text' as storage_type
	from cr_revisions r
	where revision_id = :object_id

    } -column_array datasource

    return [array get datasource]
}


ad_proc image_search__url {
    object_id
} {
    Provides a url for linking to content items which show up in a search
    result set.
} {

    set package_id [apm_package_id_from_key acs-content-repository]
    db_1row get_url_stub "
        select site_node__url(node_id) as root_url,
               (select content_item__get_path(item_id,null) 
                  from cr_revisions
                 where revision_id = :object_id) as url
          from site_nodes n
         where n.object_id = :package_id        
    "
    
    return "[ad_url][string trimright $root_url /]$url?revision_id=$object_id"
}


ad_proc template_search__datasource {
    object_id
} {
    Provides data source for search interface.  Used to access content items
    after search.
} {
    db_0or1row revisions_datasource "
	select r.revision_id as object_id, 
	       r.title as title, 
               case i.storage_type
                    when 'lob' then r.lob::text
                    when 'file' then '[cr_fs_path]' || r.content
                    when 'text' then r.content
                    else r.content
               end as content,
	       r.mime_type as mime,
	       '' as keywords,
	       i.storage_type
	from cr_revisions r, cr_items i
	where revision_id = :object_id
        and i.item_id = r.item_id
    " -column_array datasource

    return [array get datasource]
}


ad_proc template_search__url {
    object_id
} {
    Provides a url for linking to content items which show up in a search
    result set.
} {

    set package_id [apm_package_id_from_key acs-content-repository]
    db_1row get_url_stub "
        select site_node__url(node_id) as root_url,
               (select content_item__get_path(item_id,null) 
                  from cr_revisions
                 where revision_id = :object_id) as url
          from site_nodes n
         where n.object_id = :package_id        
    "
    
    return "[ad_url][string trimright $root_url /]$url?revision_id=$object_id"
}


ad_proc content_search__search_ids { 
    q 
    { offset 0 }
    { limit 100 }
} {
    Returns the object ids for a specified search.    
} {

    set package_id [apm_package_id_from_key search]
    set driver [parameter::get -package_id $package_id -parameter FtsEngineDriver]
    array set result [acs_sc::invoke -contract FtsEngineDriver -operation search -call_args [list $q $offset $limit] -impl $driver]

    return $result(ids)
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
