
if { ![info exists title] } {
    set title [ad_conn instance_name]
    ns_log Notice "acs-subsite/lib/share-bar: title has no value, substituting with instance_name"
}
if { ![info exists url] } {
    set url [ad_return_url -qualified]
}
