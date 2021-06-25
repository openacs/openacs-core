ad_library {
    Automated tests for template::data

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 25 June 2021
    @cvs-id $Id$
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::boolean
} validate_boolean {
    Test validation for boolean data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 25 June 2021
} {
    set bool_true {t 1 true yes TRUE YES f 0 false no FALSE NO}
    set bool_false {untrue asdas 1234 on ON OFF off -1}
    set message ""
    foreach value $bool_true {
        aa_true "Is $value a boolean?" [template::data::validate boolean value message]
    }
    foreach value $bool_false {
        aa_false "Is $value a boolean?" [template::data::validate boolean value message]
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
