ad_page_contract {
    Set user preferences for API browsing.
} {
    source_p:boolean,notnull
    return_url:localurl
}

ad_set_client_property -persistent t acs-api-browser api_doc_source_p $source_p

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
