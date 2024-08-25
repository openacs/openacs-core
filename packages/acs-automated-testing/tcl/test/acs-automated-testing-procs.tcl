ad_library {
    Automated tests.

    @author Peter Marklund
    @creation-date 26 July 2018
}

aa_register_case \
    -cats {api web} \
    -procs {
        aa_equals
        aa_false
        aa_log
        aa_run_with_teardown
        aa_section
        aa_true
        acs::test::confirm_email
        acs::test::http
        acs::test::login
        acs::test::logout
        acs::test::reply_contains
        acs::test::reply_contains_no
        acs::test::reply_has_status_code
        acs::test::user::create
        acs::test::user::delete
        acs::test::url

        aa_check_leftovers
        aa_silence_log_entries
        aa_register_case
        aa_runseries
        aa_test_end
        aa_test_running_p
        aa_test_start
        ad_context_node_list
        ad_get_external_registries
    } \
    webtest_example {

    A simple test case demonstrating the use of web tests (via
    HTTP/HTTPS).

    @author Gustaf Neumann
} {

    aa_run_with_teardown -test_code {
        set user_id [db_nextval acs_object_id_seq]

        # Create test user
        set user_info [acs::test::user::create -user_id $user_id]
        set request_info [list session user_info $user_info]
        acs::test::confirm_email -user_id $user_id

        ########################################################################################
        aa_section "Visit homepage as anonymous user, last name of user should not show up"
        ########################################################################################
        set d [acs::test::http /]
        acs::test::reply_contains_no $d [dict get $user_info last_name]

        # Login user
        #set d [acs::test::login $user_info]

        ########################################################################################
        aa_section "Visit homepage with request_info, should login, last name of user should be contained"
        ########################################################################################
        aa_log "USER_INFO $user_info"
        set d [acs::test::http -depth 3 -user_info $user_info /]

        acs::test::reply_has_status_code $d 200
        acs::test::reply_contains $d [dict get $user_info last_name]
        aa_equals "login [dict get $d login]" [dict get $d login] via_login
        aa_true "cookies are not empty '[dict get $d session cookies]'" {[dict get $d session cookies] ne ""}
        aa_false "cookies are not empty '[dict get $d session cookies]'" {[dict get $d session cookies] eq ""}

        ########################################################################################
        aa_section "Make a second request, now the cookie should be used"
        ########################################################################################
        set d [acs::test::http -depth 3 -last_request $d /]
        acs::test::reply_has_status_code $d 200
        acs::test::reply_contains $d [dict get $user_info last_name]
        aa_equals "login [dict get $d login]" [dict get $d login] via_cookie

        ########################################################################################
        aa_section "Logout user"
        ########################################################################################
        set d [acs::test::logout -last_request $d]

        ########################################################################################
        aa_section "Visit homepage, last name of user should not show up"
        ########################################################################################
        set d [acs::test::http -last_request $d  /]
        acs::test::reply_contains_no $d [dict get $user_info last_name]

    } -teardown_code {
        acs::test::user::delete -user_id $user_id
    }
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        aa::coverage::proc_coverage
        aa_equals
        aa_true

        aa_register_case
        aa_runseries
    } \
    aa__coverage_proc_coverage {

        Simple test for the aa::coverage::proc_coverage proc.

        @author Héctor Romojaro <hector.romojaro@gmail.com>
        @creation-date 2019-09-03
} {
    set cases [list]

    set result    [aa::coverage::proc_coverage]
    lappend cases [list cmd {aa::coverage::proc_coverage} result "$result"]
    set result    [aa::coverage::proc_coverage -package_key "acs-tcl"]
    lappend cases [list cmd {aa::coverage::proc_coverage -package_key "acs-tcl"} result "$result"]
    set result    [aa::coverage::proc_coverage -package_key "acs-kernel"]
    lappend cases [list cmd {aa::coverage::proc_coverage -package_key "acs-kernel"} result "$result"]
    set result    [aa::coverage::proc_coverage -package_key "acs-automated-testing"]
    lappend cases [list cmd {aa::coverage::proc_coverage -package_key "acs-automated-testing"} result "$result"]

    foreach testcase $cases {
        dict with testcase {
            aa_equals "$cmd dict size" "[dict size $result]" "3"
            aa_true "$cmd procs type" {
                [string is integer [dict get $result procs]] &&
                [dict get $result procs] >= 0
            }
            aa_true "$cmd covered type" {
                [string is integer [dict get $result covered]] &&
                [dict get $result covered] >= 0
            }
            aa_true "$cmd covered <= procs" {
                [dict get $result covered] <= [dict get $result procs]
            }
            aa_true "$cmd coverage type" {
                [dict get $result coverage] >= 0 &&
                [dict get $result coverage] <= 100
            }
        }
    }
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        aa::coverage::proc_covered_p
        aa::coverage::proc_list
        aa_equals
        aa_true

        aa_register_case
        aa_runseries
    } \
    aa__coverage_proc_proc_list_covered {

        Simple test for the aa::coverage::proc_list and aa::coverage::proc_covered_p procs.

        @author Héctor Romojaro <hector.romojaro@gmail.com>
        @creation-date 2019-09-03
} {
    set total_proc_list [aa::coverage::proc_list]

    foreach proc_info $total_proc_list {
        dict with proc_info {
            aa_equals "global: dict size" "[dict size $proc_info]" "3"
            aa_true "global: package_key not empty" {[dict get $proc_info package_key] ne ""}
            aa_true "global: proc_name not empty" {[dict get $proc_info proc_name] ne ""}
            aa_true "global proc $proc_name: covered_p is boolean" {[string is boolean [dict get $proc_info covered_p]]}
            aa_true "global proc $proc_name: covered_p and aa::coverage::proc_covered_p are coherent" {
                bool([dict get $proc_info covered_p]) ==
                bool([aa::coverage::proc_covered_p [dict get $proc_info proc_name]])
            }
        }
    }

    set package_list {acs-tcl acs-kernel acs-automated-testing}
    foreach package $package_list {
        set package_proc_list [aa::coverage::proc_list -package_key $package]
        foreach proc_info $package_proc_list {
            dict with proc_info {
                aa_equals "package $package: dict size" [dict size $proc_info] "2"
                aa_true "package $package: proc_name not empty" {[dict get $proc_info proc_name] ne ""}
                aa_true "package $package proc $proc_name: covered_p is boolean" {[string is boolean [dict get $proc_info covered_p]]}
                aa_true "package $package proc $proc_name: covered_p and aa::coverage::proc_covered_p are coherent" {
                    bool([dict get $proc_info covered_p]) ==
                    bool([aa::coverage::proc_covered_p [dict get $proc_info proc_name]])
                }
            }
        }
    }
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        aa::coverage::proc_coverage_level
        aa_equals

        aa_runseries
        aa_register_case
    } \
    aa__coverage_proc_coverage_level {

        Simple test for the aa::coverage::proc_coverage_level proc.

        @author Héctor Romojaro <hector.romojaro@gmail.com>
        @creation-date 2019-09-03
} {
    set values {0 very_low 1 very_low 24.999 very_low 25 low 49 low 50.00 medium 74.9 medium 75 high 99 high 100 full}
    dict for {value result} $values {
        aa_equals "aa::coverage::proc_coverage_level $value" "[aa::coverage::proc_coverage_level $value]" "$result"
    }
}


aa_register_case \
    -cats {api smoke} \
    -procs {
        ad_page_contract_filter_proc_aa_test_category
        ad_page_contract_filter_proc_aa_test_view_by

        ad_complain
        ad_page_contract_filter_proc
        ad_page_contract_set_validation_passed
    } aa_page_contract_filters {
        Test page_contract_filters of acs-automated testing
    } {
        dict set cases aa_test_category { stress 1 all 0 security_risk 1 }
        dict set cases aa_test_view_by {testcase 1 package 1 stress 0 " " 0}

        foreach filter [dict keys $cases] {
            foreach { value result } [dict get $cases $filter] {
                if { $result } {
                    aa_true "'[ns_quotehtml $value]' is $filter" \
                        [ad_page_contract_filter_invoke $filter dummy value]
                } else {
                    aa_false "'[ns_quotehtml $value]' is NOT $filter" \
                        [ad_page_contract_filter_invoke $filter dummy value]
                }
            }
        }
    }

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        acs::test::get_form
        acs::test::xpath::get_form
        acs::test::form_get_fields
        acs::test::form_is_empty
        acs::test::xpath::get_text
        acs::test::xpath::equals
        acs::test::xpath::non_empty
        acs::test::dom_html
    } \
    markup_parsing {
        Test the markup parsing api
    } {
        aa_section "Markup with form"

        set form {
            <div><span></span><form> <input name="a" type="number" value="1">
            <input name="a" type="number" value="1">
            <br/>
            <input name="b" type="button" value="Clicked">
            <span>Test stuff</span>
            <input name="c" type="date" value="2022-09-09">
            <input name="d" type="radio" value="a">
            <input name="d" type="radio" value="b">
            <input name="d" type="radio" value="c">
            <input name="e" type="radio" value="a" checked>
            <input name="e" type="radio" value="b">
            <input name="e" type="radio" value="c">
            <input type="color" name="f" value="#ff0000">
            <select name="g"><option value="1">1</option>
            <option value="2">2</option>
            <option value="3">3</option>
            </select>
            <select name="h"><option value="1">1</option>
            <option value="2" selected>2</option>
            <option value="3">3</option>
            </select></div>
        }

        set form [acs::test::get_form $form //form]

        set fields [acs::test::form_get_fields $form]

        aa_false "Form is not empty" \
            [acs::test::form_is_empty $form]

        foreach {k v} {
            a 1
            b Clicked
            c 2022-09-09
            e "a"
            f "#ff0000"
            h 2
        } {
            aa_equals "'$k' has value '$v' in the form" \
                [dict get $fields $k] $v
        }

        foreach empty {d g} {
            aa_false "Field '$empty' had no value and is not in the fields" \
                [dict exists $fields $empty]
        }

        aa_section "Markup with no form"
        set form {
            <html>
            <div><span>1</span></div>
            <br/>
            <span>Test stuff</span>
            </html>
        }

        aa_true "Form is empty" \
            [acs::test::form_is_empty [acs::test::get_form $form //form]]

        acs::test::dom_html root $form {
            aa_equals "We get the text from the second span" \
                [acs::test::xpath::get_text $root "/html/span"] "Test stuff"
            acs::test::xpath::equals $root {"/html/span" "Test stuff"}
            acs::test::xpath::non_empty $root "/html/span"
        }
    }

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        acs::test::visualize_control_chars
    } \
    visualize_control_chars {
        Test the acs::test::visualize_control_chars api
    } {
        foreach {i o} {
            "ciao  \n miao \\ bau\r" "ciao  \\n\n miao \\\\ bau\\r"
            "I am  normal" "I am  normal"
        } {
            aa_equals "'$i' becomes '$o'" \
                [acs::test::visualize_control_chars $i] $o
        }
    }
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
