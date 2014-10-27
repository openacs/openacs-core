# /pvt/hide-email.tcl

ad_page_contract {
    changes show_email field in user's table
} {
    hide:notnull
    user_id:naturalnum,notnull
}

db_dml update_show_email { }

ad_returnredirect "/pvt/home"