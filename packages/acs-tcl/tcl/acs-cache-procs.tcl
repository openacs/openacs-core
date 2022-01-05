#
#    Copyright (C) 2018 Gustaf Neumann, neumann@wu-wien.ac.at
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
    # Generic Cache class
    #
    ##########################################################################

    nx::Class create ::acs::Cache {
        #
        # Provide a base class to generalize cache management to
        # extend cache primitives like e.g. for cache partitioning.
        #
        :property name
        :property parameter:required
        :property package_key:required
        :property maxentry:integer
        :property {timeout 5m}
        :property {default_size:integer 10000}

        :method cache_name {key} {
            #
            # More or less dummy function, which can be refined.  The
            # base definition completely ignores "key".
            #
            return ${:name}
        }

        :method get_size {} {
            #
            # Determine the cache size depending on configuration
            # variables.
            #
            set specifiedSize [::parameter::get_from_package_key \
                                   -package_key ${:package_key} \
                                   -parameter "${:parameter}Size" \
                                   -default ${:default_size}]
            if {[::nsf::is integer $specifiedSize]} {
                set size $specifiedSize
            } else {
                if {[acs::icanuse ns_baseunit]} {
                    set size [ns_baseunit -size $specifiedSize]
                } else {
                    #
                    # Rough approximation for older versions of NaviServer.
                    #
                    if {[regexp {^(\d+)([mk])b} [string tolower $specifiedSize] . amount unit]} {
                        set multipliers {k 1024 m 1048576}
                        set size [expr {[dict get $multipliers $unit] * $amount}]
                    } else {
                        error "invalid size specification '$specifiedSize'"
                    }
                }
            }
            return $size
        }

        :public method flush {{-partition_key} key} {
            if {![info exists partition_key]} {
                set partition_key $key
            }
            ::acs::clusterwide ns_cache flush [:cache_name $partition_key] $key
        }

        if {[namespace which ns_cache_eval] ne ""} {
            #
            # NaviServer variant
            #
            :public method eval {{-partition_key} {-expires:integer} key command} {
                #
                # Evaluate the command unless it is cached.
                #
                if {![info exists partition_key]} {
                    set partition_key $key
                }
                if {[info exists expires]} {
                    set expires_flag [list -expires $expires]
                } else {
                    set expires_flag {}
                }
                try {
                    :uplevel [list ns_cache_eval {*}$expires_flag -- \
                                  [:cache_name $partition_key] $key $command]

                } on break {r} {
                    #
                    # When the command ends with "break", it means:
                    # "don't cache". We return in this case always a
                    # 0.
                    #
                    #ns_log notice "====================== [self] $key -> break -> <$r>"
                    return 0

                } on ok {r} {
                    return $r
                }
            }

            :public method set {-partition_key key value} {
                #
                # Set some value in the cache. This code uses
                # ns_cache_eval to achieve this behavior, which is
                # typically an AOLserver idiom and should be avoided.
                #
                if {![info exists partition_key]} {
                    set partition_key $key
                }
                :uplevel [list ns_cache_eval -force -- [:cache_name $partition_key] $key [list set _ $value]]
            }

            :public method flush_pattern {{-partition_key ""} pattern} {
                #
                # Flush in the cache a value based on a pattern
                # operation. Use this function rarely, since on large
                # caches (e.g. 100k entries or more) the glob
                # operation will cause long locks, which should be
                # avoided. The partitioned variants can help to reduce
                # the lock times.
                #
                return [ns_cache_flush -glob [:cache_name $partition_key] $pattern]
            }

            :method cache_create {name size} {
                #
                # Create a cache.
                #
                ns_cache_create \
                    -timeout ${:timeout} \
                    {*}[expr {[info exists :maxentry] ? "-maxentry ${:maxentry}" : ""}] \
                    $name $size
            }

        } else {
            #
            # AOLserver variant
            #
            :public method eval {{-partition_key} {-expires:integer} key body} {
                #
                # ignore "-expires", since not supported by AOLserver
                #
                if {![info exists partition_key]} {
                    set partition_key $key
                }
                try {
                    :uplevel [list ns_cache eval [:cache_name $partition_key] $key $body]
                } on break {r} {
                    return 0
                } on ok {r} {
                    return $r
                }
            }
            :public method set {-partition_key key value} {
                if {![info exists partition_key]} {set partition_key $key}
                :uplevel [list ns_cache set [:cache_name $partition_key] $key $value]
            }
            :public method flush_pattern {{-partition_key ""} pattern} {
                foreach name [ns_cache names [:cache_name $partition_key] $pattern] {
                    :flush -partition_key $partition_key $name
                }
            }
            :public method flush_cache {{-partition_key ""}} {
                ns_cache_flush [:cache_name $partition_key]
            }
            :method cache_create {name size} {
                ns_cache create $name -size $size
            }
        }

        :public method get {-partition_key key} {
            #
            # The "get" method retrieves data from the cache. It
            # should not be used for new applications due to likely
            # race conditions, but legacy applications use this.  As
            # implementation, we use in the case of NaviServer the
            # AOLserver API emulation.
            #
            if {![info exists partition_key]} {
                set partition_key $key
            }
            return [ns_cache get [:cache_name $partition_key] $key]
        }

        :public method show_all {} {
            ns_log notice "content of ${:name}: [ns_cache_keys ${:name}]"
        }

        :public method flush_cache {{-partition_key ""}} {
            #
            # Flush all entries in a cache. Both, NaviServer and
            # AOLserver support "ns_cache_flush".
            #
            ns_cache_flush [:cache_name $partition_key]
            #ns_log notice "flush_all -> ns_cache_flush [:cache_name $partition_key]"
            #ns_log notice "... content of ${:name}: [ns_cache_keys ${:name}]"
        }

        :public method flush_all {} {
            #
            # Flush all contents of all (partitioned) caches. In the
            # case of a base ::acs::Cache, it is identical to
            # "flush_cash".
            #
            :flush_cache
        }

        :public method init {} {
            #
            # If the name was not provided, use the object name as
            # default.
            #
            if {![info exists :name]} {
                set :name [namespace tail [current]]
            }
            :cache_create ${:name} [:get_size]
        }
    }

    ##########################################################################
    #
    # Simple Partitioned Cache class
    #
    # Partitioning is based on a modulo function using the cache
    # key, which has to be numeric.
    #
    ##########################################################################

    nx::Class create ::acs::PartitionedCache -superclasses ::acs::Cache {
        :property {partitions:integer 1}

        :protected method cache_name {key:integer} {
            #
            # Return the cache_name always as the same Tcl_Obj (list
            # element) rather than concatenating always a fresh
            # Tcl_Obj dynamically the fly (type string). Caching the
            # cache structure in the dynamic Tcl_Obj can't not work.
            #
            return [lindex ${:partition_names} [expr {$key % ${:partitions}}]]
        }

        :public method init {} {
            #
            # If the name was not provided, use the object name as
            # default for the cache name.
            #
            if {![info exists :name]} {
                set :name [namespace tail [current]]
            }
            set :partitions [::parameter::get_from_package_key \
                                -package_key ${:package_key} \
                                -parameter "${:parameter}Partitions" \
                                -default ${:partitions}]
            #
            # Create multiple separate caches depending on the
            # partitions. A PartitionedCache requires to have a
            # partitioning function that determines the nth partition
            # number from some partition_key.
            #
            set size [expr {[:get_size] / ${:partitions}}]
            set :partition_names {}
            for {set i 0} {$i < ${:partitions}} {incr i} {
                lappend :partition_names ${:name}-$i
                :cache_create ${:name}-$i $size
            }
        }

        :public method flush_all {{-partition_key ""}} {
            #
            # Flush all entries in all partitions of a cache. Both,
            # NaviServer and AOLserver support "ns_cache_flush".
            #
            for {set i 0} {$i < ${:partitions}} {incr i} {
                ns_cache_flush ${:name}-$i
                #ns_log notice "flush_all: ns_cache_flush ${:name}-$i"
                #ns_log notice "... content of ${:name}-$i: [ns_cache_keys ${:name}-$i]"
            }
        }

        if {[namespace which ns_cache_eval] ne ""} {
            #
            # NaviServer variant
            #
            :method flush_pattern_in_all_partitions {pattern} {
                #
                # Flush matching entries in all partitions of a cache based on
                # a pattern.
                #
                for {set i 0} {$i < ${:partitions}} {incr i} {
                    ns_cache_flush -glob ${:name}-$i $pattern
                    ns_log notice "flush_pattern_in_all_partitions: ns_cache_flush ${:name}-$i $pattern"
                    #ns_log notice "... content of ${:name}-$i: [ns_cache_keys ${:name}-$i]"
                }
            }
        } else {
            #
            # AOLserver variant
            #
            :method flush_pattern_in_all_partitions {pattern} {
                for {set i 0} {$i < ${:partitions}} {incr i} {
                    foreach name [ns_cache names ${:name}-$i $pattern] {
                        :flush -partition_key $partition_key $name
                    }
                }
            }
        }

        :public method show_all {} {
            for {set i 0} {$i < ${:partitions}} {incr i} {
                ns_log notice "content of ${:name}-$i: [ns_cache_keys ${:name}-$i]"
            }

        }

    }

    ##########################################################################
    #
    # Class for key-partitioned caches
    #
    # Key-partitioning is based on a modulo function using a special
    # partition_key, which has to be numeric - at least for the time being.
    #
    ##########################################################################

    nx::Class create ::acs::KeyPartitionedCache -superclasses ::acs::PartitionedCache {
        :property {partitions:integer 1}

        :public method flush_pattern {{-partition_key:integer,required} pattern} {
            #
            # flush just in the determined partition
            #
            next
        }

        #:public method flush {{-partition_key:integer,required} key} {
        #    next
        #}

        :public method set {{-partition_key:integer,required} key value} {
            next
        }
    }

    ##########################################################################
    #
    # Class for hash-key-partitioned caches
    #
    # Key-partitioning is based on a modulo function using a special
    # partition_key, which has to be numeric - at least for the time being.
    #
    ##########################################################################

    nx::Class create ::acs::HashKeyPartitionedCache -superclasses ::acs::KeyPartitionedCache {
        :property {partitions:integer 2}

        :public method flush_pattern {{-partition_key:required} pattern} {
            #
            # flush just in all partitions
            #
            :flush_pattern_in_all_partitions $pattern
        }

        :public method set {{-partition_key:required} key value} {
            next [list -partition_key [ns_hash $partition_key] $pattern]
        }

        :protected method cache_name {key} {
            next [list [ns_hash $key]]
        }

    }
}

namespace eval ::acs {
    ##########################################################################
    #
    # ::acs::LockfreeCache: Per-thread and per-request Cache
    #
    # Lockfree cache are provided either as per-thread caches or
    # per-request caches, sharing the property that accessing these
    # values does not require locks.
    #
    # The per-thread caches use namespaced variables, which are not
    # touched by the automatic cleanup routines of the server. So, the
    # values cached in one requests can be used by some later request
    # in the same thread. The entries are kept in per-thread caches as
    # long as the thread lives, there is so far no automatic mechanism
    # to flush these. So, per-thread caches are typically used for
    # values fetched from the database, which do not change, unless
    # the server is restarted.
    #
    # Per-request caches have very short-lived entries. Some values
    # are needed multiple times per request, and/or they should show
    # consistently the same value during the same request, no matter,
    # if concurrently, a value is changed (e.g. permissions).
    #
    # Note: the usage of per-thread caches is only recommended for
    # static values, which do no change during the life time of the
    # server, since there is so far no automatic measure in place to
    # the flush values in every thread.
    #
    ##########################################################################
    nx::Class create ::acs::LockfreeCache {
        :property {prefix}

        :public method get {
            {-key:required}
            var
        } {
            #
            # Get entry with the provided key from this cache if it
            # exists. In most cases, the "eval" method should be used.
            #
            # @param key cache key
            # @return return boolean value indicating success.
            #
            if {[info exists ${:prefix}] && [dict exists [set ${:prefix}] $key]} {
                :upvar $var value
                set value [dict get [set ${:prefix}] $key]
                return 1
            }
            return 0
        }

        :public method eval {
            {-key:required}
            {-no_empty:switch false}
            cmd
        } {
            #
            # Use the "prefix" to determine whether the cache is
            # per-thread or per-request.
            #
            # @param key key for caching, should start with package-key
            #            and a dot to avoid name clashes
            # @param cmd command to be executed.
            # @return    return the last value set (don't use "return").
            #
            #set cache_key ${:prefix}$key
            #ns_log notice "### exists $cache_key => [dict exists ${:prefix} $key]"

            if {![info exists ${:prefix}] || ![dict exists [set ${:prefix}] $key]} {
                #ns_log notice "### call cmd <$cmd>"
                set value [:uplevel $cmd]
                #ns_log notice "### cmd returns <$value> no_empty $no_empty "
                if {$no_empty && $value eq ""} {
                    return ""
                }
                dict set ${:prefix} $key $value
                #ns_log notice "### [list dict set ${:prefix} $key $value]"
            }
            #ns_log notice "### will return [list dict get ${:prefix} $key]"
            return [dict get [set ${:prefix}] $key]
        }

        :public method flush {
           {-pattern *}
        } {
            #
            # Flush a cache entry based on the pattern (which might be
            # wild-card-free).
            #
            if {[info exists ${:prefix}]} {
                if {$pattern eq "*"} {
                    ns_log notice "### dict flush ${:prefix} <$pattern>"
                    unset -nocomplain ${:prefix}
                } elseif {[string first "*" $pattern] != -1} {
                    #
                    # A real pattern with wild-card was provided.
                    #
                    set keys [dict keys [set ${:prefix}] $pattern]
                    ns_log notice "### dict flush ${:prefix} <$pattern> -> [llength $keys]]"
                    foreach key $keys {
                        dict unset ${:prefix} $key
                    }
                } elseif [dict exists [set ${:prefix}] $pattern] {
                    dict unset ${:prefix} $pattern
                }
            }
        }

        #
        # The per-request cache uses Tcl variables in the global
        # namespace, such they are automatically reclaimed after the
        # request. These use the prefix "::__acs_cache"
        #
        :create per_request_cache -prefix ::__acs_cache

        #
        # Define the "per_thread_cache"
        #
        if {[ns_config "ns/parameters" cachingmode "per-node"] eq "none"} {
            #
            # If caching mode is "none", let the "per_thread_cache" behave
            # like the "per_request_cache".
            #
            :create per_thread_cache -prefix ::__acs_cache
            ns_log notice "cachingmode [ns_config "ns/parameters" cachingmode singlenode]" \
                "-> per_thread_cache behaves like per-request_cache"

        } else {
            #
            # The per-thread cache uses namespaced Tcl variables, identified
            # by the prefix "::acs:cache"
            #
            :create per_thread_cache -prefix ::acs::cache
        }
    }
    namespace eval ::acs::cache {}
}


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

        #
        # Handling outgoing requests
        #
        :public object method broadcast args {
            foreach server [:info instances] {
                $server message {*}$args
            }
        }

        :public method message args {
            :log "--cluster outgoing request to ${:host}:${:port} // $args"

            try {
                ns_http run http://${:host}:${:port}/${:url}?cmd=[ns_urlencode $args]
            } on error {errorMsg} {
                ns_log warning "-cluster: send message to http://${:host}:${:port}/${:url}?cmd=[ns_urlencode $args] failed: $errorMsg"
            } on ok {result} {
                ns_log notice "-cluster: response $result"
            }
            #util::http::get -url
        }
    }
}

namespace eval ::acs {
    ad_proc -private try_cache {cache operation key args} {

        Function to support caching during bootstrap.  When the
        provided cache exists, then use it for caching, otherwise
        perform uncalled call. This function is made intentionally
        private, since this should only be required during
        bootstraping. It does not make sense to wrap arbitrary caching
        calls with this function.

    } {
        if {[info commands $cache] ne ""} {
            return [uplevel [list $cache $operation $key {*}$args]]
        } else {
            if {$operation eq "eval"} {
                ns_log warning "no cache $cache: need direct call $key $args"
                return [uplevel {*}$args]
            }
            ns_log warning "no cache $cache: call ignored"
        }
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
