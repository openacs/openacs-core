ad_library {
    full-text search engine

    @author Neophytos Demetriou (k2pts@yahoo.com)
    @cvs-id $Id$
}

namespace eval search {}

ad_proc -public search::queue {
    -object_id
    -event 
} {
    Add an object to the search_observer_queue table with
    an event.

    You should excercise care that the entry is not being
    created from a trigger (although search is robust for multiple 
    entries so it will not insert or update the same object
    more than once per sweep).

    @param object_id acs_objects object_id
    @param event INSERT or UPDATE or DELETE
    
    @author Jeff Davis (davis@xarg.net)
} {
    package_exec_plsql \
        -var_list [list \
                       [list object_id $object_id] \
                       [list event $event] ] \
        search_observer enqueue
}

ad_proc -public search::dequeue {
    -object_id
    -event_date
    -event 
} {
    Remove an object from the search queue

    @param object_id acs_objects object_id
    @param event_date the event date as retrieved from the DB (and which should not be changed)
    @param event INSERT or UPDATE or DELETE

    @author Jeff Davis (davis@xarg.net)
} {
    package_exec_plsql \
        -var_list [list [list object_id $object_id] \
                       [list event_date $event_date] \
                       [list event $event] ] \
        search_observer dequeue
}

ad_proc -private search::indexer {} {
    Search indexer loops over the existing entries in the search_observer_queue 
    table and calls the appropriate driver functions to index, update, or 
    delete the entry.

    @author Neophytos Demetriou
    @author Jeff Davis <davis@xarg.net>
} {

    set driver [ad_parameter -package_id [apm_package_id_from_key search] FtsEngineDriver]
    set syndicate [ad_parameter -package_id [apm_package_id_from_key search] Syndicate -default 0]

    if {[empty_string_p $driver]
        || ! [acs_sc_binding_exists_p FtsEngineDriver $driver]} {
        # Nothing to do if no driver
        ns_log Debug "search::indexer: driver=$driver binding exists? [acs_sc_binding_exists_p FtsEngineDriver $driver]"
        return
    }

    # JCD: pull out the rows all at once so we release the handle
    foreach row [db_list_of_lists search_observer_queue_entry {}] { 
        foreach {object_id event_date event} $row { break }

        array unset datasource
        switch -- $event {
            INSERT {
                # Don't bother reindexing if we've already inserted/updated this object in this run
                if {![info exists seen($object_id)]} {
                    set object_type [acs_object_type $object_id]
                    if {[acs_sc_binding_exists_p FtsContentProvider $object_type]} {
                        array set datasource {mime {} storage_type {} keywords {}}
                        array set datasource [acs_sc_call FtsContentProvider datasource [list $object_id] $object_type]
                        if {$syndicate} {
                            search::syndicate -datasource datasource
                        }
                        search::content_get txt $datasource(content) $datasource(mime) $datasource(storage_type)
                        acs_sc_call FtsEngineDriver index \
                            [list $datasource(object_id) $txt $datasource(title) $datasource(keywords)] $driver
                    }
                    # Remember seeing this object so we can avoid reindexing it later
                    set seen($object_id) 1
                }
            }
            DELETE {
                acs_sc_call FtsEngineDriver unindex [list $object_id] $driver
                db_dml nuke_syn {delete from syndication where object_id = :object_id} 
                # unset seen since you could conceivably delete one but then subsequently 
                # reinsert it (eg when rolling back/forward the live revision).
                if {[info exists seen($object_id)]} {
                    unset seen($object_id)
                }
            }
            UPDATE {
                # Don't bother reindexing if we've already inserted/updated this object in this run
                if {![info exists seen($object_id)]} {
                    set object_type [acs_object_type $object_id]
                    if {[acs_sc_binding_exists_p FtsContentProvider $object_type]} {
                        array set datasource {mime {} storage_type {} keywords {}}
                        array set datasource [acs_sc_call FtsContentProvider datasource [list $object_id] $object_type]
                        search::content_get txt $datasource(content) $datasource(mime) $datasource(storage_type)
                        if {$syndicate} { 
                            search::syndicate -datasource datasource
                        } 
                        acs_sc_call FtsEngineDriver update_index [list $datasource(object_id) $txt $datasource(title) $datasource(keywords)] $driver
                    }
                    # Remember seeing this object so we can avoid reindexing it later
                    set seen($object_id) 1
                }
            }
        }

        search::dequeue -object_id $object_id -event_date $event_date -event $event
    }

}

ad_proc -private search::content_get {
    _txt
    content
    mime
    storage_type
} {
    @author Neophytos Demetriou

    @param content    
    holds the filename if storage_type=file
    holds the text data if storage_type=text
    holds the lob_id if storage_type=lob
} {
    upvar $_txt txt

    set txt ""

    # lob and file are not currently implemented
    switch $storage_type {
        text {
            set data $content
        }
        file {
            set data [db_blob_get get_file_data {}]
        }
        lob {
            set data [db_blob_get get_lob_data {}]
        }
    }

    search::content_filter txt data $mime
}

ad_proc -private search::content_filter {
    _txt
    _data
    mime
} {
    @author Neophytos Demetriou
} {
    upvar $_txt txt
    upvar $_data data

    switch -glob -- $mime {
        {text/*} {
            set txt $data
        }
        default { 
            error "invalid mime type in search::content_filter: $mime"
        }
    }
}

ad_proc -private search::choice_bar { 
    items links values {default ""} 
} {
    @author Neophytos Demetriou
} {

    set count 0
    set return_list [list]

    foreach value $values {
        if {[string compare $default $value] == 0} {
            lappend return_list "<font color=\"a90a08\"><strong>[lindex $items $count]</strong></font>"
        } else {
            lappend return_list "<a href=\"[lindex $links $count]\"><font color=\"000000\">[lindex $items $count]</font></a>"
        }

        incr count
    }

    if {[llength $return_list] > 0} {
        return "[join $return_list " "]"
    } else {
        return ""
    }

}

ad_proc -private search::syndicate {
    -datasource 
} { 
    create or replace the record in the syndication table for 
    a given item id.

    called by the search::indexer.  See photo-album-search-procs for an example of 
    what you need to provide to make something syndicable.

    JCD: to fix: should not just glue together XML this way, also assumes rss 2.0, no provision for 
    alternate formats, assumes content:encoded will be defined in the wrapper.

} {
    upvar $datasource d

    if {![info exists d(syndication)]} {
        return
    }

    array set syn {
        category {}
        author {}
        guid {}
    }

    array set syn $d(syndication)

    set object_id $d(object_id)
    set url $syn(link)
    set body $d(content)

    set published [lc_time_fmt $syn(pubDate) "%a, %d %b %Y %H:%M:%S GMT"]

    set rss_xml_frag " <item>
  <title>$d(title)</title>
  <link>$url</link>
  <guid isPermaLink=\"true\">$syn(guid)</guid>
  <description>$syn(description)</description>
  <author>$syn(author)</author>
  <content:encoded><!\[CDATA\[$body]]></content:encoded>
  <category>$syn(category)</category>
  <pubDate>$published</pubDate>
 </item>"

    db_dml nuke {delete from syndication where object_id = :object_id}
    db_dml ins {insert into syndication(object_id, rss_xml_frag, body, url) values (:object_id, :rss_xml_frag, :body, :url)}

}
