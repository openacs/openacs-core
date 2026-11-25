# Convert a draft to HTML without reading or storing application content.
if {[ns_conn method] ne "POST"} {
    ns_return 405 text/plain "Use POST."
    ad_script_abort
}
set token [security::csrf::new]
if {$token eq "" || [ns_queryget __csrf_token] ne $token} {
    ns_return 403 text/plain "Invalid conversion token."
    ad_script_abort
}
ad_page_contract {} {
    contents:allhtml
    format:notnull
}
if {$format ni [template::util::richtext::formats]} {
    ns_return 400 text/plain "Unknown text format."
    ad_script_abort
}
ns_set put [ns_conn outputheaders] Cache-Control no-store
ns_return 200 text/plain [ad_html_text_convert -from $format -to text/html -- $contents]
ad_script_abort
