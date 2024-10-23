#
# Create permission caches. The sizes can be tailored in the config
# file like the following:
#
# ns_section ns/server/${server}/acs/acs-tcl
#   ns_param PermissionCacheSize        100KB
#   ns_param PermissionCachePartitions  2
#
::acs::KeyPartitionedCache create ::acs::permission_cache \
    -package_key acs-tcl \
    -parameter PermissionCache \
    -default_size 100KB \
    -partitions 2 {
        #
        # Permission cache. This partitioned cache manages partition caching.
        # In case of bottlenecks, increase the number of partitions and the cache size.
        #
    }


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
