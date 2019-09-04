ad_library {
    Tcl helper procedures for the acs-automated-testing tests of
    the acs-tcl package.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 22 January 2003
}

aa_register_case \
    -cats {api smoke} \
    base64__tcl_vs_ns_decode {
        Tests that decoding of md5 string using tcl base64 package
        behaves the same as Naviserver implementation.
    } {
        package require base64
        set md5 {iVBORw0KGgoAAAANSUhEUgAAAAUA
            AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO
            9TXL0Y4OHwAAAABJRU5ErkJggg==}
        aa_true "Decoding of md5 string is identical" \
            {[base64::decode $md5] eq [ns_base64decode $md5]}
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
