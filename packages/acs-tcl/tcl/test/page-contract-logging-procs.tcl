ad_library {
    Regression tests for bounded duplicate-parameter logging.
}

aa_register_case -cats {api smoke production_safe} -procs {
    ad_page_contract_log_duplicate ad_log util::log_rate_limit_check
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
            tcl-documentation-procs.tcl {ad_proc -private ad_page_contract_log_duplicate} ad_page_contract_log_duplicate {formal_name complaint}
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
    } finally {
        interp delete $child
    }
}
