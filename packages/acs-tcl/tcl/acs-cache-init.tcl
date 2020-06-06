#
# The acs::misc_cache is a potential successor of the util_memoize_cache, 
# but in a partitioned fashion to make it scalable. It should only be
# used for situation, where not wild-card flushes are required.
#
set cacheType [expr {[::acs::icanuse "ns_hash"] ? "HashKeyPartitionedCache" : "Cache"}]
::acs::$cacheType create ::acs::misc_cache \
    -package_key acs-tcl \
    -parameter MiscCache \
    -default_size 100000
