#!/bin/sh
#
# Edit (recreate) the run script to reflect the parameter values in install.tcl
#
# The next line restarts using tclsh. Do not remove this backslash: \
exec tclsh "$0" "$@"

set install_file_path [lindex $argv 0]

source $install_file_path

#----------------------------------------------------------------------
# Create daemontools run file
#----------------------------------------------------------------------

set __run_file_path "${serverroot}/etc/daemontools/run"
set __new_run_file_path "${serverroot}/etc/daemontools/run.new"

set __fd [open $__new_run_file_path w]
puts $__fd "#!/bin/sh"
puts $__fd ""
puts $__fd "exec ${aolserver_home}/bin/nsd-${database} -it ${serverroot}/etc/config.tcl -u ${aolserver_user} -g ${aolserver_group}"
close $__fd

# Rename
file delete "${__run_file_path}.bak"
file rename $__run_file_path "${__run_file_path}.bak"
file rename $__new_run_file_path $__run_file_path
