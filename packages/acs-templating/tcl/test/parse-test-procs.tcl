ad_library {

    Tests for adp parsing

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-01-01
    @cvs-id $Id$
}

aa_register_case \
    -cats {
        api
        production_safe
    } \
    -procs {
        template::adp_variable_regexp
        template::adp_variable_regexp_noquote
        template::adp_variable_regexp_noi18n
        template::adp_variable_regexp_literal
        template::adp_array_variable_regexp
        template::adp_array_variable_regexp_noquote
        template::adp_array_variable_regexp_noi18n
        template::adp_array_variable_regexp_literal
    } \
    template_variable {
        test adp variable parsing procedures
    } {
        aa_section "Testing plain variable"

        set code "=@test_var@"
        aa_true "Variable detected" \
            [regexp [template::adp_variable_regexp] $code discard pre var]
        aa_equals "Preceding char is '${pre}'"  "=" $pre
        aa_equals "Variable name is '${var}'"  \
            "test_var" $var

        set code "=@test_array.test_key@"
        aa_true "Regular array var name detected" \
            [regexp [template::adp_array_variable_regexp] $code discard pre arr var]
        aa_equals "Preceding char is '${pre}'"  "=" $pre
        aa_equals "Array name is '${arr}'"  \
            "test_array" $arr
        aa_equals "Variable name is '${var}'"  \
            "test_key" $var

        set code "=@formerror.test_array.test_key@"
        aa_true "Formerror regular array var name detected" \
            [regexp [template::adp_array_variable_regexp] $code discard pre arr var]
        aa_equals "Preceding char is '${pre}'"  "=" $pre
        aa_equals "Array name is '${arr}'"  \
            "formerror" $arr
        aa_equals "Variable name is '${var}'"  \
            "test_array.test_key" $var

        foreach modifier {noquote literal noi18n} {
            aa_section "Testing ;$modifier modifier"

            set code "=@test_var;$modifier@"
            aa_true "Variable detected" \
                [regexp [template::adp_variable_regexp_$modifier] $code discard pre var]
            aa_equals "Preceding char is '${pre}'"  "=" $pre
            aa_equals "Variable name is '${var}'"  \
                "test_var" $var

            set code "=@test_array.test_key;$modifier@"
            aa_true "$modifier array var name detected" \
                [regexp [template::adp_array_variable_regexp_$modifier] $code discard pre arr var]
            aa_equals "Preceding char is '${pre}'"  "=" $pre
            aa_equals "Array name is '${arr}'"  \
                "test_array" $arr
            aa_equals "Variable name is '${var}'"  \
                "test_key" $var

            set code "=@formerror.test_array.test_key;$modifier@"
            aa_true "$modifier formerror array var name detected" \
                [regexp [template::adp_array_variable_regexp_$modifier] $code discard pre arr var]
            aa_equals "Preceding char is '${pre}'"  "=" $pre
            aa_equals "Array name is '${arr}'"  \
                "formerror" $arr
            aa_equals "Variable name is '${var}'"  \
                "test_array.test_key" $var
        }
    }

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        template::expand_percentage_signs
    } \
    expand_percentage_signs {
        Test expand percentage signs to make sure it substitutes correctly

        @author Dave Bauer
        @creation-date 2005-11-20
    } {
        set orig_message "Test message %one%"
        set one "\[__does_not_exist__\]"
        set message $orig_message

        aa_false "Expanded square bracket text" \
            [catch {set expanded_message [template::expand_percentage_signs $message]} errmsg]
        aa_log $errmsg
        aa_equals "square brackets safe" $expanded_message "Test message \[__does_not_exist__\]"

        set one "\$__does_not_exist"
        aa_false "Expanded dollar test" \
            [catch {set expanded_message [template::expand_percentage_signs $message]} errmsg]
        aa_log $errmsg
        aa_equals "dollar sign safe" $expanded_message "Test message \$__does_not_exist"

        set one "\$two(\$three(\[__does_not_exist\]))"

        aa_false "Square bracket in array key test" \
            [catch {set expanded_message [template::expand_percentage_signs $message]} errmsg]
        aa_log $errmsg
        aa_equals "square brackets in array key safe" \
            $expanded_message "Test message \$two(\$three(\[__does_not_exist\]))"

    }

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        ::template::adp_parse_tags
        ::template::adp_compile_chunk
        ::template::icon
        ::template::adp_append_code
    } \
    adp_parse_tags {

        Checks the helper template::adp_parse_tags, which performs a
        subset of template::adp_compile.

    } {
        set HTML {<p>foo <adp:icon name="edit">bar}
        set result [::template::adp_parse_tags $HTML]
        aa_log [ns_quotehtml $result]
        aa_true "test substitution of adp:icon contains either 'class' or 'src' attribute" \
            [regexp {(class=|src=)} $result]
        set HTML {<p>foo @a@ <adp:icon name="edit">bar @b@}
        set result [::template::adp_parse_tags $HTML]
        aa_log [ns_quotehtml $result]
        aa_true "test substitution contains still template variables" \
            [regexp {@} $result]
    }

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        ::template::adp_parse_string
    } \
    adp_parse_string {

        Test template::adp_parse_string

    } {
        set adp {2 + 2 = <%= [expr {2 + 2}] %> !!!}
        aa_equals "Result is correct" \
            [template::adp_parse_string $adp] {2 + 2 = 4 !!!}
    }

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        ::template::adp_level
    } \
    adp_level {

        Test template::adp_level

    } {
        set template_adp_level $::template::parse_level
        try {
            unset -nocomplain ::template::parse_level
            aa_equals "When no parse level is set, result is empty" \
                [template::adp_level] ""

            set ::template::parse_level [list 1 2 3]

            aa_equals "With a parse level, result is the last level" \
                [template::adp_level] 3

            aa_true "Up must be an integer" [catch {
                template::adp_level broken
            } errmsg]

            aa_equals "Up is the number of elements we go up in the parse level" \
                [template::adp_level 3] 1

        } finally {
            set ::template::parse_level $template_adp_level
        }
    }

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        template::adp_include
        template::add_body_handler
        template::add_body_script
        template::add_confirm_handler
        template::add_event_listener
        template::add_refresh_on_history_handler
    } \
    templates_and_scripts {

        Test api to introduce javascript handlers inside a template.

    } {
        #
        # Note: we use placeholders instead of real values to better
        # find them in the output.
        #

        aa_section template::add_body_handler

        template::add_body_handler \
            -event __template::add_body_handler_event \
            -script __template::add_body_handler_script \
            -identifier __template::add_body_handler_identifier

        template::add_body_handler \
            -event __template::add_body_handler_event \
            -script __template::add_body_handler_script \
            -identifier __template::add_body_handler_identifier

        template::add_body_handler \
            -event __template::add_body_handler_event2 \
            -script __template::add_body_handler_script2 \
            -identifier __template::add_body_handler_identifier2


        aa_section template::add_body_script

        template::add_body_script \
            -charset __template::add_body_script_charset \
            -crossorigin __template::add_body_script_crossorigin \
            -integrity __template::add_body_script_integrity \
            -script __template::add_body_script_script \
            -src __template::add_body_script_src \
            -type __template::add_body_script_type \
            -async=false \
            -defer=false


        aa_section template::add_confirm_handler

        template::add_confirm_handler \
            -event __template::add_confirm_handler_event \
            -message __template::add_confirm_handler_message \
            -id __template::add_confirm_handler_id

        template::add_confirm_handler \
            -event __template::add_confirm_handler_event \
            -message __template::add_confirm_handler_message \
            -CSSclass __template::add_confirm_handler_CSSclass

        template::add_confirm_handler \
            -event __template::add_confirm_handler_event \
            -message __template::add_confirm_handler_message \
            -formfield {
                __template::add_confirm_handler_formfield1
                __template::add_confirm_handler_formfield2
            }

        template::add_confirm_handler \
            -event __template::add_confirm_handler_event \
            -message __template::add_confirm_handler_message \
            -selector __template::add_confirm_handler_selector


        aa_section template::add_event_listener

        template::add_event_listener \
            -event __template::add_event_listener_event \
            -id __template::add_event_listener_id \
            -script __template::add_event_listener_script

        template::add_event_listener \
            -event __template::add_event_listener_event \
            -CSSclass __template::add_event_listener_CSSclass \
            -script __template::add_event_listener_script

        template::add_event_listener \
            -event __template::add_event_listener_event \
            -formfield {
                __template::add_event_listener_formfield1
                __template::add_event_listener_formfield2
            } \
            -script __template::add_event_listener_script

        template::add_event_listener \
            -event __template::add_event_listener_event \
            -selector __template::add_event_listener_selector \
            -script __template::add_event_listener_script


        aa_section template::add_refresh_on_history_handler

        template::add_refresh_on_history_handler


        set page [template::adp_include /packages/acs-templating/lib/body_scripts {}]

        aa_true "Page contains script tags" \
            {[string first "<script" $page] >= 0}

        foreach expected {
            __template::add_body_handler_event
            __template::add_body_handler_script
            __template::add_body_handler_event2
            __template::add_body_handler_script2
            __template::add_body_script_charset
            __template::add_body_script_crossorigin
            __template::add_body_script_integrity
            __template::add_body_script_script
            __template::add_body_script_src
            __template::add_body_script_type
            __template::add_confirm_handler_event
            __template::add_confirm_handler_message
            __template::add_confirm_handler_id
            __template::add_confirm_handler_CSSclass
            __template::add_confirm_handler_formfield1
            __template::add_confirm_handler_formfield2
            __template::add_confirm_handler_selector
            __template::add_event_listener_event
            __template::add_event_listener_id
            __template::add_event_listener_script
            __template::add_event_listener_CSSclass
            __template::add_event_listener_formfield1
            __template::add_event_listener_formfield2
            __template::add_event_listener_selector
            "window.addEventListener( \"pageshow\""
        } {
            aa_true "'$expected' was rendered by the template" \
                {[string first $expected $page] >= 0}
        }
    }


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
