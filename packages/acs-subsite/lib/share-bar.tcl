
if { ![info exists title] } {
    set title [ad_conn instance_name]
    ns_log Notice "acs-subsite/lib/share-bar: title has no value, substituting with instance_name"
}
if { ![info exists url] } {
    set url [ad_return_url -qualified]
}
if { [security::secure_conn_p] } {
    set icons_p 0
}
if { ![info exists icons_p] } {
    set icons_p 1
}
