ad_library {

    Tests fot HTTP client API

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        util::http::get
        util::http::post
    } \
    util_http_json_encoding {
        Test that JSON is encoded as expected
    } {
        set endpoint_name /acs-tcl-test-http-client-procs-util-http-json-encoding
        set url [ad_url]$endpoint_name
        set response {{key1: "äöü", key2: "äüö", key3: "Ilić"}}

        set methods {POST GET}
        set impls [expr {[string match http://* $url] ?
                         [lindex [util::http::apis] 0] :
                         [lindex [util::http::apis] 1]}]

        aa_log "Will execute test on URL: '$url'"

        aa_run_with_teardown -test_code {
            foreach m $methods {
                aa_section "$m requests"
                foreach impl $impls {
                    aa_section "$impl implementation"
                    ns_register_proc $m $endpoint_name [subst {
                        ns_return 200 application/json {$response}
                    }]
                    aa_log "Request with correct application/json mime_type"
                    set r [util::http::[string tolower $m] -preference $impl -url $url]
                    set headers [dict get $r headers]
                    set content_type [expr {[dict exists $headers content-type] ?
                                            [dict get $headers content-type] : [dict get $headers Content-Type]}]
                    aa_true "Content-type is application/json" [string match "*application/json*" $content_type]
                    aa_equals "Response from server is encoded as expected" [dict get $r page] $response

                    # Collect a sample of what is returned when we set
                    # encoding to the default one for application/json
                    # (which by RF4627 SHALL be some unicode version)
                    if {$m eq "GET"} {
                        set tmpfile_app_json [ad_tmpnam]
                        if {$impls eq "curl"} {
                            exec -ignorestderr curl $url -o $tmpfile_app_json
                        } else {
                            ns_http run -method GET -outputfile $tmpfile_app_json $url
                        }
                    }

                    ns_register_proc $m $endpoint_name [subst {
                        ns_return 200 "application/json;charset=UTF-8" {$response}
                    }]
                    aa_log "Request with correct application/json;charset=UTF-8 mime_type"
                    set r [util::http::[string tolower $m] -preference $impl -url $url]
                    set headers [dict get $r headers]
                    set content_type [expr {[dict exists $headers content-type] ?
                                            [dict get $headers content-type] : [dict get $headers Content-Type]}]
                    aa_true "Content-type is application/json" [string match "*application/json*" $content_type]
                    aa_true "Charset is UTF-8" [string match "*UTF-8*" $content_type]
                    aa_equals "Response from server is encoded as expected" [dict get $r page] $response

                    aa_log "Request with text/plain mime_type"
                    ns_register_proc $m $endpoint_name [subst {
                        ns_return 200 text/plain {$response}
                    }]
                    set r [util::http::[string tolower $m] -preference $impls -url $url]
                    set headers [dict get $r headers]
                    set content_type [expr {[dict exists $headers content-type] ?
                                            [dict get $headers content-type] : [dict get $headers Content-Type]}]
                    aa_true "Content-type '$content_type' is text/plain" [string match "*text/plain*" $content_type]
                    aa_equals "Response from server is encoded as expected" [dict get $r page] $response

                    aa_log "Request with text/plain mime_type and iso8859-2 charset"
                    ns_register_proc $m $endpoint_name [subst {
                        ns_return 200 "text/plain; charset=iso8859-2" {$response}
                    }]

                    set r [util::http::[string tolower $m] -preference $impls -url $url]
                    set headers [dict get $r headers]
                    set content_type [expr {[dict exists $headers content-type] ?
                                            [dict get $headers content-type] : [dict get $headers Content-Type]}]
                    aa_true "Content-type is text/plain" [string match "*text/plain*" $content_type]
                    aa_true "Charset is iso8859-2" [string match "*iso8859-2*" $content_type]
                    aa_equals "Response from server is encoded as expected" [dict get $r page] $response

                    # Collect a sample of what is returned when we set
                    # encoding of the response to iso8859-2
                    if {$m eq "GET"} {
                        set tmpfile_iso8859_2 [ad_tmpnam]
                        if {$impls eq "curl"} {
                            exec -ignorestderr curl $url -o $tmpfile_iso8859_2
                        } else {
                            ns_http run -method GET -outputfile $tmpfile_iso8859_2 $url
                        }
                    }

                    # Here we expose that, when one uses the "naked"
                    # HTTP tool util::http is wrapping, response would
                    # not be automatically translated to the system
                    # encoding.
                    if {[info exists tmpfile_app_json] &&
                        [info exists tmpfile_iso8859_2] &&
                        [file exists $tmpfile_app_json] &&
                        [file exists $tmpfile_iso8859_2]} {
                        set rfd [open $tmpfile_app_json r]
                        set app_json_text [read $rfd]
                        close $rfd

                        set rfd [open $tmpfile_iso8859_2 r]
                        set iso8859_2_text [read $rfd]
                        close $rfd

                        aa_true "Setting the charset actually brings to different content in the response" {$app_json_text ne $iso8859_2_text}
                        file delete $tmpfile_app_json $tmpfile_iso8859_2
                    }
                }
            }

        } -teardown_code {
            ns_unregister_op GET  $endpoint_name
            ns_unregister_op POST $endpoint_name
        }
    }