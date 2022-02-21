#
# Note: this file is not only called as regular init procs, but as
# well out-of-band during bootstrapping a new installation.
#
# Create the cache used by util_memoize.
#
ns_cache create util_memoize -size \
    [parameter::get -package_id $::acs::kernel_id -parameter MaxSize -default 200000]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
