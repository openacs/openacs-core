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

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::email
} validate_email {
    Test validation for email

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 25 June 2021
} {
    set message ""
    #
    # Valid emails
    #
    # See: https://en.wikipedia.org/wiki/Email_address#Examples
    #
    set valid_mails {
        la@lala.la
        openacs@openacs.org
        whatever.is.this@my.mail.com
        discouraged@butvalid
        disposable.style.email.with+symbol@example.com
        other.email-with-hyphen@example.com
        fully-qualified-domain@example.com
        user.name+tag+sorting@example.com
        x@example.com
        example-indeed@strange-example.com
        test/test@test.com
        example@s.example
        john..doe@example.org
        mailhost!username@example.org
        user%example.com@example.org
        user-@example.org
    }
    foreach mail $valid_mails {
        aa_true "Is $mail valid?" [template::data::validate email mail message]
    }
    #
    # Invalid emails
    #
    set invalid_mails {
        @no.valid
        no.valid
        nope
        A@b@c@example.com
        {a"b(c)d,e:f;g<h>i[j\k]l@example.com}
        {just"not"right@example.com}
        {this is"not\allowed@example.com}
        {this\ still\"not\\allowed@example.com}
        i_like_underscore@but_its_not_allowed_in_this_part.example.com
        {QA[icon]CHOCOLATE[icon]@test.com}
    }
    foreach mail $invalid_mails {
        aa_false "Is $mail valid?" [template::data::validate email mail message]
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::integer
} validate_integer {
    Test validation for integer data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 28 June 2021
} {
    set int_true {0 -0 -5 1 20 99999999999999999999999999999999999999999999999999999999999}
    set int_false {0.0 5,3 0,1 ,3}
    set message ""
    foreach value $int_true {
        aa_true "Is $value a integer?" [template::data::validate integer value message]
    }
    foreach value $int_false {
        aa_false "Is $value a integer?" [template::data::validate integer value message]
    }
}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
