ad_library {
    Tests for search queue triggers
}

namespace eval cr_item_search:: {}

ad_proc -private cr_item_search::assert_not_in_queue {
    -revision_id
    -events
} {
    We use this test many times.
    Check if revision_id is in the search observer queue
} {
    aa_false "Revision ${revision_id} is not queued for search events $events" \
	[db_string check_queue [subst {
            select count(*) from search_observer_queue 
            where object_id = :revision_id
            and event in
            ([template::util::tcl_to_sql_list $events])
        }] -default 0]
}

ad_proc -private cr_item_search::assert_in_queue {
    -revision_id
    -events
} {
    We use this test many times.
    Check if revision_id is in the search observer queue
    
    @param events List of events to check for (INSERT,UPDATE,DELETE)
} {
    aa_true "Revision ${revision_id} is queued for search events $events" \
	[db_string check_queue [subst {
            select count(*) from search_observer_queue 
            where object_id = :revision_id
            and event in 
            ([template::util::tcl_to_sql_list $events])
        }] -default 0]
}

ad_proc -private cr_item_search::remove_from_queue {
    -revision_id
} {
    Remove all entries from queue
} {
    db_dml remove "delete from search_observer_queue
                   where object_id=:revision_id"
}

ad_proc -private cr_item_search::test_setup {
} {
    setup test environment for search trigger tests
} {
    set folder_name [ns_mktemp cr_item_search_XXXXXX]
    set folder_id [content::folder::new -name $folder_name]
    content::folder::register_content_type -folder_id $folder_id -content_type content_revision -include_subtypes t
    return $folder_id
}


aa_register_case \
    -cats {api db} \
    -procs {
        content::item::get_id
        content::item::get_latest_revision
        content::item::get_live_revision
        content::item::new
        content::item::set_live_revision
        content::item::unset_live_revision
        content::item::update
        cr_item_search::assert_in_queue
        cr_item_search::assert_not_in_queue
        cr_item_search::remove_from_queue
        cr_item_search::test_setup
    } \
    cr_item_search_triggers {
      Test search update trigger
} {
    if {![string match -nocase  "oracle*" [db_name]]} {
    aa_run_with_teardown \
	-rollback \
	-test_code \
	{
	    set folder_id [cr_item_search::test_setup]
	    set item_name [ns_mktemp cr_itemXXXXXX]

	    # test new item, not live
	    set item_id [content::item::new \
			     -name $item_name \
			     -title $item_name \
			     -parent_id $folder_id \
			     -is_live f]
	    # make sure the item exists first
	    aa_true "Item exists" {[content::item::get_id \
					      -item_path $item_name \
					      -root_folder_id $folder_id] \
					     ne ""}
	    aa_true "Item is NOT live" {[content::item::get_live_revision \
                                             -item_id $item_id] eq ""}
            set latest_revision [content::item::get_latest_revision \
                                     -item_id $item_id]
	    aa_true "But a revision exists" {$latest_revision ne ""}
	    aa_false "Item is NOT queued for search indexing" \
		[db_string check_queue {
                    select 1 from search_observer_queue 
                    where object_id = :latest_revision
                } -default 0]
            
	    aa_log "Update Item, still no live revision"
	    content::item::update \
		-item_id $item_id \
		-attributes [list [list name $item_name]]
	    cr_item_search::assert_not_in_queue \
		-revision_id $latest_revision \
		-events [list INSERT UPDATE]
            
	    aa_log "Set live revision no publish date"
	    content::item::set_live_revision \
		-revision_id $latest_revision
	    cr_item_search::assert_in_queue \
		-revision_id $latest_revision \
		-events [list INSERT UPDATE]
            
	    content::item::unset_live_revision -item_id $item_id
	    cr_item_search::assert_in_queue \
		-revision_id $latest_revision \
		-events [list DELETE]
	    cr_item_search::remove_from_queue \
		-revision_id $latest_revision
            set next_date [clock format [clock scan "tomorrow"] -format "%Y-%m-%d"]
	    db_dml set_publish_date "update cr_revisions set publish_date=:next_date where revision_id=:latest_revision"

	    aa_log "Publish Date in future, live revision not set"
	    cr_item_search::assert_not_in_queue \
		-revision_id $latest_revision \
		-events [list INSERT UPDATE]
	    # NOTE set live revision without pl/sql proc which also set
	    # publish date to right now! It should be impossible to have
	    # a live revision with publish date in the future
	    # but the point here is to never search an unpublished item
	    db_dml set_live_revision \
		"update cr_items set live_revision=latest_revision
                 where item_id=:item_id"

	    aa_log "Publish date in future, live revision set"
	    cr_item_search::assert_not_in_queue \
		-revision_id $latest_revision \
		-events [list INSERT UPDATE]
	}
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
