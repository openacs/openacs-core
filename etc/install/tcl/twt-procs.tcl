# Procs to support testing OpenACS with Tclwebtest.
#
# Basic utility procs.
#
# @author Peter Marklund

namespace eval ::twt {}

ad_proc ::twt::log { message } {
    set script_name [file tail [info script]]
    puts ""
    puts "##############################"
    puts "#"
    puts "# ${script_name}: $message"
    puts "#"
    puts "##############################"
    puts ""
}

ad_proc ::twt::do_request { page_url } {
    Takes a a url and invokes tclwebtest::do_request.
} {
    ::tclwebtest::do_request $page_url
}

ad_proc ::twt::get_url_list { page_url link_url_pattern } {

    ::twt::do_request $page_url

    set urls_list [list]

    # Loop over and add all links
    set errno "0"
    while { $errno == "0" } {
	set errno [catch {
            array set link_array [link find -next ~u "$link_url_pattern"]} error]

         if { [string equal $errno "0"] } {
            set url $link_array(url)
     
            lappend urls_list $url
        }
    }
    

    return $urls_list
}

ad_proc ::twt::get_random_items_from_list { list number } {
    Given a list and the lenght of the list to return, 
    return a list with a random subset of items from the input list.
} {

    # Build a list of indices
    set index_list [list]
    for { set i 0 } { $i < [llength $list] } { incr i } {
        lappend index_list $i
    }

    # If the list was empty - return
    if { [llength $index_list] == 0 } {
        return {}
    }

    # Cannot return more items than are in the list
    if { $number > [llength $list] } {
        error "get_random_items_from_list: cannot return $number items from list $list"
    }

    # Pick number random indices from the list. Remove each index that we have
    # already picked.
    set random_indices [list]
    for { set index_count 0 } { $index_count < $number } { incr index_count } {
        set random_index [randomRange [llength $index_list]]

        lappend random_indices [lindex $index_list $random_index]

        # Remove the index that we picked
        set index_list [lreplace $index_list $random_index $random_index]
    }

    # Build and return the items at the random indices
    set return_list [list]
    foreach index $random_indices {
        lappend return_list [lindex $list $index]
    }
    if { [llength $return_list] == 1 } {
        return [lindex $return_list 0]
    } else {
        return $return_list
    }
}

ad_proc ::twt::randomRange {range} {
    Given an integer N, return an integer between 0 and N.
} {

     return [expr int([expr rand()] * $range)]
}

ad_proc ::twt::write_response_to_file { filename } {
    Write the HTML body of the last HTTP response to the
    file with given path. If the directory of the file doesn't
    exist then create it.
} {

    # Create the directory of the output file if it doesn't exist
    if { ![file isdirectory [file dirname $filename]] } { 
        exec mkdir -p [file dirname $filename] 
    }
    set file_id [open "$filename" w+]
    puts $file_id "[response body]"
}

ad_proc ::twt::crawl_links {} {
    TODO: This proc currently doesn't crawl nearly as many links as we would like
} {

    global __url_history

    set start_url [lindex $__url_history end]

    # Return if given start URL is external
    global __server_url
    set absolute_url [tclwebtest::absolute_link $start_url]
    if { [string first $__server_url $absolute_url] == -1 } {
        #puts "not following link to external url $absolute_url"
        return
    }

    # Also return if this is the logout link
    if { [regexp {/register/logout} $start_url match] } {
        #puts "not following logout link"
        return
    }

    ::twt::do_request $start_url

    set errno 0
    while { $errno == "0" } {
	set errno [catch {
            array set link_array [link find -next]} error]

         if { [string equal $errno "0"] } {
            set url $link_array(url)

            # Don't revisit URL:s we have already tested
            # Don't follow relative anchors on pages - can't get them to work with TclWebtest
            if { [lsearch -exact $__url_history $url] == -1 && [string range $url 0 0] != "#" } {
                #puts "$start_url following url $url"

                lappend __url_history $url

                crawl_links
            } else {
                #puts "$start_url skipping url $url as visited before"
            }
         }
   }
}
