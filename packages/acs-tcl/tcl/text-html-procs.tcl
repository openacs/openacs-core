ad_library {
    Contains procs used to manipulate chunks of text and html,
    most notably converting between them.

    @author Lars Pind (lars@pinds.com)
    @creation-date 19 July 2000
    @cvs-id $Id$
}


####################
#
# text -> HTML
#
####################

ad_proc -public ad_text_to_html {
    -no_links:boolean
    -no_lines:boolean
    -no_quote:boolean
    -includes_html:boolean
    -encode:boolean
    text
} {
    Converts plaintext to html. Also translates any recognized
    email addresses or URLs into a hyperlink.

    @param no_links will prevent it from highlighting
    @param no_quote will prevent it from HTML-quoting output, so this can be run on
    semi-HTML input and preserve that formatting. This will also cause spaces/tabs to not be
    replaced with nbsp's, because this can too easily mess up HTML tags.
    @param includes_html Set this if the text parameter already contains some HTML which should be preserved.
    @param encode This will encode international characters into its html equivalent, like "ü" into &uuml;

    @author Branimir Dolicki (branimir@arsdigita.com)
    @author Lars Pind (lars@pinds.com)
    @creation-date 19 July 2000
} {
    if { $text eq "" } {
        return ""
    }

    set space_added 0
    set nr_links 0
    if { !$no_links_p } {
        #
        # We start by putting a space in front so our URL/email
        # highlighting will work for URLs/emails right in the
        # beginning of the text.
        #
        set text " $text"
        set space_added 1

        # if something is " http://" or " https://" or "ftp://" we
        # assume it is a link to an outside source.
        #
        # (bd) The only purpose of the markers is to get rid of
        # trailing dots, commas and things like that.  Note the code
        # uses utf-8 codes \u0002 (start of text) and \u0003 (end of
        # text) special chars as marker. Previously, we had \x001 and
        # \x002, which do not work reliably (regsub was missing some
        # entries, probably due to a mess-up of the internal
        # representation).
        #
        set nr_links [regsub -nocase -all \
                          {([^a-zA-Z0-9]+)((http|https|ftp)://[^\(\)\"<>\s]+)} $text \
                          "\\1\u0002\\2\u0003" text]

        # email links have the form xxx@xxx.xxx
        #
        # JCD: don't treat things =xxx@xxx.xxx as email since most
        # common occurrence seems to be in URLs (although VPATH bounce
        # emails like bounce-user=domain.com@sourcehost.com will then
        # not work correctly).  Another tricky case is
        #     http://www.postgresql.org/message-id/20060329203545.M43728@narrowpathinc.com
        # where we do not want turn the @ into a mailto.

        incr nr_links [regsub -nocase -all \
                           {([^a-zA-Z0-9=/.]+)(mailto:)?([^=\(\)\s:;,@<>/]+@[^\(\)\s.:;,@<>]+[.][^\(\)\s:;,@<>]+)} $text \
                           "\\1\u0002mailto:\\3\u0003" text]

        #
        # Remove marker from URLs that are already HREF=... or SRC=... chunks
        #
        if { $includes_html_p && $nr_links > 0} {
            regsub -nocase -all {((href|src)\s*=\s*['\"]?)\u0002([^\u0003]*)\u0003} $text {\1\3} text
        }
    }

    # At this point, before inserting some of our own <, >, and "'s
    # we quote the ones entered by the user:
    if { !$no_quote_p } {
        set text [ns_quotehtml $text]
    }

    if { $encode_p} {
        set  myChars  {
            ª º À Á Â Ã Ä Å Æ Ç
            È É Ê Ë Ì Í Î Ï Ð Ñ
            Ò Ó Ô Õ Ö Ø Ù Ú Û Ü
            Ý Þ ß à á â ã ä å æ
            ç è é ê ë ì í î ï ð
            ñ ò ó ô õ ö ø ù ú û
            ü ý þ ÿ ¿
        }

        set  myHTML  {
            &ordf; &ordm; &Agrave; &Aacute; &Acirc; &Atilde; &Auml; &Aring; &Aelig; &Ccedil;
            &Egrave; &Eacute; &Ecirc; &Euml; &Igrave; &Iacute; &Icirc; &Iuml; &ETH; &Ntilde;
            &Ograve; &Oacute; &Ocirc; &Otilde; &Ouml; &Oslash; &Ugrave; &Uacute; &Ucirc; &Uuml;
            &Yacute; &THORN; &szlig; &agrave; &aacute; &acirc; &atilde; &auml; &aring; &aelig;
            &ccedil; &egrave; &eacute; &ecirc; &euml; &igrave; &iacute; &icirc; &iuml; &eth;
            &ntilde; &ograve; &oacute; &ocirc; &otilde; &ouml; &oslash; &ugrave; &uacute; &ucirc;
            &uuml; &yacute; &thorn; &yuml; &iquest;
        }

        set map {}
        foreach ch $myChars entity $myHTML {
            lappend map $ch $entity
        }
        set text [string map $map $text]
    }

    # Convert line breaks
    if { !$no_lines_p } {
        set text [util_convert_line_breaks_to_html -includes_html=$includes_html_p -- $text]
        # the function strips all leading white space
        set space_added 0
    }

    if { !$no_quote_p } {
        # Convert every two spaces to an nbsp
        regsub -all {  } $text "\\\&nbsp; " text

        # Convert tabs to four nbsp's
        regsub -all {\t} $text {\&nbsp;\&nbsp;\&nbsp;\&nbsp;} text
    }

    if { $nr_links > 0} {
        #
        # Move the end of the link before any punctuation marks at the
        # end of the URL.
        #
        regsub -all {([\]!?.:;,<>\(\)\}\"'-]+)(\u0003)} $text {\2\1} text

        #
        # Convert the marked links and emails into "<a href=...>..."
        #
        regsub -all {\u0002([^\u0003]+?)\u0003} $text {<a href="\1">\1</a>} text

        set changed_back [regsub -all {(\u0002|\u0003)} $text {} text]
        if {$includes_html_p} {
            #
            # All markers should be gone now.
            #
            # In case we changed something back (means something is
            # broken in our regexps above), provide a warning, we have
            # to debug.
            #
            if {$changed_back > 0} {
                ad_log warning "Replaced spurious magic marker in ad_text_to_html"
            }
        }
    }

    if {$space_added} {
        set text [string range $text 1 end]
    }

    return $text
}

ad_proc -public ad_html_qualify_links {
    -location
    -path
    html
} {

    Convert in the HTML text relative URLs into fully qualified URLs
    including the host name. It performs the following operations:

    1. prepend paths starting with a "/" by the location (protocol and host).
    2. prepend paths not starting a "/" by the path, in case it was passed in.

    Links, which are already fully qualified are not modified.

    @param location protocol and host (defaults to [ad_url])
    @param path optional path to be prepended to paths not starting with a "/"
    @param html HTML text, in which substitutions should be performed.

} {
    if {![info exists location]} {
        set location [util_current_location]
    }
    #
    # Make sure, location ends with a "/".
    #
    set location "[string trimright $location /]/"

    #
    # Protect all full qualified URLs with special characters (one
    # rule for single quotes, one for double quotes).
    #
    regsub -nocase -all \
        {(href|src)\s*=\s*'((http|https|ftp|mailto):[^'\"]+)'} $html \
        "\\1='\u0001\\2\u0002'" html
    regsub -nocase -all \
        {(href|src)\s*=\s*[\"]((http|https|ftp|mailto):[^'\"]+)[\"]} $html \
        "\\1=\"\u0001\\2\u0002\"" html

    #
    # If a path is specified, prefix all relative URLs (i.e. not
    # starting with a slash) with the specified path.
    #
    if {[info exists path]} {
        set path "[string trim $path /]/"
        regsub -all {(href|src)\s*=\s*['\"]([^/][^\u0001:'\"]+?)['\"]} $html \
            "\\1='${location}${path}\\2'" html
    }

    #
    # Prefix every URL starting with a slash by the location.
    #
    regsub -nocase -all {(href|src)\s*=\s*['\"]/([^\u0001:'\"]+?)['\"]} $html \
        "\\1='${location}\\2'" html

    #
    # Remove all protection characters again.
    #
    regsub -nocase -all {((href|src)\s*=\s*['\"]?)\u0001([^\u0002]*)\u0002} $html {\1\3} html

    return $html
}


ad_proc -public util_convert_line_breaks_to_html {
    {-includes_html:boolean}
    text
} {
    Convert line breaks to <p> and <br> tags, respectively.
} {
    # Remove any leading or trailing whitespace
    regsub {^[\s]+} $text {} text
    regsub {[\s]+$} $text {} text

    # Make sure all line breaks are single \n's
    regsub -all {\r\n} $text "\n" text
    regsub -all {\r} $text "\n" text

    # Remove whitespace before \n's
    regsub -all {[ \t]+\n} $text "\n" text

    # Wrap P's around paragraphs
    regsub -all {([^\n\s])\n\n+([^\n\s])} $text {\1<p>\2} text

    # remove line breaks right before and after HTML tags that will insert a paragraph break themselves
    if { $includes_html_p } {
        set tags [join { ul ol li blockquote p div table tr td th } |]
        regsub -all -nocase "\\s*(</?($tags)\\s*\[^>\]*>)\\s*" $text {\1} text
    }

    # Convert _single_ CRLF's to <br>'s to preserve line breaks
    regsub -all {\n} $text "<br>\n" text

    # Add line breaks to P tags
    #regsub -all {</p>} $text "</p>\n" text

    return $text
}



ad_proc -public ad_quotehtml { arg } {

    Quotes ampersands, double-quotes, and angle brackets in $arg.
    Analogous to ns_quotehtml except that it quotes double-quotes
    (which ns_quotehtml does not).

    @see ad_unquotehtml
} {
    return [string map {& &amp; \" &quot; < &lt; > &gt;} $arg]
}

ad_proc -public ad_unquotehtml {arg} {
    reverses ad_quotehtml

    @see ad_quotehtml
} {
    return [string map {&amp; & &gt; > &lt; < &quot; \" &#34; \" &#39; '} $arg]
}


####################
#
# HTML -> HTML
#
####################


#
# lars@pinds.com, 19 July 2000:
# Should this proc change name to something in line with the rest
# of the library?
#
ad_proc -private util_close_html_tags {
    html_fragment
    {break_soft 0}
    {break_hard 0}
    {ellipsis ""}
    {more ""}
} {
    Given an HTML fragment, this procedure will close any tags that
    have been left open.  The optional arguments let you specify that
    the fragment is to be truncated to a certain number of displayable
    characters.  After break_soft, it truncates and closes open tags unless
    you're within non-breaking tags (e.g., Af).  After break_hard displayable
    characters, the procedure simply truncates and closes any open HTML tags
    that might have resulted from the truncation.
    <p>
    Note that the internal syntax table dictates which tags are non-breaking.
    The syntax table has codes:
    <ul>
    <li>  nobr --  treat tag as nonbreaking.
    <li>  discard -- throws away everything until the corresponding close tag.
    <li>  remove -- nuke this tag and its closing tag but leave contents.
    <li>  close -- close this tag if left open.
    </ul>

    @param break_soft the number of characters you want the html fragment
    truncated to. Will allow certain tags (A, ADDRESS, NOBR) to close first.

    @param break_hard the number of characters you want the html fragment
    truncated to. Will truncate, regardless of what tag is currently in action.

    @param ellipsis  This will get put at the end of the truncated string, if the string was truncated.
    However, this counts towards the total string length, so that the returned string
    including ellipsis is guaranteed to be shorter than the 'len' provided.

    @param more      This will get put at the end of the truncated string, if the string was truncated.

    @author Jeff Davis (davis@xarg.net)

} {
    #
    # The code in this function had an exponential behavior based on
    # the size.  On the current OpenACS.org site (Jan 2009), the
    # function took on certain forums entries 6 to 9 hours
    # (e.g. /forums/message-view?message_id=357753). This is in
    # particular a problem, since bots like googlebot will timeout on
    # these entries (while OpenACS is still computing the content) and
    # retry after some time until they get the result (which never
    # happened). So, often multiple computation ran at the same
    # time. Since OpenACS.org is configured with only a few connection
    # threads, this is essentially a "bot DOS attack".
    #
    # Therefore, the tdom-based code in the next paragraph is used to
    # speedup the process significantly (most entries are anyway
    # correct).  The forum processing query from above takes now 7.3
    # seconds instead of 9h. The tdom-based code was developed as an
    # emergency measure.
    #
    # The code below the mentioned paragraph could be certainly as
    # well made faster, but this will require some more detailed
    # analysis.
    #
    # The best solution for forums would be to check the fragment not
    # at rendering time, but at creation time.
    #
    # -gustaf neumann    (Jan 2009)

    if {$break_soft == 0 && $break_hard == 0} {
        #
        # We have to protect against crashes, that might happen due to
        # unsupported numeric entities in tdom. Therefore, we map
        # numeric entities into something sufficiently opaque
        #
        set frag [string map [list &# "\0&amp;#\0"] $html_fragment]

        try {
            dom parse -html <body>$frag doc
        } on error {errorMsg} {
            # we got an error, so do Tcl based html completion processing
            ad_log notice "tdom can't parse the provided HTML, error=$errorMsg, checking fragment without tdom\n$frag"
        } on ok {r} {
            $doc documentElement root
            set html ""
            # discard forms
            foreach node [$root selectNodes //form] {$node delete}
            # output wellformed html
            set b [lindex [$root selectNodes {//body}] 0]
            foreach n [$b childNodes] {
                append html [$n asHTML]
            }
            return [string map [list "\0&amp;#\0" &#] $html]
        }
    }

    set frag $html_fragment

    # original code continues

    set syn(a) nobr
    set syn(address) nobr
    set syn(nobr) nobr
    #
    set syn(form) discard
    #
    set syn(blink) remove
    #
    set syn(table) close
    set syn(font) close
    set syn(b) close
    set syn(big) close
    set syn(i) close
    set syn(s) close
    set syn(small) close
    set syn(strike) close
    set syn(sub) close
    set syn(sup) close
    set syn(tt) close
    set syn(u) close
    set syn(abbr) close
    set syn(acronym) close
    set syn(cite) close
    set syn(code) close
    set syn(del) close
    set syn(dfn) close
    set syn(em) close
    set syn(ins) close
    set syn(kbo) close
    set syn(samp) close
    set syn(strong) close
    set syn(var) close
    set syn(dir) close
    set syn(dl) close
    set syn(menu) close
    set syn(ol) close
    set syn(ul) close
    set syn(h1) close
    set syn(h2) close
    set syn(h3) close
    set syn(h4) close
    set syn(h5) close
    set syn(h6) close
    set syn(bdo) close
    set syn(blockquote) close
    set syn(center) close
    set syn(div) close
    set syn(pre) close
    set syn(q) close
    set syn(span) close

    set out {}
    set out_len 0

    # counts how deep we are nested in nonbreaking tags, tracks the nobr point
    # and what the nobr string length would be
    set nobr 0
    set nobr_out_point 0
    set nobr_tagptr 0
    set nobr_len 0

    if { $break_hard > 0 } {
        if { $break_soft == 0 } {
            set break_soft $break_hard
        }
    }

    set broken_p 0
    set discard 0
    set tagptr -1

    # First try to fix up < not part of a tag.

    regsub -all {<([^/[:alpha:]!])} $frag {\&lt;\1} frag
    # no we do is chop off any trailing unclosed tag
    # since when we substr blobs this sometimes happens

    # this should in theory cut any tags which have been cut open.
    while {[regexp {(.*)<[^>]*$} $frag match frag]} {}

    while { "$frag" != "" } {
        # here we attempt to cut the string into "pretag<TAG TAGBODY>posttag"
        # and build the output list.

        if {![regexp "(\[^<]*)(<(/?)(\[^ \r\n\t>]+)(\[^>]*)>)?(.*)" $frag match pretag fulltag close tag tagbody frag]} {
            # should never get here since above will match anything.
            ns_log Error "util_close_html_tag - NO MATCH: should never happen! frag=$frag"
            append out $frag
            set frag {}
        } else {
            #ns_log Notice "pretag=$pretag\n fulltag=$fulltag\n close=$close\n tag=$tag\n tagbody=$tagbody frag length is [string length $frag]"
            if { ! $discard } {
                # figure out if we can break with the pretag chunk
                if { $break_soft } {
                    if {! $nobr && [string length $pretag] + $out_len > $break_soft } {
                        # first chop pretag to the right length
                        set pretag [string range $pretag 0 [expr {$break_soft - $out_len - [string length $ellipsis]}]]
                        # clip the last word
                        regsub "\[^ \t\n\r]*$" $pretag {} pretag
                        append out [string range $pretag 0 $break_soft]
                        set broken_p 1
                        break
                    } elseif { $nobr &&  [string length $pretag] + $out_len > $break_hard } {
                        # we are in a nonbreaking tag and are past the hard break
                        # so chop back to the point we got the nobr tag...
                        set tagptr $nobr_tagptr
                        if { $nobr_out_point > 0 } {
                            set out [string range $out 0 $nobr_out_point-1]
                        } else {
                            # here maybe we should decide if we should keep the tag anyway
                            # if zero length result would be the result...
                            set out {}
                        }
                        set broken_p 1
                        break
                    }
                }

                # tack on pretag
                append out $pretag
                incr out_len [string length $pretag]
            }

            # now deal with the tag if we got one...
            if  { $tag eq "" } {
                # if the tag is empty we might have one of the bad matched that are not eating
                # any of the string so check for them
                if {[string length $match] == [string length $frag]} {
                    append out $frag
                    set frag {}
                }
            } else {
                set tag [string tolower $tag]
                if { ![info exists syn($tag)]} {
                    # if we don't have an entry in our syntax table just tack it on
                    # and hope for the best.
                    if { ! $discard } {
                        append  out $fulltag
                    }
                } else {
                    if { $close ne "/" } {
                        # new tag
                        # "remove" tags are just ignored here
                        # discard tags
                        if { $discard } {
                            if { $syn($tag) eq "discard" } {
                                incr discard
                                incr tagptr
                                set tagstack($tagptr) $tag
                            }
                        } else {
                            switch -- $syn($tag) {
                                nobr {
                                    if { ! $nobr } {
                                        set nobr_out_point [string length $out]
                                        set nobr_tagptr $tagptr
                                        set nobr_len $out_len
                                    }
                                    incr nobr
                                    incr tagptr
                                    set tagstack($tagptr) $tag
                                    append out $fulltag
                                }
                                discard {
                                    incr discard
                                    incr tagptr
                                    set tagstack($tagptr) $tag
                                }
                                close {
                                    incr tagptr
                                    set tagstack($tagptr) $tag
                                    append out $fulltag
                                }
                            }
                        }
                    } else {
                        # we got a close tag
                        if { $discard } {
                            # if we are in discard mode only watch for
                            # closes to discarded tags
                            if { $syn($tag) eq "discard"} {
                                if {$tagptr > -1} {
                                    if { $tag != $tagstack($tagptr) } {
                                        #puts "/$tag without $tag"
                                    } else {
                                        incr tagptr -1
                                        incr discard -1
                                    }
                                }
                            }
                        } else {
                            if { $syn($tag) ne "remove"} {
                                # if tag is a remove tag we just ignore it...
                                if {$tagptr > -1} {
                                    if {$tag != $tagstack($tagptr) } {
                                        # puts "/$tag without $tag"
                                    } else {
                                        incr tagptr -1
                                        if { $syn($tag) eq "nobr"} {
                                            incr nobr -1
                                        }
                                        append out $fulltag
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    # on exit of the look either we parsed it all or we truncated.
    # we should now walk the stack and close any open tags.

    # Chop off extra whitespace at the end
    if { $broken_p } {
        set end_index [expr {[string length $out] -1}]
        while { $end_index >= 0 && [string is space [string index $out $end_index]] } {
            incr end_index -1
        }
        set out [string range $out 0 $end_index]
    }

    for { set i $tagptr } { $i > -1 } { incr i -1 } {
        set tag $tagstack($i)

        # LARS: Only close tags which we aren't supposed to remove
        if { $syn($tag) ni {discard remove}} {
            append out "</$tagstack($i)>"
        }
    }

    if { $broken_p } {
        append out $ellipsis
        append out $more
    }

    return $out
}

ad_proc ad_parse_html_attributes {
    -attribute_array
    html
    {pos 0}
} {
    This is a wrapper proc for <a href="/api-doc/proc-view?proc=ad_parse_html_attributes_upvar"><code>ad_parse_html_attributes_upvar</code></a>, so you can parse attributes from a string without upvar'ing.
    See the documentation for the other proc.

    @author Lars Pind (lars@pinds.com)
    @creation-date November 10, 2000
} {
    if { [info exists attribute_array] } {
        upvar $attribute_array attribute_array_var
        return [ad_parse_html_attributes_upvar -attribute_array attribute_array_var html pos]
    } else {
        return [ad_parse_html_attributes_upvar html pos]
    }
}


ad_proc ad_parse_html_attributes_upvar {
    -attribute_array
    html_varname
    pos_varname
} {
    Parse attributes in an HTML fragment and return them as a list of lists.
    <p>
    Each element of that list is either a single element, if the attribute had no value, or
    a two-tuple, with the first element being the name of the attribute and the second being
    the value. The attribute names are all converted to lowercase.
    <p>
    If you don't really care what happens when the same attribute is present twice, you can also use the
    <code>attribute_array</code> argument, and the attributes will be
    set there. For attributes without any value, we'll use the empty string.
    <p>
    Example:

    <pre>set html {&lt;tag foo = bar baz greble="&amp;quot;hello you sucker&amp;quot;" foo='blah' Heres = '  something for   you to = "consider" '&gt;}
    set pos 5 ; # the 'f' in the first 'foo'

    set attribute_list [ad_parse_html_attributes_upvar -attribute_array attribute_array html pos]</pre>

    <code>attribute_list</code> will contain the following:
    <pre>{foo bar} baz {greble {"hello you sucker"}} {foo blah} {heres {  something for   you to = "consider" }}</pre>
    <code>attribute_array</code> will contain:
    <pre>attribute_array(foo)='blah'
    attribute_array(greble)='"hello you sucker"'
    attribute_array(baz)=''
    attribute_array(heres)='  something for   you to = "consider" '</pre>

    <p>

    Won't alter the string passed in .. promise!
    We <i>will</i> modify pos_var. Pos_var should point to the first character inside the tag,
    after the tag name (we don't care if you let if there's some whitespace before the first attribute)


    @param html_varname the name of the variable holding the HTML
    fragment. We promise that we won't change the contents of this
    variable.

    @param pos_varname the name of the variable holding the position
    within the <code>html_varname</code> string from which we should
    start. This should point to a character inside the tag, just after
    the tag name, and before the first attribute. Note, that we <i>will</i> modify this variable.
    When this proc is done, this variable will point to the tag-closing <code>&gt;</code>.
    Example:
    if the tag is &lt;img src="foo"&gt;, <code>pos_varname</code> should point to either the space between
    <code>img</code> and <code>src</code>, or the <code>s</code> in <code>src</code>.

    @param attribute_array This is an alternate way of returning the attributes, if you don't care
    about what happens when the same attribute name is defined twice.

    @return A list of list holding the attribute names and
    values. Each element of that list is either a single element, if the
    attribute had no value, or
    a two-tuple, with the first element being the name of the attribute and the second being
    the value. The attribute names are all converted to lowercase.

    @author Lars Pind (lars@pinds.com)
    @creation-date November 10, 2000
} {
    upvar $html_varname html
    upvar $pos_varname i
    if { [info exists attribute_array] } {
        upvar $attribute_array attribute_array_var
    }

    # This is where we're going to return the result
    set attributes {}

    # Loop over the attributes.
    # We maintain counter is so that we don't accidentally enter an infinite loop
    set count 0
    while { $i < [string length $html] && [string index $html $i] ne ">" } {
        if { [incr count] > 3000 } {
            error "There appears to be a programming bug in ad_parse_html_attributes_upvar: We've entered an infinite loop. We are here: \noffset $i: [string range $html $i $i+60]"
        }
        if { [string range $html $i $i+1] eq "/>" } {
            # This is an XML-style tag ending: <... />
            break
        }

        # This regexp matches an attribute name and an equal sign, if
        # present.  Also eats whitespace before or after.  The \A
        # corresponds to ^, except it matches the position we're
        # starting from, not the start of the string.
        if { ![regexp -indices -start $i {\A\s*([^\s=>]+)\s*(=?)\s*} $html match attr_name_idx equal_sign_idx] } {
            #
            # Apparently, there's no attribute name here.
            # Let's eat all whitespace and lonely equal signs.
            #
            regexp -indices -start $i {\A[\s=]*} $html match
            set i [expr { [lindex $match 1] + 1 }]
        } {
            set attr_name [string tolower [string range $html [lindex $attr_name_idx 0] [lindex $attr_name_idx 1]]]

            # Move past the attribute name just found
            set i [expr { [lindex $match 1] + 1}]

            # If there is an equal sign, we're expecting the next token to be a value
            if { [lindex $equal_sign_idx 1] - [lindex $equal_sign_idx 0] < 0 } {
                # No equal sign, no value
                lappend attributes [list $attr_name]
                if { [info exists attribute_array] } {
                    set attribute_array_var($attr_name) {}
                }
            } else {

                # is there a single or double quote sign as the first character?
                switch -- [string index $html $i] {
                    {"} { set exp {\A"([^"]*)"\s*} }
                        {'} { set exp {\A'([^']*)'\s*} }
                        default { set exp {\A([^\s>]*)\s*} }
                    }
                    if { ![regexp -indices -start $i $exp $html match attr_value_idx] } {
                        # No end quote.
                        set attr_value [string range $html $i+1 end]
                        set i [string length $html]
                    } else {
                        set attr_value [string range $html [lindex $attr_value_idx 0] [lindex $attr_value_idx 1]]
                        set i [expr { [lindex $match 1] + 1}]
                    }

                    set attr_value [util_expand_entities_ie_style $attr_value]

                    lappend attributes [list $attr_name $attr_value]
                    if { [info exists attribute_array] } {
                        set attribute_array_var($attr_name) $attr_value
                    }
                }
            }
        }
        return $attributes
    }




    ad_proc ad_html_security_check { html } {

        Returns a human-readable explanation if the user has used any HTML
        tag other than the ones marked allowed in antispam section of ad.ini.
        Otherwise returns an empty string.

        @return a human-readable, plaintext explanation of what's wrong with the user's input.

        @author Lars Pind (lars@pinds.com)
        @creation-date 20 July 2000

    } {
        if { [string first <% $html] > -1 } {
            return "For security reasons, you're not allowed to have the less-than-percent combination in your input."
        }

        array set allowed_attribute [list]
        array set allowed_tag [list]
        array set allowed_protocol [list]

        # Use the antispam tags for this package instance and whatever is on the kernel.
        set allowed_tags_list [concat \
                                   [ad_parameter_all_values_as_list -package_id [ad_acs_kernel_id] AllowedTag antispam] \
                                   [ad_parameter_all_values_as_list AllowedTag antispam]]

        set allowed_attributes_list [concat \
                                         [ad_parameter_all_values_as_list -package_id [ad_acs_kernel_id] AllowedAttribute antispam] \
                                         [ad_parameter_all_values_as_list AllowedAttribute antispam]]

        set allowed_protocols_list [concat \
                                        [ad_parameter_all_values_as_list -package_id [ad_acs_kernel_id] AllowedProtocol antispam] \
                                        [ad_parameter_all_values_as_list AllowedProtocol antispam]]

        foreach attribute $allowed_attributes_list {
            set allowed_attribute([string tolower $attribute]) 1
        }
        foreach tagname $allowed_tags_list {
            set allowed_tag([string tolower $tagname]) 1
        }
        foreach protocol $allowed_protocols_list {
            set allowed_protocol([string tolower $protocol]) 1
        }

        # loop over all tags
        for { set i [string first < $html] } { $i != -1 } { set i [string first < $html $i] } {
            # move past the tag-opening <
            incr i

            if { ![regexp -indices -start $i {\A/?([-_a-zA-Z0-9]+)\s*} $html match name_idx] } {
                # The tag-opener isn't followed by USASCII letters (with or without optional initial slash)
                # Not considered a tag. Shouldn't do any harm in browsers.
                # (Tested with digits, with &#65; syntax, with whitespace)
            } else {
                # The tag was valid ... now let's see if it's on the allowed list.
                set tagname [string tolower [string range $html [lindex $name_idx 0] [lindex $name_idx 1]]]

                if { ![info exists allowed_tag($tagname)] && ![info exists allowed_tag(*)] } {
                    # Nope, this was a naughty tag.
                    return "For security reasons we only accept the submission of HTML
        containing the following tags: [join $allowed_tags_list " "].
        You have a [string toupper $tagname] tag in there."
                } else {
                    # Legal tag.

                    # Make i point to the first character inside the tag, after the tag name and any whitespace
                    set i [expr { [lindex $match 1] + 1}]

                    set attr_list [ad_parse_html_attributes_upvar html i]

                    foreach attribute $attr_list {
                        lassign $attribute attr_name attr_value

                        if { ![info exists allowed_attribute($attr_name)]
                             && ![info exists allowed_attribute(*)] } {
                            return "The attribute '$attr_name' is not allowed for $tagname tags"
                        }

                        if { [string tolower $attr_name] ne "style" } {
                            if { [regexp {^\s*([^\s:]+):\/\/} $attr_value match protocol] } {
                                if { ![info exists allowed_protocol([string tolower $protocol])]
                                     && ![info exists allowed_protocol(*)] } {
                                    return "Your URLs can only use these protocols: [join $allowed_protocols_list ", "].
                You have a '$protocol' protocol in there."
                                }
                            }
                        }
                    }
                }
            }
        }
        return {}
    }

    # This was created in order to pre-process some content to be fed
    # to tDOM in ad_sanitize_html. In fact, even with its least picky
    # behavior, tDOM cannot swallow whatever markup you give it. This
    # proc might also be used in order to improve some OpenACS
    # routines, like util_close_html_tags. As it has some limitations,
    # this is left to future considerations.
    ad_proc -public ad_dom_fix_html {
        -html:required
        {-marker "root"}
        -dom:boolean
    } {

        Similar in spirit to the famous Tidy command line utility,
        this proc takes a piece of possibly invalid markup and returns
        a 'fixed' version where unopened tags have been closed and
        attribute specifications have been normalized by transforming them
        in the form <code>attribute-name="attribute value"</code>. All
        attributes with an invalid (non-alphanumeric) name will be
        stripped.<br>
        <br>
        Be aware that every comment and also the possibly present
        DOCTYPE declaration will be stripped from the markup. Also,
        most of tag's internal whitespace will be trimmed. This
        behavior comes from the htmlparse library used in this
        implementation.

        @param html Markup to process

        @param marker Root element use to enforce a single root of the
               DOM tree.

        @param dom When this flag is set, instead of returning markup,
        the proc will return the tDOM object built during the
        operation. Useful when the result should be used by tDOM
        anyway, so we can avoid superfluous parsing.

        @return markup or a tDOM document object if the -dom flag is
        specified

        @author Antonio Pisano

    } {
        if {[catch {package require struct}]} {
            error "Package struct non found on the system"
        }
        if {[catch {package require htmlparse}]} {
            error "Package htmlparse non found on the system"
        }

        set tree [::struct::tree]


        catch {::htmlparse::tags destroy}

        ::struct::stack ::htmlparse::tags
        ::htmlparse::tags push root
        $tree set root type root

        ::htmlparse::parse \
            -cmd [list ::htmlparse::2treeCallback $tree] \
            -incvar errs $html

        $tree walk root -order post n {
            ::htmlparse::Reorder $tree $n
        }

        ::htmlparse::tags destroy


        set lmarker "<$marker>"
        set rmarker "</$marker>"
        set doc [dom createDocument $marker]
        set root [$doc documentElement]

        set queue {}
        lappend queue [list $root [$tree children [$tree children root]]]
        while {$queue ne {}} {
            lassign [lindex $queue 0] domparent treechildren
            set queue [lrange $queue 1 end]

            foreach child $treechildren {
                set type [$tree get $child type]
                set data [$tree get $child data]
                if {$type eq "PCDATA"} {
                    set el [$doc createTextNode $data]
                } else {
                    set el [$doc createElement $type]

                    # parse element attributes
                    while {$data ne ""} {
                        set data [string trim $data]
                        # attribute with a value, optionally surrounded by double or single quotes
                        if {[regexp "^(\[^= \]+)=(\"\[^\"\]*\"|'\[^'\].*'|\[^ \]*)" $data m attname attvalue]} {
                            if {[string match "\"*\"" $attvalue] ||
                                [string match "'*'" $attvalue]} {
                                set attvalue [string range $attvalue 1 end-1]
                            }
                        # attribute with no value
                        } elseif {[regexp {^([^\s]+)} $data m attname]} {
                            set attvalue ""
                        } else {
                            error "Unrecoverable attribute spec in supplied markup"
                        }

                        # skip bogus attribute names
                        if {[string is alnum -strict $attname]} {
                            $el setAttribute $attname $attvalue
                        }

                        set data [string range $data [string length $m] end]
                    }
                }

                $domparent appendChild $el

                set elchildren [$tree children $child]
                if {$elchildren ne {}} {
                    lappend queue [list $el $elchildren]
                }
            }
        }

        $tree destroy

        if {$dom_p} {
            return $doc
        } else {
            set html [$doc asHTML]
            $doc delete
            set html [string range $html [string length $lmarker] end-[string length $rmarker]]
        }

        return [string trim $html]
    }

    # Original purpose of this proc was to introduce a better way to
    # enforce some HTML policies on the content submitted by the uses
    # (e.g. forbid some tag/attribute like <script> etc). It has some
    # limitations that make non-trivial its introduction, therefore is
    # currently not used around.
    ad_proc -public ad_dom_sanitize_html {
        -html:required
        -allowed_tags
        -allowed_attributes
        -allowed_protocols
        -unallowed_tags
        -unallowed_attributes
        -unallowed_protocols
        -no_js:boolean
        -no_outer_urls:boolean
        -validate:boolean
        -fix:boolean
    } {

        Sanitizes HTML by specified criteria, basically removing
        unallowed tags and attributes, JavaScript or outer references
        into page URLs. When desired, this proc can act also as just a
        validator in order to enforce some markup policies.

        @param html the markup to be checked.

        @param allowed_tags list of tags we allow in the markup.

        @param allowed_attributes list of attributes we allow in the
        markup.

        @param allowed_protocols list of attributes we allow into
        links

        @param unallowed_tags list of tags we don't allow in the
        markup.

        @param unallowed_attributes list of attributes we don't allow
        in the markup.

        @param unallowed_protocols list of protocols we don't allow in
        the markup. Protocol-relative URLs are allowed, but only if
        proc is called from a connection thread, as we need to
        determine our current connection protocol.

        @param no_js this flag decides whether every script tag,
        inline event handlers and the javascript: pseudo-protocol
        should be stripped from the markup.

        @param no_outer_urls this flag tells the proc to remove every
        reference to external addresses. Proc will try to distinguish
        between external URLs and fine fully specified internal
        ones. Acceptable URLs will be transformed in absolute local
        references, others will be just stripped together with the
        attribute. Absolute URLs referring to our host are allowed,
        but require the proc being called from a connection thread in
        order to determine the proper current url.

        @param validate This flag will avoid the creation of the
        stripped markup and just report whether the original one
        respects all the specified requirements.

        @param fix When parsing fails on markup as it is, try to fix
        it by, for example, closing unclosed tags or normalizing
        attribute specification. This operation will remove most of
        plain whitespace into text content of original HTML, together
        with every comment and the eventually present DOCTYPE
        declaration.

        @return sanitized markup or a (0/1) truth value when the
        -validate flag is specified

        @author Antonio Pisano

    } {
        ## Allowed/Unallowed tags come from the user or default to
        ## those specified in the parameters

        array set allowed_tag {}
        if {![info exists allowed_tags]} {
            # Use the antispam tags for this package instance and whatever is on the kernel.
            set allowed_tags {}
            lappend allowed_tags_list {*}[ad_parameter_all_values_as_list -package_id [ad_acs_kernel_id] AllowedTag antispam]
            lappend allowed_tags_list {*}[ad_parameter_all_values_as_list AllowedTag antispam]
        }

        array set allowed_attribute {}
        if {![info exists allowed_attributes]} {
            set allowed_attributes {}
            lappend allowed_attributes {*}[ad_parameter_all_values_as_list -package_id [ad_acs_kernel_id] AllowedAttribute antispam]
            lappend allowed_attributes {*}[ad_parameter_all_values_as_list AllowedAttribute antispam]
        }

        array set allowed_protocol {}
        if {![info exists allowed_protocols]} {
            set allowed_protocols {}
            lappend allowed_protocols {*}[ad_parameter_all_values_as_list -package_id [ad_acs_kernel_id] AllowedProtocol antispam]
            lappend allowed_protocols {*}[ad_parameter_all_values_as_list AllowedProtocol antispam]
        }

        if {"*" in $allowed_tags} {
            set allowed_tags "*"
        }
        foreach tag $allowed_tags {
            set allowed_tag([string tolower $tag]) 1
        }

        if {"*" in $allowed_attributes} {
            set allowed_attributes "*"
        }
        foreach attribute $allowed_attributes {
            set allowed_attribute([string tolower $attribute]) 1
        }

        if {"*" in $allowed_protocols} {
            set allowed_protocols "*"
        }
        foreach protocol $allowed_protocols {
            set allowed_protocol([string tolower $protocol]) 1
        }

        array set unallowed_tag {}
        if {![info exists unallowed_tags]} {
            set unallowed_tags {}
        }

        array set unallowed_attribute {}
        if {![info exists unallowed_attributes]} {
            set unallowed_attributes {}
        }

        array set unallowed_protocol {}
        if {![info exists unallowed_protocols]} {
            set unallowed_protocols {}
        }

        # TODO: consider default unallowed stuff to come from a parameter

        if {$no_js_p} {
            lappend unallowed_tags "script"
            lappend unallowed_attributes {*}{
                onafterprint onbeforeprint onbeforeunload onerror
                onhashchange onload onmessage onoffline ononline
                onpagehide onpageshow onpopstate onresize onstorage
                onunload onblur onchange oncontextmenu onfocus oninput
                oninvalid onreset onsearch onselect onsubmit onkeydown
                onkeypress onkeyup onclick ondblclick onmousedown
                onmousemove onmouseout onmouseover onmouseup
                onmousewheel onwheel ondrag ondragend ondragenter
                ondragleave ondragover ondragstart ondrop onscroll
                oncopy oncut onpaste onabort oncanplay
                oncanplaythrough oncuechange ondurationchange
                onemptied onended onerror onloadeddata
                onloadedmetadata onloadstart onpause onplay onplaying
                onprogress onratechange onseeked onseeking onstalled
                onsuspend ontimeupdate onvolumechange onwaiting onshow
                ontoggle
            }
            lappend unallowed_protocols "javascript"
        }

        foreach tag $unallowed_tags {
            set unallowed_tag([string tolower $tag]) 1
        }

        foreach attribute $unallowed_attributes {
            set unallowed_attribute([string tolower $attribute]) 1
        }
        foreach protocol $unallowed_protocols {
            set unallowed_protocol([string tolower $protocol]) 1
        }

        ##
        # root of the document must be unique, this will enforce it by
        # wrapping html in an auxiliary root element
        set lmarker "<root>"
        set rmarker "</root>"

        try {
            dom parse -html "${lmarker}${html}${rmarker}" doc

        } on error {errorMsg} {
            if {$fix_p} {
                try {
                    set doc [ad_dom_fix_html -html $html -dom]
                } on error {errorMsg} {
                    ad_log error "Fixing of the document failed. Reported error: $errorMsg"
                    return [expr {$validate_p ? 0 : ""}]
                }
            } else {
                ad_log error "Parsing of the document failed. Reported error: $errorMsg"
                return [expr {$validate_p ? 0 : ""}]
            }
        }

        $doc documentElement root

        # Some sanitizing requires information that is available only
        # from a connection thread such as our local address and
        # current protocol.
        if {[ns_conn isconnected]} {
            set driver_info [util_driver_info]
            set driver_prot [dict get $driver_info proto]
            set driver_host [dict get $driver_info hostname]
            set driver_port [dict get $driver_info port]

            ## create a regex clause of possible addresses referring to
            ## this system
            set our_locations [list]

            # location from conf files
            set configured_location [util::join_location \
                                         -proto    $driver_prot \
                                         -hostname $driver_host \
                                         -port     $driver_port]
            lappend our_locations $configured_location
            regsub {^\w+://} $configured_location {//} no_proto_location
            lappend our_locations $no_proto_location

            # location from connection
            set conn_location [ad_conn location]
            lappend our_locations $conn_location
            regsub {^\w+://} $conn_location {//} no_proto_location
            lappend our_locations $no_proto_location

            set our_locations [join $our_locations |]
            ##
        } else {
            set our_locations ""
            set driver_prot ""
        }

        set queue [$root childNodes]
        while {$queue ne {}} {
            set node [lindex $queue 0]
            set queue [lrange $queue 1 end]

            # skip all non-element nodes
            if {$node eq "" || [$node nodeType] ne "ELEMENT_NODE"} continue

            # 1: check tag is allowed
            set node_name [string tolower [$node nodeName]]
            if {[info exists unallowed_tag($node_name)] ||
                ($allowed_tags ne "*" && ![info exists allowed_tag($node_name)])} {
                # invalid tag!
                if {$validate_p} {return 0} else {$node delete}
                continue
            }

            # tag itself is allowed, we can inspect its children
            lappend queue {*}[$node childNodes]

            # 2: check tag contains only allowed attributes
            foreach att [$node attributes] {
                set att [string tolower $att]
                if {[info exists unallowed_attribute($att)] ||
                    ($allowed_attributes ne "*" && ![info exists allowed_attribute($att)])} {
                    # invalid attribute!
                    if {$validate_p} {return 0} else {$node removeAttribute $att}
                    continue
                }

                # 3: check for any attribute that could contain a URL
                # whether this is acceptable
                switch -- $att {
                    "href" - "src" - "content" - "action" {
                        set url [string trim [$node getAttribute $att ""]]
                        if {$url eq ""} continue

                        set prot ""

                        set parsed_url [ns_parseurl $url]
                        # attribute is a URL including the protocol
                        set proto [expr {[dict exists $parsed_url proto] ? [dict get $parsed_url proto] : ""}]
                        if {$proto ne ""} {
                            if {$no_outer_urls_p} {
                                # no external URLs allowed: we still
                                # want to allow fully specified URLs
                                # that refer to this server, but we'll
                                # transform them in a local absolute
                                # reference. For all others, attribute
                                # will be just removed.
                                # - This is ok, points to our system...
                                if {[regsub ^($our_locations) $url {} url]} {
                                    set url /[string trimleft $url "/"]
                                    $node setAttribute $att $url
                                # ...this is not, points elsewhere!
                                } else {
                                    # invalid attribute!
                                    if {$validate_p} {return 0} else {$node removeAttribute $att}
                                    continue
                                }
                            }
                        }

                        # to check for allowed protocols we need to
                        # treat URLs without one (e.g. relative or
                        # protocol-relative URLs) as using our same
                        # protocol
                        if {$proto eq ""} {
                            set proto $driver_prot
                        }

                        # check if protocol is allowed
                        if {[info exists unallowed_protocol($proto)] ||
                            ($allowed_protocols ne "*" && ![info exists allowed_protocol($proto)])} {
                            # invalid attribute!
                            if {$validate_p} {return 0} else {$node removeAttribute $att}
                            continue
                        }
                    }
                }
            }
        }

        if {$validate_p} {
            $doc delete
            return 1
        } else {
            set html [$root asHTML]
            $doc delete
            # remove auxiliary root element from output
            set html [string range $html [string length $lmarker] end-[string length $rmarker]]
            set html [string trim $html]
            return $html
        }
    }


    ####################
    #
    # HTML -> Text
    #
    ####################

    ad_proc -public ad_html_to_text {
        {-maxlen 70}
        {-showtags:boolean}
        {-no_format:boolean}
        html
    } {
        Returns a best-guess plain text version of an HTML fragment.
        Parses the HTML and does some simple formatting. The parser and
        formatting is pretty stupid, but it's better than nothing.

        @param maxlen the line length you want your output wrapped to.
        @param showtags causes any unknown (and uninterpreted) tags to get shown in the output.
        @param no_format causes hyperlink tags not to get listed at the end of the output.

        @author Lars Pind (lars@pinds.com)
        @author Aaron Swartz (aaron@swartzfam.com)
        @creation-date 19 July 2000
    } {
        set output(text) {}
        set output(linelen) 0
        set output(maxlen) $maxlen
        set output(pre) 0
        set output(p) 0
        set output(br) 0
        set output(space) 0
        set output(blockquote) 0

        set length [string length $html]
        set last_tag_end 0

        # For showing the URL of links.
        set href_urls [list]
        set href_stack [list]

        for { set i [string first < $html] } { $i != -1 } { set i [string first < $html $i] } {
            # append everything up to and not including the tag-opening <
            ad_html_to_text_put_text output [string range $html $last_tag_end $i-1]

            # Check that:
            #  - we're not past the end of the string
            #  - and that the tag starts with either
            #     - alpha or
            #     - a slash, and then alpha
            # Otherwise, it's probably just a lone < character
            if { $i >= $length - 1 ||
                 (![string is alpha [string index $html $i+1]]
                  && [string index $html $i+1] ne "!"
                  && ("/" ne [string index $html $i+1] ||
                      ![string is alpha [string index $html $i+2]]))
             } {
                # Output the < and continue with next character
                ad_html_to_text_put_text output "<"
                set last_tag_end [incr i]
                continue
            } elseif {[string match "!--*" [string range $html $i+1 end]]} {
                # Handle HTML comments, I can't believe no one noticed
                # this before.  This code maybe not be elegant but it
                # works.

                # find the closing comment tag.
                set comment_idx [string first "-->" $html $i]
                if {$comment_idx == -1} {
                    # no comment close, escape
                    set last_tag_end $i
                    set i $comment_idx
                    break
                }
                set i [expr {$comment_idx + 3}]
                set last_tag_end $i

                continue
            }
            # we're inside a tag now. Find the end of it

            # make i point to the char after the <
            incr i
            set tag_start $i

            set count 0
            while 1 {
                if {[incr count] > 3000 } {
                    # JCD: the programming bug is that an unmatched <
                    # in the input runs off forever looking for its
                    # closing > and in some long text like program
                    # listings you can have lots of quotes before you
                    # find that >
                    error "There appears to be a programming bug in ad_html_to_text: We've entered an infinite loop."
                }
                # Find the positions of the first quote, apostrophe and greater-than sign.
                set quote_idx [string first \" $html $i]
                set apostrophe_idx [string first ' $html $i]
                set gt_idx [string first > $html $i]

                # If there is no greater-than sign, then the tag isn't closed.
                if { $gt_idx == -1 } {
                    set i $length
                    break
                }

                # Find the first of the quote and the apostrophe
                if { $apostrophe_idx == -1 } {
                    set string_delimiter_idx $quote_idx
                } else {
                    if { $quote_idx == -1 } {
                        set string_delimiter_idx $apostrophe_idx
                    } else {
                        if { $apostrophe_idx < $quote_idx } {
                            set string_delimiter_idx $apostrophe_idx
                        } else {
                            set string_delimiter_idx $quote_idx
                        }
                    }
                }
                set string_delimiter [string index $html $string_delimiter_idx]

                # If the greater than sign appears before any of the
                # string delimters, we've found the tag end.
                if { $gt_idx < $string_delimiter_idx || $string_delimiter_idx == -1 } {
                    # we found the tag end
                    set i $gt_idx
                    break
                }

                # Otherwise, we'll have to skip past the ending string delimiter
                set i [string first $string_delimiter $html [incr string_delimiter_idx]]
                if { $i == -1 } {
                    # Missing string end delimiter
                    set i $length
                    break
                }
                incr i
            }

            set full_tag [string range $html $tag_start $i-1]

            if { ![regexp {^(/?)([^\s]+)[\s]*(\s.*)?$} $full_tag match slash tagname attributes] } {
                # A malformed tag -- just delete it
            } else {

                # Reset/create attribute array
                array unset attribute_array

                # Parse the attributes
                ad_parse_html_attributes -attribute_array attribute_array $attributes

                switch -- [string tolower $tagname] {
                    p - ul - ol - table {
                        set output(p) 1
                    }
                    br {
                        ad_html_to_text_put_newline output
                    }
                    tr - td - th {
                        set output(br) 1
                    }
                    h1 - h2 - h3 - h4 - h5 - h6 {
                        set output(p) 1
                        if { $slash eq "" } {
                            ad_html_to_text_put_text output [string repeat "*" [string index $tagname 1]]
                        }
                    }
                    li {
                        set output(br) 1
                        if { $slash eq "" } {
                            ad_html_to_text_put_text output "- "
                        }
                    }
                    strong - b {
                        ad_html_to_text_put_text output "*"
                    }
                    em - i - cite - u {
                        ad_html_to_text_put_text output "_"
                    }
                    a {
                        if { !$no_format_p } {
                            if { $slash eq ""} {
                                if { [info exists attribute_array(href)] } {
                                    if { [info exists attribute_array(title)] } {
                                        set title ": '$attribute_array(title)'"
                                    } else {
                                        set title ""
                                    }
                                    set href_no [expr {[llength $href_urls] + 1}]
                                    lappend href_urls "\[$href_no\] $attribute_array(href) "
                                    lappend href_stack "\[$href_no$title\]"
                                } elseif { [info exists attribute_array(title)] } {
                                    lappend href_stack "\[$attribute_array(title)\]"
                                } else {
                                    lappend href_stack {}
                                }
                            } else {
                                if { [llength $href_stack] > 0 } {
                                    if { [lindex $href_stack end] ne "" } {
                                        ad_html_to_text_put_text output " [lindex $href_stack end]"
                                    }
                                    set href_stack [lreplace $href_stack end end]
                                }
                            }
                        }
                    }
                    pre {
                        set output(p) 1
                        if { $slash eq "" } {
                            incr output(pre)
                        } else {
                            incr output(pre) -1
                        }
                    }
                    blockquote {
                        set output(p) 1
                        if { $slash eq "" } {
                            incr output(blockquote)
                            incr output(maxlen) -4
                        } else {
                            incr output(blockquote) -1
                            incr output(maxlen) 4
                        }
                    }
                    hr {
                        set output(p) 1
                        ad_html_to_text_put_text output [string repeat "-" $output(maxlen)]
                        set output(p) 1
                    }
                    q {
                        ad_html_to_text_put_text output \"
                    }
                    img {
                        if { $slash eq "" && !$no_format_p } {
                            set img_info {}
                            if { [info exists attribute_array(alt)] } {
                                lappend img_info "'$attribute_array(alt)'"
                            }
                            if { [info exists attribute_array(src)] } {
                                lappend img_info $attribute_array(src)
                            }
                            if { [llength $img_info] == 0 } {
                                ad_html_to_text_put_text output {[IMAGE]}
                            } else {
                                ad_html_to_text_put_text output "\[IMAGE: [join $img_info " "] \]"
                            }
                        }
                    }
                    default {
                        # Other tag
                        if { $showtags_p } {
                            ad_html_to_text_put_text output "&lt;$slash$tagname$attributes&gt;"
                        }
                    }
                }
            }

            # set end of last tag to the character following the >
            set last_tag_end [incr i]
        }
        # append everything after the last tag
        ad_html_to_text_put_text output [string range $html $last_tag_end end]

        # Close any unclosed tags
        set output(pre) 0
        while { $output(blockquote) > 0 } {
            incr output(blockquote) -1
            incr output(maxlen) 4
        }

        # write out URLs, if necessary:
        if { [llength $href_urls] > 0 } {
            append output(text) "\n\n[join $href_urls "\n"]"
        }

        #---
        # conversion like in ad_text_to_html
        # 2006/09/12
        set  myChars  {
            ª º À Á Â Ã Ä Å Æ Ç
            È É Ê Ë Ì Í Î Ï Ð Ñ
            Ò Ó Ô Õ Ö Ø Ù Ú Û Ü
            Ý Þ ß à á â ã ä å æ
            ç è é ê ë ì í î ï ð
            ñ ò ó ô õ ö ø ù ú û
            ü ý þ ÿ ¿
        }

        set  myHTML  {
            &ordf; &ordm; &Agrave; &Aacute; &Acirc; &Atilde; &Auml; &Aring; &Aelig; &Ccedil;
            &Egrave; &Eacute; &Ecirc; &Euml; &Igrave; &Iacute; &Icirc; &Iuml; &ETH; &Ntilde;
            &Ograve; &Oacute; &Ocirc; &Otilde; &Ouml; &Oslash; &Ugrave; &Uacute; &Ucirc; &Uuml;
            &Yacute; &THORN; &szlig; &agrave; &aacute; &acirc; &atilde; &auml; &aring; &aelig;
            &ccedil; &egrave; &eacute; &ecirc; &euml; &igrave; &iacute; &icirc; &iuml; &eth;
            &ntilde; &ograve; &oacute; &ocirc; &otilde; &ouml; &oslash; &ugrave; &uacute; &ucirc;
            &uuml; &yacute; &thorn; &yuml; &iquest;
        }

        set map {}
        foreach ch $myChars entity $myHTML {
            lappend map $entity $ch
        }

        return [string map $map $output(text)]
    }

    ad_proc -private ad_html_to_text_put_newline { output_var } {
        Helper proc for ad_html_to_text

        @author Lars Pind (lars@pinds.com)
        @author Aaron Swartz (aaron@swartzfam.com)
        @creation-date 22 September 2000
    } {
        upvar $output_var output

        append output(text) \n
        set output(linelen) 0
        append output(text) [string repeat {    } $output(blockquote)]
    }

    ad_proc -private ad_html_to_text_put_text { output_var text } {
        Helper proc for ad_html_to_text

        @author Lars Pind (lars@pinds.com)
        @author Aaron Swartz (aaron@swartzfam.com)
        @creation-date 19 July 2000
    } {
        upvar $output_var output

        # Expand entities before outputting
        set text [util_expand_entities $text]

        # If we're not in a PRE
        if { $output(pre) <= 0 } {
            # collapse all whitespace
            regsub -all {\s+} $text { } text

            # if there's only spaces in the string, wait until later
            if {$text eq " "} {
                set output(space) 1
                return
            }

            # if it's nothing, do nothing
            if { $text eq "" } {
                return
            }

            # if the first character is a space, set the space bit
            if {[string index $text 0] eq " "} {
                set output(space) 1
                set text [string trimleft $text]
            }
        } else {
            # we're in a PRE: clean line breaks and tabs
            regsub -all {\r\n} $text "\n" text
            regsub -all {\r} $text "\n" text
            # tabs become four spaces
            regsub -all {[\v\t]} $text {    } text
        }

        # output any pending paragraph breaks, line breaks or spaces.
        # as long as we're not at the beginning of the document
        if { $output(p) || $output(br) || $output(space) } {
            if { $output(text) ne "" } {
                if { $output(p) } {
                    ad_html_to_text_put_newline output
                    ad_html_to_text_put_newline output
                } elseif { $output(br) } {
                    ad_html_to_text_put_newline output
                } else {
                    # Don't add the space if we're at the beginning of a line,
                    # unless we're in a PRE
                    if { $output(pre) > 0 || $output(linelen) != 0 } {
                        append output(text) " "
                        incr output(linelen)
                    }
                }
            }
            set output(p) 0
            set output(br) 0
            set output(space) 0
        }

        # if the last character is a space, save it until the next time
        if { [regexp {^(.*) $} $text match text] } {
            set output(space) 1
        }


        if {1} {
            # If there's a blockquote in the beginning of the text, we wouldn't have caught it before
            if { $output(text) eq "" } {
                append output(text) [string repeat {    } $output(blockquote)]
            }

            # Now output the text.
            while { [regexp {^( +|\s|\S+)(.*)$} $text match word text] } {

                # convert &nbsp;'s
                # We do this now, so that they're displayed, but not treated, whitespace.
                regsub -all {&nbsp;} $word { } word

                set wordlen [string length $word]
                switch -glob -- $word {
                    " *" {
                        append output(text) "$word"
                        incr output(linelen) $wordlen
                    }
                    "\n" {
                        if { $output(text) ne "" } {
                            ad_html_to_text_put_newline output
                        }
                    }
                    default {
                        if { $output(linelen) + $wordlen > $output(maxlen) && $output(maxlen) != 0 } {
                            ad_html_to_text_put_newline output
                        }
                        append output(text) "$word"
                        incr output(linelen) $wordlen
                    }
                }
            }
        } else {
            #
            # This is an experimental version that requires a version
            # of NaviServer supporting the "-offset" argument. So it
            # is deactivated for the time being for public use.
            #
            set plain [ns_reflow_text \
                           -offset $output(linelen) \
                           -width $output(maxlen) \
                           $text]
            set lastNewLine [string last \n $plain]
            #ns_log notice "ns_reflow_text -width $output(maxlen) <$text>\ntext: $text\nplain $plain"
            if {$lastNewLine == -1} {
                incr output(linelen) [string length $plain]
            } else {
                set output(linelen) [expr {[string length $plain] - $lastNewLine}]
            }
            set plain [join [split $plain \n] \n[string repeat {    } $output(blockquote)]]
            #ns_log notice "plain\n$plain"
            #ns_log notice "blockquote $output(blockquote) linelen $output(linelen) maxlen $output(maxlen)"
            append output(text) $plain
        }
    }

    ad_proc util_expand_entities { html } {

        Replaces all occurrences of common HTML entities with their plaintext equivalents
        in a way that's appropriate for pretty-printing.

        <p>

        Currently, the following entities are converted:
        &amp;lt;, &amp;gt;, &apm;quot;,  &amp;amp;, &amp;mdash; and &amp;#151;.

        <p>

        This proc is more suitable for pretty-printing that its
        sister-proc, <a href="/api-doc/proc-view?proc=util_expand_entities_ie_style"><code>util_expand_entities_ie_style</code></a>.
        The two differences are that this one is more strict: it requires
        proper entities i.e., both opening ampersand and closing semicolon,
        and it doesn't do numeric entities, because they're generally not safe to send to browsers.
        If we want to do numeric entities in general, we should also
        consider how they interact with character encodings.

    } {
        regsub -all {&lt;} $html {<} html
        regsub -all {&gt;} $html {>} html
        regsub -all {&quot;} $html "\"" html
        regsub -all {&mdash;} $html {--} html
        regsub -all {&#151;} $html {--} html
        # Need to do the &amp; last, because otherwise it could interfere with the other expansions,
        # e.g., if the text said &amp;lt;, that would be translated into <, instead of &lt;
        regsub -all {&amp;} $html {\&} html
        return $html
    }

    ad_proc util_expand_entities_ie_style { html } {
        Replaces all occurrences of &amp;#111; and &amp;x0f; type HTML character entities
        to their ASCII equivalents. It also handles lt, gt, quot, ob, cb and amp.

        <p>

        This proc does the expansion in the style of IE and Netscape, which is to say that it
        doesn't require the trailing semicolon on the entity to replace it with something else.
        The reason we do that is that this proc was designed for checking HTML for security-issues,
        and since entities can be used for hiding malicious code, we'd better simulate the
        liberal interpretation that browsers does, even though it complicates matters.

        <p>

        Unlike its sister proc, <a href="/api-doc/proc-view?proc=util_expand_entities"><code>util_expand_entities</code></a>,
        it also expands numeric entities (#999 or #xff style).

        @author Lars Pind (lars@pinds.com)
        @creation-date October 17, 2000
    } {
        array set entities { lt < gt > quot \" ob \{ cb \} amp & }

        # Expand HTML entities on the value
        for { set i [string first & $html] } { $i != -1 } { set i [string first & $html $i] } {

            set match_p 0
            switch -regexp -- [string index $html $i+1]] {
                # {
                switch -regexp -- [string index $html $i+2] {
                    [xX] {
                        regexp -indices -start [expr {$i+3}] {[0-9a-fA-F]*} $html hex_idx
                        set hex [string range $html [lindex $hex_idx 0] [lindex $hex_idx 1]]
                        set html [string replace $html $i [lindex $hex_idx 1] \
                                      [subst -nocommands -novariables "\\x$hex"]]
                        set match_p 1
                    }
                    [0-9] {
                        regexp -indices -start [expr {$i+2}] {[0-9]*} $html dec_idx
                        set dec [string range $html [lindex $dec_idx 0] [lindex $dec_idx 1]]
                        # $dec might contain leading 0s. Since format evaluates $dec as expr
                        # leading 0s cause octal interpretation and therefore errors on e.g. &#0038;
                        set dec [string trimleft $dec 0]
                        if {$dec eq ""} {set dec 0}
                        set html [string replace $html $i [lindex $dec_idx 1] \
                                      [format "%c" $dec]]
                        set match_p 1
                    }
                }
            }
        [a-zA-Z] {
            if { [regexp -indices -start $i {\A&([^\s;]+)} $html match entity_idx] } {
                set entity [string tolower [string range $html [lindex $entity_idx 0] [lindex $entity_idx 1]]]
                if { [info exists entities($entity)] } {
                    set html [string replace $html $i [lindex $match 1] $entities($entity)]
                }
                set match_p 1
            }
        }
    }
    incr i
    if { $match_p } {
        # remove trailing semicolon
        if {[string index $html $i] eq ";"} {
            set html [string replace $html $i $i]
        }
    }
}
return $html
}



####################
#
# Text -> Text
#
####################

if {[info commands ns_reflow_text] eq ""} {
    #
    # Define compatibility function for those implementations, that do
    # not have the built-in version of NaviServer
    #
    ad_proc ns_reflow_text {{-width 80} {-prefix ""} {-offset 0} input} {

        Reflow a plain text to the given width and prefix every line
        optionally wiith the provided string. If offset is used, the
        function can be used when e.g. appending the result to some
        constant prefix or when the reflow happens incrementally.

    } {

        if {$offset > 0} {
            set input [string repeat X $offset]$input
        }

        set result_rows [list]
        set start_of_line_index 0
        while 1 {
            set this_line [string range $input $start_of_line_index [expr {$start_of_line_index + $width - 1}]]
            if { $this_line eq "" } {
                set result [join $result_rows "\n"]
                break
            }
            set first_new_line_pos [string first "\n" $this_line]
            if { $first_new_line_pos != -1 } {
                # there is a newline
                lappend result_rows [string range $input $start_of_line_index \
                                         [expr {$start_of_line_index + $first_new_line_pos - 1}]]
                set start_of_line_index [expr {$start_of_line_index + $first_new_line_pos + 1}]
                continue
            }
            if { $start_of_line_index + $width + 1 >= [string length $input] } {
                # we're on the last line and it is < width so just return it
                lappend result_rows $this_line
                break
            }
            set last_space_pos [string last " " $this_line]
            if { $last_space_pos == -1 } {
                # no space found!  Try the first space in the whole rest of the string
                set next_space_pos [string first " " [string range $input $start_of_line_index end]]
                set next_newline_pos [string first "\n" [string range $input $start_of_line_index end]]
                if {$next_space_pos == -1} {
                    set last_space_pos $next_newline_pos
                } elseif {$next_space_pos < $next_newline_pos} {
                    set last_space_pos $next_space_pos
                } else {
                    set last_space_pos $next_newline_pos
                }
                if { $last_space_pos == -1 } {
                    # didn't find any more whitespace, append the whole thing as a line
                    lappend result_rows [string range $input $start_of_line_index end]
                    break
                }
            }
            # OK, we have a last space pos of some sort
            set real_index_of_space [expr {$start_of_line_index + $last_space_pos}]
            lappend result_rows [string range $input $start_of_line_index $real_index_of_space-1]
            set start_of_line_index [expr {$start_of_line_index + $last_space_pos + 1}]
        }

        set result [join $result_rows "\n$prefix"]
        if {$offset > 0} {
            set result [string range $result $offset end]
        }

        return $prefix$result
    }
}


ad_proc -deprecated wrap_string {input {width 80}} {
    wraps a string to be no wider than 80 columns by inserting line breaks

    @see ns_reflow_text
} {
    return [ns_reflow_text -width $width -prefix "" $input]
}




####################
#
# Wrappers to make it easier to write generic code
#
####################

ad_proc -public ad_html_text_convertable_p {
    -from
    -to
} {
    Returns true of ad_html_text_convert can handle the given from and to mime types.
} {
    set valid_froms { text/enhanced text/markdown text/plain text/fixed-width text/html text/xml }
    set valid_tos { text/plain text/html }
    # Validate procedure input
    set from [ad_decode $from html text/html text text/plain plain text/plain pre text/plain $from]
    set to   [ad_decode $to   html text/html text text/plain plain text/plain pre text/plain $to]
    return [expr {$from in $valid_froms && $to in $valid_tos}]
}

ad_proc -public ad_html_text_convert {
    {-from text/plain}
    {-to text/html}
    {-maxlen 70}
    {-truncate_len 0}
    {-ellipsis "..."}
    {-more ""}
    text
} {
    Converts a chunk of text from a variety of formats to either
    text/html or text/plain.

    <p>

    Example: ad_html_text_convert -from "text/html" -to "text/plain" -- "text"

    <p>

    Putting in the -- prevents Tcl from treating a - in text portion
    from being treated as a parameter.

    <p>

    Html to html closes any unclosed html tags
    (see util_close_html_tags).

    <p>

    Text to html does ad_text_to_html, and html to text does a
    ad_html_to_text. See those procs for details.

    <p>

    When text is empty, then an empty string will be returned
    regardless of any format. This is especially useful when
    displaying content that was created with the richtext widget
    and might contain empty values for content and format.

    @param from specify what type of text you're providing. Allowed values:
    <ul>
    <li>text/plain</li>
    <li>text/enhanced</li>
    <li>text/markdown</li>
    <li>text/fixed-width</li>
    <li>text/html</li>
    </ul>

    @param to specify what format you want this translated into. Allowed values:
    <ul>
    <li>text/plain</li>
    <li>text/html</li>
    </ul>

    @param maxlen        The maximum line width when generating text/plain

    @param truncate_len  The maximum total length of the output, included ellipsis.

    @param ellipsis      This will get put at the end of the truncated string, if the string was truncated.
    However, this counts towards the total string length, so that the returned string
    including ellipsis is guaranteed to be shorter than the 'truncate_len' provided.

    @param more          This will get put at the end of the truncated string, if the string was truncated.

    @author Lars Pind (lars@pinds.com)
    @creation-date 19 July 2000
} {
    # DRB: Modified this to accept mime types (text/plain or
    # text/html).  Simplifies things when providing confirmation pages
    # for input destined for the content repository ...

    if { $text eq "" } {
        return ""
    }

    # For backwards compatibility
    set from [ad_decode $from html text/html text text/plain plain text/plain pre text/plain $from]
    set to   [ad_decode $to   html text/html text text/plain plain text/plain pre text/plain $to]

    if { ![ad_html_text_convertable_p -from $from -to $to] } {
        error "Illegal mime types for conversion - from: $from to: $to"
    }

    # Do the conversion
    switch -- $from {
        text/enhanced {
            switch -- $to {
                text/html {
                    set text [ad_enhanced_text_to_html $text]
                }
                text/plain {
                    set text [ad_enhanced_text_to_plain_text -maxlen $maxlen -- $text]
                }
            }
        }
        text/markdown {
            package require Markdown
            switch -- $to {
                text/html {
                    regsub -all \r\n $text \n text
                    #
                    # Try syntax highlighting just when target is text/html
                    #
                    if {[info commands ::Markdown::register] ne ""} {
                        #
                        # We can register a converter
                        #
                        ::Markdown::register tcl ::apidoc::tclcode_to_html
                    }

                    set text [Markdown::convert $text]

                    if {[info commands ::Markdown::get_lang_counter] ne ""} {

                        set d [::Markdown::get_lang_counter]
                        if {$d ne ""} {
                            template::head::add_style -style $::apidoc::style

                            if {0} {
                                template::head::add_css \
                                    -href //cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/styles/default.min.css
                                template::head::add_javascript \
                                    -src "//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/highlight.min.js"
                                security::csp::require script-src cdnjs.cloudflare.com
                                security::csp::require style-src cdnjs.cloudflare.com

                                template::add_body_script -script "hljs.initHighlightingOnLoad();"
                                #
                                # In case we have Tcl, load the extra lang
                                # support which is not included in the
                                # default package.
                                #
                                if {[dict get $d tcl]} {
                                    template::head::add_javascript \
                                        -src "//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/languages/tcl.min.js"
                                }
                            }
                            ::Markdown::reset_lang_counter
                        }
                    }
                }
                text/plain {
                    regsub -all \r\n $text \n text
                    set htmlText [Markdown::convert $text]
                    set text [ad_html_to_text -maxlen $maxlen -- $htmlText]
                }
            }
        }
        text/plain {
            switch -- $to {
                text/html {
                    set text [ad_text_to_html -- $text]
                }
                text/plain {
                    set text [ns_reflow_text -width $maxlen -- $text]
                }
            }
        }
        text/fixed-width {
            switch -- $to {
                text/html {
                    set text "<pre>[ad_text_to_html -no_lines -- $text]</pre>"
                }
                text/plain {
                    set text [ns_reflow_text -width $maxlen -- $text]
                }
            }
        }
        text/html {
            switch -- $to {
                text/html {
                    # Handled below
                }
                text/plain {
                    set text [ad_html_to_text -maxlen $maxlen -- $text]
                }
            }
        }
        text/xml {
            switch -- $to {
                text/html {
                    set text "<pre>[ad_text_to_html -no_lines -- $text]</pre>"
                }
                text/plain {
                    set text [ns_reflow_text -width $maxlen -- $text]
                }
            }
        }
    }

    # Handle closing of HTML tags, truncation
    switch -- $to {
        text/html {
            set text [util_close_html_tags $text $truncate_len $truncate_len $ellipsis $more]
        }
        text/plain {
            set text [string_truncate -ellipsis $ellipsis -more $more -len $truncate_len -- $text]
        }
    }

    return $text
}

ad_proc -public ad_enhanced_text_to_html {
    text
} {
    Converts enhanced text format to normal HTML.
    @author Lars Pind (lars@pinds.com)
    @creation-date 2003-01-27
} {
    return [ad_text_to_html -no_quote -includes_html -- $text]
}

ad_proc -public ad_enhanced_text_to_plain_text {
    {-maxlen 70}
    text
} {
    Converts enhanced text format to normal plaintext format.
    @author Lars Pind (lars@pinds.com)
    @creation-date 2003-01-27
} {
    # Convert the HTML version to plaintext.
    return [ad_html_to_text -maxlen $maxlen -- [ad_enhanced_text_to_html $text]]
}



ad_proc -public ad_convert_to_html {
    {-html_p f}
    text
} {
    Convenient interface to convert text or html into html.
    Does the same as <code><a href="/api-doc/proc-view?proc=ad_html_text_convert">ad_html_text_convert</a> -to html</code>.

    @param html_p specify <code>t</code> if the value of
    <code>text</code> is formatted in HTML, or <code>f</code> if <code>text</code> is plaintext.

    @author Lars Pind (lars@pinds.com)
    @creation-date 19 July 2000
} {
    if {$html_p == "t"} {
        set from "text/html"
    } else {
        set from "text/plain"
    }
    return [ad_html_text_convert -from $from -to "text/html" -- $text]
}

ad_proc -public ad_convert_to_text {
    {-html_p t}
    text
} {
    Convenient interface to convert text or html into plaintext.
    Does the same as <code><a href="/api-doc/proc-view?proc=ad_html_text_convert">ad_html_text_convert</a> -to text</code>.

    @param html_p specify <code>t</code> if the value of
    <code>text</code> is formatted in HTML, or <code>f</code> if <code>text</code> is plaintext.

    @author Lars Pind (lars@pinds.com)
    @creation-date 19 July 2000
} {
    if {$html_p == "t"} {
        set from "text/html"
    } else {
        set from "text/plain"
    }
    return [ad_html_text_convert -from $from -to "text/plain" -- $text]
}


ad_proc -public ad_looks_like_html_p {
    text
} {
    Tries to guess whether the text supplied is text or html.

    @param text the text you want tested.
    @return 1 if it looks like html, 0 if not.

    @author Lars Pind (lars@pinds.com)
    @creation-date 19 July 2000
} {
    if { [regexp -nocase {<p>} $text] || [regexp -nocase {<br>} $text] || [regexp -nocase {</a} $text] } {
        return 1
    } else {
        return 0
    }
}

ad_proc util_remove_html_tags { html } {
    Removes everything between &lt; and &gt; from the string.
} {
    regsub -all {<[^>]*>} $html {} html
    return $html
}


#####
#
# Truncate
#
#####

ad_proc -public string_truncate {
    {-len 200}
    {-ellipsis "..."}
    {-more ""}
    {-equal:boolean}
    string
} {
    Truncates a string to len characters adding the string provided in
    the ellipsis parameter if the string was truncated.

    The length of the resulting string, including the ellipsis, is
    guaranteed to be shorter or equal than the len specified.

    Should always be called as string_truncate [-flags ...] -- string
    since otherwise strings which start with a - will treated as
    switches, and will cause an error.

    @param len       The length to truncate to. If zero, no truncation will occur.

    @param ellipsis  This will get put at the end of the truncated string, if the string was truncated.
                     However, this counts towards the total string length, so that the returned string
                     including ellipsis is guaranteed to be shorter or equal than the 'len' provided.

    @param more      This will get put at the end of the truncated string, if the string was truncated.

    @param string    The string to truncate.

    @return The truncated string

    @author Lars Pind (lars@pinds.com)
    @creation-date September 8, 2002
} {
    if { $len > 0 & [string length $string] > $len } {
        set end_index [expr {$len-[string length $ellipsis]-1}]

        # Back up to the nearest whitespace
        if {[regexp -indices {\s\S*$} [string range $string 0 [expr {$end_index+1}]] match]} {
            set last_space [lindex $match 0]
        } else {
            set last_space -1
        }
        # If that leaves us with an empty string, then ignore
        # whitespace and just truncate mid-word
        set end_index [expr {$last_space > 0 ? $last_space : $end_index}]

        # Chop off extra whitespace at the end
        set string [string trimright [string range $string 0 $end_index]]${ellipsis}${more}
    }

    return $string
}

ad_proc -public ad_pad {
    -left:boolean
    -right:boolean
    string
    length
    padstring
} {
    Tcl implementation of the pad string function found in many DBMSs.<br>
    One of the directional flags -left or -right must be specified and
    will dictate whether this will be a lpad or a rpad.

    @param left text will be appended left of the original string.
    @param right text will be appended right of the original string.

    @arg string String to be padded.

    @arg length length this string will be after padding. If string
                this long or longer, will be truncated.

    @arg padstring string that will be repeated until length of
    supplied string is equal or greather than length.

    @return padded string
} {
    if {!($left_p ^ $right_p)} {
        error "Please specify single flag -left or -right"
    }

    set slength [string length $string]
    set padlength [string length $padstring]
    set repetitions [expr {int(($length - $slength) / $padlength) + 1}]
    set appended [string repeat $padstring $repetitions]

    if {$left_p} {
        set string [string range $appended$string end-[expr {$length - 1}] end]
    } else {
        set string [string range $string$appended 0 [expr {$length - 1}]]
    }

    return $string
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
