ad_library {
    Automated tests.

    @author Joel Aufrecht
    @creation-date 2 Nov 2003
    @cvs-id $Id$
}

aa_register_case acs_messaging_trivial_smoke_test {
    Minimal smoke test.
} {    

    aa_run_with_teardown \
        -rollback \
        -test_code {
            # initialize random values
            set name [ad_generate_random_string]

            set formatted_name [acs_messaging_format_as_html text/html $name]

            aa_true "Name is formatted" ![string match "<pre>$name<pre>" $formatted_name]

        }
}