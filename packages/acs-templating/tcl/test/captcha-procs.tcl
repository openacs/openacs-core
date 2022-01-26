ad_library {

    Test captcha widget api

}

aa_register_case -cats {
    api
    smoke
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
            # Simulate a 2 level depth for the api
            proc test args {
                return [template::data::validate::captcha value message]
            }
            if {[test]} {
                ns_return 200 text/plain OK
            } else {
                ns_return 500 text/plain $message
            }
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
        set query $captcha_checksum_id=nonsense
        set d [acs::test::http $endpoint_name?$query]
        acs::test::reply_has_status_code $d 500

        aa_true "Checksums were not cleared (checksum cannot be found)" \
            [db_string count {select count(*) from template_widget_captchas}]
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

        aa_true "Checksums were not cleared (text does not match the checksum)" \
            [db_string count {select count(*) from template_widget_captchas}]
        db_dml clear_checksums {
            delete from template_widget_captchas
        }

    } finally {
        ns_unregister_op GET $endpoint_name
    }
}
