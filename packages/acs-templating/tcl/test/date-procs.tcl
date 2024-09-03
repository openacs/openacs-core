#

ad_library {

    Test date procs

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-10-13
    @cvs-id $Id$
}


aa_register_case \
    -cats {
        api
        production_safe
    } -procs {
        template::util::date::get_property
        template::util::date::now
        db_type
        db_version
    } sql_date {
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
    -cats {
        api
        production_safe
    } -procs {
        template::util::date::now_min_interval
    } date_minute_interval {
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

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::util::negative
} util_negative {
    Test template::util::negative proc

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 28 June 2021
} {
    set negative_true {-1 -0,6}
    set negative_false {"" 0 +1 lala}
    foreach value $negative_true {
        aa_true "Is $value negative?" [template::util::negative $value]
    }
    foreach value $negative_false {
        aa_false "Is $value negative?" [template::util::negative $value]
    }
}

aa_register_case \
    -cats {
        api
        production_safe
    } -procs {
        template::data::from_sql::time_of_day
        template::data::from_sql::timestamp
        template::data::from_sql::date
        template::util::date::acquire
        template::util::date::create
        template::util::date::set_property
        template::data::to_sql::time_of_day
        template::data::to_sql::timestamp
        template::data::to_sql::date
        template::util::date::get_property
        template::util::date::unpack
    } template_date_api {
        Test api manipulating the template date format.

        Among the things this test shows, is the fact that this API
        can swallow a lot of garbage without complaining. It is not
        clear if this should change.

        @author Antonio Pisano (antonio@elettrotecnica.it)
    } {
        aa_section "From SQL - Valid input"

        set test_data {
            2023-02-20 {2023 2 20 0 0 0 {DD MONTH YYYY}}
            {2023-02-20 22:10} {2023 2 20 0 0 0 {DD MONTH YYYY}}
            {2023-02-20 22:10:100} {2023 2 20 22 10 10 {DD MONTH YYYY}}
            {2023-02-20 22:10:900} {2023 2 20 22 10 9 {DD MONTH YYYY}}
            {2023-02-23 99-00-00} {2023 2 23 0 0 0 {DD MONTH YYYY}}
            2023-02-99 {2023 2 9 0 0 0 {DD MONTH YYYY}}
            {0000-00-00 00:00:00} {0000 0 0 0 0 0 {DD MONTH YYYY}}
            "" {{} {} {} {} {} {} {DD MONTH YYYY}}
        }

        foreach {input expected} $test_data {
            aa_equals "template::data::from_sql::date on '$input' returns expected" \
                [template::data::from_sql::date $input] $expected
            aa_equals "template::data::from_sql::time_of_day on '$input' returns expected" \
                [template::data::from_sql::time_of_day $input] $expected
            aa_equals "template::data::from_sql::timestamp on '$input' returns expected" \
                [template::data::from_sql::timestamp $input] $expected
        }


        aa_section "From SQL - Invalid input"

        set test_data {
            2023-50-00
            a
            111
            {1-1-1 a b c}
            1-1-1
        }

        foreach input $test_data {
            aa_true "template::data::from_sql::date on '$input' returns error" [catch {
                template::data::from_sql::date $input
            }]
            aa_true "template::data::from_sql::time_of_day on '$input' returns error" [catch {
                template::data::from_sql::time_of_day $input
            }]
            aa_true "template::data::from_sql::timestamp on '$input' returns error" [catch {
                template::data::from_sql::timestamp $input
            }]
        }


        aa_section "To SQL - Valid input"

        set test_data {
            {2023 2 20 0 0 0 {DD MONTH YYYY}} "to_timestamp('2023 02 20 00 00 00', 'YYYY MM DD HH24 MI SS')"
            {2023 2 20 22 10 100 {DD MONTH YYYY}} "to_timestamp('2023 02 20 22 10 100', 'YYYY MM DD HH24 MI SS')"
            {2023 2 20 22 10 900 {DD MONTH YYYY}} "to_timestamp('2023 02 20 22 10 900', 'YYYY MM DD HH24 MI SS')"
            {2023 2 23 99 0 0 {DD MONTH YYYY}} "to_timestamp('2023 02 23 99 00 00', 'YYYY MM DD HH24 MI SS')"
            {2023 2 99 0 0 0 {DD MONTH YYYY}} "to_timestamp('2023 02 99 00 00 00', 'YYYY MM DD HH24 MI SS')"
            {0 0 0 0 0 0 {DD MONTH YYYY}} "to_timestamp('0000 00 00 00 00 00', 'YYYY MM DD HH24 MI SS')"
            2023-50-00 "to_date('2023-50-00', 'YYYY')"
            a "to_date('000a', 'YYYY')"
            111 "to_date('0111', 'YYYY')"
            {1-1-1 a b c} "to_timestamp('1-1-1 0a 0b 0c', 'YYYY MM DD HH24')"
            1-1-1 "to_date('1-1-1', 'YYYY')"
            "" NULL
        }

        foreach {input expected} $test_data {
            aa_equals "template::data::from_sql::date on '$input' returns expected" \
                [template::data::to_sql::date $input] $expected
            aa_equals "template::data::from_sql::time_of_day on '$input' returns expected" \
                [template::data::to_sql::time_of_day $input] $expected
            aa_equals "template::data::from_sql::timestamp on '$input' returns expected" \
                [template::data::to_sql::timestamp $input] $expected
        }

        set test_data {
            {2023 2 20 0 0 0 {DD MONTH YYYY}}
            2023-50-00
            a
            111
            {1-1-1 a b c}
            1-1-1
            ""
        }
        set vars {year month day hours minutes seconds format}
        foreach input $test_data {
            template::util::date::unpack $input
            set i 0
            foreach v $vars {
                aa_equals "template::util::date::unpack on '$input' for '$v' returns expected" \
                    [set ${v}] [lindex $input $i]
                incr i
            }
        }

    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
