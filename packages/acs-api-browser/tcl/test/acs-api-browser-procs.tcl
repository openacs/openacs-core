ad_library {
    Automated tests.

    @author Joel Aufrecht
    @creation-date 2 Nov 2003
    @cvs-id $Id$
}

aa_register_case \
    -cats { api smoke } \
    -procs {
        api_library_documentation
    } \
    acs_api_browser_trivial_smoke_test {
        Minimal smoke test for acs-api-browser package.
    } {

        aa_run_with_teardown \
        -rollback \
        -test_code {
            set result [api_library_documentation packages/acs-api-browser/tcl/acs-api-documentation-procs.tcl]
            aa_true "api documentation proc can document itself" \
                [string match "*packages/acs-api-browser/tcl/acs-api-documentation-procs.tcl*" $result]
        }
    }

aa_register_case \
    -cats { api smoke } \
    -procs {
        api_add_to_proc_doc
    } \
    acs_api_browser_api_add_to_proc_doc {
        Check api_add_to_proc_doc
    } {
        set proc_name [ad_generate_random_string]
        set property [ad_generate_random_string]
        set value [ad_generate_random_string]
        set value2 ${value}2

        #
        # Silence Warning: api_add_to_proc_doc: no proc_doc available for
        #
        aa_silence_log_entries -severities {warning} {
            api_add_to_proc_doc \
                -proc_name $proc_name \
                -property $property \
                -value $value
        }

        aa_true "nsv was created" [nsv_exists api_proc_doc $proc_name]

        aa_true "nsv contains the property" [dict exists [nsv_get api_proc_doc $proc_name] $property]

        aa_true "Property has 1 value" \
            {[llength [dict get [nsv_get api_proc_doc $proc_name] $property]] == 1}
        aa_log "Adding the same value again"
        api_add_to_proc_doc \
            -proc_name $proc_name \
            -property $property \
            -value $value
        aa_true "Property still has 1 value" \
            {[llength [dict get [nsv_get api_proc_doc $proc_name] $property]] == 1}

        aa_log "Adding a different value"
        api_add_to_proc_doc \
            -proc_name $proc_name \
            -property $property \
            -value $value2
        aa_true "Property now has 2 values" \
            {[llength [dict get [nsv_get api_proc_doc $proc_name] $property]] == 2}

        nsv_unset -nocomplain -- api_proc_doc $proc_name
    }

aa_register_case \
    -cats { api smoke } \
    -procs {
        api_apropos_functions
    } \
    acs_api_browser_api_apropos_functions {
        Check api_apropos_functions
    } {
        set all_ad_procs [nsv_array names api_proc_doc]

        aa_true "Searching for the empty string returns every ad_proc" \
            {[llength [api_apropos_functions ""]] == [llength $all_ad_procs]}

        while {[set bogus_proc [ad_generate_random_string]] in $all_ad_procs} {}
        aa_true "A bogus proc returns no result" \
            {[llength [api_apropos_functions $bogus_proc]] == 0}

        set proc ns_write
        set found_p false
        foreach r [api_apropos_functions $proc] {
            lassign $r name etc
            if {$name eq $proc} {
                set found_p true
                break
            }
        }
        aa_false "Builtin '$proc' is not returned" $found_p

        set proc api_apropos_functions
        set found_p false
        foreach r [api_apropos_functions $proc] {
            lassign $r name etc
            if {$name eq $proc} {
                set found_p true
                break
            }
        }
        aa_true "ad_proc '$proc' is retrieved correctly" $found_p
    }

aa_register_case \
    -cats { api smoke production_safe } \
    -procs {
        api_describe_function
        ad_looks_like_html_p

        util_wrap_list
    } \
    acs_api_browser_api_describe_function {
        Check api_describe_function
    } {
        aa_true "Searching for the empty string returns nothing" \
            {[string length [api_describe_function ""]] == 0}

        aa_true "A 'proper' search by an existing proc name returns some results" \
            {[string length [api_describe_function api_describe_function]] > 0}

        set default_results [api_describe_function api_describe_function]
        set text_results [api_describe_function -format text/plain api_describe_function]
        set html_results [api_describe_function -format text/html api_describe_function]
        set anything_else_results [api_describe_function -format [ad_generate_random_string] api_describe_function]

        aa_true "Default format is text/plain" \
            {$default_results eq $text_results}

        aa_false "Text format looks like text" \
            [ad_looks_like_html_p $text_results]

        aa_true "HTML format looks like HTML" \
            [ad_looks_like_html_p $html_results]

        aa_true "Specifying a bogus format also returns HTML" \
            [ad_looks_like_html_p $anything_else_results]
    }

aa_register_case \
    -cats { api smoke } \
    -procs {
        api_get_body
    } \
    acs_api_browser_api_get_body {
        Check api_get_body
    } {
        foreach proc_name [nsv_array names api_proc_doc] {
            aa_true "Something similar to a tcl body is returned for '$proc_name'" \
                [info complete [api_get_body $proc_name]]
        }
    }

aa_register_case \
    -cats { api smoke production_safe } \
    -procs {
        api_proc_documentation
        ad_looks_like_html_p

        util_wrap_list
    } \
    acs_api_browser_api_proc_documentation {
        Check api_proc_documentation
    } {
        set proc api_proc_documentation

        aa_true "Specifying an invalid proc throws an error" [catch {
            api_proc_documentation [ad_generate_random_string]
        }]

        set doc [api_proc_documentation $proc]
        aa_true "Format is HTML" [ad_looks_like_html_p $doc]

        set doc [api_proc_documentation -format text/plain $proc]
        aa_true "Format is HTML also when specifying deprecated -format flag" [ad_looks_like_html_p $doc]

        set proc_url [dict get [nsv_get api_proc_doc $proc] script]
        set doc [api_proc_documentation -script $proc]
        aa_true "Specifying the script flag returns the proc file" [string match *$proc_url* $doc]

        set doc [api_proc_documentation -xql $proc]
        aa_true "Specifying the xql flag returns the something about xql" [string match -nocase *xql* $doc]

        set doc [api_proc_documentation -first_line_tag <h2> $proc]
        aa_true "Specifying the first line tag prints it out around the first line" [regexp {^<h2>.*</h2>.*$} $doc]

        set label [ad_generate_random_string]
        set doc [api_proc_documentation -first_line_tag <h2> -label $label $proc]
        aa_true "Specifying the label prints it out in the first line" [regexp [subst -nocommands {^<h2>.*$label.*</h2>.*$}] $doc]

        set proc_type [ad_generate_random_string]
        set doc [api_proc_documentation -first_line_tag <h2> -proc_type $proc_type $proc]
        aa_true "Specifying the proc type it out in the first line" [regexp [subst -nocommands {^<h2>.*$proc_type.*</h2>.*$}] $doc]
    }

aa_register_case \
    -cats { api smoke production_safe } \
    -procs {
        api_proc_pretty_name
        api_proc_url
    } \
    acs_api_browser_api_proc_pretty_name {
        Check api_proc_pretty_name and api_proc_url procs
    } {
        set proc api_proc_pretty_name
        set label [ad_generate_random_string]
        set bogus_proc [ad_generate_random_string]
        set proc_type [ad_generate_random_string]

        aa_true "A bogus proc returns the empty string" \
            {[api_proc_pretty_name -hints_only $bogus_proc] eq ""}
        aa_true "A bogus proc returns the empty string" \
            {[api_proc_pretty_name -link -hints_only $bogus_proc] eq ""}
        aa_true "A bogus proc returns the empty string" \
            {[api_proc_pretty_name -include_debug_controls -link -hints_only $bogus_proc] eq ""}

        aa_true "Hints are printed in parentheses, the proc type belongs to the hints" [
            regexp "^\(.*$proc_type.*\)$" [string trim [
                api_proc_pretty_name -proc_type $proc_type -hints_only $proc]]]

        aa_true "-include_debug_controls prints out a form when XOTcl is installed" {
            [namespace which ::xo::api] eq "" || [
                regexp {^.*<form[^>]*>.*</form[^>]*.*$} [
                    api_proc_pretty_name -include_debug_controls $proc]]
        }

        aa_true "-link will put the proc URL somewhere" \
            [string match "*[ns_quotehtml [api_proc_url $proc]]*" [api_proc_pretty_name -link $proc]]

        aa_true "-label will put the label somewhere if -link is specified" \
            [string match *$label* [api_proc_pretty_name -link -label $label $proc]]
    }

aa_register_case \
    -cats { api smoke } \
    -procs {
        api_read_script_documentation
        acs_root_dir
    } \
    acs_api_browser_api_read_script_documentation {
        Check api_read_script_documentation
    } {
        set tmpfile packages/acs-automated-testing/www/[ad_generate_random_string]

        aa_true "Reading info from a non-existing file returns an error" \
            [catch {api_read_script_documentation $tmpfile}]

        aa_log "Touching tmpfile $tmpfile"
        set wfd [open [acs_root_dir]/$tmpfile w]
        close $wfd

        aa_true "Reading info from a file without documentation returns an empty list" \
            {[llength [api_read_script_documentation $tmpfile]] == 0}

        aa_log "A real file will always return a minimal set of keys"
        set real_file packages/acs-automated-testing/www/index.tcl
        set doc [api_read_script_documentation $real_file]
        set doc_keys [dict keys $doc]
        foreach key {apc_default_value apc_flags apc_arg_names main query} {
            aa_true "'$key' key found in returned doc" {$key in $doc_keys}
        }
    }

aa_register_case \
    -cats { api smoke } \
    -procs {
        acs_root_dir
        ad_looks_like_html_p
        api_script_documentation
    } \
    acs_api_browser_api_script_documentation {
        Check api_script_documentation
    } {
        set tmpfile packages/acs-automated-testing/www/[ad_generate_random_string]
        set real_file packages/acs-automated-testing/www/index.tcl

        aa_true "This proc returns HTML with a non-existing file" [ad_looks_like_html_p [api_script_documentation $tmpfile]]
        aa_true "This proc returns HTML with a non-existing tcl file" [ad_looks_like_html_p [api_script_documentation ${tmpfile}.tcl]]

        aa_log "Touching tmpfile $tmpfile"
        set wfd [open [acs_root_dir]/$tmpfile w]
        close $wfd
        aa_true "This proc returns HTML with an existing empty file" [ad_looks_like_html_p [api_script_documentation $tmpfile]]

        aa_true "This proc returns HTML with a real tcl file" [ad_looks_like_html_p [api_script_documentation $real_file]]

        aa_true "This proc returns HTML even when otherwise specified" \
            [ad_looks_like_html_p [api_script_documentation -format [ad_generate_random_string] $tmpfile]]
    }

aa_register_case \
    -cats { api smoke production_safe } \
    -procs {
        apidoc::format_author
    } \
    acs_api_browser_apidoc_format_author {
        Check apidoc::format_author
    } {
        set input1 "test@email.com"
        aa_true "Mailto link is generated for '$input1'" \
            [regexp [subst -nocommands {^<a.*href=.mailto:$input1.*</a>$}] [apidoc::format_author $input1]]

        set name "John Doe"
        set email "company@domain.com"
        set input2 "$name ($email)"
        aa_true "Mailto link with name is generated for '$input2'" \
            [regexp [subst -nocommands {$name.*<a.*href=.mailto:$email.*</a>}] [apidoc::format_author $input2]]

        set input3 [ad_generate_random_string]
        aa_true "Same string is returned for '$input3'" \
            {[apidoc::format_author $input3] eq $input3}
    }

aa_register_case \
    -cats { api smoke production_safe } \
    -procs {
        apidoc::format_see
        ad_looks_like_html_p
        ad_urldecode_query
    } \
    acs_api_browser_apidoc_format_see {
        Check apidoc::format_see
    } {
        set bogus_value [ad_generate_random_string]
        aa_true "Bogus value returns itself" \
            {[apidoc::format_see $bogus_value] eq $bogus_value}

        foreach see [list \
                         apidoc::format_see \
                         "/doc/[ad_generate_random_string]" \
                         /packages/acs-api-browser/tcl/test/acs-api-browser-procs.tcl] {
            set output [apidoc::format_see $see]
            aa_true "Valid input '$see' returns some HTML" \
                [ad_looks_like_html_p $output]
            aa_true "Valid input '$see' contains itself" \
                [string match *$see* $output]
            aa_true "Valid input '$see' contains some sort of URL of itself" \
                [string match *[ns_quotehtml [ad_urldecode_query $see]]* $output]
        }

        aa_true "<proc> and ::<proc> are the same thing" \
            {[apidoc::format_see apidoc::format_see] eq [::apidoc::format_see apidoc::format_see]}
    }

aa_register_case \
    -cats { api smoke production_safe } \
    -procs {
        apidoc::tclcode_to_html
        apidoc::tcl_to_html
        ad_looks_like_html_p
        ad_urldecode_query
    } \
    acs_api_browser_apidoc_tclcode_to_html {
        Check apidoc::tclcode_to_html
    } {
        set bogus_value [ad_generate_random_string]
        set proc_value [apidoc::tclcode_to_html $bogus_value]
        aa_true "Bogus value returns itself ('$proc_value' eq '$bogus_value')" \
            {$proc_value eq $bogus_value}

        aa_log "Fetching a few commands to test..."
        set commands [list]
        foreach command [info commands] {
            # Skip XOTcl methods
            if {[namespace which ::xotcl::Object] ne ""
                && [::xotcl::Object isobject [lindex $command 0]]} {
                continue
            }
            # Skip some corner-case command names created by the platform... is
            # this a bug or not?
            if {![regexp {(template_tag_listfilters|AcsSc\.|validator1\.|!|^_[^ ]|^\d+)} $command]} {
                lappend commands $command
            }
            if {[llength $commands] >= 50} {
                break
            }
        }
        if {[namespace which ::xotcl::Object] ne ""} {
            aa_log "Adding a few XOTcl classes"
            lappend commands {*}[lrange [::xotcl::Object info instances] 0 100]
        }
        foreach command $commands {
            set output [apidoc::tclcode_to_html $command]
            #ns_log notice ".... $command output $output"
            aa_true "Valid input '$command' returns some HTML" \
                [ad_looks_like_html_p $output]
            aa_true "Valid input '$command' contains itself" \
                {[string first $command $output] > -1}
            aa_true "Valid input '$command' contains some sort of URL of itself" \
                {[string first [ns_quotehtml [ad_urldecode_query $command]] $output] > -1}
        }

        foreach command $commands {
            set output [apidoc::tcl_to_html $command]
            aa_true "Proc '$command' returns some HTML" \
                [ad_looks_like_html_p $output]
            aa_true "Proc '$command' contains links to commands documentation" \
                {
                    [string first /api-doc/proc-view $output] > -1 ||
                    [string first /api-doc/tcl-proc $output] > -1 ||
                    [string first /xotcl/show-object $output] > -1
                }
        }

        aa_true "Specifying OO flags on non-OO commands is not harmful" \
            {[apidoc::tclcode_to_html -scope [ad_generate_random_string] apidoc::tclcode_to_html] eq [apidoc::tclcode_to_html apidoc::tclcode_to_html]}

        aa_true "Specifying namespace works as expected" \
            {[string first \
                  [ns_quotehtml [ad_urldecode_query apidoc::tclcode_to_html]] \
                  [apidoc::tclcode_to_html -proc_namespace apidoc tclcode_to_html]] > -1}
    }


aa_register_case \
    -cats {smoke production_safe} \
    -procs {
        aa_error
        api_called_proc_names
        apidoc::get_doc_property
    } \
    callgraph__bad_library_calls {

        Checks for calls of deprecated procs and for private calls in
        other packages. Remember: "private" means "package private", a
        "private" proc must be only directly called by a proc of the
        same package

        This test covers only library functions.

        @author Gustaf Neumann

        @creation-date 2020-02-18
    } {

        # Fetch service-contract procs to exclude them from the check
        # when they are called from within the acs-service-contract
        # package.
        foreach alias [db_list get_sc_aliases {
            select distinct impl_alias from acs_sc_impl_aliases
        }] {
            set sc_aliases($alias) 1
        }

        foreach caller [lsort -dictionary [nsv_array names api_proc_doc]] {
            #set caller db_transaction
            set called_procs [api_called_proc_names -proc_name $caller]
            set caller_deprecated_p [apidoc::get_doc_property $caller deprecated_p 0]
            set caller_package_key [apidoc::get_doc_property $caller package_key ""]
            foreach called $called_procs {
                #ns_log notice "$caller calls $called"
                set msg "proc $caller calls deprecated proc: $called"
                if {[apidoc::get_doc_property $called deprecated_p 0]} {
                    if {$caller_deprecated_p} {
                        aa_log_result warning "deprecated $msg"
                    } else {
                        aa_error "$msg<br>\
                            <small><code>[apidoc::get_doc_property $caller script]</code></small><br>\
                            <small><code>[apidoc::get_doc_property $called script]</code></small>"
                    }
                }
                set package_key [apidoc::get_doc_property $called package_key ""]
                if {$caller_package_key ne ""
                    && $package_key ne ""
                    && $caller_package_key ne $package_key
                } {
                    # It is fine for acs-service-contract to invoke
                    # contract implementations.
                    if {$caller_package_key eq "acs-service-contract" &&
                        [info exists sc_aliases($called)]} {
                        continue
                    }
                    if {[apidoc::get_doc_property $called protection public] eq "private"
                        && ![string match AcsSc.* $caller]
                    } {
                        set msg "proc $caller_package_key.$caller calls private $package_key.$called"
                        if {$caller_deprecated_p} {
                            aa_log_result warning "deprecated $msg"
                        } else {
                            aa_error "$msg<br>\
                                <small><code>[apidoc::get_doc_property $caller script]</code></small><br>\
                                <small><code>[apidoc::get_doc_property $called script]</code></small>"
                        }
                    }
                }
            }
        }
    }

aa_register_case \
    -cats {smoke production_safe} \
    -procs {
        aa_error
        api_called_proc_names
        apidoc::get_doc_property
        template::adp_init

        ds_adp_start_box
        ds_adp_end_box
    } \
    callgraph__bad_page_calls {

        Checks for calls of deprecated procs and for private calls in
        other packages. Remember: "private" means "package private", a
        "private" proc must be only directly called by a proc of the
        same package

        This test covers only calls from adp pages.

        @author Gustaf Neumann

        @creation-date 2020-03-12
    } {

        #
        # Iterate over all package_keys
        #
        set count 0
        foreach package_key [db_list _ {select package_key from apm_package_types order by 1}] {
            #
            # Process the content pages of the package.
            #
            set processed 0
            foreach path [apm_get_package_files -package_key $package_key -file_types content_page] {
                set type [string range [file extension $path] 1 end]
                if {$type in {tcl adp}} {
                    #
                    # Just call the template compiler for every
                    # template to populate the cache for all
                    # templates. These entries are needed below to
                    # apply the usual code-analysis on it. The "call"
                    # is never executed.
                    #
                    set stub $::acs::rootdir/packages/$package_key/[file rootname $path]
                    append _ $package_key/$path \n
                    set call [template::adp_init $type $stub]
                    incr processed
                } else {
                    append _ "ignore $package_key/$path (type $type)\n"
                }
            }
            append _ "$package_key ($processed files)\n"
            aa_log "$package_key ($processed files)"
            #if {$count > 2} break
        }

        #aa_log "<pre>[ns_quotehtml $_]</pre>"
        #
        # Collect the compiled artefacts
        #
        set procs {}
        foreach ns [lmap ns [namespace children ::template::code] {set ns}] {
            lappend procs {*}[info commands ${ns}::*]
        }

        foreach caller [lsort -dictionary $procs] {
            #set caller db_transaction
            set called_procs [api_called_proc_names -proc_name $caller]
            set caller_deprecated_p [apidoc::get_doc_property $caller deprecated_p 0]
            set caller_package_key [apidoc::get_doc_property $caller package_key ""]
            set caller_name $caller
            if {[regexp {template::code::tcl::(.*)$} $caller _ path]} {
                set caller_name $path.tcl
                regexp {/packages/([^/]+)/} $path _ caller_package_key
            }
            if {[regexp {template::code::adp::(.*)$} $caller _ path]} {
                set caller_name $path.adp
                regexp {/packages/([^/]+)/} $path _ caller_package_key
            }
            foreach called $called_procs {
                #ns_log notice "$caller calls $called"
                set msg "page $caller_name calls deprecated proc: $called"
                if {[apidoc::get_doc_property $called deprecated_p 0]} {
                    if {$caller_deprecated_p} {
                        aa_log_result warning "deprecated $msg"
                    } else {
                        aa_error "$msg<br>\
                            <small><code>$caller_name</code></small><br>\
                            <small><code>[apidoc::get_doc_property $called script]</code></small>"
                    }
                }
                set package_key [apidoc::get_doc_property $called package_key ""]
                if {$caller_package_key eq ""} {
                    aa_log "caller package key '$caller_package_key' $caller_name"
                }
                if {$caller_package_key ne ""
                    && $package_key ne ""
                    && $caller_package_key ne $package_key
                } {
                    #aa_log "$caller from $caller_package_key calls $package_key.$called [apidoc::get_doc_property $called protection public]"
                    if {[apidoc::get_doc_property $called protection public] eq "private"
                        && ![string match AcsSc.* $caller]
                    } {
                        set msg "page $caller_name calls private $package_key.$called"
                        if {$caller_deprecated_p} {
                            aa_log_result warning "deprecated $msg"
                        } else {
                            aa_error "$msg<br>\
                                <small><code>$caller_name</code></small><br>\
                                <small><code>[apidoc::get_doc_property $called script]</code></small>"
                        }
                    }
                }
            }
        }
    }

aa_register_case -cats {
    web
    smoke
} -urls {
    /api-doc/
    /api-doc/proc-search
} acs_api_browser_search {
    Simple test to search for a proc in the API-browser

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 03 March 2021
} {
    aa_run_with_teardown -test_code {
        #
        # Create a new admin user and login
        #
        set user_id [db_nextval acs_object_id_seq]
        set user_info [acs::test::user::create -user_id $user_id -admin]
        acs::test::confirm_email -user_id $user_id
        #
        # Go to the API-doc and check status code
        #
        set d [acs::test::http -depth 3 -user_info $user_info /api-doc/]
        acs::test::reply_has_status_code $d 200
        #
        # Get the form data
        #
        set form_data [::acs::test::get_form [dict get $d body] {//form[@id="api-search"]}]

        #
        # Fill in with the proc to search
        #
        set proc_to_search "ad_proc"
        set param_weight 3

        set d [::acs::test::form_reply \
                   -last_request $d \
                   -url [dict get $form_data @action] \
                   -update [subst {
                       query_string "$proc_to_search"
                       param_weight $param_weight
                   }] \
                   [dict get $form_data fields]]

        set reply [dict get $d body]

        #
        # Check, if the form was correctly validated.
        #
        acs::test::reply_contains_no $d form-error
        acs::test::reply_has_status_code $d 302
        #
        # Check the proc-search page directly
        #
        set page "/api-doc/proc-search?query_string=$proc_to_search&param_weight=$param_weight"

        #
        # Silence Warning: CSRF failure
        #
        aa_silence_log_entries -severities warning {
            set d [acs::test::http -user_info $user_info $page]
        }
        acs::test::reply_has_status_code $d 200
    }
}

aa_register_case \
    -error_level warning \
    -cats {smoke production_safe stress} \
    api__smells_of_hacking {
        Searches for "smells of hacking" inside every proc's doc and
        body.
    } {
        set smells {
            hack
            hotfix
            todo
            ugly
            fixme
            quickfix
        }
        set rx ^.*([join $smells |]).*$
        foreach proc_name [nsv_array names api_proc_doc] {
            set doc_elements [nsv_get api_proc_doc $proc_name]
            if {[dict exists $doc_elements deprecated_p]} {
                set deprecated_p [dict get $doc_elements deprecated_p]
            } else {
                set deprecated_p false
            }
            if {!$deprecated_p} {
                if {[dict exists $doc_elements main]} {
                    set documentation [dict get $doc_elements main]
                } else {
                    set documentation ""
                }
                set code [api_get_body $proc_name]
                set smells_p [regexp -nocase -- $rx $code m smell]
                set smell [expr {$smells_p ? "of '$smell'" : ""}]
                aa_false "'$proc_name' body smells $smell" $smells_p
                set smells_p [regexp -nocase -- $rx $documentation m smell]
                set smell [expr {$smells_p ? "of '$smell'" : ""}]
                aa_false "'$proc_name' doc smells $smell" $smells_p
            }
        }
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
