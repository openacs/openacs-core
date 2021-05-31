ad_library {

    Tests for HTTP client API

}

aa_register_case \
    -cats {api smoke} \
    -procs {
        ds_adp_box_class
        ds_adp_file_class
        ds_adp_output_class
        ds_set_adp_reveal_enabled
        ds_adp_reveal_enabled_p
    } \
    ds_adp_reveal_test {
        Check that the adp reveal api works as expected
    } {
        set old_state [ds_adp_reveal_enabled_p]

        try {
            ds_set_adp_reveal_enabled 0
            aa_false "ADP reveal is OFF" [ds_adp_reveal_enabled_p]

            aa_equals "box class is correct" [ds_adp_box_class] developer-support-adp-box-off
            aa_equals "file class is correct" [ds_adp_file_class] developer-support-adp-file-off
            aa_equals "output class is correct" [ds_adp_output_class] developer-support-adp-output-off

            ds_set_adp_reveal_enabled 1
            aa_true "ADP reveal is ON" [ds_adp_reveal_enabled_p]

            aa_equals "box class is correct" [ds_adp_box_class] developer-support-adp-box-on
            aa_equals "file class is correct" [ds_adp_file_class] developer-support-adp-file-on
            aa_equals "output class is correct" [ds_adp_output_class] developer-support-adp-output-on

        } finally {
            ds_set_adp_reveal_enabled $old_state
        }
    }
