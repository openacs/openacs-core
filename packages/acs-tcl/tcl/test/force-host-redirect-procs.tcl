ad_library {
    Regression coverage for ForceHostP path encoding, query preservation and
    canonical host selection. No live request, database or settings are changed.
}

aa_register_case -cats {api smoke production_safe} -procs {
    rp_filter rp_force_host_redirect
} rp_force_host_redirect {
    Exercise the production URL builder and the rp_filter preflight through
    ForceHostP, using isolated connection state and native URL parsing/encoding.
} {
    set child [interp create]
    try {
        interp alias $child ns_parseurl {} ns_parseurl
        interp alias $child ns_urlencode {} ns_urlencode
        interp alias $child ns_set {} ns_set
        interp eval $child {
            namespace eval util {}
            namespace eval acs {variable kernel_id 1}
            namespace eval security {}
        }
        foreach {filename prefix name arguments} {
            utilities-procs.tcl {ad_proc util::split_host} util::split_host {hostspec hostnameVar portVar}
            utilities-procs.tcl {ad_proc util::split_location} util::split_location {location protoVar hostnameVar portVar}
            utilities-procs-naviserver.tcl {ad_proc -public ad_urlencode_folder_path} ad_urlencode_folder_path folder_path
            request-processor-procs.tcl {ad_proc -private rp_force_host_redirect} rp_force_host_redirect {host_header location path query {effective_location ""}}
            request-processor-procs.tcl {ad_proc -private rp_filter} rp_filter why
        } {
            set channel [open [file join [acs_package_root_dir acs-tcl] tcl $filename]]
            try {set source [read $channel]} finally {close $channel}
            set start [string first "$prefix " $source]
            if {$start<0} {error "Missing production declaration: $prefix"}
            set declaration {}
            foreach line [split [string range $source $start end] \n] {
                append declaration $line \n
                if {[info complete $declaration]} break
            }
            if {![info complete $declaration]} {error "Incomplete production declaration: $prefix"}
            set body [lindex $declaration end]
            if {$name eq "rp_filter"} {
                # Test the real preflight and ForceHostP branch; stop before
                # site-node lookup, authentication and database-dependent work.
                set stop [string first {    # DRB: a bug in ns_conn} $body]
                if {$stop<0} {error "Cannot locate rp_filter preflight boundary"}
                set body "[string range $body 0 [expr {$stop-1}]]\nreturn filter_ok"
            }
            interp eval $child [list proc $name $arguments $body]
        }

        foreach {label host location path query expected} {
            pdf-spaces 137.208.116.31 https://openacs.org {/file/988398/modelling competency in dotlrn.pdf} {} https://openacs.org/file/988398/modelling%20competency%20in%20dotlrn.pdf
            backslash alias.example http://openacs.org {/storage/view/conference\ /Collaborative_task.pdf} {} http://openacs.org/storage/view/conference%5c%20/Collaborative_task.pdf
            logged-backslash alias.example http://openacs.org {/storage/view/openacs-dotlrn-conference-2007-spring\/Collaborative_task_in_dotLRN.pdf} {} http://openacs.org/storage/view/openacs-dotlrn-conference-2007-spring%5c/Collaborative_task_in_dotLRN.pdf
            empty-query alias.example https://openacs.org /plain {} https://openacs.org/plain
            encoded-query alias.example https://openacs.org /download {return_url=%2Fstorage%2F&sig=1+2+ABC&literal=%2B&x=1&x=2} {https://openacs.org/download?return_url=%2Fstorage%2F&sig=1+2+ABC&literal=%2B&x=1&x=2}
            reserved-path alias.example https://openacs.org {/a?b#c%20d} {} https://openacs.org/a%3fb%23c%2520d
            unicode alias.example https://openacs.org /café {} https://openacs.org/caf%c3%a9
            port alias.example:8080 https://openacs.org:8443 /file {} https://openacs.org:8443/file
            root alias.example https://openacs.org / {} https://openacs.org/
            canonical openacs.org https://openacs.org /file {} {}
            host-port openacs.org:443 https://openacs.org /file {} {}
            case-insensitive OPENACS.ORG https://openacs.org /file {} {}
            missing-host {} https://openacs.org /file {} {}
            ipv6-canonical {[2001:db8::1]:443} {https://[2001:db8::1]} /file {} {}
            ipv6-alias {[2001:db8::2]} {https://[2001:db8::1]:8443} /file {} {https://[2001:db8::1]:8443/file}
            configured-ip alias.example https://137.208.116.31 /file {} https://137.208.116.31/file
        } {
            aa_equals $label [interp eval $child [list rp_force_host_redirect $host $location $path $query]] $expected
        }

        foreach {label configured effective expected} {
            proxy-scheme http://openacs.org:8000 https://137.208.116.31 https://openacs.org/file
            suppressed-port https://openacs.org:8443 https://137.208.116.31 https://openacs.org/file
            explicit-port https://openacs.org:8443 https://137.208.116.31:9443 https://openacs.org:9443/file
            ipv6-effective {https://[2001:db8::1]:8443} http://alias.example:8080 {http://[2001:db8::1]:8080/file}
        } {
            aa_equals $label [interp eval $child [list rp_force_host_redirect alias.example $configured /file {} $effective]] $expected
        }

        interp eval $child {
            namespace eval parameter {}
            proc parameter::get {args} {
                set name [lindex $args [expr {[lsearch -exact $args -parameter]+1}]]
                switch -- $name {
                    ForceHostP {return $::force}
                    MaxUrlLength {return 2000}
                    default {return 0}
                }
            }
            proc ad_try {args} {uplevel 1 [list try {*}$args]}
            proc sec_handler_reset {} {}
            proc ds_collect_connection_info {} {}
            proc security::set_user_id {args} {}
            proc acs::root_of_host {host} {return $::root}
            proc ad_host {} {return $::host}
            proc ns_conn {key} {
                switch -- $key {
                    headers {return $::headers}
                    url {return $::path}
                    query {return $::query}
                    location {return $::configured_location}
                    id {return 1}
                    default {error "Unexpected ns_conn operation $key"}
                }
            }
            proc ad_conn {args} {
                switch -- [lindex $args 0] {
                    -reset {set ::connection [dict create url $::path urlv [lrange [split $::path /] 1 end] urlc 3]}
                    -set {dict set ::connection [lindex $args 1] [lindex $args 2]}
                    default {return [dict get $::connection [lindex $args 0]]}
                }
            }
            proc ad_returnredirect {args} {set ::redirect $args}
            proc ns_getform {} {error "ForceHostP must not read form data"}
            proc export_vars {args} {error "ForceHostP must not reserialize the query/body"}
            proc util_current_location {} {return https://137.208.116.31}
            proc run_filter {force root {query ""} {host 137.208.116.31}} {
                set ::force $force; set ::root $root
                set ::host $host
                set ::configured_location https://openacs.org
                set ::path {/file/988398/modelling competency in dotlrn.pdf}
                set ::query $query
                set ::headers [ns_set create headers Host $::host]
                unset -nocomplain ::redirect
                try {
                    set result [rp_filter preauth]
                    return [list $result [expr {[info exists ::redirect] ? $::redirect : {}}]]
                } finally {ns_set free $::headers}
            }
        }
        aa_equals "Full preflight redirects IP to canonical domain, encoding path without empty ?" \
            [interp eval $child {run_filter 1 {}}] \
            {filter_return {-allow_complete_url https://openacs.org/file/988398/modelling%20competency%20in%20dotlrn.pdf}}
        aa_equals "Query survives the complete preflight without form/body reserialization" \
            [interp eval $child {run_filter 1 {} {return_url=%2Fstorage%2F&sig=1+2+ABC&literal=%2B}}] \
            {filter_return {-allow_complete_url https://openacs.org/file/988398/modelling%20competency%20in%20dotlrn.pdf?return_url=%2Fstorage%2F&sig=1+2+ABC&literal=%2B}}
        aa_equals "Following the canonical redirect does not redirect again" \
            [interp eval $child {run_filter 1 {} {} openacs.org}] {filter_ok {}}
        aa_equals "ForceHostP disabled preserves normal processing" \
            [interp eval $child {run_filter 0 {}}] {filter_ok {}}
        aa_equals "Host-node subsites are not forced to the main hostname" \
            [interp eval $child {run_filter 1 /mapped}] {filter_ok {}}
    } finally {
        interp delete $child
    }
}
