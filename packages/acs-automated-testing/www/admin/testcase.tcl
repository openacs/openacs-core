ad_page_contract {
    @cvs-id $Id$
} {
    testcase_id:word,notnull
    package_key:token
    {showsource:boolean 0}
    {quiet:boolean 1}
    {return_url ""}
} -properties {
    title:onevalue
    context_bar:onevalue
    tests:multirow
    showsource:onevalue
    testcase_desc:onevalue
    testcase_file:onevalue
    testcase_on_error:onevalue
    bodys:multirow
    quiet:onevalue
    fails:onevalue
}
set title "Test case $testcase_id"
set context [list $title]

if {$quiet} {
    set filter { and result = 'fail'}
} else {
    set filter {}
}

db_multirow tests_quiet summary {
    select result, count(*) as count
    from aa_test_results
    where testcase_id = :testcase_id
    and package_key = :package_key
    group by result
}


db_multirow tests acs-automated-testing.testcase_query {}

if {![db_0or1row acs-automated-testing.get_testcase_fails_count {
    select fails
    from aa_test_final_results
    where testcase_id = :testcase_id
}]} {
    set fails -1
}

set testcase_bodys {}
set testcase_bugs ""
set testcase_procs ""        
set testcase_cats ""        
set testcase_inits ""

foreach testcase [nsv_get aa_test cases] {
    if {$testcase_id eq [lindex $testcase 0]
        && $package_key eq [lindex $testcase 3]
    } {
        lassign $testcase . testcase_desc testcase_file . \
            testcase_cats testcase_inits \
            testcase_on_error testcase_bodys testcase_error_level testcase_bugs testcase_procs
        set testcase_cats  [join $testcase_cats ", "]
        set testcase_inits [join $testcase_inits ", "]
        break
    }
}

set bug_list [list]
foreach bug $testcase_bugs {
    set href [export_vars -base "http://openacs.org/bugtracker/openacs/bug" {{bug_number $bug}}]
    lappend bug_list [subst {<a href="[ns_quotehtml $href]">$bug</a>}]
}
set bug_blurb [join $bug_list ", "]

set proc_list [list]
foreach p $testcase_procs {
    set href [export_vars -base "/api-doc/proc-view" { {proc $p} }]
    lappend proc_list [subst {<a href="[ns_quotehtml $href]">$p</a>}]
}
set proc_blurb [join $proc_list ", "]


template::multirow create bodys body_number body
if {[llength $testcase_bodys] == 0} {
    set testcase_desc ""
    set testcase_file ""
} else {
    set body_count 1

    #
    # Work out the URL for this directory (stripping off the file element).
    #
    set url [ad_conn url]
    regexp {(.*)/[^/]*} $url {\\1} url
    append url "/component?package_key=${package_key}"

    foreach body $testcase_bodys {
        #
        # This regsub changes any "aa_call_component <component_id>" so that the
        # <component_id> element is a link.
        #
        regsub -all {aa_call_component\s+(["]?)([^\s]*)(["]?)} $body \
            "aa_call_component <a href='$url\\&component_id=\\2'>\\1\\2\\3</a>" body
        template::multirow append bodys \
            $body_count \
            [::apidoc::tclcode_to_html -scope "" -proc_namespace "" $body]
        incr body_count
    }
}

set resource_file_url [export_vars -base init-file-resource {
    {return_url [ad_return_url]}
    {absolute_file_path $testcase_file}
}]

set rerun_url [export_vars -base rerun {
    testcase_id package_key quiet {return_url [ad_return_url]}
}]

if {$return_url eq ""} {
    set return_url [export_vars -base . {
        { view_by testcase } quiet { by_package_key $package_key }
    }]
}

set quiet_url "[export_vars -base testcase -entire_form -exclude {quiet}]&quiet=1"
set verbose_url "[export_vars -base testcase -entire_form -exclude {quiet}]&quiet=0"
template::head::add_style \
    -style {
        .description h2 { 1.5em; }
        .fail {
            font-weight: bold;
            color: red;
        }
        .ok {
            font-weight: bold;
            color: green;
        }
        .warn {
            color: darkmagenta;
        }

        td.log {
            font-size: normal;
            color: darkslateblue;
        }

        dt {
            font-weight: bold
        }
        th {
            background: #c0c0c0;
        }
        td pre {
            margin: 2px;
            font-size: smaller;
        }
    }

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
