ad_library {
    
    Tests that deal with the html parsing procs of openacs.

    @creation-date 15 November 2003
}


aa_register_case -cats {api smoke} ad_html_to_text_bold {

    Test if it converts b tags correctly.

} {

    set html "Some <b>bold</b> test"

    set result [ad_html_to_text $html]

    aa_true "contains asterisks?" [regexp {\*bold\*} $result]

}


aa_register_case -cats {api smoke} -bugs 386 -error_level warning  \
    ad_html_to_text_clipped_link {

    Test if it converts clipped links.

} {
    # try with missing leading and trailing quote

    foreach html {{
Some <a href="abc>linktext</a> bla
<p>
following text
} {
Some <a href=abc">linktext</a> bla
<p>
following text
    }} {
	set result [ad_html_to_text $html]

	# make sure the desired text is in there and _before_ the
	# footnotes

	aa_true "contains link" [regexp {linktext.*\[1\]} $result]
	aa_true "contains following text" [regexp {following text.*\[1\]} $result]
    }
}


aa_register_case -cats {api smoke} ad_html_security_check_href_allowed {
    tests is href attribute is allowed of A tags
} {
    set html "<a href=\"http://www.example/com\">An Link</a>"
    aa_true "href is allowed for A tags" [string equal [ad_html_security_check $html] ""]
}

aa_register_case -cats {api smoke} util_close_html_tags {
    Tests closing HTML tags.
} {
    aa_equals "" [util_close_html_tags "<b>Foobar"] "<b>Foobar</B>"

    aa_equals "" [util_close_html_tags "<b>Foobar</b>"] "<b>Foobar</b>"

    aa_equals "" [util_close_html_tags "<b>Foobar</b> is <i>a very long word</i>"] "<b>Foobar</b> is <i>a very long word</i>"

    aa_equals "" [util_close_html_tags "<b>Foobar</b> is <i>a very long word</i>" 15] "<b>Foobar</b> is <i>a</I>"

    aa_equals "" [util_close_html_tags "<b>Foobar</b> is <i>a very long word</i>" 0 20 "..."] "<b>Foobar</b> is <i>a very</I>..."
}


aa_register_case -cats {api smoke} ad_html_text_convert {
    Testing ad_html_text_convert.
} {
    #----------------------------------------------------------------------
    # from text/enhanced
    #----------------------------------------------------------------------
    
    set string "What?\n<i>Never mind, buddy</i>"
    
    aa_equals "" [ad_html_text_convert -from "text/enhanced" -to "text/html" -truncate_len 14 -- $string] \
        [ad_enhanced_text_to_html "What?\n<i>Never</I>..."]

    # The string is longer in plaintext, because the "_" symbol to denote italics is counted as well.
    aa_equals "" [ad_html_text_convert -from "text/enhanced" -to "text/plain" -truncate_len 15 -- $string] "What?\n_Never..."

    #----------------------------------------------------------------------
    # from text/plain
    #----------------------------------------------------------------------

    set string "What?\nNever mind, buddy"
    
    aa_equals "" [ad_html_text_convert -from "text/plain" -to "text/html" -truncate_len 14 -- $string] \
        [ad_text_to_html "What?\nNever..."]
    
    aa_equals "" [ad_html_text_convert -from "text/plain" -to "text/plain" -truncate_len 14 -- $string] \
        "What?\nNever..."
    
    #----------------------------------------------------------------------
    # from text/fixed-width
    #----------------------------------------------------------------------

    set string "What?\nNever mind, buddy"
    
    aa_equals "" [ad_html_text_convert -from "text/fixed-width" -to "text/html" -truncate_len 14 -- $string] \
        "<pre>What?\nNever</PRE>..."
    
    aa_equals "" [ad_html_text_convert -from "text/fixed-width" -to "text/plain" -truncate_len 14 -- $string] \
        "What?\nNever..."
    

    #----------------------------------------------------------------------
    # from text/html
    #----------------------------------------------------------------------

    set string "What?<br><i>Never mind, buddy</i>"
    
    aa_equals "" [ad_html_text_convert -from "text/html" -to "text/html" -truncate_len 14 -- $string] \
        "What?<br><i>Never</I>..."
    
    aa_equals "" [ad_html_text_convert -from "text/html" -to "text/plain" -truncate_len 15 -- $string] \
        "What?\n_Never..."

    set long_string [string repeat "Very long text. " 10]
    aa_equals "No truncation" [ad_html_text_convert -from "text/html" -to "text/html" -truncate_len [string length $long_string] -- $long_string] $long_string

}

aa_register_case -cats {api smoke} string_truncate {
    Testing string truncation
} {
    aa_equals "" [string_truncate -len  5 -ellipsis "" -- "foobar greble"] ""
    aa_equals "" [string_truncate -len  6 -ellipsis "" -- "foobar greble"] "foobar"
    aa_equals "" [string_truncate -len  7 -ellipsis "" -- "foobar greble"] "foobar"
    aa_equals "" [string_truncate -len  8 -ellipsis "" -- "foobar greble"] "foobar"
    aa_equals "" [string_truncate -len  9 -ellipsis "" -- "foobar greble"] "foobar"
    aa_equals "" [string_truncate -len 10 -ellipsis "" -- "foobar greble"] "foobar"
    aa_equals "" [string_truncate -len 11 -ellipsis "" -- "foobar greble"] "foobar"
    aa_equals "" [string_truncate -len 12 -ellipsis "" -- "foobar greble"] "foobar"
    aa_equals "" [string_truncate -len 13 -ellipsis "" -- "foobar greble"] "foobar greble"

    set long_string [string repeat "Very long text. " 100]
    aa_equals "No truncation" [string_truncate -len [string length $long_string] -- $long_string] $long_string

}
