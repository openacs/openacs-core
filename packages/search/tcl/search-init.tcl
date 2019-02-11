namespace eval search {}
namespace eval search::init {}

nsv_set search_static_variables item_counter 0

ad_proc -private search::init::schedule_indexer {} {

    Schedule the indexer if the search package has been instantiated (indexing doesn't work
    if it hasn't been, so why should we schedule it?).

    We use the uncached version of apm_package_id_from_key to avoid forcing the user to
    restart their server after mounting search.

} {
    set package_id [apm_package_id_from_key search]
    if { $package_id != 0 } {
        ad_schedule_proc \
            -thread t [parameter::get \
                          -package_id $package_id \
                          -parameter SearchIndexerInterval \
                          -default 60 ] \
            search::indexer
    }
}

search::init::schedule_indexer

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
