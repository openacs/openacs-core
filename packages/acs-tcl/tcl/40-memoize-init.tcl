ad_library {

    Initializes data structures for util_memoize.

    @creation-date 2000-10-19
    @author Bryan Quinn
    @author Rob Mayoff <mayoff@arsdigita.com>
    @cvs-id $Id$
}

if {[llength [info commands ns_cache]] > 0} {

    # Create the cache used by util_memoize.

    # Note: we must pass the package_id to ad_parameter, because
    # otherwise ad_parameter will end up calling util_memoize to figure
    # out the package_id.

    ns_cache create util_memoize -size \
	[ad_parameter -package_id [ad_acs_kernel_id] MaxSize memoize 200000]

} else {

    # Pre-declare the cache arrays used in util_memoize.
    nsv_set util_memoize_cache_value . ""
    nsv_set util_memoize_cache_timestamp . ""

}
