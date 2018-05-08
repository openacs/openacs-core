if {[ns_info version] eq "4.5"} {
    set cfgsection "ns/server/[ns_info server]"

    set minthreads [ns_config $cfgsection minthreads 5]
    set maxthreads [ns_config $cfgsection maxthreads 10]
    set maxconns   [ns_config $cfgsection maxconnections 100]
    set timeout    [ns_config $cfgsection threadtimeout 120]

    ns_pools set default -minthreads $minthreads -maxthreads $maxthreads -maxconns $maxconns -timeout $timeout

    ns_log Notice "Default Pool: [ns_pools get default]"

    # Setup optional threadpools

    set poolSection $cfgsection/pools

    set poolSet [ns_configsection $poolSection]

    if {"$poolSet" ne ""} {

        set poolSize [ns_set size $poolSet]
        for {set i 0} {$i < $poolSize} {incr i} {
            set poolName [ns_set key $poolSet $i]
            set poolDescription [ns_set value $poolSet $i]
            set poolConfigSection "ns/server/[ns_info server]/pool/$poolName"
            set poolConfigSet [ns_configsection $poolConfigSection]
            if {"$poolConfigSet" eq ""} {
                continue
            }
            set poolMinthreads [ns_config $poolConfigSection minthreads $minthreads]
            set poolMaxthreads [ns_config $poolConfigSection maxthreads $maxthreads]
            set poolMaxconns   [ns_config $poolConfigSection maxconnections $maxconns]
            set poolTimeout    [ns_config $poolConfigSection threadtimeout $timeout]

            ns_pools set $poolName -minthreads $poolMinthreads -maxthreads $poolMaxthreads -maxconns $poolMaxconns -timeout $poolTimeout
            ns_log Notice  "$poolName Pool: [ns_pools get $poolName]"
            set poolConfigSize [ns_set size $poolConfigSet]
            for {set j 0} {$j < $poolConfigSize} {incr j} {
                if {[string tolower [ns_set key $poolConfigSet $j]] eq "map"} &
                #123;
                set mapList [split [ns_set value $poolConfigSet $j]]
                lassign $mapList poolMethod poolPattern
                ns_pools register $poolName [ns_info server] $poolMethod $poolPattern
                ns_log Notice "ns_pools registered $poolName [ns_info server] $poolMethod $poolPattern"
            }
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
