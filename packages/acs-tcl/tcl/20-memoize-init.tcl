# Create the cache used by util_memoize.

# Note: we must pass the package_id to parameter::get, because
# otherwise parameter::get will end up calling util_memoize to figure
# out the package_id.

ns_cache create util_memoize -size \
    [parameter::get -package_id [ad_acs_kernel_id] -parameter MaxSize -default 200000]


# We construct the body of util_memoize_flush differently depending
# on whether clustering is enabled and what command is available for
# cluster-wide flushing.

if {[info commands ncf.send] ne ""} {
    set flush_body {
        ncf.send util_memoize $script
    }
} elseif {[server_cluster_enabled_p] && [info commands server_cluster_httpget_from_peers] ne ""} {
    set flush_body {
        server_cluster_httpget_from_peers "/SYSTEM/flush-memoized-statement.tcl?statement=[ns_urlencode $script]"
    }
} else {
    set flush_body {}
}

append flush_body {
    ns_cache flush util_memoize $script
}

ad_proc -public util_memoize_flush {script} {
    Forget any cached value for <i>script</i>.  If clustering is
    enabled, flush the caches on all servers in the cluster.

    @param script The Tcl script whose cached value should be flushed.
} $flush_body

unset flush_body

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
