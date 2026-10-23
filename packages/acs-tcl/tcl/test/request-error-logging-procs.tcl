ad_library {
    Regression tests for single-report request exceptions and error responses.
}

aa_register_case -cats {api smoke production_safe} -procs {
    rp_handler rp_report_error ad_try
} request_error_single_report {
    Exercise the production request handler and error reporter in an isolated
    interpreter. Simulate transport failures without network or database access.
} {
    set child [interp create]
    try {
        interp eval $child {
            namespace eval acs {variable kernel_id 1}
            namespace eval parameter {}
            namespace eval util {}
            set connected true; set mode timeout; set rendering normal
            set logs {}; set responses {}; set rendered 0
            array set ::ad_conn {recursion_count 0 extra_url {}}
            proc ad_conn {key args} {
                if {$key eq "-set"} {set ::ad_conn([lindex $args 0]) [lindex $args 1]; return}
                switch $key {
                    recursion_count {return $::ad_conn(recursion_count)}
                    url {return /api-doc/proc-view}
                    file {return /packages/acs-api-browser/www/proc-view.tcl}
                    user_id {return 42}
                    package_id {return 1}
                    default {error "Unexpected ad_conn key: $key"}
                }
            }
            proc ns_conn {key} {
                switch $key {
                    isconnected {return $::connected}
                    method {return GET}
                    query {return {proc=lappend}}
                    url {return /api-doc/proc-view}
                    request {return {GET /api-doc/proc-view?proc=lappend HTTP/1.1}}
                    default {error "Unexpected ns_conn key: $key"}
                }
            }
            proc ns_log {severity message} {lappend ::logs [list [string tolower $severity] $message]}
            proc ad_log {severity message} {
                lappend ::logs [list [string tolower $severity] "[ns_conn request] peer fixture-peer user_id 42: $message"]
            }
            proc rp_debug {args} {}
            proc ds_add {args} {}
            proc ad_url {} {return https://fixture.invalid}
            proc export_vars {args} {return {proc=lappend}}
            proc util::get_referrer {args} {return /api-doc/}
            proc db_nextval {args} {return 123}
            proc parameter::get {args} {return 0}
            proc ad_parse_template {args} {
                incr ::rendered
                if {$::rendering eq "fail"} {error "Error template failed"}
                if {$::rendering eq "abort"} {throw {AD EXCEPTION ad_script_abort} aborted}
                return {<html><body>Sorry, this request could not be completed.</body></html>}
            }
            proc ns_quotehtml {value} {return $value}
            proc ns_return {status type body} {lappend ::responses [list $status $type $body]}
            proc remote_documentation {} {
                return -code error -errorcode NS_TIMEOUT {HTTP request timeout after 30 seconds}
            }
            proc rp_handle_request {} {
                switch $::mode {
                    timeout {remote_documentation}
                    other {return -code error -errorcode {FIXTURE APPLICATION} {Application failure}}
                    success {ns_return 200 text/html ok}
                    abort {throw {AD EXCEPTION ad_script_abort} aborted}
                    default {error "Unexpected fixture mode"}
                }
            }
        }
        foreach {file prefix name arguments} {
            request-processor-procs.tcl {ad_proc -private rp_handler} rp_handler {}
            request-processor-procs.tcl {ad_proc -private rp_report_error} rp_report_error {}
            exception-procs.tcl {ad_proc ad_try} ad_try args
        } {
            set channel [open [file join [acs_package_root_dir acs-tcl] tcl $file]]
            try {set source [read $channel]} finally {close $channel}
            set start [string first "$prefix " $source]
            if {$start < 0} {error "Missing production declaration: $prefix"}
            set declaration {}
            foreach line [split [string range $source $start end] \n] {
                append declaration $line \n
                if {[info complete $declaration]} break
            }
            if {![info complete $declaration]} {error "Incomplete production declaration: $prefix"}
            set body [lindex $declaration end]
            if {$name eq "ad_try"} {
                # Replace only ad_proc's option parser, retaining the actual
                # automatic-abort handling and try invocation.
                set parser {
                    set auto_abort_p true
                    if {[lindex $args 0] eq "-auto_abort=false"} {
                        set auto_abort_p false; set args [lrange $args 1 end]
                    }
                    set args [lassign $args body]
                }
                append parser \n $body
                set body $parser
            }
            interp eval $child [list proc $name $arguments $body]
        }
        interp eval $child {
            proc reset {newMode {newRendering normal}} {
                set ::logs {}; set ::responses {}; set ::rendered 0
                set ::connected true; set ::ad_conn(recursion_count) 0
                set ::mode $newMode; set ::rendering $newRendering
            }
            reset timeout
            rp_handler
        }
        aa_equals "Timeout produces one Error record" [interp eval $child {llength $logs}] 1
        aa_equals "Timeout retains Error severity" [interp eval $child {lindex $logs 0 0}] error
        aa_true "Canonical report retains URL, user and peer context" \
            [interp eval $child {string match {*GET /api-doc/proc-view?proc=lappend*peer fixture-peer user_id 42*} [lindex $logs 0 1]}]
        aa_true "Canonical report retains the timeout and original call stack" \
            [interp eval $child {expr {[string first {HTTP request timeout after 30 seconds} [lindex $logs 0 1]] >= 0 && [string first remote_documentation [lindex $logs 0 1]] >= 0}}]
        aa_equals "Timeout still renders one polished error response" \
            [interp eval $child {lindex $responses 0}] \
            {500 text/html {<html><body>Sorry, this request could not be completed.</body></html>}}
        aa_equals "Error response is rendered once" [interp eval $child {set rendered}] 1

        interp eval $child {reset other; rp_handler}
        aa_equals "Other application exceptions are also reported once" [interp eval $child {llength $logs}] 1
        aa_true "Other application failures remain visible" \
            [interp eval $child {string match {*Application failure*} [lindex $logs 0 1]}]

        interp eval $child {reset timeout fail; rp_handler}
        aa_equals "Independent error-template failure retains both distinct errors" \
            [interp eval $child {llength $logs}] 2
        aa_true "Original timeout is recorded before the template failure" \
            [interp eval $child {string match {*HTTP request timeout*} [lindex $logs 0 1]}]
        aa_true "Second diagnostic identifies the error-template failure" \
            [interp eval $child {string match {*Error template failed*} [lindex $logs 1 1]}]
        aa_equals "Template failure still returns a response" [interp eval $child {lindex $responses 0 0}] 500

        interp eval $child {reset timeout abort; rp_handler}
        aa_equals "Error-template abort does not lose the original Error" \
            [interp eval $child {llength [lsearch -all -inline -index 0 $logs error]}] 1
        aa_equals "Error-template abort does not send a second response" [interp eval $child {llength $responses}] 0

        interp eval $child {reset timeout; set connected false; rp_handler}
        aa_equals "Disconnected request still records one Error" \
            [interp eval $child {llength $logs}] 1
        aa_equals "Disconnected exception retains Error severity" \
            [interp eval $child {lindex $logs 0 0}] error
        aa_equals "Disconnected request does not render an error page" [interp eval $child {set rendered}] 0

        interp eval $child {reset success; rp_handler}
        aa_equals "Successful requests produce no error records" [interp eval $child {llength $logs}] 0
        aa_equals "Successful response is preserved" [interp eval $child {lindex $responses 0}] {200 text/html ok}
        interp eval $child {reset abort; catch {rp_handler} message options}
        aa_equals "Intentional request abort is preserved" \
            [interp eval $child {dict get $options -errorcode}] {AD EXCEPTION ad_script_abort}
        aa_equals "Intentional request abort produces no error records" [interp eval $child {llength $logs}] 0
    } finally {
        interp delete $child
    }
}
