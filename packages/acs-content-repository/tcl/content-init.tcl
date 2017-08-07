
nsv_set mutex cr_file_creation [ns_mutex create oacs:cr_file_creation]

#
# Make sure that the file-creation.log exists, without using "exec
# touch", which is not available under windows (see issue #3311).
#
set creation_log_file [cr_fs_path]/file-creation.log
if {![file exists $creation_log_file]} {
    set F [open $creation_log_file w]; close $F
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
