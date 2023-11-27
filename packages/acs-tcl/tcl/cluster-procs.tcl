#    Copyright (C) 2022-2023 Gustaf Neumann, neumann@wu-wien.ac.at
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
        ::acs::cluster broadcast {*}$args
        return $result
    }

    proc cache_flush_pattern {cache pattern} {
        #
        # Provide means to perform a wildcard-based cache flushing on
        # (cluster) machines.
        #
        foreach n [ns_cache names $cache $pattern] {
            ns_cache flush $cache $n
        }
    }

    proc cache_flush_all {} {
        #
        # Reset all caches and flush all of its contents.
        #
        foreach cache [ns_cache_names] {
            ns_cache flush $cache
        }
    }

    #::nsf::method::property nx::Object "object method" debug on
    #::nsf::method::property nx::Class method debug on

    nx::Class create Cluster {
        :property {url /acs-cluster-do}
        :property {currentServerLocation ""}

        # set cls [nx::Class create ::acs::ClusterMethodMixin {
        #     :method "object method" args {
        #         ns_log notice "[self] define object method $args"
        #         next
        #     }
        #     :method method args {
        #         ns_log notice "[self] define method $args"
        #         next
        #     }
        # }]
        # :object mixins add $cls

        :variable allowed_host { "127.0.0.1" 1 }
        #
        # The allowed commands are of the form
        #   - command names followed by
        #   - optional "except patterns"
        #
        :variable allowed_command {
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
            acs::cache_flush_pattern ""
            ::acs::cluster "^::acs::cluster\s+join_request"
        }

        #
        # Control verbosity
        #
        :method log {args} {
            ns_log notice "cluster: [join $args { }]"
        }

        :public method setup {} {
            #
            # Setup object specific variables. Make sure to call this
            # method, when the called procs are available.
            #
            set :currentServerLocations [:current_server_locations]
            set :currentServerLocation [:preferred_location ${:currentServerLocations}]

            set :canonicalServer [parameter::get -package_id $::acs::kernel_id -parameter CanonicalServer]
            set :canonicalServerLocation [:preferred_location [:qualified_location ${:canonicalServer}]]

            set :current_server_is_canonical_server [:current_server_is_canonical_server]
            set :staticServerLocations \
                [lmap entry [parameter::get -package_id $::acs::kernel_id -parameter ClusterPeerIP] {
                    :preferred_location [:qualified_location $entry]
                }]
        }

        :method init {} {
            nsv_set cluster . .
            next
        }

        #
        # Handling the ns_filter methods (as defined in cluster-init.tcl)
        #
        :public method preauth args {
            #
            # Process no more pre-authorization filters for this
            # connection (avoid running of expensive filters).
            #
            #ns_log notice "PREAUTH returns filter_break"
            return filter_break
        }

        # :public method postauth args {
        #     #ns_log notice "POSTAUTH returns filter_break"
        #     return filter_break
        # }

        # :public method trace args {
        #     #:log "trace"
        #     #ns_log notice "TRACE handles request"
        #     #:incoming_request
        #     #ns_log notice "TRACE returns filter_return"
        #     return filter_return
        # }

        :method allowed_command {cmd} {
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
                      && ([$cmd_name ::nsf::methods::object::info::hastype acs::Cache]
                          || [$cmd_name ::nsf::methods::object::info::hastype acs::LockfreeCache])} {
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
        # Handle incoming requests
        #
        :public method incoming_request {} {
            #
            # We received an incoming request from a cluster peer.
            #
            catch {::throttle do incr ::count(cluster:received)}

            ad_try {
                #ns_logctl severity Debug(connchan) on
                #ns_logctl severity Debug(request) on
                #ns_logctl severity Debug(ns:driver) on
                #ns_logctl severity Debug on
                set r [:message decode]
                set receive_timestamp [clock clicks -milliseconds]
                dict with r {
                    #
                    # We could check here the provided timepstamp and
                    # honor only recent requests (protection against
                    # replay attacks). However, the allowed requests
                    # are non-destructive.
                    #
                    nsv_set cluster $peer-last-contact $receive_timestamp
                    nsv_set cluster $peer-last-request $receive_timestamp
                    nsv_incr cluster $peer-count
                    ns_log notice "--cluster got cmd='$cmd' from $peer after [expr {$receive_timestamp - $timestamp}]ms"

                    set result [:execute $r]
                }
            } on error {errorMsg} {
                ns_log notice "--cluster error: $errorMsg"
                ns_return 417 text/plain $errorMsg
            } on ok {r} {
                #ns_log notice "--cluster success $result"
                ns_return 200 text/plain $result
            }
        }

        #
        # Handling incoming requests from peeraddr
        #
        :method execute {messageDict} {
            #:log execute $messageDict
            dict with messageDict {
                if {$peer ni [nsv_get cluster cluster_peer_nodes]} {
                    ns_log notice ":execute: {$peer ni [nsv_get cluster cluster_peer_nodes]} // cmd $cmd"
                    set ok [dict exists ${:allowed_host} $peeraddr]
                } else {
                    set ok 1
                }
                if {!$ok} {
                    ns_log notice "could refuse to execute commands from $peeraddr (command: '$cmd') allowed [dict keys ${:allowed_host}]"
                }
                if {[:allowed_command $cmd]} {
                    ns_log notice "--cluster executes command '$cmd' from peeraddr $peeraddr port [ns_conn peerport]"
                    return [{*}$cmd]
                }
                error "command '$cmd' from peeraddr $peeraddr not allowed"
            }
        }

        :public method broadcast args {
            #
            # Send requests to all cluster peers.
            #
            if {[ns_ictl epoch] > 0} {
                catch {::throttle do incr ::count(cluster:broadcast)}
            }

            # Small optimization for cachingmode "none": no need to
            # send cache flushing requests to nodes, when there is no
            # caching in place.
            #
            if {[ns_config "ns/parameters" cachingmode "per-node"] eq "none"
                && [lindex $args 0] in {
                    acs::cache_flush_pattern
                    acs::cache_flush_all
                    ns_cache}
            } {
                #
                # If caching mode is none, it is expected that all
                # nodes have this parameter set. Therefore, there is no
                # need to communicate cache flushing commands.
                #
                return
            }

            if {[nsv_get cluster cluster_peer_nodes locations]} {
                #
                # During startup the throttle thread might not be started,
                # so omit these statistic values
                #
                if {[ns_ictl epoch] > 0} {
                    foreach location $locations {
                        catch {::throttle do incr ::count(cluster:sent)}
                        set t0 [clock clicks -microseconds]
                        :send $location {*}$args
                        set ms [expr {([clock clicks -microseconds] - $t0)/1000}]
                        catch {::throttle do incr ::agg_time(cluster:sent) $ms}
                    }
                } else {
                    foreach location $locations {
                        :send $location {*}$args
                    }
                }
            }
        }

        :public method update_node_info {} {
            #
            # Update cluster configuration when the when the
            # configuration variables changed, or when nodes become
            # available/unvavailable after some time.
            #
            # Typically, this method is called via scheduled procedure
            # every couple of seconds when clustering is enabled.
            #

            set dynamic_peers [parameter::get \
                                   -package_id $::acs::kernel_id \
                                   -parameter DynamicClusterPeers]

            if {!${:current_server_is_canonical_server}} {
                #
                # The current node might be a static or a dynamic
                # peer.  Do we have contact to the canonical_server?
                #
                if {![:reachable ${:canonicalServerLocation}]} {
                    #
                    # We lost contact to the canonical server. This is
                    # for our server not a big problem, since all
                    # other peer-to-peer updates will continue to
                    # work.
                    #
                    # During downtime of the canonical server,
                    # scheduled procedures (e.g. mail delivery) will
                    # be interrupted, and no new servers can register.
                    #
                    ns_log warning "cluster node lost contact to " \
                        "canonical server: ${:canonicalServerLocation}"
                }
                #
                # Are we an dynamic peer and not listed in
                # DynamicClusterPeers? This might happen in
                # situations, where the canonical server was
                # restarted (or separated for a while).
                #
                if {[:current_server_is_dynamic_cluster_peer]
                    && ${:currentServerLocation} ni $dynamic_peers
                } {
                    ns_log warning "cluster node is not listed in dynamic peers." \
                        "Must re-join canonical server: ${:canonicalServerLocation}"
                    :send_join_request ${:canonicalServerLocation}
                }
            }

            #
            # Update cluster_peer_nodes if necessary
            #
            set oldConfig [lsort [nsv_get cluster cluster_peer_nodes]]
            set newConfig [lsort [:peer_nodes $dynamic_peers]]
            if {$newConfig ne $oldConfig} {
                #
                # The cluster configuration has changed
                #
                ns_log notice "cluster config changed:\nOLD $oldConfig\nNEW $newConfig"
                nsv_set cluster cluster_peer_nodes $newConfig
            }
        }

        :public method last_contact {location} {
            #
            # Return the milliseconds since the last contact
            # with the denoted server. If there is no data available,
            # the return values is empty.
            #
            if {[nsv_get cluster $location-last-contact clicksms]} {
                return $clicksms
            }
        }
        :public method last_request {location} {
            #
            # Return the milliseconds since the last request from the
            # denoted server. If there is no data available, the
            # return values is empty.
            #
            if {[nsv_get cluster $location-last-request clicksms]} {
                return $clicksms
            }
        }

        :method reachable {location} {
            #:log "reachable $location"
            set d [ns_parseurl $location]
            #ns_log notice "reachable: $location -> $d"
            set result 0
            dict with d {
                switch $proto {
                    "udp" {
                        #
                        # assume, udp is always reachable
                        #
                        set result 1
                    }
                    "http" -
                    "https" {
                        #
                        # We can check via ns_connchan
                        #
                        try {
                            #ns_logctl severity Debug(connchan) on
                            ns_connchan connect $host $port
                        } on error {} {
                            #
                            # Not reachable, stick with the default 0
                            #
                        } on ok {chan} {
                            set result 1
                            ns_connchan close $chan
                        }
                    }
                }
            }
            :log "node $location is reachable: $result" \
                "last_contact [:last_contact $location]" \
                "last_request [:last_request $location]"
            if {$result} {
                nsv_set cluster $location-last-contact [clock clicks -milliseconds]
            }
            return $result
        }

        :method is_current_server {location} {
            #
            # Check, if the provided location is the current server.
            # We expect the that the method "setup" was already called.
            #
            set result [expr {$location in ${:currentServerLocations}}]
            #ns_log notice "is_current_server called with proto -> $location -> $result"
            return $result
        }

        :method is_configured_server {locations} {
            #
            # Check, if one of the provided locations is in the
            # currently configured cluster nodes.
            #
            foreach location $locations {
                if {$location in ${:configured_cluster_hosts}} {
                    return 1
                }
            }
            return 0
        }

        :public method is_canonical_server {location} {
            #
            # Check, if provided location belongs to the canonical
            # server specs. The canonical server might listen on
            # multiple protocols, IP addresses and ports.
            #
            if { ![info exists :canonicalServer] || ${:canonicalServer} eq "" } {
                ns_log Error "Your configuration is not correct for server clustering." \
                    "Please ensure that you have the CanonicalServer parameter set correctly."
                return 1
            }

            set result [expr {$location in ${:canonicalServerLocation}}]
            #ns_log notice "is_canonical_server $location -> $result"
            return $result
        }

        :public method current_server_is_canonical_server {} {
            #
            # Check, if the current server is the canonical_server.
            #
            if { ![info exists :canonicalServer] || ${:canonicalServer} eq "" } {
                ns_log Error "Your configuration is not correct for server clustering." \
                    "Please ensure that you have the CanonicalServer parameter set correctly."
                return 1
            }
            set result 0
            foreach location ${:currentServerLocations} {
                if {[:is_canonical_server $location]} {
                    set result 1
                    break
                }
            }
            #:log "current_server_is_canonical_server $result"
            return $result
        }

        :method current_server_is_dynamic_cluster_peer {} {
            #
            # We are a dynamic cluster peer, when we are not the
            # canonical server neither isted in the static server
            # locations.
            #
            if {${:current_server_is_canonical_server}} {
                return 0
            }
            return [expr {${:currentServerLocation} ni ${:staticServerLocations}}]
        }

        :method qualified_location {location} {
            #
            # Return a canonical representation of the provided
            # location, where the DNS name is resolved and the
            # protocol and port is always included. When there is no
            # protocol provided, HTTP is assumed. There is no default
            # provided for non-HTTP* locations.
            #
            # In theory, an input location might map to multiple
            # values, when e.g., a provided DNS name refers to
            # multiple IP addresses. For now, we just return always a
            # single value.
            #
            set d {port 80 proto http}
            if {[regexp {^([^:]+)://} $location . proto]} {
                if {$proto eq "https"} {
                    set d {port 443 proto https}
                }
                set d [dict merge $d [ns_parseurl $location]]
                dict unset d tail
                dict unset d path
            } else {
                set d [dict merge $d [ns_parsehostport $location]]
            }
            #
            # To return all IP addresses, we could use "ns_addrbyhost
            # -all ..." instead.
            #
            dict set d host [ns_addrbyhost [dict get $d host]]
            dict with d {
                set result [util::join_location -proto $proto -hostname $host -port $port]
            }
            return $result
        }

        :method preferred_location {locations:1..n} {
            #
            # Return the preferred location.
            #
            set preferred_location_regexp [parameter::get \
                                               -package_id $::acs::kernel_id \
                                               -parameter PreferredLocationRegexp \
                                               -default https:// ]

            set preferred_location ""
            foreach location $locations {
                if {[regexp $preferred_location_regexp $location]} {
                    set preferred_location $location
                    break
                }
            }
            if {$preferred_location eq ""} {
                set preferred_location [lindex $locations 0]
            }
            return $preferred_location
        }

        :method current_server_locations {
            {-network_drivers {nssock nsssl nsudp}}
        } {
            #
            # Return a list of valid locations of the current server.
            #
            # Since "ns_driver info" is not yet available at the time,
            # the *-init files are loaded, this method goes a long way
            # to check for properties of all of the loaded modules.
            # Network drivers with empty "port" or port == 0 are
            # ignored.
            #
            set result {}
            set protos {nssock http nsssl https nsudp udp nscoap coap}
            set module_file_regexp [join [dict keys $protos] |]

            foreach module_section [list ns/server/[ns_info server]/modules ns/modules] {
                set modules [ns_configsection $module_section]
                if {$modules ne ""} {
                    foreach {module file} [ns_set array $modules] {
                        #
                        # To obtain idependence of the driver name, we
                        # check whether the name of the binary (*.so
                        # or *.dylib) is one of the supported driver
                        # modules.
                        #
                        if {![regexp ($module_file_regexp) $file . module_type]} {
                            continue
                        }

                        #ns_log notice "current_server_locations: use module <$module> $file"
                        set driver_section [ns_driversection -driver $module]
                        foreach ip [ns_config $driver_section address] {
                            foreach port [ns_config -int $driver_section port] {
                                if {$port == 0} {
                                    continue
                                }
                                lappend result [util::join_location \
                                                    -proto [dict get $protos $module_type] \
                                                    -hostname $ip \
                                                    -port $port]
                            }
                        }
                    }
                }
            }
            set result [lsort -unique $result]
            ns_log notice "current_server_locations returns $result"
            return $result
        }

        :public method send_join_request {location} {
            #
            # Send a join request to the canonical server.
            #
            :log "send_join_request to $location"
            set r [:send $location [self] join_request ${:currentServerLocation}]
            #:log "... join_request returned $r"

            if {[dict exists $r body]} {
                #
                # During startup/separation caches might not be in
                # sync. Therefore, we have lost confidence in our
                # caches and clear these.
                #
                :log "send_join_request returned [dict get $r body], flushing all my caches"
                acs::cache_flush_all
            }
        }

        :public method join_request {peerLocation} -returns boolean {
            #
            # A join request was received
            #
            ns_log notice "Cluster join_request from '$peerLocation'"
            set success 1
            #
            # Was the join request received by a canonical server?
            #
            if {![:current_server_is_canonical_server]} {
                ns_log warning "Cluster join_request rejected," \
                    "since it was received by a non-canonical server"
                set success 0
            } else {
                #
                # We know, we are running on the canonical server, an
                # we know that the request is trustworthy.
                #
                ns_log notice "Cluster join_request $peerLocation accepted from $peerLocation"
                set dynamicClusterNodes [parameter::get -package_id $::acs::kernel_id -parameter DynamicClusterPeers]
                set dynamicClusterNodes [lsort -unique [concat $dynamicClusterNodes [:qualified_location $peerLocation]]]
                #
                # The parameter::set_value operation causes a
                # clusterwide cache-flush for the parameters
                #
                parameter::set_value -package_id $::acs::kernel_id -parameter DynamicClusterPeers -value $dynamicClusterNodes
                ns_log notice "Cluster join_request leads to DynamicClusterPeers $dynamicClusterNodes"
            }
            return $success
        }


        :method peer_nodes {dynamic_peers} {
            #
            # Determine the peer nodes of the server cluster. These
            # are cluster nodes which will receive intra-server
            # commands.
            #
            set :configured_cluster_hosts {}
            set peer_nodes {}
            foreach location [server_cluster_all_hosts] {
                #
                # Since the input can depend on erroneous user input,
                # use "try" to ease debugging.
                #
                try {
                    :qualified_location $location
                } on ok {qualified_location} {
                    lappend :configured_cluster_hosts $qualified_location
                } on error {errorMsg} {
                    ns_log notice "ignore $location (:qualified_location returned $errorMsg)"
                    continue
                }
                if {[:is_current_server $qualified_location]} {
                    #array:log "$qualified_location is the current server"
                    continue
                }
                #
                # For dynamic cluster peers, check the reachability
                #
                if {$qualified_location in $dynamic_peers
                    && ![:reachable $qualified_location]
                } {
                    ns_log warning "cluster node lost contact to dynamic cluster peer: $qualified_location"
                    continue
                }

                lappend peer_nodes $qualified_location
            }
            return $peer_nodes
        }

        :public method register_nodes {{-startup:switch false}} {
            #
            # Register the defined cluster nodes by
            # creating/recreating cluster node objects.
            #
            :log ":register_nodes startup $startup"

            #
            # Configure base configuration values
            #
            #
            set dynamic_peers [parameter::get -package_id $::acs::kernel_id -parameter DynamicClusterPeers]

            # At startup, when we are running on the canonical server,
            # check, whether the existing DynamicClusterPeers are
            # still reachable. When the canonical server is started
            # before the other cluster nodes, this parameter should be
            # empty. However, when the canonical server is restarted,
            # there might be some of the peer nodes already active.
            #
            if {$startup
                && ${:current_server_is_canonical_server}
                && $dynamic_peers ne ""
            } {
                #
                # When we are starting the canonical server, it resets
                # the potentially pre-existing dynamic nodes unless
                # these are reachable.
                #
                set old_peer_locations $dynamic_peers
                :log "canonical server starts with existing DynamicClusterPeers nodes: $old_peer_locations"
                #
                # Keep the reachable cluster nodes in
                # "DynamicClusterPeers".
                #
                set new_peer_locations {}
                foreach location $old_peer_locations {
                    if {[:reachable $location]} {
                        lappend new_peer_locations $location
                    }
                }
                if {$new_peer_locations ne $old_peer_locations} {
                    #
                    # Update the DynamicClusterPeers in the database
                    # such that the other nodes will pick it up as
                    # well.
                    #
                    :log "updating DynamicClusterPeers to $new_peer_locations"
                    parameter::set_value -package_id $::acs::kernel_id -parameter DynamicClusterPeers \
                        -value $new_peer_locations
                    set dynamic_peers $new_peer_locations
                }
            }

            #
            # Determine the peer nodes.
            #
            set cluster_peer_nodes [:peer_nodes $dynamic_peers]
            nsv_set cluster cluster_peer_nodes $cluster_peer_nodes

            if {![:is_configured_server ${:currentServerLocations}]} {
                #
                # Current node is not pre-registered.
                #
                ns_log notice "Current host ${:currentServerLocation} is not included in ${:configured_cluster_hosts}"
                if {![:current_server_is_canonical_server]} {
                    ns_log notice "... must join at canonical server ${:canonicalServerLocation}"
                    :send_join_request ${:canonicalServerLocation}
                }
            } else {
                #ns_log notice "Current host ${:currentServerLocation} is included in ${:configured_cluster_hosts}"
            }
        }

        :public method secret_configured {} {
            #
            # Check, whether the secret for signing messages in the
            # intra-cluster talk is configured.
            #
            # More checks for different secret definition methods
            # might be added.
            #
            set secret [:secret]
            return [expr {$secret ne ""}]
        }

        :method secret {} {
            #
            # Return secret used for signing messages
            #
            return [ns_config ns/server/[ns_info server]/acs ClusterSecret]
        }
        #
        # Methods for message encoding/decoding
        #
        :method "message sign" {message} {
            #
            # Return signature for message
            #
            #:log "message sign: $message"
            return [ns_crypto::hmac string -digest sha256 [:secret] $message]
        }

        :method "message verify" {message signature} {
            #
            # Verify if the signature of the message is ok and return
            # boolean value.
            #
            #:log "message verify {$message $signature}"
            set local_signature [ns_crypto::hmac string -digest sha256 [:secret] $message]
            return [expr {$local_signature eq $signature}]
        }

        :method "message encode" {cmd} {
            set timestamp [clock clicks -milliseconds]
            append result \
                cmd=[ns_urlencode $cmd] \
                &f=[ns_urlencode ${:currentServerLocation}] \
                &t=$timestamp \
                &s=[:message sign [list $cmd $timestamp]]
        }

        :method "message decode" {} {
            #
            # Return a dict of the decoded message
            # TODO: add timestamp?
            #
            dict set r cmd [ns_queryget cmd]
            dict set r peer [ns_queryget f]
            dict set r timestamp [ns_queryget t]
            dict set r signature [ns_queryget s]
            dict set r peeraddr [ns_conn peeraddr]
            dict with r {
                if {![:message verify [list $cmd $timestamp] $signature]} {
                    error "received message from $peeraddr does not match signature: $r"
                }
            }
            return $r
        }

        #
        # Methods for message delivery
        #
        :public method send {{-delivery ns_http} location args} {
            #
            # Send a command by different means to the cluster node
            # for intra-server talk.
            #
            # Valid delivery methods are
            #  - ns_http (for HTTP and HTTPS)
            #  - connchan (for HTTP and HTTPS)
            #  - udp (plain UDP only)
            #
            :log "outgoing request to $location // $args"
            set t0 [clock clicks -microseconds]
            switch $delivery {
                #connchan -
                #udp      -
                ns_http   {set result [:${delivery}_send $location {*}$args]}
                default {error "unknown delivery method '$delivery'"}
            }
            ns_log notice "-cluster: $location $args sent" \
                "total [expr {([clock clicks -microseconds] - $t0)/1000.0}]ms"
            return $result
        }

        :method ns_http_send {location args} {
            #:log "outgoing ns_http request to $location // $args"
            try {
                ns_http run $location/${:url}?[:message encode $args]
            } on error {errorMsg} {
                ns_log warning "-cluster: send message to $location/${:url}?cmd=[ns_urlencode $args] failed: $errorMsg"
                set result ""
            } on ok {result} {
                #ns_log notice "-cluster: response $result"
            }
            return $result
        }

    }

    #
    # Define the acs::cluster object, since this is used e.g. in
    # "acs::clusterwide", which is used quite early during boot.
    #
    acs::Cluster create ::acs::cluster
    #
    # Refetch setup on reload operations of this file.
    #
    if {[ns_ictl epoch] > 0 && [server_cluster_enabled_p]} {
        ::acs::cluster setup
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
