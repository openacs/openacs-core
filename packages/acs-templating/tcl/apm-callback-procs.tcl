ad_library {
    APM callback procedures for acs-templating.
    
    @creation-date 2003-09-22
    @author Lars Pind (lars@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval template {}
namespace eval template::apm {}

ad_proc -private template::apm::before_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    before upgrade apm callback for acs-templating.
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            4.6.4 5.0d1 {
                db_transaction {

                    # Change 'standard-lars' to 'standard'

                    set package_id [apm_package_id_from_key "acs-templating"]
                    set DefaultFormStyle [parameter::get \
                                              -package_id $package_id \
                                              -parameter DefaultFormStyle]

                    if { [string equal $DefaultFormStyle "standard-lars"] } {
                        parameter::set_value \
                            -package_id $package_id \
                            -parameter DefaultFormStyle \
                            -value "standard"
                    }

                    db_foreach subsite {
                        select package_id
                        from   apm_packages
                        where  package_key = 'acs-subsite'
                    } {
                        set DefaultFormStyle [parameter::get \
                                                  -package_id $package_id \
                                                  -parameter DefaultFormStyle]

                        if { [string equal $DefaultFormStyle "standard-lars"] } {
                            parameter::set_value \
                                -package_id $package_id \
                                -parameter DefaultFormStyle \
                                -value "standard"
                        }
                    }
                }
            }
        }
}
