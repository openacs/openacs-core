#
# Create permission caches. The sizes can be tailored in the config
            # file like the following:
#
# ns_section ns/server/${server}/acs/acs-tcl
#   ns_param PermissionCacheSize        100000
#   ns_param PermissionCachePartitions  2
#
::acs::KeyPartitionedCache create ::acs::permission_cache \
    -package_key acs-tcl \
    -parameter PermissionCache \
    -default_size 100000 \
    -partitions 2

