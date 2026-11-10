ad_library {
    Regression tests for qualified NaviServer command links.
}

aa_register_case \
    -cats {api smoke} \
    -procs {apidoc::tclcode_to_html api_called_proc_names} \
    acs_api_browser_native_command_links {
        Qualified NaviServer commands use canonical server-documentation links;
        NSF and similarly named commands are not treated as NaviServer builtins.
    } {
        foreach name {ns_dbquotelist ns_dbquotevalue ns_write nsv_get ns_crypto::md nscp} {
            foreach spelling [list $name ::$name] {
                set html [apidoc::tclcode_to_html "$spelling argument"]
                set doc [dom parse -html "<div>$html</div>"]
                try {
                    set a [lindex [[$doc documentElement] selectNodes //a] 0]
                    aa_equals "Native link for $spelling" [$a getAttribute href] \
                        "/api-doc/tcl-proc-view?tcl_proc=$name"
                    aa_equals "Preserve displayed spelling $spelling" [$a asText] $spelling
                } finally {
                    $doc delete
                }
                aa_equals "No local call-graph entry for $spelling" \
                    [api_called_proc_names -proc_name native-link-test -body "$spelling argument"] {}
            }
        }
        foreach name {nsf::dispatch ::nsf::dispatch nsf::var::exists ::nsf::var::exists nslookalike ::nslookalike nscplookalike ::nscplookalike nscp::helper ::nscp::helper} {
            set html [apidoc::tclcode_to_html "$name argument"]
            aa_false "No NaviServer link for $name" \
                [string match {*tcl-proc-view?tcl_proc=*} $html]
        }
        foreach name {api_proc_url ::api_proc_url apidoc::length_proc ::apidoc::length_proc} {
            set html [apidoc::tclcode_to_html "$name argument"]
            set doc [dom parse -html "<div>$html</div>"]
            try {
                set a [lindex [[$doc documentElement] selectNodes //a] 0]
                aa_equals "Ordinary API link for $name" [$a getAttribute href] [api_proc_url $name]
            } finally {
                $doc delete
            }
        }
        foreach name {ns_write nsv_get ns_crypto::md nscp} {
            foreach prefix {: ::: ::::} {
                set html [apidoc::tclcode_to_html "$prefix$name argument"]
                aa_false "Reject malformed native name $prefix$name" \
                    [string match {*tcl-proc-view?tcl_proc=*} $html]
            }
        }
        set html [apidoc::tclcode_to_html {::set variable value}]
        aa_true "Qualified Tcl keyword keeps its existing link" \
            [string match {*proc-view?proc=set*} $html]
    }
