namespace eval search {}
namespace eval search::install {}

ad_proc search::install::after_instantiate {
    -package_id:required
} {
    Package after instantiation callback proc.

    Schedule the indexer so the admin doesn't have to restart their server to get search
    up and running after mounting it.
} {
    search::init::schedule_indexer
}
