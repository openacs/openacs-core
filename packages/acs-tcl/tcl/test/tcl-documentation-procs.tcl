ad_library {

    Test about documenting pages and processing query arguments.

}


aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        ad_page_contract_parse_argspec
        ad_page_contract_split_argspec_flags
        ad_page_contract_split_argspec_flag_parameters
    } ad_page_contract_argspec_parsing {

        Make sure that helpers parsing of the argspec in
        ad_page_contract work as expected.

    } {
        aa_section "Valid specs"
        foreach {spec expected_name expected_flags} {
            w:oneof(red|green)
            w
            oneof(red|green)

            my_page_parameter
            my_page_parameter
            ""

            my_page_parameter:integer
            my_page_parameter
            integer

            my_page_parameter:integer,notnull
            my_page_parameter
            integer,notnull

            my_page_parameter:integer,notnull,oneof(1|2|3)
            my_page_parameter
            integer,notnull,oneof(1|2|3)

            {another_page_parameter:oneof(this is valid|This, is also valid|This is valid \(as well!\))}
            another_page_parameter
            {oneof(this is valid|This, is also valid|This is valid \(as well!\))}

            {another_page_parameter:oneof(this is \|valid|This, is also valid|This is valid \(as well!\))}
            another_page_parameter
            {oneof(this is \|valid|This, is also valid|This is valid \(as well!\))}

        } {
            set r [ad_page_contract_parse_argspec $spec]
            aa_equals "name for spec '$spec' OK" $expected_name [lindex $r 0]
            aa_equals "flags for spec '$spec' OK" $expected_flags [lindex $r 1]
        }

        aa_section "Invalid specs"
        foreach spec {
            w::a

            w::

            w:oneof(red|green))

            w:notnull,,integer

            "my_page_parameter)"

            "my_page_parameter:(integer"
        } {
            aa_true "spec '$spec' KO" [catch {
                [ad_page_contract_parse_argspec $spec]
            } errmsg]
        }

        aa_section "Spec flags"
        foreach {flags flags_list} {
            oneof(red|green)
            oneof(red|green)

            ""
            ""

            integer
            integer

            integer,notnull
            {integer notnull}

            integer,notnull,oneof(1|2|3)
            {integer notnull oneof(1|2|3)}

            {oneof(this is valid|This, is also valid|This is valid \(as well!\))}
            {{oneof(this is valid|This, is also valid|This is valid \(as well!\))}}

            {optional,notnull,oneof(this is valid|This, is also valid|This is valid \(as well!\))}
            {optional notnull {oneof(this is valid|This, is also valid|This is valid \(as well!\))}}

            {optional,notnull,oneof(this is \|valid|This, is also valid|This is valid \(as well!\))}
            {optional notnull {oneof(this is \|valid|This, is also valid|This is valid \(as well!\))}}
        } {
            set r [ad_page_contract_split_argspec_flags $flags]
            aa_equals "Parsing flags '$flags' OK" $flags_list $r
        }

        aa_section "Spec flag parameters"
        foreach {flag_parameters flag_parameters_list} {
            red|green
            {red green}

            ""
            ""

            {this is valid|This, is also valid|This is valid \(as well!\)}
            {{this is valid} {This, is also valid} {This is valid (as well!)}}

            {part1\|part2|another \(value\)|normievalue}
            {part1|part2 {another (value)} normievalue}
        } {
            set r [ad_page_contract_split_argspec_flag_parameters $flag_parameters]
            aa_equals "Splitting flag parameters '$flag_parameters' OK" $flag_parameters_list $r
        }
    }