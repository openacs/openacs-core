ad_library {

    Search Test Procs

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        search::convert::binary_to_text
    } \
    convert_binary_to_text {

        Test the conversion of various file types to plain text for
        indexing.

        The test files all contain the word "OpenACS". We test if this
        is correctly extracted.

    } {
        foreach {extension mime_type} {
            txt text/plain
            html text/html
            doc application/msword
            xls application/msexcel
            ppt application/mspowerpoint
            pdf application/pdf
            odt application/vnd.oasis.opendocument.text
            ott application/vnd.oasis.opendocument.text-template
            odp application/vnd.oasis.opendocument.presentation
            otp application/vnd.oasis.opendocument.presentation-template
            ods application/vnd.oasis.opendocument.spreadsheet
            ots application/vnd.oasis.opendocument.spreadsheet-template
            docx application/vnd.openxmlformats-officedocument.wordprocessingml.document
            xlsx application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
            pptx application/vnd.openxmlformats-officedocument.presentationml.presentation
        } {
            set filename [acs_root_dir]/packages/search/tcl/test/data/test.$extension
            aa_true "Text was extracted correctly for '.$extension'/'$mime_type'" {
                [string first "OpenACS" [search::convert::binary_to_text \
                                             -filename $filename \
                                             -mime_type $mime_type]] >= 0
            }
        }
    }

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        search::extra_args
        search::extra_args_names
        search::extra_args_page_contract
    } \
    extra_args {

        Test the api dealing with extra args introduced by the
        full-text engine in use.

    } {
        set expected_names [list]
        foreach procname [info procs ::callback::search::extra_arg::impl::*] {
            lappend expected_names [namespace tail $procname]
        }

        aa_equals "Extra arg names are expected" \
            [search::extra_args_names] $expected_names

        foreach arg $expected_names {
            unset -nocomplain $arg
        }
        aa_equals "Extra args returns empty when no var is defined" \
            [search::extra_args] ""

        set expected_values [list]
        set i 0
        foreach arg $expected_names {
            set $arg $i
            lappend expected_values $arg $i
            incr i
        }
        aa_equals "Extra args returns the values defined in the caller scope" \
            [lsort [search::extra_args]] [lsort $expected_values]


        set expected_contract ""
        foreach name $expected_names {
            append expected_contract "\{$name \{\}\}\n"
        }
        aa_equals "Extra args contract returns expected" \
            [search::extra_args_page_contract] $expected_contract
    }
