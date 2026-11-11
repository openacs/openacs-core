ad_library {
    Regression tests for command resolution in formatted Tcl source.
}

aa_register_case -cats {api smoke production_safe} -procs {
    apidoc::tclcode_to_html api_called_proc_names
} acs_api_browser_command_resolution {
    Preserve Tcl namespace resolution and avoid links for substituted names.
} {
    set ns ::api_browser_resolution_test
    namespace eval $ns {
        # An NX slot can expose a local method named namespace.
        proc namespace {} {}
        proc target {args} {}
        proc api_browser_resolution_global {args} {}
        namespace eval child {proc target {args} {}}
    }
    proc ::api_browser_resolution_global {args} {}
    try {
        foreach {word expected} {
            target api_browser_resolution_test::target
            child::target api_browser_resolution_test::child::target
            ::api_browser_resolution_global api_browser_resolution_global
            api_browser_resolution_global api_browser_resolution_test::api_browser_resolution_global
            ::api_browser_resolution_test::target api_browser_resolution_test::target
        } {
            set html [apidoc::tclcode_to_html -proc_namespace $ns "$word argument"]
            set doc [dom parse -html "<div>$html</div>"]
            try {
                set a [lindex [[$doc documentElement] selectNodes //a] 0]
                aa_equals "Resolved link $word" [$a getAttribute href] [api_proc_url $expected]
                aa_equals "Original spelling $word" [$a asText] $word
            } finally {$doc delete}
            # Exercise the production caller extraction path with namespace context.
            set body "namespace eval $ns \{\n$word argument\n\}"
            aa_equals "Canonical caller target $word" \
                [api_called_proc_names -proc_name resolution-test -body $body] [list $expected]
        }
        rename ${ns}::api_browser_resolution_global {}
        set html [apidoc::tclcode_to_html -proc_namespace $ns {api_browser_resolution_global argument}]
        aa_true "Unqualified name falls back to global" \
            [string match {*proc=api_browser_resolution_global&*} $html]
        foreach script {
            {${namespace}::target argument}
            {$namespace\::target argument}
            {target${suffix} argument}
            {target[factory] argument}
            {[factory]::target argument}
            {[factory]target argument}
        } {
            set html [apidoc::tclcode_to_html -proc_namespace $ns $script]
            aa_false "No invented target for $script" [string match {*proc=*target*} $html]
            set body "namespace eval $ns \{\n$script\n\}"
            aa_equals "No false caller for $script" \
                [api_called_proc_names -proc_name resolution-test -body $body] {}
        }
        set html [apidoc::tclcode_to_html -proc_namespace $ns \
                      {target[::api_browser_resolution_global] argument}]
        aa_false "Dynamic outer name has no target link" [string match {*proc=*target*} $html]
        aa_true "Literal nested call remains linked" \
            [string match {*proc=api_browser_resolution_global&*} $html]
    } finally {
        namespace delete $ns
        rename ::api_browser_resolution_global {}
    }
}
