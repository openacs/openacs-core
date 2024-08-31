ad_library {
    Test html email procs
}

aa_register_case \
    -cats {api smoke} \
    -procs {ad_build_mime_message} \
    ad_build_mime_message {
        Basic test of build mime message
    } {
        try {
            package require mime
        } on ok {versionNumber} {
            aa_true "MIME package in version $versionNumber loaded" 1
        } on error {errorMsg} {
            aa_false "could not load MIME package from tcllib: $errorMsg" 1
        }

        try {
            ad_build_mime_message \
                "Test Message" \
                "<p>Test Message</p>"
        } on ok {ns_set} {
            aa_true "built ns_set for containing an email message" {$ns_set ne ""}
        } on error {errorMsg} {
            aa_false "could not build build_mime_message: $errorMsg" 1
        }

}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
