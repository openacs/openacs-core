ad_library {

    Tests that deal with the html parsing procs of openacs.

    @creation-date 15 November 2003
}


aa_register_case \
    -cats {api smoke} \
    -procs {ad_html_to_text} \
    ad_html_to_text_bold {

    Test if it converts "b" tags correctly.

} {
    set html "Some <b>bold</b> test"
    set result [ad_html_to_text -- $html]
    aa_true "contains asterisks?" [regexp {\*bold\*} $result]
}

aa_register_case \
    -cats {api smoke} \
    -procs {ad_html_to_text} \
    ad_html_to_text_anchor {

    Test if it converts "a" tags correctly.

} {
    set html {
        This is a text with an <a name='foo'>anchor</a>
        and a <a href='#foo'>reference</a>
        and an empty <a href="">href</a>
        and a regular <a href='https://openacs.org' title='OpenACS main site'>link</a>.
    }
    set result [ad_html_to_text -- $html]
    aa_log "<pre>$result</pre>"
    aa_true "contains link \[1\]" [string match {*\[1\]*} $result]
    aa_false "contains link \[2\]" [string match {*\[2\]*} $result]
    aa_true "contains link title" [string match {*OpenACS main site*} $result]
}

aa_register_case \
    -cats {api smoke} \
    -procs {ad_html_to_text} \
    ad_html_to_text_image {

    Test if it converts "img" tags correctly.

} {
    set html {
        This is a text with an regular image <img src="/images/foo.png">,
        image with alt text <img src="/images/bar.png" alt="flower">,
        and an embedded image <img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEU..."
        alt='embedded'>.
    }
    set result [ad_html_to_text -- $html]
    aa_log "<pre>$result</pre>"
    aa_true "contains image" [string match {*\[IMAGE: /images*} $result]
    aa_true "contains alt text" [string match {*\[IMAGE: 'flower'*} $result]
    aa_true "contains embedded image abbreviated" [string match {*\[IMAGE:*data:...*} $result]
}


aa_register_case \
    -cats {api smoke} \
    -bugs 386 \
    -error_level warning \
    -procs {ad_html_to_text} \
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
        set result [ad_html_to_text -- $html]

        # make sure the desired text is in there and _before_ the
        # footnotes

        aa_true "contains link" [regexp {linktext.*\[1\]} $result]
        aa_true "contains following text" [regexp {following text.*\[1\]} $result]
    }
}


aa_register_case \
    -cats {api smoke} \
    -procs {ad_html_security_check} \
    ad_html_security_check_href_allowed {
    tests is href attribute is allowed of A tags
} {
    set html "<a href=\"http://www.example/com\">An Link</a>"
    aa_equals "href is allowed for A tags" [ad_html_security_check $html] ""
}

aa_register_case \
    -cats {api smoke} \
    -procs {util_close_html_tags} \
    util_close_html_tags {
    Tests closing HTML tags.
} {
    aa_equals "" [util_close_html_tags "<b>Foobar"] "<b>Foobar</b>"
    aa_equals "" [util_close_html_tags "<b>Foobar</b>"] "<b>Foobar</b>"
    aa_equals "" [util_close_html_tags "<b>Foobar</b> is <i>a very long word</i>"] "<b>Foobar</b> is <i>a very long word</i>"
    aa_equals "" [util_close_html_tags "<b>Foobar</b> is <i>a very long word</i>" 15] "<b>Foobar</b> is <i>a</i>"
    aa_equals "" [util_close_html_tags "<b>Foobar</b> is <i>a very long word</i>" 0 20 "..."] "<b>Foobar</b> is <i>a very</i>..."
}


aa_register_case \
    -cats {api smoke} \
    -procs {ad_html_text_convert ad_enhanced_text_to_html} \
    ad_html_text_convert {
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
    # from text/markdown
    #----------------------------------------------------------------------

    if {![catch {package present Markdown}]} {
        set string "What?\n*Never mind, buddy*"

        aa_equals "" [ad_html_text_convert -from "text/markdown" -to "text/html" -truncate_len 14 -- $string] \
            "What?\n<i>Never</i>..."

        aa_equals "" [ad_html_text_convert -from "text/markdown" -to "text/plain" -truncate_len 15 -- $string] \
            "What?\n_Never..."
    }

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
    aa_equals "No truncation" \
        [ad_html_text_convert \
             -from "text/html" \
             -to "text/html" \
             -truncate_len [string length $long_string] \
             -- \
             $long_string] \
        $long_string

}

aa_register_case \
    -cats {api smoke} \
    -procs {string_truncate} \
    string_truncate {
    Testing string truncation
} {
    aa_equals "" [string_truncate -len  5 -ellipsis "" -- "foo"] "foo"
    aa_equals "" [string_truncate -len  5 -ellipsis "" -- "foobar greble"] "fooba"
    aa_equals "" [string_truncate -len  6 -ellipsis "" -- "foobar greble"] "foobar"
    aa_equals "" [string_truncate -len  7 -ellipsis "" -- "foobar greble"] "foobar"
    aa_equals "" [string_truncate -len  7 -ellipsis "" -- "foobar\tgreble"] "foobar"
    aa_equals "" [string_truncate -len  7 -ellipsis "" -- "foobar\ngreble"] "foobar"
    aa_equals "" [string_truncate -len  7 -ellipsis "" -- "foobar\rgreble"] "foobar"
    aa_equals "" [string_truncate -len  7 -ellipsis "" -- "foobar\fgreble"] "foobar"
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


aa_register_case \
    -cats {api smoke} \
    -procs {util_convert_line_breaks_to_html} \
    util_convert_line_breaks_to_html {
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


aa_register_case \
    -cats {api smoke} \
    -procs {ad_unquotehtml} \
    quote_unquote_html {
    Test if it quote and unquote html
} {
    #quote html
    set html {"<&text>"}
    aa_log "Unquote html=$html"
    set result [ns_quotehtml $html]
    aa_equals "Quoute html=$result"  "&#34;&lt;&amp;text&gt;&#34;" $result

    #unquote html
    set html $result
    aa_log "Quote html=$html"
    set result [ad_unquotehtml $html]
    aa_equals "Unquote html=$result" "\"<&text>\"" $result
}

aa_register_case \
    -cats {api smoke} \
    -procs {ad_looks_like_html_p} \
    ad_looks_like_html_p {
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

aa_register_case \
    -cats {api smoke} \
    -procs {util_remove_html_tags} \
    util_remove_html_tags {
    Test if it remove all between tags
} {
    set html "<p><b>some</b> text <i>to</i> probe if it <table><tr>remove all between \"<\" and \">\"<tr><table><tags>"
    set result [util_remove_html_tags $html]
    aa_equals "Without all between \"<\" and \">\" html=\"$result\""\
        "some text to probe if it remove all between \"\"" $result
}

aa_register_case \
    -cats {api smoke} \
    -procs {ad_parse_html_attributes} \
    ad_parse_html_attributes {
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

aa_register_case \
    -cats {api smoke} \
    -procs {ad_html_text_convert} \
    ad_text_html_convert_outlook_word_comments {
    Test whether HTML comments inserted by MS Word are stripped
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

aa_register_case \
    -cats {api smoke} \
    -procs {ad_html_text_convert} \
    ad_text_html_convert_to_plain {
    Test rendering of a more or less standard HTML text
} {

    set html {<html><head><title>Some Title</title></head><body>
        <h1>An H1 Title</h1>
        <p>This is <b>bold</b> and this is <strong>strong</strong>.
        This is <i>italics</i> and this is <em>em</em>.
        A text with a <a href='/foo'>link</a>.
        </p>
        <h2>An H2 Title</h2>
        <p> Now the same with a blockquote:
        <blockquote>
        This is <b>bold</b> and this is <strong>strong</strong>.
        This is <i>italics</i> and this is <em>em</em>.
        A text with a <a href='/bar'>link</a>.
        </blockquote>
        Now a text with a ul:
        <ul>
        <li>First list item
        <li>Second list item
        </ul>
        Now a text with a ol:
        <ol>
        <li>First enumerated item
        <li>Second enumerated item
        </ol>

        and a program
        <pre>
        set x 1
        set r [expr {$x + 1}]
        </pre>
    }
    set result [ad_html_text_convert -from text/html -to text/plain $html]

    aa_log "Resulting text:\n$result"
    aa_true "Text contains title" [string match {Some Title*} $result]
    aa_true "<h1> and <h2> are detected and marked with stars" {
        [string first "\n*An H1" $result] > 0
        && [string first "\n**An H2" $result] > 0
    }
    aa_true "<b> and <strong> are converted" {
        [string first {*bold*} $result] > 0
        && [string first {*strong*} $result] > 0
    }
    aa_true "<i> and <em> are converted" {
        [string first {_italics_} $result] > 0
        && [string first {_em_} $result] > 0
    }
    aa_true "<ul> is converted" {
        [string first "\n- First list" $result] > 0
        && [string first "\n- Second list" $result] > 0
    }
    aa_true "<ol> is converted (same as <ul>)" {
        [string first "\n- First enumerated" $result] > 0
        && [string first "\n- Second enumerated" $result] > 0
    }

    aa_true "<pre> results in linebreaks and deeper indentation" {
        [string first "\n        set x" $result] > 0
        && [string first "\n        set r" $result] > 0
    }


    aa_true "Text contains two links" {
        [string first {[1].} $result] > 0
        && [string first {[2].} $result] > 0
    }
    aa_true "Text contains two references" {
        [string first {[1] /foo} $result] > 0
        && [string first {[2] /bar} $result] > 0
    }
    aa_true "Blockquote is indented" {
        [string first {    This is *bold} $result] > 0
    }

}

aa_register_case \
    -cats {api} \
    -bugs 1450 \
    -procs {ad_enhanced_text_to_html} \
    acs_tcl__process_enhanced_correctly {

        Process sample text correctly
        @author Nima Mazloumi
    } {

        set string_with_img {<img src="http://test.test/foo.png">}
        aa_log "Original string is $string_with_img"
        set html_version [ad_enhanced_text_to_html $string_with_img]
        aa_equals "new: $html_version should be the same" $html_version $string_with_img
}

aa_register_case \
    -cats {api smoke} \
    -procs {ad_html_to_text} \
    text_to_html {

        Test code the supposedly causes ad_html_to_text to break
} {

    # Test bad <<<'s

    set offending_post {><<<}
    set errno [catch { set text_version [ad_html_to_text -- $offending_post] } errmsg]

    if { ![aa_equals "Does not bomb" $errno 0] } {
                aa_log "errmsg: $errmsg"
        aa_log "errorInfo: $::errorInfo"
    } else {
        aa_equals "Expected identical result" $text_version $offending_post
    }

    # Test offending post sent by Dave Bauer

    set offending_post {
I have a dynamically assigned ip address, so I use dyndns.org to
change
addresses for my acs server.
Mail is sent to any yahoo address fine. Mail sent to aol fails. I am
not running a dns server on my acs box. What do I need to do to
correct this problem?<br>
Here's my error message:<blockquote>
            Mail Delivery Subsystem<br>
<MAILER-DAEMON@testdsl.homeip.net>  | Block
            Address | Add to Address Book<br>
       To:
            gmt3rd@yahoo.com<br>
 Subject:
            Returned mail: Service unavailable
<p>


The original message was received at Sat, 17 Mar 2001 11:48:57 -0500
from IDENT:nsadmin@localhost [127.0.0.1]
<br>
   ----- The following addresses had permanent fatal errors -----
gmt3rd@aol.com
<br>
   ----- Transcript of session follows -----<p>
... while talking to mailin-04.mx.aol.com.:
<<< 550-AOL no longer accepts connections from dynamically assigned
<<< 550-IP addresses to our relay servers.  Please contact your ISP
<<< 550 to have your mail redirected through your ISP's SMTP servers.
... while talking to mailin-02.mx.aol.com.:
>>> QUIT
<p>

                              Attachment: Message/delivery-status

Reporting-MTA: dns; testdsl.homeip.net
Received-From-MTA: DNS; localhost
Arrival-Date: Sat, 17 Mar 2001 11:48:57 -0500

Final-Recipient: RFC822; gmt3rd@aol.com
Action: failed
Status: 5.5.0
Remote-MTA: DNS; mailin-01.mx.aol.com
Diagnostic-Code: SMTP; 550-AOL no longer accepts connections from
dynamically assigned
Last-Attempt-Date: Sat, 17 Mar 2001 11:48:57 -0500

</blockquote>
<p>
anybody have any ideas?
    }

    set errno [catch { set text_version [ad_html_to_text -- $offending_post] } errmsg]

    if { ![aa_equals "Does not bomb" $errno 0] } {
        aa_log "errmsg: $errmsg"
        aa_log "errorInfo: $::errorInfo"
    } else {
        aa_log "Text version: $text_version"
    }

    # Test placement of [1] reference
    set html {Here is <a href="http://openacs.org">http://openacs.org</a> my friend}

    set text_version [ad_html_to_text -- $html]

    aa_log "Text version: $text_version"
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
