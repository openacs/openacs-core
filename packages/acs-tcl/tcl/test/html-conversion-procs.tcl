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
    aa_equals "" [util_close_html_tags "<b>Foobar"] "<b>Foobar</b>"

    aa_equals "" [util_close_html_tags "<b>Foobar</b>"] "<b>Foobar</b>"

    aa_equals "" [util_close_html_tags "<b>Foobar</b> is <i>a very long word</i>"] "<b>Foobar</b> is <i>a very long word</i>"

    aa_equals "" [util_close_html_tags "<b>Foobar</b> is <i>a very long word</i>" 15] "<b>Foobar</b> is <i>a</i>"

    aa_equals "" [util_close_html_tags "<b>Foobar</b> is <i>a very long word</i>" 0 20 "..."] "<b>Foobar</b> is <i>a very</i>..."
}


aa_register_case -cats {api smoke} ad_html_text_convert {
    Testing ad_html_text_convert.
} {
    #----------------------------------------------------------------------
    # from text/enhanced
    #----------------------------------------------------------------------
    
    set string "What?\n<i>Never mind, buddy</i>"
    
    aa_equals "" [ad_html_text_convert -from "text/enhanced" -to "text/html" -truncate_len 14 -- $string] \
        [ad_enhanced_text_to_html "What?\n<i>Never</i>..."]

    # The string is longer in plaintext, because the "_" symbol to denote italics is counted as well.
    aa_equals "" [ad_html_text_convert -from "text/enhanced" -to "text/plain" -truncate_len 15 -- $string] "What?\n_Never..."

    #----------------------------------------------------------------------
    # from text/plain
    #----------------------------------------------------------------------

    set string "What?\nNever mind, buddy"
    
    aa_equals "" [ad_html_text_convert -from "text/plain" -to "text/html" -truncate_len 14 -- $string] \
        "What?<br>\nNever..."
    
    aa_equals "" [ad_html_text_convert -from "text/plain" -to "text/plain" -truncate_len 14 -- $string] \
        "What?\nNever..."
    
    #----------------------------------------------------------------------
    # from text/fixed-width
    #----------------------------------------------------------------------

    set string "What?\nNever mind, buddy"
    
    aa_equals "" [ad_html_text_convert -from "text/fixed-width" -to "text/html" -truncate_len 14 -- $string] \
        "<pre>What?\nNever</pre>..."
    
    aa_equals "" [ad_html_text_convert -from "text/fixed-width" -to "text/plain" -truncate_len 14 -- $string] \
        "What?\nNever..."
    

    #----------------------------------------------------------------------
    # from text/html
    #----------------------------------------------------------------------

    set string "What?<br><i>Never mind, buddy</i>"
    
    aa_equals "" [ad_html_text_convert -from "text/html" -to "text/html" -truncate_len 14 -- $string] \
        "What?<br><i>Never</i>..."
    
    aa_equals "" [ad_html_text_convert -from "text/html" -to "text/plain" -truncate_len 15 -- $string] \
        "What?\n_Never..."

    set long_string [string repeat "Very long text. " 10]
    aa_equals "No truncation" [ad_html_text_convert -from "text/html" -to "text/html" -truncate_len [string length $long_string] -- $long_string] $long_string

}

aa_register_case -cats {api smoke} string_truncate {
    Testing string truncation
} {
    aa_equals "" [string_truncate -len  5 -ellipsis "" -- "foo"] "foo"
    aa_equals "" [string_truncate -len  5 -ellipsis "" -- "foobar greble"] "fooba"
    aa_equals "" [string_truncate -len  6 -ellipsis "" -- "foobar greble"] "foobar"
    aa_equals "" [string_truncate -len  7 -ellipsis "" -- "foobar greble"] "foobar"
    aa_equals "" [string_truncate -len  8 -ellipsis "" -- "foobar greble"] "foobar"
    aa_equals "" [string_truncate -len  9 -ellipsis "" -- "foobar greble"] "foobar"
    aa_equals "" [string_truncate -len 10 -ellipsis "" -- "foobar greble"] "foobar"
    aa_equals "" [string_truncate -len 11 -ellipsis "" -- "foobar greble"] "foobar"
    aa_equals "" [string_truncate -len 12 -ellipsis "" -- "foobar greble"] "foobar"
    aa_equals "" [string_truncate -len 13 -ellipsis "" -- "foobar greble"] "foobar greble"

    aa_equals "" [string_truncate -len  5 -ellipsis "..." -- "foo"] "foo"
    aa_equals "" [string_truncate -len  5 -ellipsis "..." -- "foobar greble"] "fo..."
    aa_equals "" [string_truncate -len  6 -ellipsis "..." -- "foobar greble"] "foo..."
    aa_equals "" [string_truncate -len  7 -ellipsis "..." -- "foobar greble"] "foob..."
    aa_equals "" [string_truncate -len  8 -ellipsis "..." -- "foobar greble"] "fooba..."
    aa_equals "" [string_truncate -len  9 -ellipsis "..." -- "foobar greble"] "foobar..."
    aa_equals "" [string_truncate -len 10 -ellipsis "..." -- "foobar greble"] "foobar..."
    aa_equals "" [string_truncate -len 11 -ellipsis "..." -- "foobar greble"] "foobar..."
    aa_equals "" [string_truncate -len 12 -ellipsis "..." -- "foobar greble"] "foobar..."
    aa_equals "" [string_truncate -len 13 -ellipsis "..." -- "foobar greble"] "foobar greble"

    set long_string [string repeat "Very long text. " 100]
    aa_equals "No truncation" [string_truncate -len [string length $long_string] -- $long_string] $long_string

}

aa_register_case -cats {api smoke} -procs {util_convert_line_breaks_to_html} util_convert_line_breaks_to_html {
    Test if it converts spaces and line breaks correctly.
} {
    #Convert leading and trailing spaces or tabs
    set html "\tinter spaces  "
    aa_log "html= \"$html\" - Contains tabs and spaces"
    set result [util_convert_line_breaks_to_html $html]
    aa_false "Now html=\"$result\"" [regexp {\sinter spaces\s} $result]

    #convert single break
    set html "\r\n inter\r\nbreaks \r\n"
    aa_log "html= \"$html\" - Contains a single break"
    set result [util_convert_line_breaks_to_html $html]
    aa_false "Now html=\"$result\"" [regexp {inter<b />\nspaces} $result]

    #convert paragraph break
    set html "\r\n inter\r\n\r\nbreaks \r\n"
    aa_log "html= \"$html\" - Contains a double break"
    set result [util_convert_line_breaks_to_html $html]
    aa_false "Now html=\"$result\"" [regexp {inter</p><p style="margin-bottom: 0px;">spaces} $result]

    #convert more than 2 breaks
    set html "\r\n inter\r\n\r\n\r\nbreaks \r\n"
    aa_log "html= \"$html\" - Contains more than 2 breaks"
    set result [util_convert_line_breaks_to_html $html]
    aa_false "Now html=\"$result\"" [regexp {inter<b />\n<b />\n<b />\nspaces} $result]
}


aa_register_case -cats {api smoke} -procs {ad_quotehtml ad_unquotehtml} quote_unquote_html {
    Test if it quote and unquote html
} {
    #quote html
    set html {"<&text>"}
    aa_log "Unquote html=$html"
    set result [ns_quotehtml $html]
    aa_true "Quoute html=$result" [string equal "&#34;&lt;&amp;text&gt;&#34;" $result]

    #unquote html
    set html $result
    aa_log "Quote html=$html"
    set result [ad_unquotehtml $html]
    aa_true "Unquote html=$result" [string equal "\"<&text>\"" $result]
}

aa_register_case -cats {api smoke} -procs {ad_looks_like_html_p} ad_looks_like_html_p {
    Test if it guess the text supplied is html
} {
    set html "<a href=/home/page>Home Page</a>"
    aa_log "A link html=$html"
    aa_true "Is html text" [ad_looks_like_html_p $html]

    set html "<p> This is a paragraph</p>"
    aa_log "A paragraph html=$html"
    aa_true "Is html text" [ad_looks_like_html_p $html]

    set html "This is <BR> a short text"
    aa_log "Some text with <BR> html=$html"
    aa_true "Is html text" [ad_looks_like_html_p $html]
}

aa_register_case -cats {api smoke} -procs {util_remove_html_tags} util_remove_html_tags {
    Test if it remove all between tags
} {
    set html "<p><b>some</b> text <i>to</i> probe if it <table><tr>remove all between \"<\" and \">\"<tr><table><tags>"
    set result [util_remove_html_tags $html]
    aa_true "Without all between \"<\" and \">\" html=\"$result\""\
	[string equal "some text to probe if it remove all between \"\"" $result]
}

aa_register_case -cats {api smoke} -procs {ad_parse_html_attributes} ad_parse_html_attributes {
    Test if returns a list of attributes inside an HTML tag
} {
    set pos 5

    # Two attributes without values
    set html "<tag foo bar>"
    aa_log "A tag with two attributes without values - $html"
    set result [ad_parse_html_attributes $html $pos]
    aa_equals "Attributes - $result" $result {foo bar}

    # One Attribute with value and one whitout value
    set html "<tag foo = bar tob>"
    aa_log "A tag with one Attribute with value and one whitout value - $html"
    set result [ad_parse_html_attributes $html $pos]
    aa_equals "Attributes - $result" $result {{foo bar} tob}

    # More attributes
    set html {<tag foo = bar greeting="welcome home" ja='blah'>}
    aa_log "A tag with one attribute between quotes - $html"
    set result [ad_parse_html_attributes $html $pos]
    aa_equals "Attributes - $result" $result {{foo bar} {greeting {welcome home}} {ja blah}}
}

aa_register_case -cats {api smoke} -procs {ad_html_text_convert} ad_text_html_convert_outlook_word_comments {
    Test is MS Word HTML Comments are stripped or not
} {

    set html {<!-- standard comments -->}
    set result [ad_html_text_convert -from text/html -to text/plain $html]
    
    aa_equals "Standard HTML Comments cleaned $result" $result ""
    set html {<!--[if !mso]> v\:* {behavior:url(MESSAGE KEY MISSING: 'default'VML);} o\:*
	{behavior:url(MESSAGE KEY MISSING: 'default'VML);} w\:* {behavior:url(MESSAGE KEY MISSING: 'default'VML);}
	.shape {behavior:url(MESSAGE KEY MISSING: 'default'VML);} <![endif]--> <!-- /* Font
	Definitions */ @font-face {font-family:Wingdings; panose-1:5 0 0 0 0 0
	    0 0 0 0;} @font-face {font-family:Tahoma; panose-1:2 11 6 4 3 5 4 4 2
		4;} /* Style Definitions */ p.MsoNormal, li.MsoNormal, div.MsoNormal
	{margin:0in; margin-bottom:.0001pt; font-size:12.0pt;
	    font-family:"Times New Roman";} a:link, span.MsoHyperlink {color:blue;
		text-decoration:underline;} a:visited, span.MsoHyperlinkFollowed
	{color:blue; text-decoration:underline;} p {mso-margin-top-alt:auto;
	    margin-right:0in; mso-margin-bottom-alt:auto; margin-left:0in;
	    font-size:12.0pt; font-family:"Times New Roman";} span.EmailStyle18
	{mso-style-type:personal-reply; font-family:Arial; color:navy;} @page
	Section1 {size:8.5in 11.0in; margin:1.0in 1.25in 1.0in 1.25in;}
	div.Section1 {page:Section1;} /* List Definitions */ @list l0
	{mso-list-id:669450480; mso-list-template-ids:145939189
	    6;} @list
	l0:level1 {mso-level-number-format:bullet; mso-level-text:\F0B7;
	    mso-level-tab-stop:.5in; mso-level-number-position:left;
	    text-indent:-.25in; mso-ansi-font-size:10.0pt; font-family:Symbol;}
	@list l1 {mso-list-id:1015379521; mso-list-template-ids:-1243462522;}
	ol {margin-bottom:0in;} ul {margin-bottom:0in;} --> }

    set result [ad_html_text_convert -from text/html -to text/plain $html]
    
    aa_equals "MS Word Comments cleaned $result" $result ""

    set html {Regular Text<!-- Unclosed comment with very long content}
    set result [ad_html_text_convert -from text/html -to text/plain $html]
    aa_equals "Unclosed comment OK" $result $html

    set html {<b>Bold</b> <i>Italic</i><!-- comment -->}
    set result [ad_html_text_convert -from text/html -to text/plain $html]
    aa_equals "Some HTML with Comment ok" $result "*Bold* _Italic_"


}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
