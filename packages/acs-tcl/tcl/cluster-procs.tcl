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
        set result [eval $args]
        #
        # Then, distribute the command to all servers in the cluster.
        #
        ::acs::Cluster broadcast {*}$args
        return $result
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
        :property {chan}

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
            util_memoize_flush_regexp_local ""
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
        :public object method preauth args {
            #ns_log notice "PREAUTH returns filter_break"
            return filter_break
        }

        :public object method postauth args {
            #ns_log notice "POSTAUTH returns filter_break"
            return filter_break
        }

        :public object method trace args {
            #:log "trace"
            #ns_log notice "TRACE handles request"
            #:incoming_request
            #ns_log notice "TRACE returns filter_return"
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
            } elseif {[nsf::is object $cmd_name]
                      && ($cmd_name ::nsf::methods::object::info::hastype acs::Cache
                          || $cmd_name ::nsf::methods::object::info::hastype acs::LockfreeCache)} {
                #
                # Allow operations on cache objects (e.g. needed for)
                #
                ns_log notice "--cluster acs_cache operation: $cmd"
                set allowed 1
            } else {
                set allowed 0
            }
            return $allowed
        }

        #
        # handle incoming request issues
        #
        :public object method incoming_request {} {
            catch {::throttle do incr ::count(cluster:received)}
            set cmd [ns_queryget cmd]
            set addr [lindex [ns_set iget [ns_conn headers] x-forwarded-for] end]
            set sender [ns_set iget [ns_conn headers] host]
            nsv_set cluster $sender-update [clock clicks -milliseconds]
            nsv_incr cluster $sender-count
            if {$addr eq ""} {set addr [ns_conn peeraddr]}
            ns_log notice "--cluster got cmd='$cmd' from $addr // sender $sender"
            ad_try {
                #ns_logctl severity Debug(connchan) on
                #ns_logctl severity Debug(request) on
                #ns_logctl severity Debug(ns:driver) on
                #ns_logctl severity Debug on

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
        # Handling incoming requests from host
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
                ns_log notice "--cluster executes command '$cmd' from host $host port [ns_conn peerport]"
                return [eval $cmd]
            }
            error "command '$cmd' from host $host not allowed"
        }

        :public object method broadcast args {
            #
            # Send requests to all cluster nodes.
            #
            if {[ns_ictl epoch] > 0} {
                catch {::throttle do incr ::count(cluster:broadcast)}
            }

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

            if {[ns_ictl epoch] > 0} {
                foreach server [:info instances] {
                    catch {::throttle do incr ::count(cluster:sent)}
                    set t0 [clock clicks -microseconds]
                    $server message {*}$args
                    set ms [expr {([clock clicks -microseconds] - $t0)/1000}]
                    catch {::throttle do incr ::agg_time(cluster:sent) $ms}
                }
            } else {
                foreach server [:info instances] {
                    $server message {*}$args
                }
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

        :public object method check_nodes {} {
            #
            # For the time being (testing only) just measure some
            # times from the canonical server with hardcoded locations
            #
            if {[ad_canonical_server_p]} {
                ns_log notice "-------check nodes"
                ::acs::CS_127.0.0.1_8101 message set x ns_http
                ::acs::CS_127.0.0.1_8444 message set x ns_https
                ::acs::CS_127.0.0.1_8101 message -delivery connchan set x ns_connchan
                ::acs::CS_127.0.0.1_8444 message -delivery connchan set x https-connchan
                ::acs::CS_127.0.0.1_8101 message -delivery udp set x udp
            }
            # foreach node [::acs::Cluster info instances] {
            #     if {[$node require_connchan_channel]} {
            #         if {$node eq "::acs::CS_127.0.0.1_8101"} {
            #             #ns_log notice "[self] check_node $node is connected [$node cget -chan]"
            #             #ns_logctl severity Debug(connchan) on
            #             #ns_logctl severity Debug(request) on
            #             #ns_logctl severity Debug(ns:driver) on
            #             #ns_logctl severity Debug on
            #             $node connchan_message set ok 123
            #         }
            #     } else {
            #         #
            #         # We see a warning message in the log file, when
            #         # the server cannot connect to the node.
            #         #
            #         #ns_log notice "[self] check_node $node is not connected"
            #     }
            # }
            set :to [::after 1000 [list [self] check_nodes]]

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
            foreach location [server_cluster_all_hosts] {
                ns_log notice "creating ::acs::Cluster on $location"
                try {
                    server_cluster_get_config $location
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
                    # try {
                    #     ns_logctl severity Debug(connchan) on
                    #     ns_connchan connect $host $port
                    # } on error {} {
                    #     ns_log notice "Cluster: server $host $port is not available"
                    #     continue
                    # } on ok {chan} {
                    #     ns_connchan close $chan
                    # }

                    # ns_log debug "Cluster: server $host $port is an available cluster peer"
                    ns_log notice "call create ::acs::Cluster create CS_${host}_${port}"

                    ::acs::Cluster create CS_${host}_${port} \
                        -proto $proto \
                        -host $host \
                        -port $port \
                        -url $cluster_do_url
                }
            }
        }
        :method name {} {
            return ${:proto}://${:host}:${:port}
        }

        :public method require_connchan_channel {} {
            #
            #
            #
            if {![info exists :chan]} {
                set tlsOption [expr {${:proto} in {https} ? "-tls" : ""}]
                try {
                    set :retry 0
                    ns_connchan connect -timeout 10ms {*}$tlsOption ${:host} ${:port}
                } on ok {result} {
                    set :chan $result
                    ns_log notice "-cluster: [:name] connected - channel ${:chan}"
                } on error {errorMsg} {
                    ns_log warning "-cluster: [:name] can not connect"
                }
            }
            return [info exists :chan]
        }
        :public method has_channel {} {
            return [info exists :chan]
        }

        :method connchan_retry_message {args} {
            #
            # Make a single retry to send an HTTP message to this node
            # and return its full HTTP response on success.
            #

            #
            # Cleanup old connection
            #
            try {
                ns_connchan close ${:chan}
            } on error {errorMsg} {
                ns_log notice "... connchan ${:chan} CLOSE returns error $errorMsg, giving up"
                return
            }
            unset -nocomplain :chan
            #
            # Create at new connection, but notice retry mode to avoid
            # endless retries for one message
            #
            #ns_log notice "... connchan ${:chan} CLOSED"
            if {[:require_connchan_channel]} {
                set :retry 1
                ns_log notice "-cluster: [self] connchan RETRY channel ${:chan}"
                :connchan_message {*}$args
            }
        }

        :method connchan_message {args} {
            #
            # Send an HTTP message to this node and return its full HTTP
            # response on success.
            #
            set reply ""
            #set t0 [clock clicks -microseconds]
            if {[:require_connchan_channel]} {
                set message "GET /${:url}?cmd=[ns_urlencode $args] HTTP/1.1\r\nHost:localhost\r\n\r\n"
                #ns_log notice "-cluster: send $message to ${:proto}://${:host}:${:port}"

                try {
                    ns_connchan write ${:chan} $message
                    #set t2 [clock clicks -microseconds]
                    #ns_log notice "... message sent"
                    set reply [ns_connchan read ${:chan}]
                    #set t3 [clock clicks -microseconds]

                    #ns_log notice "... reply $reply"
                } on error {errorMsg} {
                    #ns_log notice "-cluster: send $args to ${:proto}://${:host}:${:port} returned ERROR $::errorInfo $errorMsg"
                    ns_log notice "-cluster: send connchan ${:chan} error $errorMsg RETRY ${:retry}"
                    if {${:retry} == 0} {
                        set reply [:connchan_retry_message {*}$args]
                    }
                } on ok {result} {
                    set :retry 0
                    #ns_log notice "-cluster: [:name] sent OK " \
                        "total [expr {([clock clicks -microseconds] - $t0)/1000.0}]ms" \
                        "write [expr {($t2 - $t0)/1000.0}]ms" \
                        "read [expr {($t3 - $t2)/1000.0}]ms" \
                }
            }
            return $reply
        }

        :method ns_http_message args {
            #:log "--cluster outgoing request to ${:proto}://${:host}:${:port} // $args"
            try {
                ns_http run ${:proto}://${:host}:${:port}/${:url}?cmd=[ns_urlencode $args]
            } on error {errorMsg} {
                ns_log warning "-cluster: send message to ${:proto}://${:host}:${:port}/${:url}?cmd=[ns_urlencode $args] failed: $errorMsg"
                set result ""
            } on ok {result} {
                #ns_log notice "-cluster: response $result"
            }
            return $result
        }

        :method udp_message args {
            #:log "--cluster outgoing request to ${:proto}://${:host}:${:port} // $args"
            try {
                ns_udp ${:host} ${:port} "GET /${:url}?cmd=[ns_urlencode $args] HTTP/1.0\n\n"
            } on error {errorMsg} {
                ns_log warning "-cluster: send message to ${:proto}://${:host}:${:port}/${:url}?cmd=[ns_urlencode $args] failed: $errorMsg"
                set result ""
            } on ok {result} {
                #ns_log notice "-cluster: response $result"
            }
            return $result
        }

        :public method message {{-delivery ns_http} args} {
            #
            # Send a command by different means to the node server for
            # intra-server talk.
            #
            # Valid delivery methods are
            #  - ns_http (for HTTP and HTTPS)
            #  - connchan (for HTTP and HTTPS)
            #  - udp (plain UDP only)
            #
            #:log "--cluster outgoing request to [:name] // $args"
            set t0 [clock clicks -microseconds]
            switch $delivery {
                ns_http -
                connchan -
                udp     {set result [:${delivery}_message {*}$args]}
                default {error "unknown delivery method '$delivery'"}
            }
            ns_log notice "-cluster: [:name] $args sent" \
                "total [expr {([clock clicks -microseconds] - $t0)/1000.0}]ms"
            return $result
        }
    }

}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
