ReturnHeaders

ns_write "[ad_header "Security API test"]
<ul>
"

ad_set_client_property test MyName MyValue

ns_write "<li>Set client property..."

set result [ad_get_client_property test MyName]

if { $result eq "MyValue"  } {
    ns_write "<li>Success: Client property successfully retrieved..."
} else {
    ns_write "<li>Failure: Client property was incorrectly retrieved, expected MyValue, instead got $result..."
}

ns_write "
</ul>
[ad_footer]"
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
