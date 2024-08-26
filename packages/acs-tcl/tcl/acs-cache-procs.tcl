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
        :property {default_size 100KB}

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
                set size [ns_baseunit -size $specifiedSize]
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
            :public method eval {{-partition_key} {-expires} {-timeout} {-per_request:switch} key command} {
                #
                # Evaluate the command unless it is cached.
                #
                # @param expires (passed straight through to NaviServer)
                # @param partition_key Used for determining the cache
                #        name in partitioned caches
                # @param per_request when set, cache the result per
                #        request. So far, no attempt is made to flush
                #        the result inside the request.
                #
                if {![info exists partition_key]} {
                    set partition_key $key
                }
                foreach optional_parameter {expires timeout} {
                    if {[info exists $optional_parameter]} {
                        set ${optional_parameter}_flag [list -$optional_parameter [set $optional_parameter]]
                    } else {
                        set ${optional_parameter}_flag ""
                    }
                }
                set cache_name [:cache_name $partition_key]
                try {
                    if {$per_request} {
                        acs::per_request_cache eval -key ::acs-${cache_name}($key) {
                            :uplevel [list ns_cache_eval \
                                          {*}$expires_flag {*}$timeout_flag -- \
                                          $cache_name $key $command]
                        }
                    } else {
                        :uplevel [list ns_cache_eval {*}$expires_flag {*}$timeout_flag -- \
                                      $cache_name $key $command]
                    }

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
                return [::acs::clusterwide ns_cache_flush -glob [:cache_name $partition_key] $pattern]
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
            :public method eval {{-partition_key} {-expires}  {-timeout} {-per_request:switch} key command} {
                #
                # ignore "-expires", since not supported by AOLserver
                # ignore "-timeout", since not supported by AOLserver
                # ignore "-per_request" optimization so far
                #
                if {![info exists partition_key]} {
                    set partition_key $key
                }
                try {
                    :uplevel [list ns_cache eval [:cache_name $partition_key] $key $command]
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
            ::acs::clusterwide ns_cache_flush [:cache_name $partition_key]
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
                ::acs::clusterwide ns_cache_flush ${:name}-$i
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
                    ::acs::clusterwide ns_cache_flush -glob ${:name}-$i $pattern
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
            {-no_cache}
            {-no_empty:switch false}
            {-from_cache_indicator}
            cmd
        } {
            #
            # Use the "prefix" to determine whether the cache is
            # per-thread or per-request.
            #
            # @param key key for caching, should start with package-key
            #            and a dot to avoid name clashes
            # @param cmd command to be executed.
            # @param no_empty don't cache empty values. This flag is
            #        deprecated, one should use the no_cache flag
            #        instead.
            # @param no_cache list of returned values that should not be cached
            # @param from_cache_indicator variable name to indicate whether
            #        the returned value was from cache or not
            #
            # @return return the last value set (don't use "return").
            #
            #set cache_key ${:prefix}$key
            #ns_log notice "### exists $cache_key => [dict exists ${:prefix} $key]"
            if {[info exists from_cache_indicator]} {
                :upvar $from_cache_indicator from_cache
            }

            if {![info exists ${:prefix}] || ![dict exists [set ${:prefix}] $key]} {
                #ns_log notice "### call cmd <$cmd>"
                set from_cache 0
                set value [:uplevel $cmd]
                if {$no_empty} {
                    ad_log warning "no_empty flag is deprecated and will be dropped in the future."
                    lappend no_cache ""
                }
                if {[info exists no_cache] && $value in $no_cache} {
                    #ns_log notice "### cache eval $key returns <$value> without caching"
                    return $value
                }
                #if {$value eq "0"} {
                #    ns_log notice "### cache eval $key returns <$value> with caching"
                #}
                dict set ${:prefix} $key $value
                #ns_log notice "### [list dict set ${:prefix} $key $value]"
            } else {
                set from_cache 1
                set value [dict get [set ${:prefix}] $key]
            }
            #ns_log notice "### will return [list dict get ${:prefix} $key]"
            return $value
        }

        #:public method flush {
        #   {-pattern *}
        #} {
        #    #
        #    # Flush a cache entry based on the pattern (which might be
        #    # wild-card-free).
        #    #
        #    ::acs::clusterwide [self] flush_local -pattern $pattern
        #}

        :public method flush {
           {-pattern *}
        } {
            #
            # Flush a cache entry based on the pattern (which might be
            # wild-card-free). Currently, the clusterwide flushing is
            # omitted.
            #
            # We have the per-request cache (clusterwide operations do
            # not make sense for this) and per-thread caching. The
            # per-thread caching application have to be aware that
            # flushing is happening only in one thread, so clusterwide
            # operations will only start to make sense, when the all
            # threads of a server would be cleaned.
            #
            if {[info exists ${:prefix}]} {
                if {$pattern eq "*"} {
                    #ns_log notice "### dict flush ${:prefix} <$pattern>"
                    unset -nocomplain ${:prefix}
                } elseif {[string first "*" $pattern] != -1} {
                    #
                    # A real pattern with wild-card was provided.
                    #
                    set keys [dict keys [set ${:prefix}] $pattern]
                    #ns_log notice "### dict flush ${:prefix} <$pattern> -> [llength $keys]"
                    foreach key $keys {
                        dict unset ${:prefix} $key
                    }
                } elseif [dict exists [set ${:prefix}] $pattern] {
                    #
                    # A "pattern" without a wildcard was provided
                    #
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
    ad_proc -private try_cache {cache operation args} {

        Function to support caching during bootstrap.  When the
        provided cache exists, then use it for caching, otherwise
        perform uncalled call. This function is made intentionally
        private, since this should only be required during
        bootstrapping. It does not make sense to wrap arbitrary caching
        calls with this function.

    } {
        if {
            [namespace which $cache] ne "" &&
            [$cache info lookup methods $operation] ne ""
        } {
            return [uplevel 1 [list $cache $operation {*}$args]]
        } else {
            #
            # Complain only, when
            # a) not during initial install, and
            # b) if this is not during startup of an installed version
            #
            set complain_p [expr {[ns_ictl epoch] > 0 && [nsv_names acs_installer] eq ""}]
            if {$operation eq "eval"} {
                nsf::parseargs {{-partition_key} {-expires} {-per_request:switch} key command} $args
                if {$complain_p} {
                    ns_log warning "no cache $cache: need direct call $key $args"
                }
                #ns_log warning "no cache $cache: need direct call $key [info exists partition_key] <$command>"
                return [uplevel 1 $command]
            }
            if {$complain_p} {
                ns_log warning "no cache $cache: call ignored"
            }
        }
    }
}

namespace eval ::acs {
    #
    # Experimental disk-cache, to test whether this can speed up long
    # calls, producing potentially large output ..
    #
    # The interface should be probably streamlined with the other
    # chaching infrastructure.
    #
    # Documentation follows.

    if { [apm_first_time_loading_p] } {
        nsv_set ad_disk_cache mutex [ns_mutex create disk_cache]
    }

    ad_proc -public disk_cache_flush {
        -key:required
        -id:required
    } {
        Flushes the filesystem cache.

        @param key the key used to name the directory where the disk cache
               is stored.
        @param id the id used to name the file where the disk cache is
               stored.

        @see acs::disk_cache_eval
    } {
        set dir [ad_tmpdir]/oacs-cache/$key
        foreach file [glob -nocomplain $dir/$id-*] {
            file delete -- $file
            ns_log notice "FLUSH file delete -- $file"
        }
    }

    ad_proc -public disk_cache_eval {
        -call:required
        -key:required
        -id:required
    } {
        Evaluate an expression. When the acs-tcl.DiskCache parameter is
        set, cache the result on the disk. If a cache already exists,
        return the cached value.

        @param call a Tcl snippet executed in the caller scope.
        @param key a key used to name the directory where the disk cache
               will be stored.
        @param id an id used to name the file where the disk cache will be
              stored. The name will also depend on a hash of the
              actual snippet.
    } {
        set cache [::parameter::get_from_package_key \
                       -package_key acs-tcl \
                       -parameter DiskCache \
                       -default 1]
        if {$cache} {
            set hash [ns_sha1 $call]
            set dir [ad_tmpdir]/oacs-cache/$key
            set file_name $dir/$id-$hash
            if {![ad_file isdirectory $dir]} {
                file mkdir $dir
            }
            ns_mutex eval [nsv_get ad_disk_cache mutex] {
                if {[ad_file readable $file_name]} {
                    set result [template::util::read_file $file_name]
                } else {
                    set result [uplevel $call]
                    template::util::write_file $file_name $result
                }
            }
        } else {
            set result [uplevel $call]
        }
        return $result
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
