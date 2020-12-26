ad_library {

    Tests for utilities

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        ad_sanitize_filename
    } \
    ad__sanitize_filename {
        Tests that sanitizing a filename works as expected.
    } {
        aa_section "Sanitized string without an extension"
        set str "A;\\  <<<ß*>CoOO/etc/passwdl# \"\u001f:: f__?ilename \u0000"
        # Our test string is poisonous enough that this log command
        # would fail...
        # aa_log "Checking against '$str'"
        aa_equals "Basic sanitizing" [ad_sanitize_filename $str] "A  ßCoOOetcpasswdl#  f__ilename "
        aa_equals "Collapsing spaces" [ad_sanitize_filename -collapse_spaces $str] "A-ßCoOOetcpasswdl#-f__ilename-"
        aa_equals "Collapsing spaces with a custom separator" [ad_sanitize_filename -replace_with _ -collapse_spaces $str] "A_ßCoOOetcpasswdl#_f__ilename_"
        aa_equals "Collapsing spaces with a custom separator, to lowercase" [ad_sanitize_filename -tolower -replace_with _ -collapse_spaces $str] [string tolower "A_ßCoOOetcpasswdl#_f__ilename_"]

        aa_true "Sanitizing to an existing filename without resolving throws an error" [catch {
            ad_sanitize_filename \
                -tolower \
                -replace_with _ \
                -collapse_spaces \
                -no_resolve \
                -existing_names {a_ßcoooetcpasswdl#_f__ilename_} \
                $str
        }]
        aa_false "Sanitizing without resolving does not throw an error with an empty list fo existing names" [catch {
            ad_sanitize_filename \
                -tolower \
                -replace_with _ \
                -collapse_spaces \
                -no_resolve \
                -existing_names {} \
                $str
        }]

        set resolved [ad_sanitize_filename \
                          -tolower \
                          -replace_with _ \
                          -collapse_spaces \
                          -existing_names {a_ßcoooetcpasswdl#_f__ilename_} \
                          $str]
        aa_equals "Sanitizing to an existing filename with resolving is fine" $resolved [string tolower "A_ßCoOOetcpasswdl#_f__ilename_"]_2

        aa_section "Sanitized string containing an extension"
        set str "A;\\  <<<ß*>CoOO/etc/passwdl# \"\u001f:: f__?ilename \u0000.extension"
        aa_equals "Basic sanitizing" [ad_sanitize_filename $str] "A  ßCoOOetcpasswdl#  f__ilename .extension"
        aa_equals "Collapsing spaces" [ad_sanitize_filename -collapse_spaces $str] "A-ßCoOOetcpasswdl#-f__ilename-.extension"
        aa_equals "Collapsing spaces with a custom separator" [ad_sanitize_filename -replace_with _ -collapse_spaces $str] "A_ßCoOOetcpasswdl#_f__ilename_.extension"
        aa_equals "Collapsing spaces with a custom separator, to lowercase" [ad_sanitize_filename -tolower -replace_with _ -collapse_spaces $str] [string tolower "A_ßCoOOetcpasswdl#_f__ilename_.extension"]

        aa_true "Sanitizing to an existing filename without resolving throws an error" [catch {
            ad_sanitize_filename \
                -tolower \
                -replace_with _ \
                -collapse_spaces \
                -no_resolve \
                -existing_names {a_ßcoooetcpasswdl#_f__ilename_.extension} \
                $str
        }]
        aa_false "Sanitizing without resolving does not throw an error with an empty list fo existing names" [catch {
            ad_sanitize_filename \
                -tolower \
                -replace_with _ \
                -collapse_spaces \
                -no_resolve \
                -existing_names {} \
                $str
        }]

        set resolved [ad_sanitize_filename \
                          -tolower \
                          -replace_with _ \
                          -collapse_spaces \
                          -existing_names {a_ßcoooetcpasswdl#_f__ilename_.extension} \
                          $str]
        aa_equals "Sanitizing to an existing filename with resolving is fine" $resolved [string tolower "A_ßCoOOetcpasswdl#_f__ilename_.extension"]_2
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
