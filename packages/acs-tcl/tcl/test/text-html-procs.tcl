ad_library {

    Tests that deal with the html - text procs

    @creation-date 2017-01-12
}


aa_register_case \
    -cats {web api smoke} \
    -procs {ad_dom_sanitize_html} \
    ad_dom_sanitize_html {

    Test if it HTML sanitization works as expected

} {

    # - Weird HTML, nonexistent and unclosed tags, '<' and '>' chars:
    #   result should be ok, with '<' and '>' converted to entities
    lappend test_msgs "Test case 1: invalid markup with single '<' and '>' chars ok"
    lappend test_cases {<noexist>sadsa</noexist> dfsdafs <a> 3 > 2 dfsdfasdfsdfsad  sasasadsasa <    sadASDSA}
    lappend test_results_trivial {<noexist>sadsa</noexist> dfsdafs <a> 3 &gt; 2 dfsdfasdfsdfsad  sasasadsasa &lt;    sadASDSA</a>}
    lappend test_results_no_js {<noexist>sadsa</noexist> dfsdafs <a> 3 &gt; 2 dfsdfasdfsdfsad  sasasadsasa &lt;    sadASDSA</a>}
    lappend test_results_no_outer_urls {<noexist>sadsa</noexist> dfsdafs <a> 3 &gt; 2 dfsdfasdfsdfsad  sasasadsasa &lt;    sadASDSA</a>}
    lappend test_results_fixing_markup {<noexist>sadsa</noexist> dfsdafs <a> 3 &gt; 2 dfsdfasdfsdfsad  sasasadsasa &lt;    sadASDSA</a>}

    # - Weird HTML, nonexistent and unclosed tags, MULTIPLE '<' and '>' chars:
    #   some loss in translation, multiple '<' and '>' become single ones
    lappend test_msgs "Test case 2: invalid markup with multiple '<' and '>' chars ok"
    lappend test_cases {
        <noexist>sadsa</noexist> dfsdafs <a></a> 3 < 2 dfsdfasdfsdfsad <<<<<<<<<< a <<< a << <<< << sasasadsasa <    sadASDSA
    }
    lappend test_results_trivial {
        <noexist>sadsa</noexist> dfsdafs <a></a> 3 &lt; 2 dfsdfasdfsdfsad &lt; a &lt; a &lt; sasasadsasa &lt;    sadASDSA
    }
    lappend test_results_no_js {
        <noexist>sadsa</noexist> dfsdafs <a></a> 3 &lt; 2 dfsdfasdfsdfsad &lt; a &lt; a &lt; sasasadsasa &lt;    sadASDSA
    }
    lappend test_results_no_outer_urls {
        <noexist>sadsa</noexist> dfsdafs <a></a> 3 &lt; 2 dfsdfasdfsdfsad &lt; a &lt; a &lt; sasasadsasa &lt;    sadASDSA
    }
    lappend test_results_fixing_markup {
        <noexist>sadsa</noexist> dfsdafs <a></a> 3 &lt; 2 dfsdfasdfsdfsad &lt; a &lt; a &lt; sasasadsasa &lt;    sadASDSA
    }

    # - Half opened HTML into other markup: this markup will be completely rejected
    lappend test_msgs "Test case 3: invalid unparseable markup ok"
    lappend test_cases {
        <noexist>sadsa</noexist> dfsdafs <a><tag</a> 3 sadASDSA
    }
    lappend test_results_trivial {}
    lappend test_results_no_js {}
    lappend test_results_no_outer_urls {}
    lappend test_results_fixing_markup {}

    # - Formally invalid HTML: this markup will be rejected when the
    #   fix option is not enabled and parsed otherwise. Internal
    #   blank space into tags will be lost.
    lappend test_msgs "Test case 4: formally invalid markup ok"
    lappend test_cases {<div a %%> fooo <a>}
    lappend test_results_trivial {}
    lappend test_results_no_js {}
    lappend test_results_no_outer_urls {}
    lappend test_results_fixing_markup "<div a=\"\">fooo<a></a>\n</div>"

    # - Plain text: this should stay as it is
    lappend test_msgs "Test case 5: plain text ok"
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
    lappend test_results_trivial $test_case
    lappend test_results_no_js $test_case
    lappend test_results_no_outer_urls $test_case
    lappend test_results_fixing_markup $test_case    

    # Try test cases allowing all kind of markup
    foreach \
        msg          $test_msgs \
        test_case    $test_cases \
        test_result  $test_results_trivial {
            set result [ad_dom_sanitize_html -html $test_case \
                            -allowed_tags * \
                            -allowed_attributes * \
                            -allowed_protocols *]
            set result [string trim $result]
            set test_result [string trim $test_result]
            aa_true "$msg trivial?" {$result eq $test_result}
        }

    # Try test cases not allowing js
    foreach \
        msg          $test_msgs \
        test_case    $test_cases \
        test_result  $test_results_no_js {
            set result [ad_dom_sanitize_html -html $test_case \
                            -allowed_tags * \
                            -allowed_attributes * \
                            -allowed_protocols * \
                            -no_js]
            set result [string trim $result]
            set test_result [string trim $test_result]
            aa_true "$msg no js?" {$result eq $test_result}
        }

    # Try test cases not allowing outer URLs
    foreach \
        msg          $test_msgs \
        test_case    $test_cases \
        test_result  $test_results_no_outer_urls {
            set result [ad_dom_sanitize_html -html $test_case \
                            -allowed_tags * \
                            -allowed_attributes * \
                            -allowed_protocols * \
                            -no_outer_urls]
            set result [string trim $result]
            set test_result [string trim $test_result]
            aa_true "$msg no outer URLs?" {$result eq $test_result}
        }

    # Try test cases fixing markup
    foreach \
        msg          $test_msgs \
        test_case    $test_cases \
        test_result  $test_results_fixing_markup {
            set result [ad_dom_sanitize_html -html $test_case \
                            -allowed_tags * \
                            -allowed_attributes * \
                            -allowed_protocols * \
                            -fix]
            set result [string trim $result]
            set test_result [string trim $test_result]
            aa_true "$msg fixing markup?" {$result eq $test_result}
        }
    
    set d [acs::test::http /]
    aa_equals "Start page of current server: Status code valid" [dict get $d status] 200

    set test_case [dict get $d body]

    set msg "Test case 6: in our index page is removing tags ok"
    set unallowed_tags {div style script}
    set result [ad_dom_sanitize_html -html $test_case \
                    -allowed_tags * \
                    -allowed_attributes * \
                    -allowed_protocols * \
                    -unallowed_tags $unallowed_tags]
    set valid_p [ad_dom_sanitize_html -html $result \
                     -allowed_tags * \
                     -allowed_attributes * \
                     -allowed_protocols * \
                     -unallowed_tags $unallowed_tags \
                     -validate]
    aa_true "$msg with validate?" $valid_p    
    aa_false $msg? [regexp {<(div|style|script)\s*[^>]*>} $result]

    set msg "In our index page is removing attributes ok"
    set unallowed_attributes {id style}
    set result [ad_dom_sanitize_html -html $test_case \
                    -allowed_tags * \
                    -allowed_attributes * \
                    -allowed_protocols * \
                    -unallowed_attributes $unallowed_attributes]
    set valid_p [ad_dom_sanitize_html -html $result \
                     -allowed_tags * \
                     -allowed_attributes * \
                     -allowed_protocols * \
                     -unallowed_attributes $unallowed_attributes \
                     -validate]
    aa_true "$msg with validate?" $valid_p
    aa_false $msg? [regexp {<([a-z]\w*)\s+[^>]*(id|style)=".*"[^>]*>} $result]

    set msg "In our index page is removing protocols ok"
    set unallowed_protocols {http javascript https}
    set result [ad_dom_sanitize_html -html $test_case \
                    -allowed_tags * \
                    -allowed_attributes * \
                    -allowed_protocols * \
                    -unallowed_protocols $unallowed_protocols]
    set valid_p [ad_dom_sanitize_html -html $result \
                     -allowed_tags * \
                     -allowed_attributes * \
                     -allowed_protocols * \
                     -unallowed_protocols $unallowed_protocols \
                     -validate]
    aa_true "$msg with validate?" $valid_p    
    aa_false $msg? [regexp {<([a-z]\w*)\s+[^>]*(href|src|content|action)="(http|javascript):.*"[^>]*>} $result]

    set msg "In our index page is removing outer links ok"
    set result [ad_dom_sanitize_html -html $test_case \
                    -allowed_tags * \
                    -allowed_attributes * \
                    -allowed_protocols * \
                    -no_outer_urls]
    set valid_p [ad_dom_sanitize_html -html $result \
                     -allowed_tags * \
                     -allowed_attributes * \
                     -allowed_protocols * \
                     -no_outer_urls \
                     -validate]
    aa_true "$msg with validate?" $valid_p
    aa_false $msg? [regexp {<([a-z]\w*)\s+[^>]*(href|src|content|action)="(http|https|//):.*"[^>]*>} $result]

}

aa_register_case \
    -cats {api smoke} \
    -procs {ad_js_escape} \
    ad_js_escape {

    Test if ad_js_escape is working as expected

} {
    set string "\"\"\"\"\"\'"
    aa_true " - String of only quotes " {[ad_js_escape $string] eq {\"\"\"\"\"\'}}

    set string   "\n\r\t  \n\n\n \t\t \b \v\v\v  \f"
    set expected {\n\r\t  \n\n\n \t\t \b \v\v\v  \f}
    
    aa_true " - String of only escape sequences " {[ad_js_escape $string] eq $expected}

    set string   "\n\r\t  \na word  \'\n\n \t\"\" aaaaa\' \'\'\'\b \v\v\v  \f"
    set expected {\n\r\t  \na word  \'\n\n \t\"\" aaaaa\' \'\'\'\b \v\v\v  \f}

    ns_log notice EXP:<$expected>
    ns_log notice GOT:<[ad_js_escape $string]>

    aa_true " - String of escape sequences, quotes and text (with some quotes already escaped)" \
        {[ad_js_escape $string] eq $expected}
}

aa_register_case \
    -cats {api smoke} \
    -procs {ad_pad} \
    ad_pad {

    Test if ad_pad is working as expected

} {
    
    aa_section "Testing left pad"

    set string [ad_generate_random_string]
    set length [expr {int(rand()*1000)}]
    set padstring [ad_generate_random_string]

    aa_log " - string: $string"
    aa_log " - length: $length"
    aa_log " - padstring: $padstring"
    
    set result [ad_pad -left $string $length $padstring]

    aa_true " - Result is exactly $length long " {[string length $result] == $length}
    aa_true " - String is at right end " [regexp "^.*${string}\$" $result]

    aa_section "Testing right pad"

    set string [ad_generate_random_string]
    set length [expr {int(rand()*1000)}]
    set padstring [ad_generate_random_string]

    aa_log " - string: $string"
    aa_log " - length: $length"
    aa_log " - padstring: $padstring"
    
    set result [ad_pad -right $string $length $padstring]

    aa_true " - Result is exactly $length long " {[string length $result] == $length}
    aa_true " - String is at left end " [regexp "^${string}.*\$" $result]
    
}

aa_register_case \
    -cats {api smoke} \
    -procs {ad_html_qualify_links} \
    ad_html_qualify_links {

        Test if ad_html_qualify_links is working as expected.
        
        @author Gustaf Neumann
} {
    
    aa_section "Testing without path"

    set rURL "relative/r.txt"
    set aURL "/dotlrn/clubs/club1/mytext.docx"
    set fqURL "https://openacs.org/doc/"
    
    set html [subst {<div><div class="table">
        A relative URL <a href="$rURL">relative/r.txt</a>
        An absolute URL <a href="$aURL">mytext.docx</a>
        A fully qualified URL <a href="$fqURL">Documentation</a>        
    }]
    set result [ad_html_qualify_links -location {http://myhost/} $html]

    aa_true "result contains relative URL NOT expanded" {[string match *href=\"$rURL* $result]}
    aa_true "result contains absolute URL location-prefixed" {[string match *http://myhost$aURL* $result]}
    aa_true "result contains fully qualified URL" {[string match *$fqURL* $result]}

    aa_section "Testing with path"

    set pretty_link "/dotlrn/clubs/club2/uploads/mytext.docx"
    set result [ad_html_qualify_links -location {http://myhost/} -path /somepath $html]

    aa_true "result contains relative URL expanded" {[string match */somepath/$rURL* $result]}
    aa_true "result contains absolute URL location-prefixed" {[string match *http://myhost$aURL* $result]}
    aa_true "result contains fully qualified URL" {[string match *$fqURL* $result]}

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
