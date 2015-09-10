ad_page_contract {
    Displays procs not covered by test cases in the given package

    @author Peter Marklund
} {
    package_key
}

set all_proc_names [list]
foreach file_path [nsv_array names api_proc_doc_scripts] {
    if { [regexp "^packages/$package_key" $file_path] } {
	foreach proc_name [nsv_get api_proc_doc_scripts $file_path] {
	    lappend all_proc_names $proc_name
	}
    }
}

set tested_proc_names [list]
foreach testcase [nsv_get aa_test cases] {
    set testcase_package_key [lindex $testcase 3]

    if {$testcase_package_key eq $package_key} {
	set tested_procs [lindex $testcase 10]
	if { [llength $tested_procs] > 0 } {
	    set tested_proc_names [concat $tested_proc_names $tested_procs] 
	}
    }
}

set uncovered_procs [list]
foreach proc_name $all_proc_names {
    if {$proc_name ni $tested_proc_names} {
	lappend uncovered_procs $proc_name
    }
}

set uncovered_procs [join $uncovered_procs "<br>"]
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
