ad_page_contract {
    Notifications admin page
}

set parameters_url [export_vars -base "/shared/parameters" { { return_url [ad_return_url] } { package_id {[ad_conn package_id]} } }]
