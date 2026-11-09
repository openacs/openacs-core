ad_library {
    Regression tests for request processor redirects and error page parameters.
}

aa_register_case -cats {api smoke production_safe} -procs {
    ad_conn rp_handler
} rp_unresolved_file_error {
    An exception before file resolution must reach the error reporter without
    trying the nonexistent ns_conn file subcommand or hiding the original error.
} {
    set channel [open [file join [acs_package_root_dir acs-tcl] tcl request-processor-procs.tcl]]
    try {set source [read $channel]} finally {close $channel}
    set child [interp create]
    try {
        foreach {prefix name arguments} {
            {ad_proc -public ad_conn} ad_conn args
            {ad_proc -private rp_handler} rp_handler {}
        } {
            set start [string first "$prefix " $source]
            if {$start < 0} {error "Missing production declaration: $prefix"}
            set declaration {}
            foreach line [split [string range $source $start end] \n] {
                append declaration $line \n
                if {[info complete $declaration]} break
            }
            if {![info complete $declaration]} {error "Incomplete declaration: $prefix"}
            interp eval $child [list proc $name $arguments [lindex $declaration end]]
        }
        interp eval $child {
            proc ns_conn {key} {
                switch -- $key {
                    url {return /shared/404}
                    method {return GET}
                    query {return {}}
                    request {return {GET /shared/404 HTTP/1.1}}
                    file {incr ::file_calls; error "ns_conn file must not be called"}
                    default {error "Unexpected ns_conn $key"}
                }
            }
            proc ns_log {args} {}
            proc rp_debug {args} {}
            proc ad_try {args} {uplevel 1 [list try {*}$args]}
            proc rp_handle_request {} {error "Original resource-handler exception"}
            proc rp_report_error {} {
                set ::reported $::errorInfo
                # The production reporter also reads this diagnostic field.
                set ::reported_file [ad_conn file]
                incr ::reports
            }
            set file_calls 0
            set reports 0
            array set ::ad_conn {recursion_count 0 url /shared/404}
        }
        aa_equals "Missing file has an empty fallback" [interp eval $child {ad_conn file}] ""
        aa_equals "Explicit -get uses the same fallback" [interp eval $child {ad_conn -get file}] ""
        aa_equals "Missing file is cached as empty" [interp eval $child {set ::ad_conn(file)}] ""
        interp eval $child {ad_conn -set file /fixture/resolved.tcl}
        aa_equals "Resolved file is preserved" [interp eval $child {ad_conn file}] /fixture/resolved.tcl
        interp eval $child {ad_conn -unset file; rp_handler}
        aa_equals "Exception reaches the error reporter once" [interp eval $child {set reports}] 1
        aa_true "Original exception is preserved" \
            [interp eval $child {string match {*Original resource-handler exception*} $reported}]
        aa_equals "Error reporter can read the unresolved file" [interp eval $child {set reported_file}] ""
        aa_equals "No ns_conn file fallback is attempted" [interp eval $child {set file_calls}] 0
    } finally {
        interp delete $child
    }
}

aa_register_case -cats {api smoke production_safe} -procs {
    rp_report_error
} rp_report_error_parameters {
    Error templates receive no original form parameters, while diagnostics
    retain the original request and exception. Use a child interpreter so
    the live server's request commands and state are not changed.
} {
    set channel [open [file join [acs_package_root_dir acs-tcl] tcl request-processor-procs.tcl]]
    try {set source [read $channel]} finally {close $channel}
    set child [interp create]
    set form [ns_set create]
    try {
        interp alias $child ns_set {} ns_set
        interp eval $child [list set source $source]
        interp eval $child [list set test_form $form]
        interp eval $child {
            set start [string first {ad_proc -private rp_report_error } $source]
            if {$start < 0} {error "Missing rp_report_error declaration"}
            set declaration {}
            foreach line [split [string range $source $start end] \n] {
                append declaration $line \n
                if {[info complete $declaration]} break
            }
            if {![info complete $declaration]} {error "Incomplete rp_report_error declaration"}
            # Only the ad_proc option parser is omitted; use the production body.
            proc rp_report_error {} [lindex $declaration end]
            namespace eval acs {variable kernel_id 1}
            namespace eval parameter {proc get {args} {return 0}}
            namespace eval util {proc get_referrer {args} {return https://local.example/}}
            proc ns_conn {key} {
                switch -- $key {
                    isconnected {return $::connected}
                    query {return {@page=log.smtpsent&raw=1}}
                    default {error "Unexpected ns_conn $key"}
                }
            }
            proc ns_getform {} {return $::test_form}
            proc ad_conn {key} {
                return [dict get {url /broken file /fixture/broken.tcl user_id 7 package_id 1} $key]
            }
            proc ad_url {} {return https://local.example}
            proc ad_log {severity message} {lappend ::logs [list $severity $message]}
            proc db_nextval {args} {return 42}
            proc ds_add {args} {}
            proc export_vars {args} {
                if {$args eq "-entire_form"} {
                    set form [ns_getform]
                    set ::diagnostic_form_size [expr {$form eq "" ? 0 : [ns_set size $form]}]
                    return [ns_conn query]
                }
                return feedback-form
            }
            proc ad_try {args} {uplevel 1 [list try {*}[lrange $args 1 end]]}
            proc ad_parse_template {args} {
                set ::render_form_size [expr {$::test_form eq "" ? 0 : [ns_set size $::test_form]}]
                set ::render_params [dict create {*}[concat {*}[lindex $args 1]]]
                return rendered-error
            }
            proc ns_return {args} {set ::response $args}
        }

        foreach connected {1 0} {
            ns_set truncate $form 0
            ns_set put $form @page log.smtpsent
            ns_set put $form raw 1
            interp eval $child [list set connected $connected]
            interp eval $child {
                set logs {}
                unset -nocomplain render_form_size render_params response
                set ::errorInfo {original test exception}
                rp_report_error
            }
            if {$connected} {
                aa_equals "Diagnostics capture parameters before clearing" \
                    [interp eval $child {set diagnostic_form_size}] 2
                aa_equals "Error template receives an empty parsed form" \
                    [interp eval $child {set render_form_size}] 0
                aa_equals "Cached form remains empty after rendering" [ns_set size $form] 0
                aa_equals "Diagnostic URL retains the original query" \
                    [interp eval $child {dict get $render_params error_url}] \
                    {https://local.example/broken?@page=log.smtpsent&raw=1}
                aa_equals "Error template retains the original exception" \
                    [interp eval $child {dict get $render_params stacktrace}] {original test exception}
                aa_equals "Original exception is logged once" \
                    [interp eval $child {set logs}] {{error {original test exception}}}
                aa_equals "Response is still HTTP 500" \
                    [interp eval $child {set response}] {500 text/html rendered-error}
            } else {
                aa_equals "Disconnected request does not change its form" [ns_set size $form] 2
                aa_equals "Disconnected request does not render an error template" \
                    [interp eval $child {info exists render_form_size}] 0
            }
        }
        interp eval $child {
            set connected 1
            set test_form ""
            set ::errorInfo {original test exception}
            rp_report_error
        }
        aa_equals "Missing parsed form still permits rendering" \
            [interp eval $child {set response}] {500 text/html rendered-error}
    } finally {
        interp delete $child
        ns_set free $form
    }
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
