ad_library {

    Provides the caching implementation of the brute force 
    login prevention feature.

    @author Guenter Ernst (guenter.ernst@wu.ac.at)
    @creation-date 28 Feb 2018
    @cvs-id $Id$
}


if {[ns_info name] ne "NaviServer"} {
    return
}

#-------------------------------------------------------------------------
# NaviServer implementation of the brute force 
#    login prevention feature caching procs
#-------------------------------------------------------------------------
namespace eval auth::login_attempts {}

ad_proc -private ::auth::login_attempts::login_attempt_incr {
    {-key:required}
    {-max_age 21600}
}  {
    Increment the login attempts of a user.
    The max_age is specified in seconds.
} {
    return [ns_cache_incr -expires $max_age -- ns:memoize login-attempt-$key]
}


ad_proc -private ::auth::login_attempts::login_attempt_flush {
    {-key:required}
}  {
    Flush the login attempts of a user.
} {
    ns_cache_flush ns:memoize login-attempt-$key
}

ad_proc -private ::auth::login_attempts::flush_all {}  {
    Flush all login attempt counters.
} {
    ns_cache_flush -glob -- ns:memoize login-attempt-*
}    

ad_proc -private ::auth::login_attempts::get {
    {-key:required}
}  {
    Get the current number of login attempts of a user.
} {
    if {[ns_cache get ns:memoize login-attempt-$key value]} {
        return $value
    } else {
        return 0
    }

}

ad_proc -private ::auth::login_attempts::all_entries {}  {
    Get all login attempts

    @return list {key number_of_attempts timeout ... }
} {

    set result [list]
    set keys [ns_cache_keys ns:memoize]
    set contents [lindex [ns_cache_stats -contents -- ns:memoize] 0]

    foreach key $keys {size timeout} $contents {
        if {![string match "login-attempt-*" $key]} {
            continue
        }

        set value ""
        ns_cache_get ns:memoize $key value

        lappend result [string range $key 14 end] [ns_time seconds $timeout] $value
    }

    return $result

}



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

