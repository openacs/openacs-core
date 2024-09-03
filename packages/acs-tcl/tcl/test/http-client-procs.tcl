ad_library {

    Tests for HTTP client API

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        util::http::get
        util::http::post
        util::http::post_payload
        ad_opentmpfile
        ad_url

        db_1row
    } \
    util_http_json_encoding {
        Test that JSON is encoded as expected
    } {
        set endpoint_name /acs-tcl-test-http-client-procs-util-http-json-encoding
        set url [::acs::test::url]
        #
        # Fallback to util_current_location if ad_url returns an empty string,
        # such in cases when the SystemUrl is not set.
        #
        if {$url eq ""} {
            set url [util_current_location]
        }
        set url $url$endpoint_name

        set response {{key1: "äöü", key2: "äüö", key3: "Ilić"}}

        set methods {POST GET}
        set impls {curl native}

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
                    aa_log "... [list util::http::[string tolower $m] -preference $impl -url $url]"
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
                        set F_json [ad_opentmpfile tmpfile_app_json]
                        if {$impl eq "curl"} {
                            aa_log "... running [::util::which curl] $url -k -o -"
                            puts $F_json [exec -ignorestderr [::util::which curl] $url -s -k -o -]
                        } else {
                            ns_http run -method GET -spoolsize 0 -outputchan $F_json $url
                        }
                        close $F_json
                    }

                    ns_register_proc $m $endpoint_name [subst {
                        ns_return 200 "application/json;charset=UTF-8" {$response}
                    }]
                    aa_log "Request with correct application/json;charset=UTF-8 mime_type"
                    aa_log "... running [list util::http::[string tolower $m] -preference $impl -url $url]"
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
                        set F_iso8859_2 [ad_opentmpfile tmpfile_iso8859_2]

                        if {$impl eq "curl"} {
                            puts $F_iso8859_2 [exec -ignorestderr [::util::which curl] $url -s -k -o -]
                        } else {
                            ns_http run -method GET -spoolsize 0 -outputchan $F_iso8859_2 $url
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
                        file delete -- $tmpfile_app_json $tmpfile_iso8859_2
                    }
                }
            }

        } -teardown_code {
            ns_unregister_op GET  $endpoint_name
            ns_unregister_op POST $endpoint_name
        }
    }

aa_register_case \
    -cats {api smoke} \
    -procs {
        export_vars
        util::http::get
        util::http::post
        util::http::post_payload
        ns_http
    } \
    postman_echo {
        Test HTTP client API against Postman Echo webservice
        (https://docs.postman-echo.com)
    } {
        set url "https://postman-echo.com"

        set test_key "string"
        set test_string "Umlaut ÜÄ"
        set json_data "{\"$test_key\": \"$test_string\"}"

        set get_url [export_vars -base $url/get [list [list $test_key $test_string]]]

        set content_types {
            "application/json;charset=UTF-8"
            "application/json"
        }
        set implementations {
            native curl ns_http
        }

        foreach impl $implementations {
            foreach content_type $content_types {
                set headers [ns_set create headers]
                ns_set update $headers "Content-Type" $content_type

                aa_section " - POST request - ContentType: '$content_type' - Implementation: '$impl'"
                if {$impl ne "ns_http"} {
                    set r [util::http::post -preference $impl -url $url/post -body $json_data -headers $headers]
                    set json_response [dict get $r page]
                } else {
                    set r [ns_http run -method POST -body $json_data -headers $headers $url/post]
                    set json_response [dict get $r body]
                }

                set status [dict get $r status]
                aa_equals "Server '$url' answers correctly with - status='$status'" $status 200

                aa_log "Server responded with: $json_response"

                set doc [dom parse -json -- $json_response]
                set resp_key ""
                set resp_value ""
                foreach node [$doc childNodes] {
                    if {[$node nodeName] eq "data"} {
                        set child [$node firstChild]
                        set resp_key    [$child nodeName]
                        set resp_string [$child text]
                    }
                }
                $doc delete

                aa_equals "Format seems correct" $resp_key $test_key
                aa_equals "Value is correct" $resp_string $test_string


                aa_section " - GET request - ContentType: '$content_type' - Implementation: '$impl'"
                if {$impl ne "ns_http"} {
                    set r [util::http::get -preference $impl -url $get_url -headers $headers]
                    set json_response [dict get $r page]
                } else {
                    set r [ns_http run -method GET -headers $headers $get_url]
                    set json_response [dict get $r body]
                }

                set status [dict get $r status]
                aa_equals "Server '$url' answers correctly with - status='$status'" $status 200

                aa_log "Server responded with: $json_response"

                set doc [dom parse -json -- $json_response]
                set resp_key ""
                set resp_value ""
                foreach node [$doc childNodes] {
                    if {[$node nodeName] eq "args"} {
                        set child [$node firstChild]
                        set resp_key    [$child nodeName]
                        set resp_string [$child text]
                    }
                }
                $doc delete

                aa_equals "Format seems correct" $resp_key $test_key
                aa_equals "Value is correct" $resp_string $test_string
            }
        }
    }

aa_register_case -cats {
    api
    smoke
} -procs {
    util::http::post_payload
    util::http::post
    export_vars
} util_http_post_vars {

    Test the behavior of util::http::post with respect to its handling
    of request variables.

} {
    set endpoint_name /acs-tcl-util-http-post-vars

    set url [acs::test::url]${endpoint_name}

    set script {
        set files [list]
        foreach f [ns_querygetall files.tmpfile] {
            lappend files [ns_md file $f]
        }
        set vars [ns_querygetall vars]
        set vars_urlencoded [ns_querygetall vars_urlencoded]
        set vars_list [ns_querygetall vars_list]
        ns_return 200 text/plain [list $files $vars $vars_urlencoded $vars_list]
    }

    try {
        ns_register_proc POST $endpoint_name $script

        aa_section "Try to send the same parameter as URL and POST"
        aa_true "One cannot specify URLvars and POST vars at the same time" [catch {
            util::http::post \
                -url $url?thevars=1 \
                -formvars [export_vars {{thevars 2}}] \
                -formvars_list {thevars 3 thevars 4}
        } errmsg]

        aa_section "Try to send the same parameter as file and non-file"
        aa_true "One cannot specify file vars and POST vars at the same time" [catch {
            util::http::post \
                -url $url \
                -files {{file /tmp/myfile.txt fieldname thevars}} \
                -formvars [export_vars {{thevars 2}}] \
                -formvars_list {thevars 3 thevars 4}
        } errmsg]

        aa_section "Combine URLencoded and list parameters in a urlencoded POST request"
        set r [util::http::post \
                   -url $url \
                   -formvars [export_vars {{vars 2} {vars_urlencoded:multiple {c d e f}}}] \
                   -formvars_list {vars 3 vars 4 vars_list a vars_list b}]
        lassign [dict get $r page] files vars vars_urlencoded vars_list
        aa_equals "'files' has been sent correctly" \
            [lsort $files] [list]
        aa_equals "'vars' have been sent correctly" \
            [lsort $vars] {2 3 4}
        aa_equals "'vars_urlencoded' has been sent correctly" \
            [lsort $vars_urlencoded] {c d e f}
        aa_equals "'vars_list' has been sent correctly" \
            [lsort $vars_list] {a b}

        aa_section "Combine URLencoded, list parameters and files in a multipart POST request"
        set files {}
        set files_checksums {}
        set to_delete {}
        foreach c {abc 123 ÄÜÖ} {
            set F [ad_opentmpfile tmpfile]
            puts -nonewline $F $c
            close $F
            lappend files [list file $tmpfile fieldname files]
            lappend files_checksums [ns_md file $tmpfile]
            lappend to_delete $tmpfile
        }
        set r [util::http::post \
                   -url $url \
                   -files $files \
                   -formvars [export_vars {{vars 2} {vars_urlencoded:multiple {c d e f}}}] \
                   -formvars_list {vars 3 vars 4 vars_list a vars_list b}]
        lassign [dict get $r page] files vars vars_urlencoded vars_list
        aa_equals "'files' has been sent correctly" \
            [lsort $files] [lsort $files_checksums]
        aa_equals "'vars' have been sent correctly" \
            [lsort $vars] {2 3 4}
        aa_equals "'vars_urlencoded' has been sent correctly" \
            [lsort $vars_urlencoded] {c d e f}
        aa_equals "'vars_list' has been sent correctly" \
            [lsort $vars_list] {a b}

        aa_section "Combine URLencoded and list parameters in a multipart POST request"
        set r [util::http::post \
                   -url $url \
                   -multipart \
                   -formvars [export_vars {{vars 2} {vars_urlencoded:multiple {c d e f}}}] \
                   -formvars_list {vars 3 vars 4 vars_list a vars_list b}]
        lassign [dict get $r page] files vars vars_urlencoded vars_list
        aa_equals "'files' has been sent correctly" \
            [lsort $files] [list]
        aa_equals "'vars' have been sent correctly" \
            [lsort $vars] {2 3 4}
        aa_equals "'vars_urlencoded' has been sent correctly" \
            [lsort $vars_urlencoded] {c d e f}
        aa_equals "'vars_list' has been sent correctly" \
            [lsort $vars_list] {a b}
        ad_file delete {*}$to_delete

    } finally {
        ns_unregister_op POST $endpoint_name
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
