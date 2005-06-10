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
    if {![empty_string_p $object_id]
        && ![empty_string_p $event]} {
        package_exec_plsql \
            -var_list [list \
                           [list object_id $object_id] \
                           [list event $event] ] \
            search_observer enqueue
    } else {
        ns_log warning "search::queue: invalid: called with object_id=$object_id event=$event\n[ad_print_stack_trace]\n"
    }
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
    if {![empty_string_p $object_id]
        && ![empty_string_p $event_date]
        && ![empty_string_p $event]} {
            package_exec_plsql \
                -var_list [list [list object_id $object_id] \
                               [list event_date $event_date] \
                               [list event $event] ] \
                search_observer dequeue
    } else {
        ns_log warning "search::dequeue: invalid: called with object_id=$object_id event_date=$event_date event=$event\n[ad_print_stack_trace]\n"
    }
}


ad_proc -public -callback search::action {
    -action
    -object_id
    -datasource
    -object_type
} {
    Do something with a search datasource Called by the indexer
    after having created the datasource.

    @param action UPDATE INSERT DELETE
    @param datasource name of the datasource array

    @return ignored

    @author Jeff Davis (davis@xarg.net)
} -


ad_proc -private search::indexer {} {
    Search indexer loops over the existing entries in the search_observer_queue 
    table and calls the appropriate driver functions to index, update, or 
    delete the entry.

    @author Neophytos Demetriou
    @author Jeff Davis (davis@xarg.net)
} {

    set driver [ad_parameter -package_id [apm_package_id_from_key search] FtsEngineDriver]

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
            UPDATE -
            INSERT {
                # Don't bother reindexing if we've already inserted/updated this object in this run
                if {![info exists seen($object_id)]} {
                    set object_type [acs_object_type $object_id]
                    if {[acs_sc_binding_exists_p FtsContentProvider $object_type]} {
                        array set datasource {mime {} storage_type {} keywords {}}
                        if {[catch {
                            # check if a callback exists, if not fall
                            # back to service contract
                            if {[callback::impl_exists -callback search::datasource -impl $object_type]} {
                                array set datasource [lindex [callback -impl $object_type search::datasource -object_id $object_id] 0]
                            } else {
                                array set datasource  [acs_sc_call FtsContentProvider datasource [list $object_id] $object_type]
                            }
                            search::content_get txt $datasource(content) $datasource(mime) $datasource(storage_type)

                            acs_sc_call FtsEngineDriver \
                                [ad_decode $event UPDATE update_index index] \
                                [list $datasource(object_id) $txt $datasource(title) $datasource(keywords)] $driver
                        } errMsg]} {
                            ns_log Error "search::indexer: error getting datasource for $object_id $object_type: $errMsg\n[ad_print_stack_trace]\n"
                        } else {
                            # call the action so other people who do indexey things have a hook
                            callback -catch search::action \
                                -action $event \
                                -object_id $object_id \
                                -datasource datasource \
                                -object_type $object_type

                            # Remember seeing this object so we can avoid reindexing it later
                            set seen($object_id) 1

                            search::dequeue -object_id $object_id -event_date $event_date -event $event
                        }
                    }
                }
            }
            DELETE {
                if {[catch {
                    acs_sc_call FtsEngineDriver unindex [list $object_id] $driver
                } errMsg]} {
                    ns_log Error "search::indexer: error unindexing $object_id $object_type: $errMsg\n[ad_print_stack_trace]\n"
                } else {
                    # call the search action callbacks.
                    callback -catch search::action \
                        -action $event \
                        -object_id $object_id \
                        -datasource NONE \
                        -object_type {}

                    search::dequeue -object_id $object_id -event_date $event_date -event $event

                }

                # unset seen since you could conceivably delete one but then subsequently
                # reinsert it (eg when rolling back/forward the live revision).
                if {[info exists seen($object_id)]} {
                    unset seen($object_id)
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
