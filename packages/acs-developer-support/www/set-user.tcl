ad_page_contract {
    A hack that will allow us to simulate being a different user
} {
    user_id:integer
    return_url
}

##NOTE THIS DOESN'T REQUIRE ADMIN SO THAT WE CAN DO USER SWITCHING
ad_require_permission [ad_conn package_id] "read"

ad_set_client_property developer-support user_id $user_id

ad_returnredirect $return_url
