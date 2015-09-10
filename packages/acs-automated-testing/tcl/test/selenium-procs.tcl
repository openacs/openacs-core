ad_library {
    Test cases for Selenium Remote Control integration
}

aa_register_case \
    -cats {web selenium smoke} \
    -init_classes {{selenium acs-automated-testing}} selenium_server_configured {
    Is the selenium server configured and working?
} {
     aa_false "Start Selenium RC Session" [catch {Se start} errmsg]
    aa_log $errmsg
    aa_false "Open [ad_url]" [catch {Se open [ad_url]} errmsg]
    aa_log $errmsg
}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
