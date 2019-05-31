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

        aa_log "Will execute test on URL: '$url'"

        aa_run_with_teardown -rollback -test_code {
            set response {{key1: "äöü", key2: "äüö", key3: "Ilić"}}

            aa_log "JSON GET and POST requests with proper application/json mime type"
            ns_register_proc GET $endpoint_name {
                ns_return 200 application/json {{key1: "äöü", key2: "äüö", key3: "Ilić"}}
            }
            set r [util::http::get -url $url]
            set content_type [dict get [dict get $r headers] content-type]
            aa_true "Content-type is application/json" [string match "*application/json*" $content_type]
            aa_equals "Response from server is encoded as expected" [dict get $r page] $response

            ns_register_proc POST $endpoint_name {
                ns_return 200 application/json {{key1: "äöü", key2: "äüö", key3: "Ilić"}}
            }
            set r [util::http::post -url $url]
            set content_type [dict get [dict get $r headers] content-type]
            aa_true "Content-type is application/json" [string match "*application/json*" $content_type]
            aa_equals "Response from server is encoded as expected" [dict get $r page] $response


            aa_log "JSON GET and POST requests with text/plain mime type"
            ns_register_proc GET $endpoint_name {
                ns_return 200 text/plain {{key1: "äöü", key2: "äüö", key3: "Ilić"}}
            }
            set r [util::http::get -url $url]
            set content_type [dict get [dict get $r headers] content-type]
            aa_true "Content-type is text/plain" [string match "*text/plain*" $content_type]
            aa_equals "Response from server is encoded as expected" [dict get $r page] $response

            ns_register_proc POST $endpoint_name {
                ns_return 200 text/plain {{key1: "äöü", key2: "äüö", key3: "Ilić"}}
            }
            set r [util::http::post -url $url]
            set content_type [dict get [dict get $r headers] content-type]
            aa_true "Content-type is text/plain" [string match "*text/plain*" $content_type]
            aa_equals "Response from server is encoded as expected" [dict get $r page] $response


            aa_log "JSON GET and POST requests with text/plain mime type and a not RFC4627 compliant charset"
            ns_register_proc GET $endpoint_name {
                ns_conn encoding iso8859-15
                ns_return 200 text/plain {{key1: "äöü", key2: "äüö", key3: "Ilić"}}
            }
            set r [util::http::get -url $url]
            set content_type [dict get [dict get $r headers] content-type]
            aa_true "Content-type is text/plain" [string match "*text/plain*" $content_type]
            aa_true "Charset is iso8859-15" [string match "*iso8859-15*" $content_type]
            aa_true "Response from server is NOT encoded correctly!" {[dict get $r page] ne $response}

            ns_register_proc POST $endpoint_name {
                ns_conn encoding iso8859-15
                ns_return 200 text/plain {{key1: "äöü", key2: "äüö", key3: "Ilić"}}
            }
            set r [util::http::post -url $url]
            set content_type [dict get [dict get $r headers] content-type]
            aa_true "Content-type is text/plain" [string match "*text/plain*" $content_type]
            aa_true "Charset is iso8859-15" [string match "*iso8859-15*" $content_type]
            aa_true "Response from server is NOT encoded correctly!" {[dict get $r page] ne $response}

        } -teardown_code {
            ns_unregister_proc GET $endpoint_name
            ns_unregister_proc POST $endpoint_name
        }
    }
