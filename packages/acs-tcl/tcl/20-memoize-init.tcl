# Create the cache used by util_memoize.

# Note: we must pass the package_id to ad_parameter, because
# otherwise ad_parameter will end up calling util_memoize to figure
# out the package_id.

ns_cache create util_memoize -size \
    [ad_parameter -package_id [ad_acs_kernel_id] MaxSize memoize 200000]
