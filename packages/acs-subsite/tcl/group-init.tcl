
#
# Create group cache. The sizes can be tailored in the config
# file like the following:
#
# ns_section ns/server/${server}/acs/acs-subsite
#   ns_param GroupCache        2000000
#
::acs::KeyPartitionedCache create ::acs::group_cache \
    -package_key acs-subsite \
    -parameter GroupCache \
    -default_size 2000000

