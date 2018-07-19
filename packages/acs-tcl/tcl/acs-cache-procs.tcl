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
	    return [::parameter::get_from_package_key \
			-package_key ${:package_key} \
			-parameter "${:parameter}Size" \
			-default ${:default_size}]
	}

	:public method flush {{-partition_key} key} {
	    if {![info exists partition_key]} {
                set partition_key $key
            }
	    ::acs::clusterwide ns_cache flush [:cache_name $partition_key] $key
	}

	if {[info commands ns_cache_eval] ne ""} {
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
		# typically a AOLserver idiom and should be avoided.
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
	    return ${:name}-[expr {$key % ${:partitions}}]
	}

	:public method init {} {
            #
            # If the name was not provided, use the object name as
            # default.
            #
            if {![info exists :name]} {
                set :name [namespace tail [current]]
            }
	    set partitions [::parameter::get_from_package_key \
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
	    for {set i 0} {$i < ${:partitions}} {incr i} {
		:cache_create ${:name}-$i $size
	    }
	}

        :public method flush_all {{-partition_key ""}} {
            #
            # Flush all entries in all caches. Both, NaviServer and
            # AOLserver support "ns_cache_flush".
            #
            for {set i 0} {$i < ${:partitions}} {incr i} {
		ns_cache_flush ${:name}-$i
                #ns_log notice "flush_all: ns_cache_flush ${:name}-$i"
                #ns_log notice "... content of ${:name}-$i: [ns_cache_keys ${:name}-$i]"
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

	:public method flush {{-partition_key:integer,required} key} {
	    next
	}

	:public method set {{-partition_key:integer,required} key value} {
	    next
	}
    }
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
	# Provide means to perform a wildcard-based cache flushing on
	# (cluster) machines.
	foreach n [ns_cache names $cache $pattern] {ns_cache flush $cache $n}
    }

    nx::Class create Cluster {
	:property host
	:property {port 80}

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
	    bgdelivery ""
	    ns_cache "^ns_cache\s+eval"
	    ns_cache_flush ""
	    acs::cache_flush_all ""
	}

	#
	# handling the ns_filter methods
	#
	:public object method trace args {
	    :log ""
	    return filter_return
	}

	:public object method preauth args {
	    :log ""
	    :incoming_request
	    return filter_return
	}

	:public object method postauth args {
	    :log ""
	    return filter_return
	}

	#
	# handle incoming request issues
	#
	:public object method  incoming_request {} {
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
	    set cmd_name [lindex $cmd 0]
	    set key allowed_command($cmd_name)
	    #ns_log notice "--cluster $key exists ? [info exists :$key]"
	    if {[info exists :$key]} {
		set except_RE [set :$key]
		#ns_log notice "--cluster [list regexp $except_RE $cmd] -> [regexp $except_RE $cmd]"
		if {$except_RE eq "" || ![regexp $except_RE $cmd]} {
		    ns_log notice "--cluster executes command '$cmd' from host $host"
		    return [eval $cmd]
		}
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

	:public object method message args {
	    :log "--cluster outgoing request to [:host]:[:port] // $args"

	    utl::http::get -url http://[:host]:[:port]/[:url]?cmd=[ns_urlencode $args]
	}
    }
}



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
