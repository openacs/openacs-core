ad_library {

    Tests for procs in tcl tcl/lang-widget-procs.tcl

}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        template::widget::select_locales
    } locale_select_widget {
        Test template::widget::select_locales
    } {
        aa_section "Edit Mode"

        set tag_attributes {data-att {I am another test attribute value}}
        array set element {
            html {data-test {I am a test attribute value}}
            values {en_US de_DE}
            mode edit
            name test-lang
            options {{English en_US} {Deutsch de_DE} {Italiano it_IT}}
        }

        set widget [template::widget::select_locales element $tag_attributes]

        aa_true "Output looks like a select HTML" {
            [string first "<select" $widget] >= 0 &&
            [string first "<option" $widget] >= 0
        }
        foreach lang_text {English en_US Deutsch de_DE Italiano it_IT} {
            aa_true "Output contains '$lang_text'" {
                [string first $lang_text $widget] >= 0
            }
        }
        foreach value {it de en} {
            aa_true "options provide required lang attribute for '$value'" \
                [regexp "option lang=('$value'|\"$value\")" $widget]
        }
        foreach {att value} {
            data-att {I am another test attribute value}
            data-test {I am a test attribute value}
        } {
            aa_true "Output contains '$att=\"$value\"" \
                [regexp $att=('$value'|\"$value\") $widget]
        }


        aa_section "View Mode"

        set element(mode) view
        set widget [template::widget::select_locales element $tag_attributes]

        foreach value {en_US de_DE it_IT} {
            aa_false "Output contains hidden field for '$value'" {
                [string first "input type=\"hidden\" value=\"$value\"" $widget] >= 0
            }
        }

    }
