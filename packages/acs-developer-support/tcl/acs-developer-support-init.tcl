# $Id$
# File:        developer-support-init.tcl
# Author:      Jon Salz <jsalz@mit.edu>
# Date:        22 Apr 2000
# Description: Provides routines used to aggregate request/response information for debugging.

# Make sure we do the setup only once
if { ![nsv_exists ds_properties enabled_p] } {
    ad_register_filter -critical t -priority 999999 trace * /* ds_trace_filter
    ad_schedule_proc [ad_parameter -package_id [ds_instance_id] DataSweepInterval acs-developer-support 900] ds_sweep_data
    nsv_array set ds_request [list]

    nsv_set ds_properties enabled_p [ad_parameter -package_id [ds_instance_id] EnabledOnStartupP acs-developer-support 0]

    # Take the IP list (space or comma seperated) and turn it into a tcl list.
    set IPs [list]
    foreach ip [lsort -unique [split [ad_parameter -package_id [ds_instance_id] EnabledIPs acs-developer-support *] { ,}]] { 
        if {[string equal $ip "*"]} {
            # a star means anything will match so just use the * instead
            set IPs "*"
            break
        } elseif {![empty_string_p $ip]} {
            lappend IPs $ip
        }
    }
    nsv_set ds_properties enabled_ips $IPs


    nsv_set ds_properties database_enabled_p [ad_parameter -package_id [ds_instance_id] DatabaseEnabledP developer-support 0]

    nsv_set ds_properties adp_reveal_enabled_p [ad_parameter -package_id [ds_instance_id] AdpRevealEnabledP developer-support 0]

    nsv_set ds_properties page_fragment_cache_p [ad_parameter -package_id [ds_instance_id] PageFragmentCacheP developer-support 0]

    ds_set_user_switching_enabled [ad_parameter -package_id [ds_instance_id] UserSwitchingEnabledP acs-developer-support 0]

    # JCD: used to cache rendered page bits.  cap at 10mb for now.
    ns_cache create ds_page_bits -size 10000000
}

ds_watch_packages
