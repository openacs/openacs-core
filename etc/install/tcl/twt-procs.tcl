# Procs to support testing OpenACS with Tclwebtest.
#
# Basic utility procs.
#
# @author Peter Marklund

namespace eval ::twt {}

ad_proc ::twt::log_section { message } {
    set script_name [file tail [info script]]
    puts ""
    puts "##############################"
    puts "#"
    puts "# ${script_name}: $message"
    puts "#"
    puts "##############################"
    puts ""
}

ad_proc ::twt::log { message } {
    set script_name [file tail [info script]]
    puts "${script_name}: $message"
}

ad_proc ::twt::log_alert { message } {
    set script_name [file tail [info script]]
    puts ""
    puts "${script_name}: [::twt::config::alert_keyword] - $message"
    puts ""
}

ad_proc ::twt::assert { explanation expression } {
    if { !$expression } {
        ::twt::log_alert "Assertion \"$explanation\" failed"
    }
} 

ad_proc ::twt::assert_equals { explanation actual_value expected_value } {
    if { $actual_value ne $expected_value } {
        ::twt::log_alert "Assertion \"$explanation\" failed: actual_value=\"$actual_value\", expected_value=\"$expected_value\""
    }
} 

ad_proc ::twt::do_request { page_url } {
    Takes a a url and invokes tclwebtest::do_request. Will retry
    the request a number of times if it fails because of a socket
    connect problem.
} {
    # Qualify page_url if necessary
    if { [regexp {^/} $page_url] } {
        set page_url "[::twt::config::server_url]${page_url}"
    }

    set retry_count 0
    set retry_max 10
    set error_p 0
    while { [catch {::tclwebtest::do_request $page_url} errmsg] } {
        set error_p 1

        if { $retry_count < $retry_max } {
            switch -regexp -- $errmsg {
                {unreachable} - {refused} {
                    ::twt::log "Failed to connect to server with error \"$errmsg\" - retrying"
                    incr retry_count
                    exec "sleep" "5"
                    set error_p 0
                    continue
                }
                default {
                    ::twt::log "Failed to connect to server with error \"$errmsg\" - giving up"
                    break
                }
            }
        } else {
            break
        }
    }

    if { $error_p } {
        # Either some non-socket error, or a socket problem occuring with more than
        # $retry_max times. Propagate the error while retaining the stack trace
        global errorInfo
        error $errmsg $errorInfo
    }

    ::twt::acs_lang::check_no_keys
}

ad_proc ::twt::get_url_list { page_url link_url_pattern } {

    ::twt::do_request $page_url

    set urls_list [list]

    # Loop over and add all links
    set errno "0"
    while { $errno == "0" } {
	set errno [catch {
            array set link_array [link find -next ~u "$link_url_pattern"]} error]

         if {$errno eq "0"} {
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

     return [expr int([expr {rand()}] * $range)]
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

ad_proc ::twt::set_crawler_exclude_links { url_list } {
    A list of URLs that the crawler should not visit (for example
    URLs that would delete data that shouldn't be deleted).

    @author Peter Marklund
} {
    global __crawler_exclude_links
    
    set __crawler_exclude_links $url_list
}

ad_proc ::twt::get_crawler_exclude_links {} {
    Get the list of URLs that the crawler should exclude.

    @see ::twt::set_crawler_exclude_links

    @author Peter Marklund
} {
    global __crawler_exclude_links

    if { [info exists __crawler_exclude_links] } {
        return $__crawler_exclude_links
    } else {
        return {}
    }
}

ad_proc ::twt::exclude_crawl_link_p { url } {
    Return 1 if the given URL matches the patterns in the
    URL exclude list and 0 otherwise.
} {
    foreach exclude_pattern [get_crawler_exclude_links] {
        if { [regexp [string trim $exclude_pattern] $url] } {
            return 1
        }
    }

    return 0
}

ad_proc ::twt::record_excluded_url { url } {
    Record that a URL was not crawled because it matched
    a pattern in the exclude list.
} {
    global __crawler_excluded_links
    
    lappend __crawler_excluded_links $url
}

ad_proc ::twt::get_excluded_urls {} {
    global __crawler_excluded_links
    
    if { [info exists __crawler_excluded_links] } {
        return $__crawler_excluded_links
    } else {
        return {}
    }
}

ad_proc ::twt::crawl_links { 
    {-max_requests 2000}
    {-previous_url ""}
    start_url 
} {
    Crawl links recursively under the given
    url. For example, if start_url is "/simulation" then a link
    with the URL "/simulation/object-display?object_id=125" would be visited
    whereas a link with a URL not under "/simulation", such as "/", would not.
    Never visit links with external URLs (outside the server). 

    @param max_requests The maximum number of links that the proc will crawl
    @param start_url    The url to start crawling from. The first
                        time the proc is invoked the start_url needs to have
                        a trailing slash if it is a directory.

    @author Peter Marklund
} {
    if { $previous_url ne "" } {
        # For relative links to work, when we come back from the recursive crawling of a link, we need to make
        # Tclwebtest understand that we are now relative to a different URL than the one last requested, namely
        # relative to the URL of the page the link is on.
        #::twt::log "pm debug setting previous_url $previous_url"
        #::twt::log "pm debug set ::tclwebtest::url $previous_url"
        set ::tclwebtest::url $previous_url
    }

    # Return if given start URL is external
    set server_url [::twt::config::server_url]    
    #::twt::log "pm debug about to generate absolute_url start_url=$start_url previous_url=$previous_url"
    set start_url_absolute [tclwebtest::absolute_link $start_url]
    #::twt::log "pm debug after generating absolute_url start_url_absolute=$start_url_absolute"
    if { [string first $server_url $start_url_absolute] == -1 } {
        #::twt::log "pm debug returning because link $start_url_absolute is external"
        return
    }

    # Also return if this is the logout link
    if { [regexp {/register/logout} $start_url match] } {
        #::twt::log "pm debug returning because link $start_url_absolute is logout"
        return
    }

    global __url_history

    # Return if maximum number of links is exceeded
    if { [llength $__url_history] > $max_requests } {
        ::twt::log "[::twt::config::alert_keyword] - maximum number of links exceeded, not following link to $start_url_absolute"
        return
    }

    # Before requesting, check if the URL matches the exclude list
    if { [::twt::exclude_crawl_link_p $start_url_absolute] } {
        # Keep a record of URLs not visited because the matched the exclude link
        ::twt::record_excluded_url $start_url_absolute
        return
    }

    lappend __url_history $start_url_absolute
    # Request the page
    #::twt::log "pm debug about to invoke \"do_request $start_url_absolute\" start_url=$start_url previous_url=$previous_url"
    # Note that we are re-initializing start_url_absolute here since a trailing slash will be added if the URL is a directory
    # and we need that to resolve relative URLs
    if { [catch {set foobar [::twt::do_request $start_url_absolute]} errmsg] } {
        if { "$previous_url" ne "" } {
            set previous_page_message " (link found on page $previous_url)"
        } else {
            set previous_page_message ""
        }
        ::twt::log "[::twt::config::alert_keyword] - requesting url $start_url_absolute failed${previous_page_message}. Response status is [response status] and error is $errmsg"
        return
    } else {
        #::twt::log "pm debug after do_request ::tclwebtest::url=$::tclwebtest::url start_url_absolute=$start_url_absolute foobar=$foobar"
        set start_url_absolute $::tclwebtest::url
    }

    # Get all links on the page
    if { [catch {set all_links [link all]} errmsg] } {
        #::twt::log "pm debug could not get links for url $start_url_absolute : $errmsg"
        return
    }

    # Loop over and recurse on each appropriate link
    foreach link_list $all_links {
        array set link $link_list
        set url $link(url)
        set absolute_url [tclwebtest::absolute_link $url]

        # Don't revisit URL:s we have already tested
        # Don't follow relative anchors on pages - can't get them to work with TclWebtest
        set new_url_p [expr {[lsearch -exact $__url_history $absolute_url] == -1}]
        if { [string range $url 0 0] == "#" } {
            set anchor_link_p 1
        } else {
            set anchor_link_p 0
        }
        #::twt::log "pm debug under_start_url_p - string first $start_url_absolute $absolute_url"
        set under_start_url_p [expr {[string first $start_url_absolute $absolute_url] != -1}]

        set visit_p [expr {$new_url_p && !$anchor_link_p && $under_start_url_p}]
        if { $visit_p } {
            crawl_links -previous_url $start_url_absolute $url
        }

        #::twt::log "pm debug looping with url $absolute_url visit_p=$visit_p new_url_p=$new_url_p under_start_url_p=$under_start_url_p anchor_link_p=$anchor_link_p"
    }
}

ad_proc ::twt::multiple_select_value { name value } {
    Selects the option with the given value in the current
    form widget (workaround since I can only get tclwebtest
    to select based on label).
} {
    field find ~n $name

    array set current_field [field current]
    set field_choices $current_field(choices)
    set index 0
    foreach field_choice $field_choices {
        if {$value eq [lindex $field_choice 0]} {
            break
        }
        incr index
    }

    ::tclwebtest::field_select -index $index
}

ad_proc ::twt::count_links { pattern } {

    set count 0
    foreach link_list [link all] {
        array set link $link_list

        if { [regexp $pattern $link(url)] } {
            incr count
        }
    }

    return $count
}

# No longer needed as the problem was due to malformed HTML and is
# better handled within tclwebtest
#  ad_proc ::twt::all_urls {} {
#      Returns all urls on the page last requested.

#      This proc is a workaround to the problem
#      with Tclwebtest not always finding all links with the [link all]
#      command.

#      @return A list of URLs of the last requested page

#      @author Peter Marklund
#  } {
#      set all_urls [list]
#      set remaining_body [response body]
#      while { [regexp -all {^(.*?)<a href="?([^">]+)(.*)$} $remaining_body match before_match link_url remaining_body] } {
#          lappend all_urls $link_url
#      }    
    
#      return $all_urls
#  }
