ad_library {

    Automated functions for acs-admin

    @author Gustaf Neumann
    @creation-date 2018-08-15
}

namespace eval acs_admin {

    ad_proc ::acs_admin::check_expired_certificates {} {

        Check expire-dates of certificates and send warning
        emails to the admin. In case HTTPS is not configured via the
        "nsssl" driver, or the command line tool "openssl" openssl is
        installed, the proc does nothing.  } {

        set openssl [util::which openssl]
        if {[info commands ns_driver] ne "" && $openssl ne ""} {
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
                    set body ""
                    if {[llength $critCertInfo] > 1} {
                        set certLabel "certificates"
                    } else {
                        set certLabel "certificate"
                    }
                    acs_mail_lite::send -send_immediately \
                        -to_addr $to_addr \
                        -from_addr [ad_system_owner] \
                        -subject "Certificate of [ad_system_name] expires soon" \
                        -body [append body \
                                   "Dear Webmaster of [ad_system_name]," \n\n\
                                   "The following $certLabel of your site will expire soon:\n\n" \
                                   "- " [join $critCertInfo "\n- "] \n\n\
                                   "Your friendly daemon" \n]
                }
            }
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
