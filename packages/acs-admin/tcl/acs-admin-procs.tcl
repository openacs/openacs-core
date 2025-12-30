ad_library {

    Automated functions for acs-admin

    @author Gustaf Neumann
    @creation-date 2018-08-15
}

namespace eval acs_admin {

    ad_proc -private ::acs_admin::posture_status {
        {-current_location:required}
        {-url:required}
    } {

        return information about the posture status of the provided
        URL.

        @return dict containing status, diagnosis, and package_id
    } {
        try {
            set node_id [site_node::get_node_id -url $url]
            set package_id [site_node::get_object_id -node_id $node_id]
            set parties [permission::get_parties_with_permission -object_id $package_id]
            set direct_permissions [::acs::dc list get {select grantee_id || ' ' || privilege from acs_permissions where object_id = :package_id}]
            #ns_log notice "direct_permissions $direct_permissions"
            set direct_permissions [lmap p $direct_permissions {
                #ns_log notice "XXX [lindex $p 0] [ad_decode [lindex $p 0] -1 public -2 registered-users]"
                list [ad_decode [lindex $p 0] -1 public -2 "registered-users" [lindex $p 0]] [lindex $p 1]
            }]
            ns_http run -timeout 300ms $current_location$url
        } on ok {result} {
            set status [dict get $result status]
            set diagnosis ""
            switch $status {
                200 {set diagnosis "publicly accessible"}
                302 {
                    set location [ns_set iget [dict get $result headers] location]
                    if {[string match *register* $location]} {
                        set diagnosis "requires login"
                    } else {
                        set diagnosis "redirect to $location"
                    }
                    #set diagnose "publicly accessible"
                }
                422 {set diagnosis "Potentially success with other parameters"}
                404 {set diagnosis "not installed"}
            }
            #append diagnosis " $node_id $package_id ($parties) // [llength $parties] // $direct_permissions"
            #append report "status $status $diagnose\n<br>"
        } on error {errorMsg} {
            set diagnosis $errorMsg
            set status 0
            set direct_permissions ""
            set parties ""
            set package_id 0
        }
        return [list status $status diagnosis $diagnosis package_id $package_id direct_permissions $direct_permissions parties $parties]
    }


    ad_proc -private ::acs_admin::check_expired_certificates {
        {-api production}
        {-key_type ecdsa}
    } {

        Check expire-dates of certificates and send warning emails to
        the admin. In case HTTPS is not configured via the "nsssl"
        driver, or the command line tool "openssl" is not installed,
        the proc does nothing.

        @param api possible values: "production" or "staging".
            In case the certificate is expired, use this type of
            letsencrypt environment to obtain a fresh certificate.

        @param key_type possible values: "rsa" or "ecdsa".

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
                        set notAfter [exec $openssl x509 -enddate -noout -in $certfile]
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
                    set mailSubject "Certificate of [ad_system_name] expires soon"
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
                            if {[::letsencrypt::Client info lookup parameters \
                                     create key_type] ne ""} {
                                set key_type_parameter "-key_type $key_type"
                            } else {
                                set key_type_parameter ""
                            }
                            set c [::letsencrypt::Client new \
                                       -API $api \
                                       {*}$key_type_parameter \
                                       -sslpath [file dirname $certfile] \
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
                            set success "success"
                        } on error {errorMsg} {
                            append report "Error: $errorMsg\nConsider upgrading to letsencrypt 0.6\n"
                            ns_log notice "letsencrypt: automated renew request failed: $errorMsg"
                            set success "error"
                        }

                        parameter::set_value \
                            -package_id $::acs::kernel_id \
                            -parameter UseCanonicalLocation \
                            -value $oldValue
                        set mailSubject "Certificate of [ad_system_name] renewal ($success)"
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
                        -subject $mailSubject \
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
