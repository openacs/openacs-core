ad_library {

    Request and confirm changes to account email addresses.

}

namespace eval subsite {}

ad_proc -private subsite::request_email_change {user_id old_email new_email} {
    Store a pending email change and send confirmation to the proposed address.
} {
    set new_email [string tolower [string trim $new_email]]
    if {$new_email eq "" || [string length $new_email] > 100
        || ![util_email_valid_p $new_email]} {
        error "Invalid email address"
    }
    set token [ns_crypto::randombytes -encoding hex 32]
    set digest [ns_crypto::md string -digest sha256 -encoding hex $token]
    set expires [expr {[clock seconds] + 86400}]
    set base "[string trimright [ad_url] /]/user/email-change-confirm"
    set confirmation_url [export_vars -base $base {token}]

    db_transaction {
        set current_email [db_string email_change_lock_party {
            select email from parties where party_id = :user_id for update
        }]
        if {$current_email ne $old_email
            || [party::get_by_email_not_cached -email $new_email] ne ""} {
            error "Account email changed or proposed email is unavailable"
        }
        db_dml email_change_replace_pending {
            delete from subsite_email_changes where user_id = :user_id
        }
        db_dml email_change_insert_pending {
            insert into subsite_email_changes
                (user_id, old_email, new_email, token_digest, expires_at)
            values (:user_id, :old_email, :new_email, :digest, :expires)
        }
        acs_mail_lite::send -to_addr $new_email -from_addr [ad_system_owner] \
            -subject [_ acs-subsite.Email_change_confirm] \
            -body [_ acs-subsite.Email_change_mail_body]
    }
}

ad_proc -private subsite::confirm_email_change {user_id token} {
    Apply a pending email change for this account.
    Return 1 on success and 0 if the request is invalid or no longer applicable.
} {
    if {![regexp {^[0-9a-f]{64}$} $token]} {
        return 0
    }
    set digest [ns_crypto::md string -digest sha256 -encoding hex $token]
    set confirmed 0
    db_transaction {
        # Both request and confirmation lock the same party first.
        set current_email [db_string email_change_confirm_lock_party {
            select email from parties where party_id = :user_id for update
        }]
        set now [clock seconds]
        if {[db_0or1row email_change_find_pending {
            select old_email, new_email from subsite_email_changes
             where user_id = :user_id and token_digest = :digest and expires_at > :now
        }] && $current_email eq $old_email} {
            acs_user::get -user_id $user_id -array user
            if {"email" ni [auth::sync::get_sync_elements -authority_id $user(authority_id)]
                && [party::get_by_email_not_cached -email $new_email] eq ""} {
                array set update [list email $new_email email_verified_p t]
                set result [auth::update_local_account -authority_id $user(authority_id) \
                                -username $user(username) -array update]
                if {[dict get $result update_status] eq "ok"} {
                    if {[dict get $result user_id] != $user_id} {
                        error "Account changed during email confirmation"
                    }
                    db_dml email_change_consume_pending {
                        delete from subsite_email_changes where user_id = :user_id
                    }
                    set confirmed 1
                }
            }
        }
    }
    if {$confirmed} {
        catch {email_image::edit_email_image -user_id $user_id -new_email $new_email}
    }
    return $confirmed
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
