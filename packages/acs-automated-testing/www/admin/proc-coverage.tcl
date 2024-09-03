ad_page_contract {
    Displays proc test coverage in the given package, or system wide

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 2019-08-29
} {
    {package_key ""}
    orderby:token,optional
}

# CSS
template::head::add_css -href /resources/acs-automated-testing/tests.css

# Choose between global and package-wise proc test coverage
if { $package_key eq "" } {
    #
    # System wide proc test coverage
    #
    set title "Global Test coverage"
    set context       [list $title]
    set proc_list     [aa::coverage::proc_list]
    set test_coverage [aa::coverage::proc_coverage]
    set list_elements {
        package_key {
            label "Package"
        }
    }
    set orderby_elements {
        default_value package_key,asc
        package_key {
            multirow_cols package_key
        }
    }
} else {
    #
    # Proc test coverage for a particular package
    #
    set title "Test coverage of $package_key"
    set context [list \
                     [list "./index?by_package_key=$package_key&view_by=testcase" "Package $package_key"] \
                     "Test coverage"]
    set proc_list     [aa::coverage::proc_list -package_key $package_key]
    set test_coverage [aa::coverage::proc_coverage -package_key $package_key]
    set list_elements [list]
    set orderby_elements {
        default_value proc_name,asc
    }
}

# Set context and coverage vars
set test_coverage_percent   [dict get $test_coverage coverage]
set test_coverage_procs_nr  [dict get $test_coverage procs]
set test_coverage_procs_cv  [dict get $test_coverage covered]
set test_coverage_level     [aa::coverage::proc_coverage_level $test_coverage_percent]

# Add the rest of elements
lappend list_elements {*}{
    proc_name {
        label "Proc name"
        display_template {[api_proc_pretty_name -link @procs_mr.proc_name@]}
    }
    covered_p {
        label "Covered"
        display_template {
            <if @procs_mr.covered_p@ true>
                <div class=covered>Yes</div>
            </if>
            <else>
                <div class=uncovered>No</div>
            </else>
        }
    }
}

# Add the rest of orderby elements
lappend orderby_elements {*}{
    proc_name {
        multirow_cols proc_name
    }
    covered_p {
        multirow_cols covered_p
    }
}

# Create the multirow and the template::list
template::util::list_to_multirow procs_mr $proc_list
template::list::create \
    -name procs \
    -multirow procs_mr \
    -filters {package_key {}} \
    -elements $list_elements \
    -orderby $orderby_elements

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
