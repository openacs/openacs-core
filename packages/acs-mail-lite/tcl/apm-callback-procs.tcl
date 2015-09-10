ad_library {

    Installation procs for acs-mail-lite

    @author Emmanuelle Raffenne (eraffenne@gmail.com)
}

namespace eval acs_mail_lite {}

ad_proc -private acs_mail_lite::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    After upgrade callback for acs-mail-lite
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            5.4.0d2 5.4.0d3 {
                db_transaction {
                    db_dml remove_param_values {
                        delete from apm_parameter_values where parameter_id in (select parameter_id from apm_parameters where package_key = 'acs-mail-lite' and parameter_name='SendmailBin')
                    }
                    db_dml remove_param {
                        delete from apm_parameters where package_key = 'acs-mail-lite' and parameter_name='SendmailBin'
                    }
                } on_error {
                    ns_log Error "acs-mail-lite::after_upgrade from 5.4.0d2 to 5.4.0d3: $errmsg"
                }
            }
        }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
