# Procs to support testing OpenACS with Tclwebtest.
#
# This is the master file - the only file that needs to be sourced.
# It sets up global vars and sources all procs.
#
# @author Peter Marklund

namespace eval twt {}

source global-vars.tcl
source util-procs.tcl
source admin-procs.tcl
source dotlrn-procs.tcl
source class-procs.tcl
source forums-procs.tcl
