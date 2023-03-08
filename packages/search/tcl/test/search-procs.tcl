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
