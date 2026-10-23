ad_library {
    Regression tests for bounded duplicate-parameter and request-block logging.
}

aa_register_case -cats {api smoke production_safe} -procs {
    ad_page_contract ad_page_contract_log_duplicate util::block_request ad_log util::log_rate_limit_check
} page_contract_duplicate_logging {
    Exercise production logging bodies in an isolated interpreter, without
    replacing live request commands or touching the server's limiter state.
} {
    set child [interp create]
    try {
        # Extract complete declarations rather than copying production bodies.
        # ad_log's OpenACS option parser is replaced by a small test wrapper;
        # its logging and suppression implementation is used unchanged.
        foreach {file prefix name arguments} {
            tcl-documentation-procs.tcl {ad_proc -public ad_page_contract} ad_page_contract {docstring args}
            tcl-documentation-procs.tcl {ad_proc -private ad_page_contract_argspec_flag_regexp} ad_page_contract_argspec_flag_regexp {}
            tcl-documentation-procs.tcl {ad_proc -private ad_page_contract_parse_argspec} ad_page_contract_parse_argspec {arg_spec}
            tcl-documentation-procs.tcl {ad_proc -private ad_page_contract_split_argspec_flags} ad_page_contract_split_argspec_flags {flags}
            tcl-documentation-procs.tcl {ad_proc -private ad_page_contract_get_validation_passed_p} ad_page_contract_get_validation_passed_p {key}
            tcl-documentation-procs.tcl {ad_proc -private ad_page_contract_log_duplicate} ad_page_contract_log_duplicate {formal_name complaint}
            utilities-procs.tcl {ad_proc ::util::block_request} util::block_request {condition {target you}}
            utilities-procs.tcl {ad_proc -private util::log_rate_limit_check} util::log_rate_limit_check {severity key interval}
            utilities-procs.tcl {ad_proc -public ad_log} ad_log {}
        } {
            set channel [open [file join [acs_package_root_dir acs-tcl] tcl $file]]
            try {set text [read $channel]} finally {close $channel}
            set start [string first "$prefix \{" $text]
            if {$start < 0} {error "Missing declaration: $prefix"}
            set declaration {}
            foreach line [split [string range $text $start end] \n] {
                append declaration $line \n
                if {[info complete $declaration]} break
            }
            if {![info complete $declaration]} {error "Incomplete declaration: $prefix"}
            interp eval $child {namespace eval util {}; namespace eval acs {}}
            if {$name eq "ad_log"} {
                interp eval $child [list set adLogBody [lindex $declaration end]]
            } elseif {$name eq "ad_page_contract"} {
                # Supply only the public option parser's defaults. All contract
                # parsing, variable assignment and form handling remain production code.
                set body {set form $::testForm; set context {}; set level 1; set warn_p false}
                append body \n [lindex $declaration end]
                interp eval $child [list proc $name $arguments $body]
            } else {
                interp eval $child [list proc $name $arguments [lindex $declaration end]]
            }
        }
        interp eval $child {
            set now 1000; set user_id 0; set pool bots; set connected true
            set logs {}; set contextCalls 0; set state {}; set cache {}
            proc ad_conn {key} {
                switch $key {user_id {return $::user_id} path_info {return /fixture/} default {error unexpected}}
            }
            proc ns_conn {key} {
                switch $key {pool {return $::pool} isconnected {return $::connected} default {error unexpected}}
            }
            proc ns_thread {key} {return fixture-thread}
            proc clock {key} {if {$key ne "seconds"} {error unexpected}; return $::now}
            proc ns_log {severity args} {lappend ::logs [list $severity [join $args ""]]}
            proc ad_get_tcl_call_stack {} {return fixture-stack}
            proc util::request_info {args} {incr ::contextCalls; return fixture-context}
            proc nsv_set {args} {
                set mode {}
                if {[lindex $args 0] in {-default -reset}} {
                    set mode [lindex $args 0]; set args [lrange $args 1 end]
                }
                lassign $args array key value
                set old [expr {[dict exists $::state $array $key] ? [dict get $::state $array $key] : ""}]
                if {$mode eq "-default" && [dict exists $::state $array $key]} {return $old}
                dict set ::state $array $key $value
                return [expr {$mode eq "-reset" ? $old : $value}]
            }
            proc nsv_incr {array key} {
                set count [expr {[dict get $::state $array $key]+1}]
                dict set ::state $array $key $count
                return $count
            }
            proc acs::misc_cache {operation args} {
                if {$operation ne "eval"} {error unexpected}
                lassign $args flag interval separator key script
                if {$flag ne "-expires" || $separator ne "--"} {error unexpected}
                if {[dict exists $::cache $key] && [dict get $::cache $key] > $::now} {return 1}
                dict set ::cache $key [expr {$::now+$interval}]
                uplevel 1 $script
            }
            proc ad_log {args} {
                set key {}; set interval 60; set plain_p false
                while {[lindex $args 0] in {-key -interval}} {
                    lassign $args option value
                    set [string range $option 1 end] $value
                    set args [lrange $args 2 end]
                }
                set severity [lindex $args 0]; set args [lrange $args 1 end]
                lappend ::logKeys $key
                eval $::adLogBody
            }
        }

        interp eval $child {
            ad_page_contract_log_duplicate return_url {duplicate return_url}
            for {set n 0} {$n < 5} {incr n} {ad_page_contract_log_duplicate return_url {duplicate return_url}}
        }
        aa_equals "Anonymous burst emits one warning" [interp eval $child {llength $logs}] 1
        aa_equals "Suppressed calls skip expensive context gathering" [interp eval $child {set contextCalls}] 1
        aa_equals "Warning severity is retained" [interp eval $child {lindex $logs 0 0}] warning

        interp eval $child {
            set user_id 42
            for {set n 0} {$n < 3} {incr n} {ad_page_contract_log_duplicate return_url {duplicate return_url}}
        }
        aa_equals "Every authenticated warning is emitted despite anonymous suppression" [interp eval $child {llength $logs}] 4
        aa_equals "Authenticated warnings retain full context" [interp eval $child {set contextCalls}] 4
        aa_true "Stack context is present" [interp eval $child {string match *fixture-stack* [lindex $logs end 1]}]

        interp eval $child {
            set user_id 0; incr now 300
            ad_page_contract_log_duplicate return_url {duplicate return_url}
        }
        aa_equals "Next interval emits a fresh example" [interp eval $child {llength $logs}] 5
        aa_true "Suppression counts exclude authenticated requests" \
            [interp eval $child {string match {*5 additional messages suppressed; see fixture-thread*} [lindex $logs end 1]}]
        aa_true "Current complaint and path are preserved" \
            [interp eval $child {string match {*duplicate return_url*path_info: /fixture/*} [lindex $logs end 1]}]

        interp eval $child {
            set pool default
            ad_page_contract_log_duplicate return_url {duplicate return_url}
            set pool fast
            ad_page_contract_log_duplicate return_url {duplicate return_url}
        }
        aa_equals "Other pools get an independent example and share their own limit" [interp eval $child {llength $logs}] 6
        interp eval $child {
            foreach pool {bots default} {
                ad_page_contract_log_duplicate view {duplicate view}
                for {set n 0} {$n < 100} {incr n} {
                    ad_page_contract_log_duplicate arbitrary_$n {duplicate arbitrary}
                }
            }
        }
        aa_equals "View and other parameters are separated from return_url in each pool class" \
            [interp eval $child {llength $logs}] 10
        aa_equals "Unbounded submitted names cannot grow the six limiter groups" \
            [interp eval $child {dict size $cache}] 6
        aa_equals "Suppression references and counters remain bounded" \
            [interp eval $child {dict size [dict get $state ad_log_rate_limited]}] 12

        interp eval $child {
            incr now 300
            set connected false
            ad_page_contract_log_duplicate view {duplicate view}
        }
        aa_equals "No connection uses the other-pool category" [interp eval $child {llength $logs}] 11

        # The same production limiter also controls block_request's notices.
        # Rejection must run even when the diagnostic itself is suppressed.
        interp eval $child {
            set logs {}; set contextCalls 0; set state {}; set cache {}
            set now 2000; set connected true; set pool bots
            set complaints {}; set aborts 0
            proc ad_return_complaint {count message} {lappend ::complaints [list $count $message]}
            proc ad_script_abort {} {incr ::aborts; return -code error -errorcode {TEST BLOCK ABORT} aborted}
            for {set n 0} {$n < 6} {incr n} {
                catch {util::block_request {[ns_conn pool] eq "bots"} bots} message options
                if {[dict get $options -errorcode] ne {TEST BLOCK ABORT}} {error "Unexpected rejection result: $message"}
            }
        }
        aa_equals "Blocked burst emits one Notice" [interp eval $child {llength $logs}] 1
        aa_equals "Blocked Notice severity is unchanged" [interp eval $child {lindex $logs 0 0}] notice
        aa_equals "Only emitted block notices gather request context" [interp eval $child {set contextCalls}] 1
        aa_equals "All blocked requests receive a complaint" [interp eval $child {llength $complaints}] 6
        aa_equals "All blocked requests abort, including suppressed notices" [interp eval $child {set aborts}] 6
        aa_equals "Complaint response is unchanged" [interp eval $child {lindex $complaints end}] {1 {page is not allowed for bots}}
        interp eval $child {
            incr now 300
            catch {util::block_request true bots}
        }
        aa_true "Block notice carries the suppressed count and reference" \
            [interp eval $child {string match {*5 additional messages suppressed; see fixture-thread*} [lindex $logs end 1]}]
        aa_equals "Resumed logging gathers context once" [interp eval $child {set contextCalls}] 2
        interp eval $child {
            set pool default; catch {util::block_request true other}
            set pool fast; catch {util::block_request true other}
        }
        aa_equals "Other pools have an independent shared block-notice limit" [interp eval $child {llength $logs}] 3
        aa_equals "Other-pool suppressed notice skips request context" [interp eval $child {set contextCalls}] 3
        interp eval $child {
            set beforeAborts $aborts
            util::block_request false
            set connected false
            util::block_request {[error must-not-evaluate]}
        }
        aa_equals "Allowed and disconnected requests do not abort" [interp eval $child {expr {$aborts-$beforeAborts}}] 0
        aa_equals "Allowed and disconnected requests do not log" [interp eval $child {llength $logs}] 3
        interp eval $child {
            set connected true
            proc block_from_caller {} {
                set selected true
                util::block_request {$selected} caller
            }
            catch {block_from_caller} message options
        }
        aa_equals "Condition still evaluates in the caller's scope" \
            [interp eval $child {dict get $options -errorcode}] {TEST BLOCK ABORT}
        aa_equals "Caller target still appears in the rejection" \
            [interp eval $child {lindex $complaints end}] {1 {page is not allowed for caller}}
        interp eval $child {
            set beforeAborts $aborts
            for {set n 0} {$n < 100} {incr n} {
                catch {util::block_request "true || $n" target$n}
            }
        }
        aa_equals "Varying conditions and targets cannot grow block-notice groups" [interp eval $child {dict size $cache}] 2
        aa_equals "Varying requests are all still rejected" [interp eval $child {expr {$aborts-$beforeAborts}}] 100
        aa_equals "Suppressed varying requests do not collect context" [interp eval $child {set contextCalls}] 3

        # Exercise complete contract bodies with both query shapes. The ns_set
        # fixture observes the actual parser frame to verify whether name exists;
        # it never assigns that local variable or chooses the logging category.
        interp eval $child {
            array set ::acs::ad_page_contract_filter_rules {}
            proc ad_complaints_init {context} {
                unset -nocomplain ::ad_page_contract_validations_passed
                array set ::ad_page_contract_validations_passed {}
            }
            proc ad_complaints_count {} {return 0}
            proc api_page_documentation_mode_p {} {return 0}
            proc ad_arg_parser {valid options} {
                if {$options ne ""} {error "Unexpected test option: $options"}
            }
            proc ns_set {operation form} {
                if {$operation ne "array"} {error "Unexpected ns_set operation: $operation"}
                incr ::formReads
                set ::nameAtForm [uplevel 1 {
                    if {[info exists name]} {list present $name} else {list absent}
                }]
                return $form
            }
            proc run_contract {query parameter} {
                set ::testForm [list $parameter 1]
                set ::formReads 0; set ::nameAtForm not-read
                set ::user_id 0; set ::connected true
                set ::state {}; set ::cache {}; set ::logs {}; set ::logKeys {}
                ad_page_contract {Regression fixture} $query
                if {[info exists page]} {return $page}
            }
            run_contract {} {<!--#include file="nessus.html"-->}
        }
        aa_equals "Empty contract with invalid input returns without reading the form" \
            [interp eval $child {set formReads}] 0
        aa_equals "Empty contract does not enter invalid-name logging" \
            [interp eval $child {llength $logs}] 0
        aa_equals "Nonempty contract still assigns its unrelated default" \
            [interp eval $child {run_contract {{page default}} {amp;project_id}}] default
        aa_equals "Nonempty parser leaves an unrelated formal name in its local variable" \
            [interp eval $child {set nameAtForm}] {present page}
        aa_equals "Classification uses the submitted name rather than the unrelated formal" \
            [interp eval $child {lindex $logKeys end}] {page-contract-invalid-name html-entity-name}
        aa_equals "Nonempty contract emits one warning for invalid input" \
            [interp eval $child {llength $logs}] 1
        aa_true "Warning contains the submitted name" \
            [interp eval $child {string match {*'amp;project_id'*} [lindex $logs 0 1]}]

        # Exercise the actual nonstandard-name logging branch. No variable
        # named "name" exists: submitted names are held in actual_name.
        set channel [open [file join [acs_package_root_dir acs-tcl] tcl tcl-documentation-procs.tcl]]
        try {set text [read $channel]} finally {close $channel}
        set start [string first {set message  "ad_page_contract: attempt to use a nonstandard variable name} $text]
        set start [string first {if {[ad_conn user_id] != 0}} $text $start]
        set branch {}
        foreach line [split [string range $text $start end] \n] {
            append branch $line \n
            if {[info complete $branch]} break
        }
        interp eval $child {
            unset -nocomplain name
            set user_id 0; set message invalid; set state {}; set cache {}; set logs {}
            set actual_name {amp;project_id}
        }
        interp eval $child $branch
        aa_equals "Entity-prefixed invalid name logs without an undefined variable" \
            [interp eval $child {set category}] html-entity-name
        interp eval $child {set actual_name {)}}
        interp eval $child $branch
        aa_equals "Other invalid name uses the general bounded category" \
            [interp eval $child {set category}] nonstandard-name

        # Cover the old warning branch independently as well: deployed older
        # contract bodies did not return early for an empty query. A stale formal
        # must not silently choose the category, in either direction.
        interp eval $child {
            set name unrelated
            set actual_name {amp;project_id}
        }
        interp eval $child $branch
        aa_equals "Unrelated stale formal cannot hide an entity-prefixed submitted name" \
            [interp eval $child {set category}] html-entity-name
        interp eval $child {
            set name {amp;unrelated}
            set actual_name {)}
        }
        interp eval $child $branch
        aa_equals "Entity-prefixed stale formal cannot misclassify other submitted names" \
            [interp eval $child {set category}] nonstandard-name

    } finally {
        interp delete $child
    }
}
