ad_library {
    Tests for signed acs-mail-lite bounce addresses.
}

aa_register_case -cats {api db} -procs {
    acs_mail_lite::unique_id_create
    acs_mail_lite::unique_id_parse
    acs_mail_lite::bounce_address
    acs_mail_lite::bounce_address_valid_p
} acs_mail_lite_bounce_address_roundtrip {
    Validate generated bounce addresses without requiring their context metadata.
} {
    aa_run_with_teardown -rollback -test_code {
        aa_stub acs_mail_lite::bounce_prefix {return bounce-lite}
        aa_stub acs_mail_lite::address_domain {return example.org}
        foreach max_age {0 3600} {
            aa_stub parameter::get [string map [list @AGE@ $max_age] {
                if {$parameter eq "IncomingMaxAge"} {return @AGE@}
                if {$parameter eq "FixedSenderEmail"} {return ""}
                return [parameter::get_unstubbed -package_id $package_id \
                            -parameter $parameter -default $default]
            }]
            set marker "bounce-roundtrip-$max_age"
            set id [acs_mail_lite::unique_id_create -other $marker]
            set address [acs_mail_lite::bounce_address -user_id 0 \
                             -package_id [apm_package_id_from_key acs-mail-lite] \
                             -message_id $id]
            foreach variant [list $address [string trim $address <>] \
                                 [string tolower $address] \
                                 [string map {example.org EXAMPLE.ORG} $address]] {
                aa_true "Generated address validates (age $max_age)" \
                    [acs_mail_lite::bounce_address_valid_p $variant]
                aa_equals "Metadata round trip (age $max_age)" \
                    [dict get [acs_mail_lite::unique_id_parse -message_id $variant] other] $marker
            }
            foreach invalid [list \
                                 [string map {example.org wrong.example} $address] \
                                 [string map {bounce-lite forged-lite} $address] \
                                 [string map {bounce-lite bounce-liteX} $address] \
                                 "$address\r\n" \
                                 "<$address>" \
                                 bounce-lite.123.1@example.org \
                                 <> ""] {
                aa_false "Malformed, unsigned or tampered address rejected" \
                    [acs_mail_lite::bounce_address_valid_p $invalid]
                aa_equals "Invalid address has no metadata" \
                    [dict get [acs_mail_lite::unique_id_parse -message_id $invalid] other] ""
            }
        }
        set uid bounce-lite-expired
        set signature [join [ad_sign -max_age -1 $uid] +]
        aa_false "Expired signature rejected" \
            [acs_mail_lite::bounce_address_valid_p "$uid-$signature@example.org"]
        set uid bounce-lite-unmapped
        set signature [join [ad_sign $uid] -]
        aa_true "Signature validation does not require message metadata" \
            [acs_mail_lite::bounce_address_valid_p "$uid-$signature@example.org"]
        aa_equals "Unmapped valid signature returns empty metadata" \
            [dict get [acs_mail_lite::unique_id_parse \
                           -message_id "$uid-$signature@example.org"] other] ""
        lassign [ad_sign -max_age 3600 $uid] token expiry hash
        set altered_hash [string replace $hash 0 0 [expr {[string index $hash 0] eq "0" ? "1" : "0"}]]
        foreach invalid [list \
                             "$uid-$token+$expiry+$altered_hash@example.org" \
                             "$uid-$token+[expr {$expiry + 1}]+$hash@example.org" \
                             "$uid-$token+$expiry-$hash@example.org"] {
            aa_false "Tampered signature or mixed separators rejected" \
                [acs_mail_lite::bounce_address_valid_p $invalid]
        }
        aa_stub sec_get_token {error "Invalid token ID"}
        aa_false "Unknown signature token rejected" \
            [acs_mail_lite::bounce_address_valid_p "$uid-$signature@example.org"]
        aa_stub sec_get_token {error "token-store-unavailable"}
        try {
            acs_mail_lite::bounce_address_valid_p "$uid-$signature@example.org"
            aa_true "Token-store errors must propagate" 0
        } on error {message options} {
            aa_equals "Token-store error preserved" $message token-store-unavailable
        } finally {
            aa_unstub sec_get_token
        }
    }
}
