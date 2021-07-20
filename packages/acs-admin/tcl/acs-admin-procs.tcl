ad_library {

    Automated functions for acs-admin

    @author Gustaf Neumann
    @creation-date 2018-08-15
}

namespace eval acs_admin {

    ad_proc -private ::acs_admin::check_expired_certificates {
        {-api production}
    } {
        Check expire-dates of certificates and send warning emails to
        the admin. In case HTTPS is not configured via the "nsssl"
        driver, or the command line tool "openssl" is not installed,
        the proc does nothing.

        @param api possible values: "production" or "staging".
            In case the certificate is expired, use this type of
            letsencrypt environment to obtain a fresh certificate

        @return boolean telling whether expired certificates existed
        (true) or not (false)
    } {
        set openssl [util::which openssl]
        if {[namespace which ns_driver] ne "" && $openssl ne ""} {
            #
            # Get certificates to check expire dates
            #
            set critCertInfo {}
            foreach entry [ns_driver info] {
                set module [dict get $entry module]
                if {[dict get $entry type] eq "nsssl"} {
                    set server [dict get $entry server]
                    if {$server ne ""} {
                        set certfile [ns_config ns/server/$server/module/$module certificate]
                    } else {
                        set certfile [ns_config ns/module/$module certificate]
                    }
                    if {![info exists processed($certfile)]} {
                        #
                        # Check expiration of the certificate using the
                        # "openssl" command line tool.
                        #
                        set notAfter [exec openssl x509 -enddate -noout -in $certfile]
                        regexp {notAfter=(.*)$} $notAfter . date
                        set days [expr {([clock scan $date] - [clock seconds])/(60*60*24.0)}]
                        set info "Certificate $certfile will expire in [format %.1f $days] days"
                        ns_log notice "ssl: $info"
                        set warnInDays [parameter::get_from_package_key \
                                            -package_key "acs-admin" \
                                            -parameter ExpireCertificateWarningPeriod \
                                            -default 30]
                        if {$warnInDays > -1 && $days < $warnInDays} {
                            lappend critCertInfo $info
                        }
                        set processed($certfile) 1
                    }
                }
            }

            if {[llength $critCertInfo] > 0} {
                set to_addr [parameter::get_from_package_key \
                                 -package_key "acs-admin" \
                                 -parameter ExpireCertificateEmail \
                                 -default ""]
                if {$to_addr eq ""} {
                    set to_addr [ad_host_administrator]
                }
                if {$to_addr ne ""} {
                    set report ""
                    if {[info commands ::letsencrypt::Client] ne ""} {

                        #
                        # Make sure, UseCanonicalLocation is NOT set,
                        # since otherwise the requests from
                        # letsencrypt will be redirected. One could
                        # think about other solution, such ignoring
                        # mapping to the canonical location for
                        # letsencryp URLs.
                        #
                        set param_exists [db_0or1row check_params {
                            select 1 from apm_parameters
                            where package_key = 'acs-kernel'
                            and parameter_name = 'UseCanonicalLocation'
                        }]
                        if {!$param_exists} {
                            catch {apm_parameter_register UseCanonicalLocation "Use Canonical Location" acs-kernel 0 number }
                        }
                        ad_parameter_cache -delete $::acs::kernel_id UseCanonicalLocation
                        set oldValue [parameter::get \
                                          -package_id $::acs::kernel_id \
                                          -parameter UseCanonicalLocation \
                                          -default 0]
                        parameter::set_value \
                            -package_id $::acs::kernel_id \
                            -parameter UseCanonicalLocation \
                            -value 0

                        #
                        # Now we are all set to create and start the ACME client
                        #
                        #set api staging ;# can be activated for testing purposes
                        set report "Report of automated certificate renewal:\n[string repeat = 72]\n"

                        try {
                            #
                            # We do not specify "-domains" here, so
                            # get the values from the NaviServer
                            # configuration file from section:
                            # (ns_section ns/server/${server}/module/letsencrypt)
                            #
                            set c [::letsencrypt::Client new \
                                       -API $api \
                                       -background \
                                       -domains {} \
                                      ]
                            ns_log notice "ssl: call getCertificate"
                            $c getCertificate
                            ns_log notice "ssl: call getCertificate DONE"
                            append report \n[ad_html_to_text [$c cget -log]]\n
                            $c destroy

                        } on ok {result} {
                            ns_log notice "letsencrypt: automated renew request succeeded: $result"
                        } on error {errorMsg} {
                            append report "Error: $errorMsg\nConsider upgrading to letsencrypt 0.6\n"
                            ns_log notice "letsencrypt: automated renew request failed: $errorMsg"
                        }

                        parameter::set_value \
                            -package_id $::acs::kernel_id \
                            -parameter UseCanonicalLocation \
                            -value $oldValue
                    }
                    append report \n[string repeat = 72]\n

                    set certLabel [expr {[llength $critCertInfo] > 1 ? "certificates" : "certificate"}]
                    set body [ns_trim -delimiter | {
                        |Dear Webmaster of [ad_system_name],
                        |
                        |The following $certLabel of your site will expire soon:
                        |
                        | - [join $critCertInfo "\n- "]
                        |
                        |${report}Your friendly daemon
                    }]
                    #set to_addr neumann@wu.ac.at ;# can be activated for testing purposes
                    acs_mail_lite::send -send_immediately \
                        -to_addr $to_addr \
                        -from_addr [ad_system_owner] \
                        -subject "Certificate of [ad_system_name] expires soon" \
                        -body [subst $body]
                }
            }

            return [expr {[llength $critCertInfo] > 0}]
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
