ad_proc content_search__datasource {
    object_id
} {
    Provides data source for search interface.  Used to access content items
    after search.
} {
    db_0or1row notes_datasource {
	select r.revision_id as object_id, 
	       r.title as title, 
	       r.content as content,
               r.lob as lob,
	       r.mime_type as mime,
	       '' as keywords,
	       i.storage_type as storage
	from cr_revisions r, cr_items i
	where revision_id = :object_id
        and i.item_id = r.item_id
    } -column_array datasource

    switch $datasource(storage) {
        lob {
            db_with_handle db {
                set datasource(content) [ns_pg blob_get $db $datasource(lob)]
            }
        }

        file {
            set fh [open [cr_fs_path]/$content r]
            fconfigure $fh -translation binary
            set datasource(content) [read $fh]
            close $fh
        }
    }

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
        select site_node__url(node_id) || 
               (select content_item__get_path(item_id,null) 
                  from cr_revisions
                 where revision_id = :object_id) as url
          from site_nodes n
         where n.object_id = :package_id        
    "

    return $url
}

ad_proc content_search__search_ids { 
    q 
    { offset 0 }
    { limit 100 }
} {
    Returns the object ids for a specified search.    
} {

    set package_id [apm_package_id_from_key search]
    set driver [ad_parameter -package_id $package_id FtsEngineDriver]
    array set result [acs_sc_call FtsEngineDriver search [list $q $offset $limit] $driver]

    return $result(ids)
}
