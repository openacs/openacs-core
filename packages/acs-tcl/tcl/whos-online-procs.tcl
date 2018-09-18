ad_library {
    Provides support for registering which users are online.

    @author Bjoern Kiesbye
    @author Peter Marklund
    @author Lars Pind
    @creation-date 03 October 2003
    @cvs-id $Id$
}

# TODO: Count anonymous users based on their IP, just to have the number

namespace eval whos_online {}


ad_proc -private whos_online::init {} {
    Schedules the flush proc that cleans up old who's online values.
    Makes sure the unregistered visitor (user_id=0) is invisible.

    @author Bjoern Kiesbye
} {
    ad_schedule_proc -thread t 3600 whos_online::flush

    # We typically don't want to see the unregistered user in the who's online list
    set_invisible 0
}

ad_proc -private whos_online::flush {} {
    Removing all user_ids from the last_hit (nsv_set) which have a timestamp older than
    the number of seconds indicated by the proc whos_online::interval.

    @author Bjoern Kiesbye
} {
    array set last_hit [nsv_array get last_hit]
    set onliners_out [list]
    set interval 1
    set oldtime [expr {[ns_time] - [interval]}]

    for { set search [array startsearch last_hit] } { [array anymore last_hit $search] } {} {
        set user [array nextelement last_hit $search]
        set time $last_hit($user)
        if {$time<$oldtime} {
            lappend onliners_out $user
        }
    }

    array donesearch last_hit $search

    for { set i 0 } { $i < [llength $onliners_out] } { incr i } {
        set user_id [lindex $onliners_out $i]
        foreach name { last_hit invsible_users first_hit } {
            if { [nsv_exists $name $user_id] } {
                nsv_unset $name $user_id
            }
        }
    }
}

ad_proc -private whos_online::interval {} {
    Returns the last number of seconds within a user must have requested
    a page to be considered online. Based on the LastVisitUpdateInterval parameter
    of the main site and defaults to 600 seconds = 10 minutes.

    @author Peter Marklund
} {
    return [parameter::get \
                -package_id [subsite::main_site_id] \
                -parameter LastVisitUpdateInterval \
                -default 600]
}

ad_proc -private whos_online::user_requested_page { user_id } {
    Records that the user with given id requested a page on the server

    @author Bjoern Kiesbye
} {
    if { $user_id != 0 } {
        nsv_set last_hit $user_id [ns_time]
        if { ![nsv_exists first_hit $user_id] } {
            nsv_set first_hit $user_id [ns_time]
        }
    } else {
        # TODO: Record the IP address from [ad_conn peeraddr]
    }
}

ad_proc -public whos_online::seconds_since_last_request { user_id } {
    Returns the number of seconds since the user with given id requested
    a page. Returns the empty string if the user is not currently online.

    @author Peter Marklund
} {
    if { [nsv_exists last_hit $user_id] } {
        return [expr {[ns_time] - [nsv_get last_hit $user_id]}]
    } else {
        return {}
    }
}

ad_proc -public whos_online::seconds_since_first_request { user_id } {
    Returns the number of seconds since the user with given id first requested
    a page. Returns the empty string if the user is not currently online.

    @author Peter Marklund
} {
    if { [nsv_exists last_hit $user_id] } {
        return [expr {[ns_time] - [nsv_get first_hit $user_id]}]
    } else {
        return {}
    }
}

ad_proc -public whos_online::num_users {} {
    Get the number of registered users currently online, and not invisible
} {
    # We might want to optimize this, but for now, let's just do it this way:
    return [llength [whos_online::user_ids]]
}

ad_proc -public whos_online::num_anonymous {} {
    Get the number of anonymous users currently online, and not invisible
} {
    # Not implemented yet: number of anonymous users counted by IP + number of invisible users
    return 0
}

ad_proc -public whos_online::user_ids {
    {-all:boolean}
} {
    This function returns a list of user_ids from users which have requested a page
    from this Server in the last 10 min and aren't set to invisible.

    @param all Set this flag if you want to include invisible users.

    @author Bjoern Kiesbye
} {
    array set last_hit [nsv_array get last_hit]
    set onliners [list]
    set oldtime [expr {[ns_time] - [interval]}]

    for { set search [array startsearch last_hit] } { [array anymore last_hit $search] } {} {
        set user_id [array nextelement last_hit $search]
        if { $last_hit($user_id) > $oldtime } {
            # User is online
            if { $all_p || ![user_invisible_p $user_id] } {
                # And he's not invisible, or we want all users
                lappend onliners $user_id
            }
        }
    }

    array donesearch last_hit $search

    return $onliners
}

ad_proc -public whos_online::set_invisible {
    user_id
} {
    This procedure sets the user user_id to invisible,
    his user_id will not be returned by user_ids.
    The invisible state will only last as long as the user is online.

    @author Bjoern Kiesbye
} {
    nsv_set invisible_users $user_id [ns_time]
}

ad_proc -public whos_online::unset_invisible {
    user_id
} {
    This procedure unsets the invisible state of user_id.

    @author Bjoern Kiesbye
} {
    if { [nsv_exists invisible_users $user_id] } {
        nsv_unset invisible_users $user_id
    }
}


ad_proc -public whos_online::user_invisible_p {
    user_id
} {
    This function checks if the user user_id is set
    to invisible. Returns a Tcl boolean.

    @author Bjoern Kiesbye
} {
    return [nsv_exists invisible_users $user_id]
}

ad_proc -public whos_online::all_invisible_user_ids {} {
    This function returns a list with all user_ids which are set to invisible

    @author Bjoern Kiesbye
} {
    return [nsv_array names invisible_users]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
