# /www/register/email-confirm.tcl

ad_page_contract {
    @cvs-id $Id$

} {
    row_id:notnull,trim
} -properties {
    site_link:onevalue
    system_name:onevalue
    export_vars:onevalue
    user_id:onevalue
    email:onevalue
    email_verified_p:onevalue
    member_state:onevalue
}

# remove whitespace from rowid
# regsub -all "\[ \t\n]+" $rowid {} rowid

# we take authorized here in case the
# person responds more than once

set sql "select member_state, email, user_id, email_verified_p
         from cc_users
         where rowid = :row_id"

# we want to catch DB errors related to illegal rowids.
# but, we also have to make sure to get the rturn value from db_0or1row too.
set status [catch {set rowid_check [db_0or1row register_email_user_info_get $sql]}]

if { $status != 0 || $rowid_check == 0} {
    db_release_unused_handles
    ad_return_error "Couldn't find your record" "Row id $row_id is not in the database.  Please check your email and verifiy that you have cut and pasted the url correctly."
    return
}
    
set site_link [ad_site_home_link]
set system_name [ad_system_name]
set export_vars [export_form_vars email]

if {$email_verified_p == "f" && $member_state == "approved"} {
    db_dml register_email_user_update "update users 
                        set email_verified_p = 't'
                        where user_id = :user_id" 

} elseif { $member_state == "" && $email_verified_p == "f" } {
    #state is need_email_verification_and_admin_approv
    db_dml register_email_confirm_update3 "update users
                        set email_verified_p = 't'
                        where user_id = :user_id" 
    
}

set email_verified_p "f"
set member_state "approved"

ad_return_template
