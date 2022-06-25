ad_library {

    Test captcha widget api

}

aa_register_case -cats {
    api
    smoke
    stress
} -procs {
    template::widget::captcha
    template::data::validate::captcha
} captcha_widget {
    Test the captcha widget API
} {
    try {
        set endpoint_name /acs-templating-test-captcha-widget
        ns_register_proc GET $endpoint_name {
            array set element {
                mode edit
                form_id test
                name captcha
            }
            set message ""
            set value [ns_queryget value]
            # Simulate a 2-level depth for the API
            proc test args {
                return [template::data::validate::captcha value message]
            }
            if {[test]} {
                ns_return 200 text/plain OK
            } else {
                ns_return 500 text/plain $message
            }
            rename test ""
        }

        array set element {
            mode edit
            form_id test
            name captcha
        }

        set captcha_checksum_id $element(form_id):$element(name):image_checksum

        db_dml clear_checksums {
            delete from template_widget_captchas
        }

        set widget [template::widget::captcha element {}]
        aa_true "Widget is HTML" {[string first "<img" $widget] >= 0}

        aa_true "Checksum was created" \
            [db_string count {select count(*) from template_widget_captchas}]

        db_1row get_checksum {
            select image_checksum, text from template_widget_captchas
        }

        set query $captcha_checksum_id=$image_checksum&value=$text
        set d [acs::test::http $endpoint_name?$query]
        acs::test::reply_has_status_code $d 200

        aa_false "Checksums were cleared" \
            [db_string count {select count(*) from template_widget_captchas}]

        template::widget::captcha element {}
        db_dml store_expired_captcha {
            insert into template_widget_captchas
            (image_checksum, text, expiration)
             values
            ('test',
             'test',
             current_timestamp - cast('1 seconds' as interval)
            )
         }

        set query $captcha_checksum_id=nonsense
        set d [acs::test::http $endpoint_name?$query]
        acs::test::reply_has_status_code $d 500

        aa_equals "Checksums were not cleared (checksum cannot be found), but expired captchas were cleaned up" \
            [db_string count {select count(*) from template_widget_captchas}] \
            1

        db_dml clear_checksums {
            delete from template_widget_captchas
        }

        template::widget::captcha element {}
        db_1row get_checksum {
            select image_checksum, text from template_widget_captchas
        }
        set query $captcha_checksum_id=$image_checksum&value=nonsense
        set d [acs::test::http $endpoint_name?$query]
        acs::test::reply_has_status_code $d 500

        aa_false "Checksums were cleared even when the text does not match" \
            [db_string count {select count(*) from template_widget_captchas}]

    } finally {
        ns_unregister_op GET $endpoint_name
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    captcha::image::generate
} tesseract_cannot_crack_catpcha {

    Provide a baseline check for robustness by making sure a free tool
    such as Tesseract cannot crack the captcha.

    @see https://github.com/tesseract-ocr/tessdoc

} {
    set tesseract [::util::which tesseract]
    if {$tesseract eq ""} {
        aa_log "Tesseract command not available. We cannot perform this check."
        return
    }

    foreach size {
        50x150
        100x300
        200x600
        400x1200
        800x2400
        160x120
        320x240
        640x480
        1024x768
        1280x960
    } {
        set text [ad_generate_random_string 5]
        set captcha [captcha::image::generate \
                         -size $size \
                         -text $text]
        set ocr ""
        try {
            set ocr [exec -ignorestderr -- $tesseract [dict get $captcha path] -]
        } on error {errmsg} {
            aa_log "Tesseract failed on '[dict get $captcha path]'"
        }

        aa_false "Tesseract guessed '$ocr' in '[dict get $captcha path]', the real text was '$text'" [expr {$text eq $ocr}]

        # Make tesseract a favor and clean up non-alphanum chars
        regsub -all -- {([^\w]|\s)} $ocr {} ocr_clean
        aa_false "One can get to '$ocr_clean' in '[dict get $captcha path]' by cleaning non-alphanumerics, the real text was '$text'" \
             [expr {$text eq $ocr_clean}]

        # Make yet another favor and convert to uppercase
        set ocr_clean_uppercase [string toupper $ocr_clean]
        aa_false "One can get to '$ocr_clean_uppercase' in '[dict get $captcha path]' by converting to uppercase, the real text was '$text'" \
             [expr {$text eq $ocr_clean_uppercase}]

    }
}
