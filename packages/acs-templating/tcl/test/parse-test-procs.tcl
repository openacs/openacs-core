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
        template::adp_variable_regexp_no18n
        template::adp_variable_regexp_literal
        template::adp_array_variable_regexp
        template::adp_array_variable_regexp_noquote
        template::adp_array_variable_regexp_no18n
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


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
