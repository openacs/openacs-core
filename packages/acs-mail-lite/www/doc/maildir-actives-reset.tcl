ad_page_contract {
    Provies a framework for manually testing acs_mail_lite procs
    A dummy mailbox value provided to show example of what is expected.
} {
    {mail_dir ""}
}
set user_id [ad_conn user_id]
set package_id [ad_conn package_id]
set admin_p [permission::permission_p \
                 -party_id $user_id \
                 -object_id $package_id \
                 -privilege admin ]
if { !$admin_p } {
    set content "Requires admin permission"
    ad_script_abort
}

set content "www/doc/maildir-actives-reset"
#nsv_set acs_mail_lite sj_actives_list /lrange /nsv_get acs_mail_lite sj_actives_list/ end end/
nsv_set acs_mail_lite sj_actives_list [list]
append content ".. done."

