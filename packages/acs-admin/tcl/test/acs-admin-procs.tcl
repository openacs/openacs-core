ad_library {
    Automated tests.

    @author Joel Aufrecht
    @creation-date 2 Nov 2003
    @cvs-id $Id$
}

aa_register_case -cats {
    api smoke
} -procs {
    apm_higher_version_installed_p
} apm_higher_version_installed_p {
    Test apm_higher_version_installed_p proc.
} {

    aa_run_with_teardown \
        -rollback \
        -test_code {

            set is_lower [apm_higher_version_installed_p acs-admin "1"]
            aa_equals "is the version of acs-admin higher than 0.1d?" $is_lower -1

            set is_higher [apm_higher_version_installed_p acs-admin "1000"]
            aa_equals "is the version of acs-admin lower than 1000.1d?" $is_higher 1

        }
}

aa_register_case -cats {
    api smoke
} -procs {
    acs_admin::check_expired_certificates
} acs_admin_check_expired_certificates {
    Check acs_admin::check_expired_certificates
} {
    nsv_set __acs_admin_get_expired_certificates email_sent_p false
    aa_stub acs_mail_lite::send {
        nsv_set __acs_admin_get_expired_certificates email_sent_p true
    }

    set expired_certificates_p [::acs_admin::check_expired_certificates]

    if {$expired_certificates_p} {
        aa_true "Expired certificates have been found. Need to send an email." \
            [nsv_get __acs_admin_get_expired_certificates email_sent_p]
    } else {
        aa_log "No expired certificates... Nothing to do."
    }

    nsv_unset __acs_admin_get_expired_certificates
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
