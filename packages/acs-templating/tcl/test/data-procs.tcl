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
        aa_true "Is $value a boolean?" \
            [template::data::validate boolean value message]
    }
    foreach value $bool_false {
        aa_false "Is $value a boolean?" \
            [template::data::validate boolean value message]
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
    set int_true {
        0
        -0
        -5
        1
        20
        99999999999999999999999999999999999999999999999999999999999
    }
    set int_false {0.0 5,3 0,1 ,3}
    set message ""
    foreach value $int_true {
        aa_true "Is $value an integer?" \
            [template::data::validate integer value message]
    }
    foreach value $int_false {
        aa_false "Is $value an integer?" \
            [template::data::validate integer value message]
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::naturalnum
} validate_naturalnum {
    Test validation for naturalnum data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 28 June 2021
} {
    set nat_true {
        0
        5
        1
        20
        99999999999999999999999999999999999999999999999999999999999
        08
    }
    set nat_false {0.0 5,3 0,1 ,3 -1 -9.3}
    set message ""
    foreach value $nat_true {
        aa_true "Is $value a naturalnum?" \
            [template::data::validate naturalnum value message]
    }
    foreach value $nat_false {
        aa_false "Is $value a naturalnum?" \
            [template::data::validate naturalnum value message]
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::float
} validate_float {
    Test validation for float data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 28 June 2021
} {
    set float_true {
        0
        1
        -9
        0.0
        5.3
        +0.1
        .3
        -9.3
        34433333333333333333333333333333333333.4566666666666
    }
    set float_false {lala -1,0 ,3 - .}
    set message ""
    foreach value $float_true {
        aa_true "Is $value a float?" \
            [template::data::validate float value message]
    }
    foreach value $float_false {
        aa_false "Is $value a float?" \
            [template::data::validate float value message]
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::number
} validate_number {
    Test validation for number data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 28 June 2021
} {
    set number_true {
        0
        1
        -9
        0.0
        5.3
        +0.1
        .3
        -9.3
        34433333333333333333333333333333333333.4566666666666
    }
    set number_false {lala -1,0 ,3 - .}
    set message ""
    foreach value $number_true {
        aa_true "Is $value a number?" \
            [template::data::validate number value message]
    }
    foreach value $number_false {
        aa_false "Is $value a number?" \
            [template::data::validate number value message]
    }
}
aa_register_case -cats {

    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::text
    template::data::validate::string
    template::data::validate::checkbox_text
    template::data::validate::radio_text
    template::data::validate::select_text
} validate_text {
    Test validation for text related data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 28 June 2021
} {
    #
    # Currently, all submitted text to the validator is valid...
    #
    set text_true {"" "my text" "lalala"}
    set message ""
    foreach value $text_true {
        aa_true "Is $value text?" \
            [template::data::validate text value message]
        aa_true "Is $value a string?" \
            [template::data::validate string value message]
        aa_true "Is $value a checkbox_text?" \
            [template::data::validate checkbox_text value message]
        aa_true "Is $value a radio_text?" \
            [template::data::validate radio_text value message]
        aa_true "Is $value a select_text?" \
            [template::data::validate select_text value message]
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::search
    template::data::validate::party_search
} validate_search {
    Test validation for search data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 28 June 2021
} {
    #
    # Currently, all submitted search strings to the validator are valid...
    #
    set search_true {"" "my search" "lalala"}
    set message ""
    foreach value $search_true {
        aa_true "Is $value a search?" \
            [template::data::validate search value message]
        aa_true "Is $value a party_search?" \
            [template::data::validate party_search value message]
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::file
} validate_file {
    Test validation for file data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 28 June 2021
} {
    #
    # Currently, the file widget is assumed to never fail...
    #
    set file_true {my_file lalala}
    set message ""
    foreach value $file_true {
        aa_true "Is $value a file?" \
            [template::data::validate file value message]
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::keyword
} validate_keyword {
    Test validation for keyword data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 28 June 2021
} {
    set keyword_true {0 1 lala lala_la_la}
    set keyword_false {-1,0 -ojaio ,3 - . "la la la"}
    set message ""
    foreach value $keyword_true {
        aa_true "Is $value a keyword?" \
            [template::data::validate keyword value message]
    }
    foreach value $keyword_false {
        aa_false "Is $value a keyword?" \
            [template::data::validate keyword value message]
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::filename
} validate_filename {
    Test validation for filename data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 28 June 2021
} {
    #
    # Currently, filename must be alphanumeric, "-" or "_".
    #
    set filename_true {0 1 lala lala_la_la lala-la-la -yes -}
    set filename_false {not,valid ,no . "la la la" la.la}
    set message ""
    foreach value $filename_true {
        aa_true "Is $value a filename?" \
            [template::data::validate filename value message]
    }
    foreach value $filename_false {
        aa_false "Is $value a filename?" \
            [template::data::validate filename value message]
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::url
} validate_url {
    Test validation for url data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 28 June 2021
} {
    set url_true {
        "http://la.la"
        "https://la.la"
        "https://a.a"
        "http://example.com"
        "https://example.com"
        "ftp://example.com"
        "http://example.com/"
        "http://example.com/index.html"
        "HTTP://example.com"
        "http://example.com/foo/bar/blah"
        "http://example.com?foo=bar&bar=foo"
        "http://foo.com/blah_blah"
        "http://foo.com/blah_blah/"
        "http://foo.com/blah_blah_(wikipedia)"
        "http://foo.com/blah_blah_(wikipedia)_(again)"
        "http://www.example.com/wpstyle/?p=364"
        "https://www.example.com/foo/?bar=baz&inga=42&quux"
        "http://✪df.ws/123"
        "http://userid:password@example.com:8080"
        "http://userid:password@example.com:8080/"
        "http://userid@example.com"
        "http://userid@example.com/"
        "http://userid@example.com:8080"
        "http://userid@example.com:8080/"
        "http://userid:password@example.com"
        "http://userid:password@example.com/"
        "http://142.42.1.1/"
        "http://142.42.1.1:8080/"
        "http://➡.ws/䨹"
        "http://⌘.ws"
        "http://⌘.ws/"
        "http://foo.com/blah_(wikipedia)#cite-1"
        "http://foo.com/blah_(wikipedia)_blah#cite-1"
        "http://foo.com/unicode_(✪)_in_parens"
        "http://foo.com/(something)?after=parens"
        "http://☺.damowmow.com/"
        "http://code.google.com/events/#&product=browser"
        "http://j.mp"
        "ftp://foo.bar/baz"
        "http://foo.bar/?q=Test%20URL-encoded%20stuff"
        "http://مثال.إختبار"
        "http://例子.测试"
        "http://उदाहरण.परीक्षा"
        "http://-.~_!$&'()*+,;=:%40:80%2f::::::@example.com"
        "http://1337.net"
        "http://a.b-c.de"
        "http://223.255.255.254"
        ""
        "/"
        "//"
        "//a"
        "///a"
        "///"
        "?a"
        "a:h"
        "./a"
        "g?y"
        "g?y/./x"
        "foo"
        "#s"
        "g#s"
        "g#s/./x"
        "g?y#s"
        ";x"
        "g;x"
        "g;x?y#s"
        "."
        "./"
        ".."
        "../"
        "../g"
        "../.."
        "../../"
        "../../g"
        "../../g/"
        "/foo/"
        "/foo/bar"
        "/foo/bar/"
        "/foo/bar/lol.html"
        "/foo.bar/?q=Test%20URL-encoded%20stuff"
        "foo.com"
        "foo.com/bar/lol"
        "/foo.com/bar/lol"
        "/مثال.إختبار"
        "/例子.测试"
        "/उदाहरण.परीक्षा"
        "/-.~_!$&'()*+,;=:%40:80%2f::::::@example.com"
        "foo.bar/?q=Test%20URL-encoded%20stuff"
        "مثال.إختبار"
        "例子.测试"
        "उदाहरण.परीक्षा"
        "-.~_!$&'()*+,;=:%40:80%2f::::::@example.com"
        "no-protocol"
        "/relative"
    }
    set url_false {
        "xhttp://example.com"
        "httpx://example.com"
        "wysiwyg://example.com"
        "mailto:joe@example.com"
        "http://"
        "http://."
        "http://.."
        "http://../"
        "http://?"
        "http://??"
        "http://??/"
        "http://#"
        "http://##"
        "http://##/"
        "http://foo.bar?q=Spaces should be encoded"
        "http:///a"
        "rdar://1234"
        "h://test"
        "http:// shouldfail.com"
        ":// should fail"
        "http://foo.bar/foo(bar)baz quux"
        "ftps://foo.bar/"
        "http://.www.foo.bar/"
        "http://.www.foo.bar./"
        "la la la"
        "http:// la.com"
        {http://$la.com}
        "http:///la.com"
        "http://.la.com"
        "http://?la.com"
        "http://#la.com"
        "http://a "
        "http://a a"
    }
    set message ""
    foreach value $url_true {
        aa_true "Is $value a url?" [template::data::validate url value message]
    }
    foreach value $url_false {
        aa_false "Is $value a url?" [template::data::validate url value message]
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::url_element
} validate_url_element {
    Test validation for url_element data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 28 June 2021
} {
    #
    #  URL elements may only contain lowercase characters, numbers and hyphens.
    #
    set url_element_true {
        lalala
        0
        -1
        -asdasaf
    }
    set url_element_false {
        LALALA
        NO
        "la la"
        not,valid
        ://
    }
    set message ""
    foreach value $url_element_true {
        aa_true "Is $value a url_element?" \
            [template::data::validate url_element value message]
    }
    foreach value $url_element_false {
        aa_false "Is $value a url_element?" \
            [template::data::validate url_element value message]
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::date
    template::data::validate::timestamp
    template::data::validate::time_of_day
    template::util::date::validate
} validate_date {
    Test validation for date data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 28 June 2021
} {
    #
    # date, time_of_day and timestamp are all validated by
    # template::util::date::validate.
    #
    set date_true {
        "2021 06 28"
        "2021 06 28 13 01 00"
        "2021 06 28 13 01"
        "2021 06 28 13"
    }
    set date_false {
        LALALA
        NO
        "2021-06-28 12:52:44"
        "2021_06_28"
        "2021 Jun 28"
        "2021-06-28"
        "-2021 06 28"
        "2021 -06 28"
        "2021 06 -28"
        "2021 06 38"
        "2021 16 28"
        "2021 06 28 25 01 00"
        "2021 06 28 13 71 00"
        "2021 06 28 13 01 70"
        "2021 06 28 13 01 -00"
        "2021 06 28 13 -01 00"
        "2021 06 28 -13 01 00"
        "la la"
        not,valid
        ://
    }
    set message ""
    foreach value $date_true {
        aa_true "Is $value a date?" \
            [template::data::validate date value message]
        aa_true "Is $value a timestamp?" \
            [template::data::validate timestamp value message]
        aa_true "Is $value a time_of_day?" \
            [template::data::validate timestamp value message]
    }
    foreach value $date_false {
        aa_false "Is $value a date?" \
            [template::data::validate date value message]
        aa_false "Is $value a timestamp?" \
            [template::data::validate timestamp value message]
        aa_false "Is $value a time_of_day?" \
            [template::data::validate time_of_day value message]
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::enumeration
} validate_enumeration {
    Test validation for enumeration data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 30 June 2021
} {
    #
    # An enumeration is a unique csv alphanumeric list.
    #
    set enumeration_true {
        {1,2,3}
        {first,second,third}
        first
    }
    set enumeration_false {
        {1 2 3}
        {first,first}
        {-,.}
        ""
    }
    set message ""
    foreach value $enumeration_true {
        aa_true "Is $value an enumeration?" \
            [template::data::validate enumeration value message]
    }
    foreach value $enumeration_false {
        aa_false "Is $value an enumeration?" \
            [template::data::validate enumeration value message]
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::textdate
} validate_textdate {
    Test validation for textdate data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 30 June 2021
} {
    #
    # An textdate is a date in ISO  YYYY-MM-DD.
    #
    set textdate_true {
        2021-06-30
        ""
    }
    set textdate_false {
        21-06-30
        2021-13-30
        2021-00-30
        2021-06-32
        2021-06-00
        "lala"
    }
    set message ""
    foreach value $textdate_true {
        aa_true "Is $value a textdate?" \
            [template::data::validate textdate value message]
    }
    foreach value $textdate_false {
        aa_false "Is $value a textdate?" \
            [template::data::validate textdate value message]
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::oneof
} validate_oneof {
    Test validation for oneof data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 30 June 2021
} {
    set message ""
    set values ""
    array set element {options {{zero 0} {one 1} {two 2} {three 3}}}
    set value_true {0 1 2 3}
    set value_false {zero null nope 4 ""}
    foreach value $value_true {
        aa_true "Is $value in the list of values?" \
            [template::data::validate oneof value message]
    }
    foreach value $value_false {
        aa_false "Is $value in the list of values?" \
            [template::data::validate oneof value message]
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::data::validate
    template::data::validate::currency
} validate_currency {
    Test validation for currency data types

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 30 June 2021
} {
    #
    # An textdate is a date in ISO  YYYY-MM-DD.
    #
    set currency_true {
        "€ 0 . 0"
        "€ 0 , 0"
        "€ 0"
        "€ 11 . 01"
        "€ 1500 , 01"
        "€ 1 , 5"
        {$ 2 . 03}
        "Rs 50 . 42"
        "L 12 . 52"
    }
    set currency_false {
        lalala
        1€
        "not a currency"
        ""
    }
    set message ""
    foreach value $currency_true {
        aa_true "Is $value a currency?" \
            [template::data::validate currency value message]
    }
    foreach value $currency_false {
        aa_false "Is $value a currency?" \
            [template::data::validate currency value message]
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
