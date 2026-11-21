ad_library {

    Account-bound, expiring action tokens.

    Client properties hold state within a session. Action tokens authorize
    a specific operation across sessions and are consumed transactionally.

}

namespace eval auth::token {}

ad_proc -public auth::token::issue {
    {-purpose:required}
    {-user_id:required}
    {-ttl:required}
    {-context ""}
} {
    Issue a token, replacing the outstanding token for this account and purpose.
    Deliver the returned token only through the channel authorized by the caller.
    Use an application-defined purpose and keep context free of credentials.

    @param ttl Lifetime in seconds.
    @param context Optional state for the redemption callback (up to 4000 bytes).
    @return The raw token, which is stored only as a digest.
    @see ad_set_client_property
    @see ad_get_client_property
} {
    if {![regexp {^[a-z][a-z0-9_]{0,63}$} $purpose]} {
        error "Invalid action token purpose"
    }
    if {![string is integer -strict $ttl] || $ttl <= 0} {
        error "Action token lifetime must be a positive integer"
    }
    if {[string bytelength $context] > 4000} {
        error "Action token context exceeds 4000 bytes"
    }

    set token [ns_crypto::randombytes -encoding hex 32]
    set digest [ns_crypto::md string -digest sha256 -encoding hex $token]
    db_transaction {
        if {![auth::token::lock_account $user_id]} {
            error "Cannot issue an action token for a missing account"
        }
        set expires_at [expr {[clock seconds] + $ttl}]
        db_dml replace_token {
            delete from auth_action_tokens where user_id = :user_id and purpose = :purpose
        }
        db_dml insert_token {
            insert into auth_action_tokens (user_id, purpose, token_digest, expires_at, token_context)
            values (:user_id, :purpose, :digest, :expires_at, :context)
        }
    }
    return $token
}

ad_proc -public auth::token::redeem {
    {-purpose:required}
    {-token:required}
    {-callback:required}
} {
    Redeem a token for the expected purpose.

    The callback is a trusted command prefix. It receives the user ID and stored
    context as its final arguments and runs in the token transaction. It must
    enforce the operation's authorization rules. A normal return consumes the
    token. An error rolls back the operation and leaves the token available to
    retry until expiry. External side effects belong after commit.

    @return A dictionary with status invalid, or status redeemed and the callback result.
} {
    if {![llength $callback]} {
        error "Action token redemption requires a callback"
    }
    set invalid {status invalid}
    if {![regexp {^[0-9a-f]{64}$} $token]} {
        return $invalid
    }
    set digest [ns_crypto::md string -digest sha256 -encoding hex $token]
    set user_id [db_string find_token_account {
        select user_id from auth_action_tokens where token_digest = :digest and purpose = :purpose
    } -default ""]
    if {$user_id eq ""} {
        return $invalid
    }

    set result $invalid
    db_transaction {
        if {[auth::token::lock_account $user_id]} {
            set now [clock seconds]
            if {[db_0or1row find_redeemable_token {
                select token_context from auth_action_tokens
                 where user_id = :user_id and purpose = :purpose
                   and token_digest = :digest and expires_at > :now
            }]} {
                set value [{*}$callback $user_id $token_context]
                db_dml consume_token {
                    delete from auth_action_tokens
                     where user_id = :user_id and purpose = :purpose and token_digest = :digest
                }
                set result [dict create status redeemed result $value]
            }
        }
    }
    return $result
}

ad_proc -public auth::token::revoke {
    {-purpose:required}
    {-user_id:required}
} {
    Revoke the outstanding token for this account and purpose. When called as
    part of an account update, take the token account lock before making the
    update and keep both operations in the same transaction.
} {
    db_transaction {
        if {[auth::token::lock_account $user_id]} {
            db_dml revoke_token {
                delete from auth_action_tokens where user_id = :user_id and purpose = :purpose
            }
        }
    }
}

ad_proc -private auth::token::lock_account {user_id} {
    Serialize token operations on the same account. Call inside a transaction.
} {
    return [db_0or1row lock_account {
        select 1 as account_exists from users where user_id = :user_id for update
    }]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
