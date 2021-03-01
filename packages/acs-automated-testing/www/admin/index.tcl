ad_page_contract {
    @cvs-id $Id$
} {
    {quiet:boolean 0}
    {by_package_key ""}
    {by_category:aa_test_category ""}
    {view_by:aa_test_view_by "package"}
    {stress:boolean 0}
    {security_risk:boolean 0}
    {populator:boolean 0}
} -properties {
    context_bar:onevalue
    server_name:onevalue
    tests:multirow
    packages:multirow
    categories:multirow
    by_package_key:onevalue
    by_category:onevalue
    view_by:onevalue
    quiet:onevalue
    global_test_coverage_color
}
set doc(title) "System test cases"
set context ""

set return_url [ad_return_url]
set coverage_url [export_vars -base proc-coverage {{package_key $by_package_key}}]

template::head::add_css -href /resources/acs-automated-testing/tests.css

if {$by_package_key ne ""} {
    append  doc(title)  " for package $by_package_key"
    set context "Package $by_package_key"
}
if {$by_category ne ""} {
    append  doc(title)  ", category $by_category"
    set context "Category $by_category"
} else {
    append  doc(title)  ", all categories"
}

# Include all enabled packages in the package view list
foreach enabled_package [apm_enabled_packages] {
    set packages($enabled_package) [list 0 0 0 0]
}

# Check for testcases
foreach testcase [nsv_get aa_test cases] {
    lassign $testcase testcase_id testcase_desc . package_key categories

    set results($testcase_id,$package_key) [list $testcase_desc $package_key $categories]
}

db_foreach acs-automated-testing.results_queryx {
    select
       fr.testcase_id,
       fr.package_key,
       to_char(fr.timestamp,'YYYY-MM-DD_HH24:MI:SS') as timestamp,
       fr.passes,
       fr.fails,
       sum(case when r.result = 'warn' then 1 else 0 end) as warnings
    from aa_test_final_results fr,
         aa_test_results r
     where fr.testcase_id = r.testcase_id
     group by 1, 2, 3, 4, 5
} {
    if {[info exists results($testcase_id,$package_key)]} {
        # Append results to individual testcase
        lappend results($testcase_id,$package_key) $timestamp $passes $fails $warnings

        #
        # If viewing by package, update the by-package results, taking into
        # account whether a specific category has been specified.
        #
        if {$view_by eq "package"} {
            lassign $packages($package_key) package_total package_pass package_fail package_warnings
            if {$by_category ne ""} {
                # Category specific, only add results if this testcase is of the
                # specified category.
                set categories  [lindex $results($testcase_id,$package_key) 2]
                if {$by_category in $categories} {
                    incr package_total
                    incr package_pass     $passes
                    incr package_fail     $fails
                    incr package_warnings $warnings
                    set packages($package_key) \
                        [list $package_total $package_pass $package_fail $package_warnings]
                }
            } else {
                # No category specified, add results.
                incr package_total
                incr package_pass     $passes
                incr package_fail     $fails
                incr package_warnings $warnings
                set packages($package_key) \
                    [list $package_total $package_pass $package_fail $package_warnings]
            }
        }
    }
}

if {$view_by eq "package"} {
    #
    # Calculate package proc test coverage
    #
    set global_test_coverage            [aa::coverage::proc_coverage]
    set global_test_coverage_percent    [dict get $global_test_coverage coverage]
    set global_test_coverage_level      [aa::coverage::proc_coverage_level $global_test_coverage_percent]
    array set global_test_coverage_color [aa::percentage_to_color $global_test_coverage_percent]

    #
    # Prepare the template data for a view_by "package"
    #
    template::multirow create packageinfo key total passes fails warnings proc_coverage \
        proc_coverage_level background foreground
    foreach package_key [lsort [array names packages]] {
        lassign $packages($package_key) total passes fails warnings
        set proc_coverage [dict get [aa::coverage::proc_coverage -package_key $package_key] coverage]
        set proc_coverage_level [aa::coverage::proc_coverage_level $proc_coverage]
        set color [aa::percentage_to_color $proc_coverage]
        #ns_log notice "view_by $view_by package_key=$package_key $proc_coverage_level $proc_coverage_color"

        template::multirow append packageinfo $package_key $total \
            $passes $fails $warnings \
            $proc_coverage $proc_coverage_level \
            [dict get $color background] [dict get $color foreground]
    }
} else {
    #
    # Prepare the template data for a view_by "testcase"
    #
    template::multirow create tests id url description package_key categories \
        timestamp passes fails warnings marker
    set old_package_key ""
    foreach testcase [lsort [nsv_get aa_test cases]] {
        set testcase_id [lindex $testcase 0]
        set package_key [lindex $testcase 3]

        lassign $results($testcase_id,$package_key) testcase_desc . categories \
            testcase_timestamp testcase_passes testcase_fails testcase_warnings

        regexp {^(.+?\.)\s} $testcase_desc "" testcase_desc
        set categories_str     [join $categories ", "]
        #
        # Only add the testcase to the template multirow if either
        # - The package key is blank or it matches the specified.
        # - The category is blank or it matches the specified.
        #
        if {$by_package_key in [list "" $package_key]
            && $by_category in [list "" $categories]
        } {
            # Swap the highlight flag between packages.
            if {$old_package_key ne $package_key} {
                set marker 1
                set old_package_key $package_key
            } else {
                set marker 0
            }
            set testcase_url [export_vars -base "testcase" -url {
                testcase_id package_key view_by {category by_category} quiet return_url
            }]
            template::multirow append tests \
                $testcase_id \
                $testcase_url \
                $testcase_desc \
                $package_key \
                $categories_str \
                $testcase_timestamp \
                $testcase_passes $testcase_fails $testcase_warnings \
                $marker
        }
    }
}

#
# Create the category multirow
#
template::multirow create main_categories name
template::multirow create exclusion_categories name
foreach category [nsv_get aa_test categories] {
    # joel@aufrecht.org: putting in special cases for exclusionary categories
    if { $category in [nsv_get aa_test exclusion_categories] } {
        template::multirow append main_categories $category
    } else {
        template::multirow append exclusion_categories $category
    }
}

set record_url [export_vars -base "record-test" -url {return_url package_key}]
set bulk_actions_vars [export_vars -form {{category $by_category} view_by quiet stress security_risk}]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
