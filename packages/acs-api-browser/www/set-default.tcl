ad_page_contract {
    Set user preferences for API browsing.
} {
    source_p:integer,optional,notnull
    return_url
}

set found_p 0

if { [info exists source_p] } {
    ad_set_client_property -persistent t acs-api-browser api_doc_source_p $source_p
    set found_p 1
}

if { $found_p } {
    ad_returnredirect $return_url
} else {
    ad_return_error "Unknown Property" "Couldn't find any property to set"
}