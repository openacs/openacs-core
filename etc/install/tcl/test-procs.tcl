# Procs to support testing OpenACS with Tclwebtest.
#
# This is the master file - the only file that needs to be sourced.
# It sets up global vars and sources all procs.
#
# @author Peter Marklund

namespace eval ::twt {}

set script_dir [file dirname [info script]]

source $script_dir/config-procs.tcl
source $script_dir/twt-procs.tcl
source $script_dir/user-procs.tcl
source $script_dir/admin-procs.tcl
source $script_dir/acs-lang-procs.tcl
source $script_dir/dotlrn-procs.tcl
source $script_dir/class-procs.tcl
source $script_dir/forums-procs.tcl
source $script_dir/news-procs.tcl
