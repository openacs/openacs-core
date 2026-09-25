ad_library {
    Initializes datastructures for utility procs.
}

# initialize the random number generator
util::random_init [ns_time]

# Create mutex for util_background_exec
#nsv_set util_background_exec_mutex . [ns_mutex create oacs:bg_exec]

# if logmaxbackup in config is missing or zero, don't run auto-logrolling
set logmaxbackup [ns_config -int "ns/parameters" logmaxbackup 0]

if { $logmaxbackup } {
    ad_schedule_proc -all_servers t -schedule_proc ns_schedule_daily \
        [list 00 00] util::roll_server_log
}

nsv_set ad_log_rate_limited mutex \
    [ns_mutex create ad_log_rate_limited]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
