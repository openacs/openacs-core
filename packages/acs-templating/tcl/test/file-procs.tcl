ad_library {

    Tests for api in tcl/file-procs.tcl

}

aa_register_case -cats {
    api
    smoke
} -procs {
    template::util::file_transform
    template::util::file::get_property
    template::data::validate::file
    template::widget::file
    template::element::create
    template::form
    ad_form
    template::adp_eval
    template::adp_compile
    util::http::post_payload
    template::adp_append_code
} template_widget_file {
    Test template::widget::file.

    In particular, we are interested in making sure that it is not
    possible to forge a request so that a form interprets a file that
    already exists on the server as the file the user has uploaded.
} {
    set endpoint_name /acs-templating-test-template-widget-file

    set url [parameter::get \
                 -package_id [apm_package_id_from_key acs-automated-testing] \
                 -parameter TestURL \
                 -default ""]
    if {$url eq ""} {
        set url [ns_conn location]
    }
    set urlInfo [ns_parseurl $url]
    set url ${url}${endpoint_name}

    set script {
        set ::template::parse_level 0
        ad_form -name test -html { enctype multipart/form-data } \
            -form {
                {upload_file:file
                    {label "Upload a file"}
                }
            } -on_submit {
                set file_name [template::util::file::get_property filename $upload_file]
                set tmpfile   [template::util::file::get_property tmp_filename $upload_file]
                set type      [template::util::file::get_property mime_type $upload_file]

                if {$file_name eq ""} {
                    ns_return 500 text/plain "Filename missing: '$upload_file'"
                }
                if {![file exists $tmpfile]} {
                    ns_return 500 text/plain "Tmpfile missing: '$upload_file'"
                }

                set tmpdir [file dirname $tmpfile]
                set new_path $tmpdir/acs-templating-test-template-widget-file
                file rename -force -- $tmpfile $new_path

                ad_returnredirect /
                ad_script_abort
            }

        set template [template::adp_compile -string {
            <formtemplate id="test"></formtemplate>
        }]

        ns_return 200 text/html [template::adp_eval template]
    }

    try {
        ns_register_proc POST $endpoint_name $script
        ns_register_proc GET  $endpoint_name $script

        set d [ns_http run -method GET $url]

        acs::test::reply_has_status_code $d 200

        set response [dict get $d body]
        set form [acs::test::get_form $response {//form[@id='test']}]

        aa_true "add form was returned" {[llength $form] > 2}

        set file_name afile

        #
        # Here we send an unsafe tmpfile using a urlencoded request.
        #
        aa_section "- EVIL - Send an unsafe tmpfile using a urlencoded request."

        set tmpfile [ad_tmpnam]/inafolder/test.txt
        file mkdir [file dirname $tmpfile]
        set wfd [open $tmpfile w]
        puts $wfd aaaa
        close $wfd

        aa_true "Tmpfile '$tmpfile' exists" [file exists $tmpfile]

        set d [::acs::test::form_reply \
                   -last_request $d \
                   -form $form \
                   -update [list \
                                upload_file $file_name \
                                upload_file.tmpfile $tmpfile \
                                upload_file.content-type text/plain \
                                title $file_name \
                                description $file_name]]

        aa_true "Tmpfile '$tmpfile' still exists" [file exists $tmpfile]

        #
        # Here we expect 200 because the file does not count as sent.
        #
        acs::test::reply_has_status_code $d 200


        #
        # Here we send an unsafe tmpfile using the 3 elements list
        # format.
        #
        aa_section "- EVIL - send an unsafe tmpfile using the 3 elements list format"

        set tmpfile [ad_tmpnam]/inafolder/test.txt
        file mkdir [file dirname $tmpfile]
        set wfd [open $tmpfile w]
        puts $wfd bbbb
        close $wfd

        aa_true "Tmpfile '$tmpfile' exists" [file exists $tmpfile]

        set d [::acs::test::form_reply \
                   -last_request $d \
                   -form $form \
                   -update [list \
                                upload_file {$file_name $tmpfile text/plain} \
                                title $file_name \
                                description $file_name]]

        aa_true "Tmpfile '$tmpfile' still exists" [file exists $tmpfile]

        #
        # Here we expect 200 because the file does not count as sent.
        #
        acs::test::reply_has_status_code $d 200


        #
        # Here we send an unsafe tmpfile as part of a multipart request.
        #
        aa_section "- EVIL - Send an unsafe tmpfile as part of a multipart request"

        set tmpfile [ad_tmpnam]/inafolder/test.txt
        file mkdir [file dirname $tmpfile]
        set wfd [open $tmpfile w]
        puts $wfd cccc
        close $wfd

        aa_true "Tmpfile '$tmpfile' exists" [file exists $tmpfile]

        #
        # Send the POST request
        #
        set export {}
        set form_content [::acs::test::form_get_fields $form]
        dict set form_content upload_file $file_name
        dict set form_content upload_file.tmpfile $tmpfile
        dict set form_content upload_file.content-type text/plain
        foreach {att value} $form_content {
            lappend export [ad_urlencode_query $att]=[ad_urlencode_query $value]
        }
        set body [join $export &]
        set d [::util::http::post \
                   -url $url \
                   -max_depth 0 \
                   -multipart \
                   -formvars $body]
        dict set d body [dict get $d page]

        aa_true "Tmpfile '$tmpfile' still exists" [file exists $tmpfile]

        #
        # Here we expect 200 because the file does not count as sent.
        #
        acs::test::reply_has_status_code $d 200


        #
        # Here we send a safe tmpfile via a genuine multipart request.
        #
        aa_section "- GOOD - Send a safe tmpfile via a genuine multipart request"

        set tmpfile [ad_tmpnam].txt
        set wfd [open $tmpfile w]
        puts $wfd dddd
        close $wfd

        aa_true "Tmpfile '$tmpfile' exists" [file exists $tmpfile]

        #
        # Send the POST request
        #
        set export {}
        foreach {att value} [::acs::test::form_get_fields $form] {
            if {$att eq "upload_file"} {
                continue
            }
            lappend export [ad_urlencode_query $att]=[ad_urlencode_query $value]
        }
        set body [join $export &]
        set d [::util::http::post \
                   -url $url \
                   -max_depth 0 \
                   -formvars $body \
                   -files [list [list \
                                     file $tmpfile \
                                     fieldname upload_file]]]
        dict set d body [dict get $d page]

        aa_true "Tmpfile '$tmpfile' still exists" [file exists $tmpfile]

        set tmpdir [file dirname $tmpfile]
        set new_path $tmpdir/acs-templating-test-template-widget-file
        aa_true "Form received a different file" [file exists $new_path]
        aa_equals "The other file has the same content of our file" \
            [ns_md file $new_path] [ns_md file $tmpfile]
        file delete -- $new_path


        #
        # Here we expect 302 because the form redirects on success
        #
        acs::test::reply_has_status_code $d 302


    } finally {
        ns_unregister_op GET  $endpoint_name
        ns_unregister_op POST $endpoint_name
        if {[info exists new_path]} {
            file delete -- $new_path
        }
    }
}
