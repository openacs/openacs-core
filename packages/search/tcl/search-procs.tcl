ad_library {
    full-text search engine

    @author Neophytos Demetriou (k2pts@yahoo.com)
    @cvs-id $Id$
}

namespace eval search {}

ad_proc -public search::searchable_type_p  {
    -object_type:required
} {
    Is this object type searchable?

    @return boolean
} {
    return [expr {[callback::impl_exists -callback search::datasource -impl $object_type]
                  || [acs_sc_binding_exists_p FtsContentProvider $object_type]}]
}

ad_proc -public search::object_datasource {
    -object_id:required
} {
    Obtains the datasource for an object by invoking the proper
    datasource and callbacks.

    @return datasource as dict
} {
    set object_type [acs_object_type $object_id]
    if {![search::searchable_type_p -object_type $object_type]} {
        return
    }

    set d(object_id) $object_id

    array set d {
        title {}
        mime {}
        storage_type {}
        keywords {}
        package_id {}
        relevant_date {}
    }

    if {[callback::impl_exists -callback search::datasource -impl $object_type]} {
        array set d [lindex [callback \
                                 -impl $object_type \
                                 search::datasource \
                                 -object_id $object_id] 0]
    } else {
        array set d [acs_sc::invoke \
                         -contract FtsContentProvider \
                         -operation datasource \
                         -call_args [list $object_id] \
                         -impl $object_type]
    }

    return [array get d]
}

ad_proc -public search::object_index {
    -object_id:required
    {-event "UPDATE"}
} {
    Indexes an object by invoking the proper datasource and callbacks.

    @return datasource as dict
} {
    set driver [search::driver_name]
    if {$driver eq ""} {
        return
    }

    array set d [search::object_datasource -object_id $object_id]
    if {[array size d] == 0} {
        return
    }

    search::content_get txt \
        $d(content) \
        $d(mime) \
        $d(storage_type) \
        $object_id

    if {[callback::impl_exists -callback search::index -impl $driver]} {
        callback -impl $driver search::index \
            -object_id $object_id \
            -content $txt \
            -title $d(title) \
            -keywords $d(keywords) \
            -package_id $d(package_id) \
            -community_id $d(community_id) \
            -relevant_date $d(relevant_date) \
            -datasource d
    } else {
        acs_sc::invoke \
            -contract FtsEngineDriver \
            -operation [expr {$event eq "UPDATE" ? "update_index" : "index"}] \
            -call_args [list \
                            $d(object_id) \
                            $txt \
                            $d(title) \
                            $d(keywords)] \
            -impl $driver
    }

    set object_type [acs_object_type $object_id]

    #
    # Call the action so other people who do indexey things have a
    # hook.
    #
    callback -catch search::action \
        -action $event \
        -object_id $object_id \
        -datasource d \
        -object_type $object_type

    return [array get d]
}

ad_proc -public search::object_unindex {
    -object_id:required
} {
    Unindexes an object by invoking the proper callbacks.
} {
    set driver [search::driver_name]
    if {$driver eq ""} {
        return
    }

    acs_sc::invoke \
        -contract FtsEngineDriver \
        -operation unindex \
        -call_args [list $object_id] \
        -impl $driver

    # call the search action callbacks.
    callback -catch search::action \
        -action DELETE \
        -object_id $object_id \
        -datasource NONE \
        -object_type {}

}

ad_proc -public search::object_url {
    -object_id:required
} {
    Retrieves the object URL by invoking the proper callbacks.

    @return URL
} {
    set object_type [acs_object_type $object_id]

    if {[callback::impl_exists -impl $object_type -callback search::url]} {
	return [callback -impl $object_type search::url -object_id $object_id]
    } else {
	return [acs_sc::invoke \
                    -contract FtsContentProvider \
                    -operation url \
                    -call_args [list $object_id] \
                    -impl $object_type]
    }
}

ad_proc -public search::queue {
    -object_id
    -event
} {
    Add an object to the search_observer_queue table with
    an event.

    You should exercise care that the entry is not being
    created from a trigger (although search is robust for multiple
    entries so it will not insert or update the same object
    more than once per sweep).

    @param object_id acs_objects object_id
    @param event INSERT or UPDATE or DELETE

    @author Jeff Davis (davis@xarg.net)
} {
    if {$object_id ne "" && $event ne "" } {
        package_exec_plsql \
            -var_list [list \
                           [list object_id $object_id] \
                           [list event $event] ] \
            search_observer enqueue
    } else {
        ns_log warning "search::queue: invalid: called with object_id=$object_id " \
            "event=$event\n[ad_print_stack_trace]"
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
    if {$object_id ne ""
        && $event_date ne ""
        && $event ne ""} {
            package_exec_plsql \
                -var_list [list [list object_id $object_id] \
                               [list event_date $event_date] \
                               [list event $event] ] \
                search_observer dequeue
    } else {
        ns_log warning "search::dequeue: invalid: called with object_id=$object_id" \
            "event_date=$event_date event=$event\n[ad_print_stack_trace]"
    }
}

ad_proc -public -deprecated search::is_guest_p {
} {
    Checks whether the logged-in user is a guest

    Deprecated: returning 0 since more than 10 years...

    @see :acs::dc proc "call dotlrn_privacy guest_p"
} {
    # set user_id [ad_conn user_id]
    # return [db_string get_is_guest_p {select dotlrn_privacy.guest_p(:user_id) from dual}]
    return 0
}

ad_proc -public -callback search::action {
     -action
     -object_id
     -datasource
     -object_type
} {
     Do something with a search datasource called by the indexer
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

    set driver [search::driver_name]
    if { $driver eq "" } {
        #
        # Nothing to do if no driver
        #
        return
    }

    # JCD: pull out the rows all at once so we release the handle
    foreach row [db_list_of_lists search_observer_queue_entry {}] {

        # DRB: only do Oracle shit for oracle (doh)
        if { [ns_config "ns/db/drivers" oracle] ne "" } {
            if {[nsv_incr search_static_variables item_counter] > 1000} {
                nsv_set search_static_variables item_counter 0
                db_exec_plsql optimize_intermedia_index {begin
                    ctx_ddl.sync_index ('swi_index');
                    end;
                }
            }
        }

        lassign $row object_id event_date event
        switch -- $event {
            UPDATE -
            INSERT {
                # Don't bother reindexing if we've already inserted/updated this object in this run
                if {![info exists seen($object_id)]} {
                    try {
                        search::object_index \
                            -event $event \
                            -object_id $object_id
                    } on error {errMsg} {
                        ns_log Error "search::indexer: error getting datasource for " \
                            "[acs_object_type $object_id]: $errMsg\n[ad_print_stack_trace]"
                    } on ok {d} {
                        #
                        # Remember seeing this object so we can avoid
                        # reindexing it later.
                        #
                        set seen($object_id) 1
                    }
                }
            }
            DELETE {
                try {
                    search::object_unindex -object_id $object_id
                } on error {errMsg} {
                    ns_log Error "search::indexer: error unindexing $object_id " \
                        "[acs_object_type $object_id]: $errMsg\n[ad_print_stack_trace]"
                }

                #
                # Unset "seen" element since one could conceivably
                # delete one but then subsequently reinsert it (e.g.
                # when rolling back/forward the live revision).
                #
                unset -nocomplain seen($object_id)
            }
        }

        # Don't put that dequeue in a default block of the switch above
        # otherwise objects with insert/update and delete operations in the same
        # run would crash and never get dequeued

        search::dequeue -object_id $object_id -event_date $event_date -event $event
    }

}

ad_proc -private search::content_get {
    _txt
    content
    mime
    storage_type
    object_id
} {
    @author Neophytos Demetriou

    @param content

    holds the filename if storage_type=file
    holds the text data if storage_type=text
    holds the lob_id if storage_type=lob
} {
    upvar $_txt txt
    set txt ""
    set passing_style string

    # lob and file are not currently implemented
    switch $storage_type {
        text {
            set data $content
        }
        file {
            set data [content::revision::get_cr_file_path -revision_id $object_id]
            set passing_style file
        }
        lob {
            set data [db_blob_get get_lob_data {}]
        }
    }

    search::content_filter -passing_style $passing_style txt data $mime
}

ad_proc -private search::content_filter {
    {-passing_style string}
    _txt
    _data
    mime
} {
    @author Neophytos Demetriou
} {
    upvar $_txt txt
    upvar $_data data

    #ns_log notice "---search::content_filter $mime data=[string length $data] <$passing_style>"

    if {$passing_style eq "string"} {
        if {[string match text/* $mime]} {
            if {$mime eq "text/html"} {
                set txt [ns_striphtml $data]
            } else {
                set txt $data
            }
            return
        }
        #
        # Write content to a file and let the filter below extract the
        # words for the index from the file.
        #
        set f [ad_opentmpfile tmp_filename]
        puts $f $data
        close $f
        set data $tmp_filename
    }

    set txt [search::convert::binary_to_text -filename $data -mime_type $mime]
    #ns_log notice "search::content_filter txt len [string length $txt]"

    if {[info exists tmp_filename]} {
        file delete -- $tmp_filename
    }
}

ad_proc -callback search::datasource {
    -object_id:required
} {
    This callback is invoked by the search indexer when and object is
    indexed for search. The datasource implementation name should be
    the object_type for the object.
} -

# define for all objects, not just search?

ad_proc -callback search::search {
    -query:required
    -user_id
    {-offset 0}
    {-limit 10}
    {-df ""}
    {-dt ""}
    {-package_ids ""}
    {-object_type ""}
    {-extra_args {}}
} {
    This callback is invoked when a search is to be performed. Query
    will be a list of lists. The first list is required and will be a
    list of search terms to send to the full text search
    engine. Additional optional lists will be a two element list. The
    first element will be the name of an advanced search operator. The
    second element will be a list of data to restrict search results
    based on that operator.
} -

ad_proc -callback search::unindex {
    -object_id:required
} {
    This callback is invoked to remove an item from the search index.
} -

ad_proc -callback search::url {
    -object_id:required
} {
   This callback is invoked when a URL needs to be generated for an
   object. Usually, this is called from /o.vuh which defers URL
   calculation until a link is actually clicked, so generating a list
   of URLs for various object types is quick.
} -

ad_proc -callback search::index {
    -object_id
    -content
    -title
    -keywords
    -community_id
    -relevant_date
    {-description ""}
    {-datasource ""}
    {-package_id ""}
} {
    This callback is invoked from the search::indexer scheduled procedure
    to add an item to the index
} -

ad_proc -callback search::update_index {
    -object_id
    -content
    -title
    -keywords
    -community_id
    -relevant_date
    {-description ""}
    {-datasource ""}
    {-package_id ""}
} {
    This callback is invoked from the search::indexer scheduled procedure
    to update an item already in the index
} -

ad_proc -callback search::summary {
    -query
    -text
} {
    This callback is invoked to return an HTML fragment highlighting the terms in query
} -

ad_proc -callback search::driver_info {
} {
    This callback returns information about the search engine implementation
} -

ad_proc -public search::driver_name {
} {
    Return the name of the current search driver.
} {
    set driver [parameter::get \
                    -package_id [apm_package_id_from_key search] \
                    -parameter FtsEngineDriver]

    if { $driver eq ""
         || (![callback::impl_exists -callback search::index -impl $driver] \
                 && ! [acs_sc_binding_exists_p FtsEngineDriver $driver])
     } {
        ns_log Debug "search::indexer: driver=$driver not properly configured."
        return
    }

    return $driver
}

# dotlrn specific procs

namespace eval search::dotlrn {}

ad_proc -public search::dotlrn::get_community_id {
    -package_id:required
} {
    If dotlrn is installed find the package's community_id

    @param package_id Package to find community

    @return dotLRN community_id. Empty string if package_id is not
            under a dotlrn package instance
} {
    if {[apm_package_installed_p dotlrn]} {
        set site_node [site_node::get_node_id_from_object_id -object_id $package_id]
        set dotlrn_package_id [site_node::closest_ancestor_package \
                                   -node_id $site_node \
                                   -package_key dotlrn \
                                   -include_self]
        set community_id [db_string get_community_id {
            select community_id from dotlrn_communities_all
            where package_id = :dotlrn_package_id
        } -default ""]
        return $community_id
    }
    return ""
}

ad_proc -callback search::extra_arg {
    -value
    {-object_table_alias {}}
} {
    Generate a query fragment for search filtering by extra argument.
    Argument name will be the implementation name called.

    Search driver should call this for every extra argument and then
    build the search query using the query fragments returned.

    @param value value of the argument
    @param object_table_alias SQL alias of table that contains the object_id to join against

    @return list in array format of {from_clause {} where_clause {}}
} -

ad_proc search::extra_args_names {
} {
    List of names of extra args implemented
} {
    set names [list]
    foreach procname [info procs ::callback::search::extra_arg::impl::*] {
        lappend names [namespace tail $procname]
    }
    return $names
}

ad_proc search::extra_args_page_contract {
} {
    Generate ad_page_contract fragment for extra_args options

    Get all the callback impls for extra_args and add
     a page contract declaration

    @return string containing the ad_page_contract query declarations
            for the extra_args that are implemented
} {
    set contract ""
    foreach name [extra_args_names] {
        append contract "\{$name \{\}\}\n"
    }
    return $contract
}

ad_proc search::extra_args {
} {
    List of extra_args to pass to search::search callback
} {
    set extra_args [list]
    foreach name [extra_args_names] {
        upvar $name local_$name
        ns_log debug "extra_args name = '${name}' exists [info exists local_${name}]"
        if {[info exists local_$name]} {
            lappend extra_args $name [set local_$name]
        }
    }
    return $extra_args
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
