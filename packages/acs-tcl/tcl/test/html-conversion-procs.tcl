ad_library {
    
    Tests that deal with the html parsing procs of openacs.

    @creation-date 15 November 2003
}


aa_register_case ad_html_to_text_bold {

    Test if it converts b tags correctly.

} {

    set html "Some <b>bold</b> test"

    set result [ad_html_to_text $html]

    aa_true "contains asterisks?" [regexp {\*bold\*} $result]

}


aa_register_case ad_html_to_text_clipped_link {

    Test if it converts clipped links.

    http://openacs.org/bugtracker/openacs/bug?bug_number=386
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


aa_register_case ad_html_security_check_href_allowed {
    tests is href attribute is allowed of A tags
} {
    set html "<a href=\"http://www.example/com\">An Link</a>"
    aa_true "href is allowed for A tags" [string equal [ad_html_security_check $html] ""]
}