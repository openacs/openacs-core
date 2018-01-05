ad_page_contract {
    A hack that will allow us to simulate being a different user
} {
    user_id:naturalnum,notnull
    return_url:localurl
}

##NOTE THIS DOESN'T REQUIRE ADMIN SO THAT WE CAN DO USER SWITCHING
permission::require_permission -object_id [ad_conn package_id] -privilege "read"

ad_set_client_property developer-support user_id $user_id

ad_returnredirect $return_url
ad_script_abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
