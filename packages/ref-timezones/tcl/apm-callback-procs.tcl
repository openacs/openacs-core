# 

ad_library {
    
    APM Callback procs
    
    @author Victor Guerra (vguerra@wu-wien.ac.at)
    @creation-date 2008-12-16
    @cvs-id $Id$
}

namespace eval ref-timezones::apm {}

ad_proc -public ref-timezones::apm::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    After upgrade callback.
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            5.5.0d1 5.5.0d2 {
                db_load_sql_data [acs_root_dir]/packages/ref-timezones/sql/[db_driverkey ""]/upgrade/upgrade-timezones.ctl
                set entries [db_string _ "select count(*) from timezones"]
                ns_log Notice "$entries time zones loaded"
            }
        }
}
