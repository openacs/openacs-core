
ad_page_contract {
    Check a user's ID
} {
    email:notnull
}

set user_id [cc_lookup_email_user $email]

ad_returnredirect "email-password?user_id=$user_id"

