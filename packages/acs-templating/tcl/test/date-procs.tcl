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
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
