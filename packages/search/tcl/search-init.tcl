namespace eval search {}
namespace eval search::init {}

nsv_set search_static_variables item_counter 0

ad_proc -private search::init::schedule_indexer {} {

    Schedule the indexer if the search package has been instantiated (indexing doesn't work
    if it hasn't been, so why should we schedule it?).

    We do not use the cached api apm_package_id_from_key to avoid
    forcing the user to restart their server after mounting search.
} {
    set package_id [db_string get_package {
        select package_id from apm_packages
        where package_key = 'search'
    } -default 0]
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
