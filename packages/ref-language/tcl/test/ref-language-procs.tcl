ad_library {
    Automated tests for the ref-language package.

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 2020-08-21
    @cvs-id $Id$
}

aa_register_case -procs {
        ref_language::set_data
    } -cats {
        api
    } ref_language__set_data {
        Test ref_language::set_data proc.
} {
    aa_run_with_teardown -rollback -test_code {
        #
        # Check if the language foo already exists.
        #
        if {[db_0or1row foo {
            select * from language_639_2_codes where iso_639_2='foo'
        }]} {
            aa_error "Language 'Foo' already exists in the database"
        } else {
            #
            # Create the new language 'foo'.
            #
            # As this is running in a transaction, it should be cleaned up
            # automatically.
            #
            ref_language::set_data -label Foo -iso2 foo
            #
            # Check if creation was successful.
            #
            aa_true "Language Foo created" "[db_0or1row foo {
                select * from language_639_2_codes where iso_639_2='foo'
            }]"
            #
            # Try to modify it
            #
            ref_language::set_data -label Bar -iso2 foo -iso1 fo
            #
            # Check if modification was successful.
            #
            set iso_639_2 ""
            set iso_639_1 ""
            set label ""
            db_0or1row foo {
                select * from language_639_2_codes where iso_639_2='foo'
            }
            aa_equals "iso_639_2 should be foo" "$iso_639_2" "foo"
            aa_equals "iso_639_1 should be foo" "$iso_639_1" "fo"
            aa_equals "label should be Bar"     "$label"     "Bar"
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
