ad_library {

    Tests that deal with the html - text procs

    @creation-date 2017-01-12
}


aa_register_case -cats {api smoke} ad_sanitize_html {

    Test if it HTML sanitization works as expected

} {

    # - Weird HTML, nonexistent and unclosed tags, '<' and '>' chars:
    #   result should be ok, with '<' and '>' converted to entities
    lappend test_msgs "Invalid markup with single '<' and '>' chars ok?"
    lappend test_cases {<noexist>sadsa</noexist> dfsdafs <a> 3 > 2 dfsdfasdfsdfsad  sasasadsasa <    sadASDSA}
    lappend test_result_trivial {<noexist>sadsa</noexist> dfsdafs <a> 3 &gt; 2 dfsdfasdfsdfsad  sasasadsasa &lt;    sadASDSA</a>}
    lappend test_result_no_js {<noexist>sadsa</noexist> dfsdafs <a> 3 &gt; 2 dfsdfasdfsdfsad  sasasadsasa &lt;    sadASDSA</a>}
    lappend test_result_no_outer_urls {<noexist>sadsa</noexist> dfsdafs <a> 3 &gt; 2 dfsdfasdfsdfsad  sasasadsasa &lt;    sadASDSA</a>}

    # - Weird HTML, nonexistent and unclosed tags, MULTIPLE '<' and '>' chars:
    #   some loss in translation, multiple '<' and '>' become single ones
    lappend test_msgs "Invalid markup with multiple '<' and '>' chars ok?"
    lappend test_cases {
        <noexist>sadsa</noexist> dfsdafs <a></a> 3 < 2 dfsdfasdfsdfsad <<<<<<<<<< a <<< a << <<< << sasasadsasa <    sadASDSA
    }
    lappend test_result_trivial {
        <noexist>sadsa</noexist> dfsdafs <a></a> 3 &lt; 2 dfsdfasdfsdfsad &lt; a &lt; a &lt; sasasadsasa &lt;    sadASDSA
    }
    lappend test_result_no_js {
        <noexist>sadsa</noexist> dfsdafs <a></a> 3 &lt; 2 dfsdfasdfsdfsad &lt; a &lt; a &lt; sasasadsasa &lt;    sadASDSA
    }
    lappend test_result_no_outer_urls {
        <noexist>sadsa</noexist> dfsdafs <a></a> 3 &lt; 2 dfsdfasdfsdfsad &lt; a &lt; a &lt; sasasadsasa &lt;    sadASDSA
    }

    # - Half opened HTML into other markup: this markup will be completely rejected
    lappend test_msgs "Invalid unparseable markup ok?"
    lappend test_cases {
        <noexist>sadsa</noexist> dfsdafs <a><tag</a> 3 sadASDSA
    }
    lappend test_result_trivial {}
    lappend test_result_no_js {}
    lappend test_result_no_outer_urls {}

    # - Plain text: this should stay as it is
    lappend test_msgs "Plain text ok?"
    set test_case {
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed
        do eiusmod tempor incididunt ut labore et dolore magna
        aliqua. Ut enim ad minim veniam, quis nostrud exercitation
        ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis
        aute irure dolor in reprehenderit in voluptate velit esse
        cillum dolore eu fugiat nulla pariatur. Excepteur sint
        occaecat cupidatat non proident, sunt in culpa qui officia
        deserunt mollit anim id est laborum.
    }
    lappend test_cases $test_case
    lappend test_result_trivial $test_case
    lappend test_result_no_js $test_case
    lappend test_result_no_outer_urls $test_case

    foreach msg $test_msgs test_case $test_cases result_trivial $test_result_trivial result_no_js $test_result_no_js result_no_outer_urls $test_result_no_outer_urls {
        set result [ad_sanitize_html -html $test_case -allowed_tags * -allowed_attributes * -allowed_protocols *]
        set result [string trim $result] ; set result_trivial [string trim $result_trivial]
        aa_true $msg [expr {$result eq $result_trivial}]
        set result [ad_sanitize_html -html $test_case -allowed_tags * -allowed_attributes * -allowed_protocols * -no_js]
        set result [string trim $result] ; set result_no_js [string trim $result_no_js]
        aa_true $msg [expr {$result eq $result_no_js}]
        set result [ad_sanitize_html -html $test_case -allowed_tags * -allowed_attributes * -allowed_protocols * -no_outer_urls]
        set result [string trim $result] ; set result_no_outer_urls [string trim $result_no_outer_urls]
        aa_true $msg [expr {$result eq $result_no_outer_urls}]
    }

    array set r [util::http::get -url [util::configured_location]]
    set test_case $r(page)

    set msg "In our index page is removing tags ok"
    set unallowed_tags {div style script}
    set result [ad_sanitize_html -html $test_case -allowed_tags * -allowed_attributes * -allowed_protocols * -unallowed_tags $unallowed_tags]
    set valid_p [ad_sanitize_html -html $result -allowed_tags * -allowed_attributes * -allowed_protocols * -unallowed_tags $unallowed_tags -validate]
    aa_true "$msg with validate?" $valid_p    
    aa_false $msg? [regexp {<(div|style|script)\s*[^>]*>} $result]

    set msg "In our index page is removing attributes ok"
    set unallowed_attributes {id style}
    set result [ad_sanitize_html -html $test_case -allowed_tags * -allowed_attributes * -allowed_protocols * -unallowed_attributes $unallowed_attributes]
    set valid_p [ad_sanitize_html -html $result -allowed_tags * -allowed_attributes * -allowed_protocols * -unallowed_attributes $unallowed_attributes -validate]
    aa_true "$msg with validate?" $valid_p
    aa_false $msg? [regexp {<([a-z]\w*)\s+[^>]*(id|style)=".*"[^>]*>} $result]

    set msg "In our index page is removing protocols ok?"
    set unallowed_protocols {http javascript https}
    set result [ad_sanitize_html -html $test_case -allowed_tags * -allowed_attributes * -allowed_protocols * -unallowed_protocols $unallowed_protocols]
    set valid_p [ad_sanitize_html -html $result -allowed_tags * -allowed_attributes * -allowed_protocols * -unallowed_protocols $unallowed_protocols -validate]
    aa_true "$msg with validate?" $valid_p    
    aa_false $msg? [regexp {<([a-z]\w*)\s+[^>]*(href|src|content|action)="(http|javascript):.*"[^>]*>} $result]

    set msg "In our index page is removing outer links ok?"
    set result [ad_sanitize_html -html $test_case -allowed_tags * -allowed_attributes * -allowed_protocols * -no_outer_urls]
    set valid_p [ad_sanitize_html -html $result -allowed_tags * -allowed_attributes * -allowed_protocols * -no_outer_urls -validate]
    aa_true "$msg with validate?" $valid_p    
    aa_false $msg? [regexp {<([a-z]\w*)\s+[^>]*(href|src|content|action)="(http|https|//):.*"[^>]*>} $result]

}



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
