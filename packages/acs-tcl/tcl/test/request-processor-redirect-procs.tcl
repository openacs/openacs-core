ad_library {
    Regression tests for internal redirect detection in the request processor.
}

aa_register_case -cats {api smoke production_safe} -procs {
    rp_filter rp_handler
} rp_internal_redirect_connection_url {
    Check full connection URL comparisons, including suffix collisions, empty
    extra_url, and host mappings. Exercise production handler code in an
    isolated interpreter without changing live connection commands or state.
} {
    set channel [open [file join [acs_package_root_dir acs-tcl] tcl request-processor-procs.tcl]]
    try {set source [read $channel]} finally {close $channel}
    set child [interp create]
    try {
        interp alias $child ns_set {} ns_set
        interp eval $child [list set source $source]
        interp eval $child {
            proc declaration_body {source name} {
                set start [string first "ad_proc -private $name " $source]
                if {$start < 0} {
                    error "Missing production procedure $name"
                }
                set declaration {}
                foreach line [split [string range $source $start end] \n] {
                    append declaration $line \n
                    if {[info complete $declaration]} {
                        return [lindex $declaration end]
                    }
                }
                error "Incomplete production procedure $name"
            }

            # Load the entire production handler and the filter's initialization prefix.
            # The rest of rp_filter needs site/database services unrelated to this check.
            set filterBody [declaration_body $source rp_filter]
            set boundary [string first {    security::set_user_id 0} $filterBody]
            if {$boundary < 0} {
                error "Missing filter initialization boundary"
            }
            proc initialize_request {} [string range $filterBody 0 $boundary-1]
            proc rp_handler {} [declaration_body $source rp_handler]

            proc sec_handler_reset {} {}
            proc ns_conn {key} {return [dict get $::connection $key]}
            proc ad_conn {operation args} {
                switch -- $operation {
                    -reset {
                        unset -nocomplain ::ad_conn
                        array set ::ad_conn {recursion_count 0}
                    }
                    -set {
                        lassign $args key value
                        if {$key eq "package_key"} {incr ::resets}
                        set ::ad_conn($key) $value
                    }
                    default {return $::ad_conn($operation)}
                }
            }
            proc rp_debug {args} {}
            proc ns_getform {} {
                if {[info exists ::test_form]} {return $::test_form}
                return ""
            }
            proc ad_try {body args} {uplevel 1 $body}
            proc rp_handle_request {} {incr ::handled}
            namespace eval site_node {
                proc get {args} {error "Unexpected site-node lookup: $args"}
            }

            proc setup_request {url extra {mappedUrl {}}} {
                set ::connection [dict create url $url id 1 status 200 method GET query {}]
                set ::resets 0
                set ::handled 0
                initialize_request
                if {$mappedUrl eq ""} {
                    set mappedUrl $url
                }
                array set ::ad_conn [list url $mappedUrl extra_url $extra \
                                         package_key original-package package_url /original/]
            }
        }

        interp eval $child {
            setup_request /old old
            dict set ::connection url /new
            initialize_request
        }
        aa_equals "A new filter pass replaces the saved connection URL" \
            [interp eval $child {set ::ad_conn(rp_conn_url)}] /new

        foreach {name original extra mapped target} {
            suffix-collision /4 4 /4 /shared/404
            empty-extra / {} / /shared/404
            ordinary-missing /missing missing /missing /shared/404
            host-mapped /4 4 /tenant/4 /shared/404
            arbitrary-error-name /4 4 /4 /errors/not-found
        } {
            interp eval $child [list setup_request $original $extra $mapped]
            interp eval $child {rp_handler}
            aa_equals "$name: original URL does not reset routing" \
                [interp eval $child {set ::resets}] 0
            interp eval $child [list dict set ::connection url $target]
            interp eval $child {
                dict set ::connection status 404
                rp_handler
            }
            aa_equals "$name: redirect updates resource and package routing" \
                [interp eval $child {
                    list $::ad_conn(extra_url) $::ad_conn(package_key) $::ad_conn(package_url)
                }] [list $target acs-subsite /]
            aa_equals "$name: redirect records its complete connection URL" \
                [interp eval $child {set ::ad_conn(rp_conn_url)}] $target
            interp eval $child {rp_handler}
            aa_equals "$name: repeated handling of the same URL does not reset again" \
                [interp eval $child {set ::resets}] 1
            aa_equals "$name: all handler invocations dispatch the request" \
                [interp eval $child {set ::handled}] 3
        }

        interp eval $child {
            setup_request /4 4 /tenant/4
            dict set ::connection status 404
            rp_handler
        }
        aa_equals "Host mapping and error status alone do not reset routing" \
            [interp eval $child {
                list $::resets $::ad_conn(extra_url) $::ad_conn(package_key)
            }] {0 4 original-package}

        interp eval $child {
            setup_request {/a*} {a*}
            dict set ::connection url /abc
            dict set ::connection status 404
            rp_handler
        }
        aa_equals "Connection URLs containing glob characters are compared literally" \
            [interp eval $child {list $::resets $::ad_conn(extra_url)}] {1 /abc}

        foreach status {302 399 400 401 403 404 499 500 503 599 600} {
            set form [ns_set create]
            try {
                ns_set put $form @page log.smtpsent
                ns_set put $form raw 1
                interp eval $child [list set ::test_form $form]
                interp eval $child {
                    setup_request /wrong-nsstats wrong-nsstats
                    dict set ::connection query {@page=log.smtpsent&raw=1}
                    rp_handler
                }
                aa_equals "$status: original request retains its form parameters" \
                    [ns_set size $form] 2
                interp eval $child [list dict set ::connection status $status]
                interp eval $child {dict set ::connection url /shared/404; rp_handler}
                aa_equals "$status: only a 4xx or 5xx redirect clears the parsed form" \
                    [ns_set size $form] [expr {$status >= 400 && $status < 600 ? 0 : 2}]
                aa_equals "$status: raw query remains available for diagnostics" \
                    [interp eval $child {ns_conn query}] {@page=log.smtpsent&raw=1}
            } finally {
                interp eval $child {unset -nocomplain ::test_form}
                ns_set free $form
            }
        }
    } finally {
        interp delete $child
    }
}
