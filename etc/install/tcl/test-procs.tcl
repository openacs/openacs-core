# Procs to support testing OpenACS with Tclwebtest.
#
# This is the master file - the only file that needs to be sourced.
# It sets up global vars and sources all procs.
#
# @author Peter Marklund

namespace eval ::twt {}

set script_dir [file dirname [info script]]

# Source all *-procs.tcl files in this directory
foreach path [glob ${script_dir}/*-procs.tcl] {
    if { ![regexp {test-procs\.tcl$} $path] } {
        source $path
    }
}
