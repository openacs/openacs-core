# $Id$
# File:        developer-support-init.tcl
# Author:      Jon Salz <jsalz@mit.edu>
# Date:        22 Apr 2000
# Description: Provides routines used to aggregate request/response information for debugging.

# Make sure we do the setup only once
if { ![nsv_exists ds_properties enabled_p] } {
    ad_register_filter -critical t -priority 999999 trace * /* ds_trace_filter
    ad_schedule_proc [parameter::get -package_id [ds_instance_id] -parameter DataSweepInterval -default 900] ds_sweep_data
    nsv_array set ds_request [list]

    nsv_set ds_properties enabled_p [parameter::get -package_id [ds_instance_id] -parameter EnabledOnStartupP -default 0]

    # Take the IP list (space or comma separated) and turn it into a Tcl list.
    set IPs [list]
    foreach ip [lsort -unique [split [parameter::get -package_id [ds_instance_id] -parameter EnabledIPs -default *] { ,}]] { 
        if {$ip eq "*"} {
            # a star means anything will match so just use the * instead
            set IPs "*"
            break
        } elseif {$ip ne ""} {
            lappend IPs $ip
        }
    }
    nsv_set ds_properties enabled_ips $IPs

    nsv_set ds_properties profiling_enabled_p [parameter::get -package_id [ds_instance_id] -parameter ProfilingEnabledP -default 0]

    nsv_set ds_properties database_enabled_p [parameter::get -package_id [ds_instance_id] -parameter DatabaseEnabledP -default 0]

    nsv_set ds_properties adp_reveal_enabled_p [parameter::get -package_id [ds_instance_id] -parameter AdpRevealEnabledP -default 0]

    nsv_set ds_properties page_fragment_cache_p [parameter::get -package_id [ds_instance_id] -parameter PageFragmentCacheP -default 0]

    ds_set_user_switching_enabled [parameter::get -package_id [ds_instance_id] -parameter UserSwitchingEnabledP -default 0]

    # JCD: used to cache rendered page bits.  cap at 10mb for now.
    ns_cache create ds_page_bits -size 10000000
}

ds_watch_packages

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
