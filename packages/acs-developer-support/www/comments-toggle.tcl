ad_page_contract {
    Toggle comments on/off
} {
    return_url
}

if { [parameter::get -package_id [ds_instance_id] -parameter ShowCommentsInlineP -default 0] } {
    parameter::set_value -package_id [ds_instance_id] -parameter ShowCommentsInlineP -value 0
} else {
    parameter::set_value -package_id [ds_instance_id] -parameter ShowCommentsInlineP -value 1
}

ad_returnredirect $return_url
