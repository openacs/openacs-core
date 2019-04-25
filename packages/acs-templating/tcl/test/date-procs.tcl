#

ad_library {

    Test date procs

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-10-13
    @cvs-id $Id$
}


aa_register_case \
    -procs {
        template::util::date::get_property
        template::util::date::now
    } \
    sql_date {
    test sql date transform
} {
    aa_run_with_teardown \
        -test_code {
            set date [template::util::date::now]
            set sql_date [template::util::date::get_property sql_date $date]
            if { [db_type] eq "oracle" && [string match "8.*" [db_version]] } {
                aa_true "to_date for Oracle 8i" [string match "to_date*"]
            } else {
                aa_true "to_timestamp for Oracle 9i and PostgreSQL" [string match "to_timestamp*" $sql_date]
            }
        }
}

aa_register_case \
    -procs {
        template::util::date::now_min_interval
    } \
    date_minute_interval {
        test minute interval
    } {
    aa_run_with_teardown \
        -test_code {
            
            set clock [clock scan "2019-04-25 16:19:00"]
            set date [template::util::date::now_min_interval -clock $clock]
            aa_equals "interval up from 19" $date {2019 4 25 16 20 0 {DD MONTH YYYY}}
            
            set clock [clock scan "2019-04-25 16:20:00"]
            set date [template::util::date::now_min_interval -clock $clock]
            aa_equals "interval same " $date {2019 4 25 16 20 0 {DD MONTH YYYY}}

            set clock [clock scan "2019-04-25 16:21:00"]
            set date [template::util::date::now_min_interval -clock $clock]
            aa_equals "interval up from 21 " $date {2019 4 25 16 25 0 {DD MONTH YYYY}}

        }
}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
