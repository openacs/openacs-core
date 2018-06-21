ad_library {

    Provides a simple API for reliably sending email.

    @author Eric Lorenzo (eric@openforce.net)
    @creation-date 22 March 2002
    @cvs-id $Id$

}

package require mime 1.4
package require smtp 1.4
package require base64 2.3.1
namespace eval acs_mail_lite {

    ad_proc -public address_domain {} {
        @return domain address to which bounces are directed to.
        If empty, uses domain from FixedSenderEmail parameter,
        otherwise the hostname in config.tcl is used.
    } {
        set domain [parameter::get_from_package_key \
                        -package_key "acs-mail-lite" \
                        -parameter "BounceDomain"]
        if { $domain eq "" } {
            # Assume a FixedSenderEmail domain, if it exists.
            set email [parameter::get_from_package_key \
                           -package_key "acs-mail-lite" \
                           -parameter "FixedSenderEmail"]
            if { $email ne "" } {
                set domain [string range $email [string last "@" $email]+1 end]
            } else {
                #
                # If there is no domain configured, use the configured
                # hostname as domain name
                #
                foreach driver {nsssl nssock_v4 nssock_v6 nssock} {
                    set section [ns_driversection -driver $driver]
                    set configured_hostname [ns_config $section hostname]
                    if {$configured_hostname ne ""} {
                        set domain $configured_hostname
                        break
                    }
                }
            }
        }
        return $domain
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
