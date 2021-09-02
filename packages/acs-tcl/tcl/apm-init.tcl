
# FIXME: Peter M - This file cannot be watched with the APM as it
# re-initializes the reload level to 0 every time it is sourced. Could
# we move these initialization to an -init.tcl file instead?

# Initialize loader NSV arrays. See apm-procs.tcl for a description of
# these arrays.

nsv_array set apm_library_mtime [list]
nsv_array set apm_version_procs_loaded_p [list]
nsv_array set apm_reload_watch [list]
nsv_array set apm_package_info [list]
nsv_set apm_properties reload_level 0

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
