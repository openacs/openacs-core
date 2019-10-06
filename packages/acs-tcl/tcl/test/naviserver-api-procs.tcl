ad_library {
    Procs to test NaviServer API capabilities.
}

aa_register_case \
    -cats {api smoke} \
    base64__tcl_vs_ns_decode {

        Tests that decoding of base64 encoded strings using the tcllib
        base64 package behaves the same as NaviServer implementation.

    } {
        package require base64
        #
        # base64 encoded tring with weird spaces.
        #
        set base64encoded {iVBORw0KGgoAAAANSUhEUgAAAAUA
            AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO
            9TXL0Y4OHwAAAABJRU5ErkJggg==}
        #
        # Force the result to binary to get same results as tcllib function.
        #
        catch {ns_base64decode} result
        set flag [expr {[string match *binary* $result] ? "-binary" : ""}]
        aa_log "base64::decode: [ns_md5 [base64::decode $base64encoded]]"
        aa_log "ns_base64decode: [ns_md5 [ns_base64decode {*}$flag $base64encoded]]"
        aa_true "Decoding of md5 string is identical" \
            {[ns_md5 [base64::decode $base64encoded]] eq [ns_md5 [ns_base64decode {*}$flag $base64encoded]]}
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
