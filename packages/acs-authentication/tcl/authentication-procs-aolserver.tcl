ad_library {

    Provides the caching implementation of the brute force 
    login prevention feature.

    @author Guenter Ernst (guenter.ernst@wu.ac.at)
    @creation-date 28 Feb 2018
    @cvs-id $Id:
}

if {[ns_info name] eq "NaviServer"} {
    return
}

#-------------------------------------------------------------------------
# AOLserver implementation of the brute force 
# login prevention feature caching procs
#-------------------------------------------------------------------------

namespace eval auth::login_attempts {}

ad_proc -private ::auth::login_attempts::login_attempt_incr {
    {-key:required}
    {-max_age 21600}
}  {
    Increment the login attempts of a user.
    The max_age is specified in seconds.
} {
    set key login-attempt-$key
    set current_time [ns_time]

    set cached_p [ns_cache get util_memoize $key pair]
    if {$cached_p} {
        set cache_time [lindex $pair 0]
        if {$current_time - $cache_time > $max_age} {
            ns_cache flush util_memoize $key
            set cached_p 0
        }
    }

    if {!$cached_p} {
        set pair [ns_cache set util_memoize $key [list $current_time 1]]
    } else {
        ns_cache flush util_memoize $key
        set old_value [lindex $pair 1]
        set pair [ns_cache set util_memoize $key [list $current_time [incr old_value]]]
    }
    return [lindex $pair 1]
}

ad_proc -private ::auth::login_attempts::login_attempt_flush {
    {-key:required}
}  {
    Flush the login attempts of a user.
} {
    ns_cache flush util_memoize login-attempt-$key
}

ad_proc -private ::auth::login_attempts::flush_all {}  {
    Flush all login attempt counters
} {
    
    set keys [ns_cache names util_memoize login-attempt-*]
    
    ns_cache flush util_memoize {*}$keys
}

ad_proc -private ::auth::login_attempts::get {
    {-key:required}
}  {
    Get the current count of login attempts of a user.
} {

    set current_time [ns_time]
    set max_age [parameter::get_from_package_key \
                    -parameter "MaxConsecutiveFailedLoginAttemptsLockoutTime" \
                    -package_key "acs-authentication" \
                    -default 21600]

    set cached_p [ns_cache get util_memoize login-attempt-$key pair]

    if {$cached_p} {
        lassign $pair cache_time count

        if {$current_time - $cache_time > $max_age} {
            ns_cache flush util_memoize $key
            return 0
        }

        return $count

    } else {
        return 0
    }
}

ad_proc -private ::auth::login_attempts::all_entries {}  {
    Get all login attempts

    @return list {key number_of_attempts timeout}
} {

    set result {}
    set current_time [ns_time]
    set max_age [parameter::get_from_package_key \
                    -parameter "MaxConsecutiveFailedLoginAttemptsLockoutTime" \
                    -package_key "acs-authentication" \
                    -default 21600]

    foreach key [ns_cache names util_memoize login-attempt-*] {
        set cached_p [ns_cache get util_memoize $key pair]

        if {$cached_p} {
            lassign $pair cache_time count

            if {$current_time - $cache_time > $max_age} {
                ns_cache flush util_memoize $key
            } else {
                lappend result [string range $key 14 end] $cache_time $count
            }
        }
    }

    return $result
}



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
