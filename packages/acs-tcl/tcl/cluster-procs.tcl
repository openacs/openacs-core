#
#    Copyright (C) 2022 Gustaf Neumann, neumann@wu-wien.ac.at
#
#       Vienna University of Economics and Business
#       Institute of Information Systems and New Media
#       A-1020, Welthandelsplatz 1
#       Vienna, Austria
#
#    This is a BSD-Style license applicable for this file.
#
#    Permission to use, copy, modify, distribute, and sell this
#    software and its documentation for any purpose is hereby granted
#    without fee, provided that the above copyright notice appears in
#    all copies and that both that copyright notice and this permission
#    notice appear in supporting documentation. We make no
#    representations about the suitability of this software for any
#    purpose.  It is provided "as is" without express or implied
#    warranty.
#

namespace eval ::acs {
    ##########################################################################
    #
    # Cluster Management
    #
    # If a site is running a cluster of OpenACS systems, certain
    # commands have to be executed on cluster nodes (e.g. flushing
    # caches, etc). A cluster setup is currently not commonly used and
    # requires probably some more work, but the code here provides a
    # basic infrastructure. It is a good practice to flag commands to
    # be executed on all cluster nodes in the code with
    # ::acs::clusterwide.
    ##########################################################################

    proc clusterwide args {
        #
        # First, execute the command on the local server.
        #
        eval $args
        #
        # Then, distribute the command to all servers in the cluster.
        #
        ::acs::Cluster broadcast {*}$args
    }

    proc cache_flush_all {cache pattern} {
        #
        # Provide means to perform a wildcard-based cache flushing on
        # (cluster) machines.
        #
        foreach n [ns_cache names $cache $pattern] {
            ns_cache flush $cache $n
        }
    }

    nx::Class create Cluster {
        :property {proto http}
        :property host
        :property {port 80}
        :property {url /acs-cluster-do}

        set :allowed_host_patterns [list]
        set :url /acs-cluster-do
        array set :allowed_host { "127.0.0.1" 1 }

        #
        # The allowed commands are of the form
        #   - command names followed by
        #   - optional "except patterns"
        #
        set :allowed_command {
            set ""
            unset ""
            nsv_set ""
            nsv_unset ""
            nsv_incr ""
            nsv_dict ""
            bgdelivery ""
            callback ""
            ns_cache "^ns_cache\s+eval"
            ns_cache_flush ""
            ns_urlspace ""
            acs::cache_flush_all ""
        }

        :object method log {args} {
            ns_log notice "cluster: [join $args { }]"
        }
        :method log {args} {
            ns_log notice "cluster host ${:host} ${:port}: [join $args { }]"
        }

        #
        # Handling the ns_filter methods
        #
        :public object method trace args {
            #:log "trace"
            return filter_return
        }

        :public object method preauth args {
            #:log "preauth"
            :incoming_request
            return filter_return
        }

        :public object method postauth args {
            #:log "postauth"
            return filter_return
        }

        :public object method allowed_command {cmd} {
            #
            # Check, which command are allowed to be executed in the
            # cluster.
            #

            #ns_log notice "--cluster allowed [dict keys ${:allowed_command}]?"
            set cmd_name [lindex $cmd 0]
            #ns_log notice "--cluster can i execute $cmd_name? [dict exists ${:allowed_command} $cmd_name]"
            if {[dict exists ${:allowed_command} $cmd_name]} {
                set except_RE [dict get ${:allowed_command} $cmd_name]
                #ns_log notice "--cluster [list regexp $except_RE $cmd] -> [regexp $except_RE $cmd]"
                set allowed [expr {$except_RE eq "" || ![regexp $except_RE $cmd]}]
            } else {
                set allowed 0
            }
            return $allowed
        }

        #
        # handle incoming request issues
        #
        :public object method incoming_request {} {
            set cmd [ns_queryget cmd]
            set addr [lindex [ns_set iget [ns_conn headers] x-forwarded-for] end]
            if {$addr eq ""} {set addr [ns_conn peeraddr]}
            #ns_log notice "--cluster got cmd='$cmd' from $addr"
            ad_try {
                set result [::acs::Cluster execute [ns_conn peeraddr] $cmd]
            } on error {errorMsg} {
                ns_log notice "--cluster error: $errorMsg"
                ns_return 417 text/plain $errorMsg
            } on ok {r} {
                #ns_log notice "--cluster success $result"
                ns_return 200 text/plain $result
            }
        }

        #
        # Handling outgoing requests
        #
        :public object method execute {host cmd} {
            if {![info exists :allowed_host($host)]} {
                set ok 0
                foreach g ${:allowed_host_patterns} {
                    if {[string match $g $host]} {
                        set ok 1
                        break
                    }
                }
                if {!$ok} {
                    error "refuse to execute commands from $host (command: '$cmd')"
                }
            }
            if {[::acs::Cluster allowed_command $cmd]} {
                ns_log notice "--cluster executes command '$cmd' from host $host"
                return [eval $cmd]
            }
            error "command '$cmd' from host $host not allowed"
        }

        :public object method broadcast args {
            #
            # Send requests to all cluster nodes.
            #

            # Small optimization for cachingmode "none": no need to
            # send cache flushing requests to nodes, when there is no
            # caching in place.
            #
            if {[ns_config "ns/parameters" cachingmode "per-node"] eq "none"
                && [lindex $args 0] in {acs::cache_flush_all ns_cache}} {
                #
                # If caching mode is none, it is expected that all
                # nodes have this parameter set. Therefore, there is no
                # need to communicate cache flushing commands.
                #
                return
            }

            foreach server [:info instances] {
                $server message {*}$args
            }
        }

        :public object method refresh_blueprint {} {
            #
            # Update the blueprint in case the nodes have
            # changed. This might happen, when the configuration
            # variables changed, or when nodes become
            # available/unvavailable after some time.
            #
            set oldConfig [::acs::Cluster info instances]
            :register_nodes
            set newConfig [::acs::Cluster info instances]
            if {$newConfig ne $oldConfig} {
                set code ""
                foreach obj $newConfig {
                    append code [$obj serialize] \n
                }
                ns_log notice "cluster: node configuration changed:\n$code"
                ns_eval $code
            }
        }

        :public object method register_nodes {} {
            #
            # Register the defined cluster nodes
            #

            #
            # First delete the old cluster node objects
            #
            foreach node [::acs::Cluster info instances] {
                $node destroy
            }

            #
            # Base configuration values
            #
            set cluster_do_url [::acs::Cluster eval {set :url}]
            set myConfig [server_cluster_my_config]

            #
            # Create new cluster node objects. Iterate over all
            # servers in the cluster and add Cluster objects for the
            # ones, which are different from the current host (the
            # peer hosts).
            #
            foreach hostport [server_cluster_all_hosts] {
                try {
                    server_cluster_get_config $hostport
                } on ok {config} {
                } on error {errorMsg} {
                    ns_log notice "ignore $hostport (server_cluster_get_config returned $errorMsg)"
                    continue
                }
                dict with config {
                    if {$host in [dict get $myConfig host]
                        && $port in [dict get $myConfig port]
                    } {
                        ns_log debug "Cluster: server $host $port is no cluster peer"
                        continue
                    }
                    try {
                        ns_connchan connect $host $port
                    } on error {} {
                        ns_log notice "Cluster: server $host $port is not available"
                        continue
                    } on ok {chan} {
                        ns_connchan close $chan
                    }

                    ns_log debug "Cluster: server $host $port is an available cluster peer"
                    ::acs::Cluster create CS_${host}_${port} \
                        -proto $proto \
                        -host $host \
                        -port $port \
                        -url $cluster_do_url
                }
            }
        }

        :public method message args {
            :log "--cluster outgoing request to ${:proto}://${:host}:${:port} // $args"
            try {
                ns_http run ${:proto}://${:host}:${:port}/${:url}?cmd=[ns_urlencode $args]
            } on error {errorMsg} {
                ns_log warning "-cluster: send message to ${:proto}://${:host}:${:port}/${:url}?cmd=[ns_urlencode $args] failed: $errorMsg"
            } on ok {result} {
                ns_log notice "-cluster: response $result"
            }
        }
    }

}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
