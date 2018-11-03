ad_library {
    Test html email procs
}

aa_register_case \
    -cats {api smoke} \
    -procs {build_mime_message} \
    build_mime_message {
    Basic test of build mime message
} {
    aa_false "Build mime message, no error" \
        [catch {build_mime_message \
                    "Test Message" \
                    "<p>Test Message</p>"} errmsg]
    aa_log err=$errmsg
    aa_false "Package require mime package found" \
        [catch {package require mime} errmsg]


}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
