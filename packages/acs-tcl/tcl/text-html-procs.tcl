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
    @param encode This will encode international characters into it's html equivalent, like "ü" into &uuml;

    @author Branimir Dolicki (branimir@arsdigita.com)
    @author Lars Pind (lars@pinds.com)
    @creation-date 19 July 2000
} {
    if { [empty_string_p $text] } {
        return {}
    }
    
    if { !$no_links_p } {
	# We start by putting a space in front so our URL/email highlighting will work
	# for URLs/emails right in the beginning of the text.
	set text " $text"
	
	# if something is " http://" or " https://"
	# we assume it is a link to an outside source. 
	
	# (bd) The only purpose of thiese sTaRtUrL and
	# eNdUrL markers is to get rid of trailing dots,
	# commas and things like that.  Note that there
	# is a \x001 special char before and after each marker.
	
        regsub -nocase -all {([^a-zA-Z0-9]+)(http://[^\(\)"<>\s]+)} $text "\\1\x001sTaRtUrL\\2eNdUrL\x001" text
        regsub -nocase -all {([^a-zA-Z0-9]+)(https://[^\(\)"<>\s]+)} $text "\\1\x001sTaRtUrL\\2eNdUrL\x001" text
        regsub -nocase -all {([^a-zA-Z0-9]+)(ftp://[^\(\)"<>\s]+)} $text "\\1\x001sTaRtUrL\\2eNdUrL\x001" text

        # Don't dress URLs that are already HREF=... or SRC=... chunks
        if { $includes_html_p } {
            regsub -nocase -all {(href\s*=\s*['"]?)\x001sTaRtUrL([^\x001]*)eNdUrL\x001} $text {\1\2} text
            regsub -nocase -all {(src\s*=\s*['"]?)\x001sTaRtUrL([^\x001]*)eNdUrL\x001} $text {\1\2} text
        }
	
	# email links have the form xxx@xxx.xxx
        # JCD: don't treat things =xxx@xxx.xxx as email since most
        # common occurance seems to be in urls (although VPATH bounce
        # emails like bounce-user=domain.com@sourcehost.com will then not
        # work correctly).  It's all quite ugly.
 
        regsub -nocase -all {([^a-zA-Z0-9=]+)(mailto:)?([^=\(\)\s:;,@<>]+@[^\(\)\s.:;,@<>]+[.][^\(\)\s:;,@<>]+)} $text \
                "\\1\x001sTaRtEmAiL\\3eNdEmAiL\x001" text
    }    

    # At this point, before inserting some of our own <, >, and "'s
    # we quote the ones entered by the user:
    if { !$no_quote_p } {
        set text [ad_quotehtml $text]
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

	for  { set i 0 }   { $i  < [ llength  $myChars ] }   { incr i }  {
	    set  text [ string map "[ lindex $myChars $i ] [ lindex  $myHTML  $i ]" $text ]
	}
    }

    # Convert line breaks
    if { !$no_lines_p } {
        set text [util_convert_line_breaks_to_html -includes_html=$includes_html_p -- $text]
    }

    if { !$no_quote_p } {
        # Convert every two spaces to an nbsp
        regsub -all {  } $text "\\\&nbsp; " text
        
        # Convert tabs to four nbsp's
        regsub -all {\t} $text {\&nbsp;\&nbsp;\&nbsp;\&nbsp;} text
    }

    if { !$no_links_p } {
        # Move the end of the link before any punctuation marks at the end of the URL
	regsub -all {([]!?.:;,<>\(\)\}"'-]+)(eNdUrL\x001)} $text {\2\1} text
	regsub -all {([]!?.:;,<>\(\)\}"'-]+)(eNdEmAiL\x001)} $text {\2\1} text

	# Dress the links and emails with A HREF
	regsub -all {\x001sTaRtUrL([^\x001]*)eNdUrL\x001} $text {<a href="\1">\1</a>} text
	regsub -all {\x001sTaRtEmAiL([^\x001]*)eNdEmAiL\x001} $text {<a href="mailto:\1">\1</a>} text
	set text [string trimleft $text]
    }

    # JCD: Remove all the eNd sTaRt stuff and warn if we do it since its bad
    # to have these left (means something is broken in our regexps above)
    if {[regsub -all {(\x001sTaRtUrL|eNdUrL\x001|\x001sTaRtEmAiL|eNdEmAiL\x001)} $text {} text]} {
        ns_log warning "Replaced sTaRt/eNd magic tags in ad_text_to_html"
    }

    return $text
}

ad_proc -public util_convert_line_breaks_to_html {
    {-includes_html:boolean}
    text
} {
    Convert line breaks to <p> and <br> tags, respectively.
} {
    # Remove any leading or trailing whitespace
    regsub {^[\s]*} $text {} text
    regsub {[\s]*$} $text {} text

    # Make sure all line breaks are single \n's
    regsub -all {\r\n} $text "\n" text
    regsub -all {\r} $text "\n" text
    
    # Remove whitespace before \n's
    regsub -all {[ \t]*\n} $text "\n" text
    
    # Wrap P's around paragraphs
    regsub -all {([^\n\s])\n\n([^\n\s])} $text {\1</p><p>\2} text

    # Convert _single_ CRLF's to <br>'s to preserve line breaks
    # Lars: This must be done after we've made P tags, because otherwise the line
    # breaks will already have been converted into BR's.

    # remove line breaks right before and after HTML tags that will insert a paragraph break themselves
    if { $includes_html_p } {
        foreach tag { ul ol li blockquote p div table tr td th } {
            regsub -all -nocase "\\n\\s*(</?${tag}\\s*\[^>\]*>)" $text {\1} text
            regsub -all -nocase "(</?${tag}\\s*\[^>\]*>)\\s*\\n" $text {\1} text
        }
    }

    regsub -all {\n} $text "<br />\n" text

    # Add line breaks to P tags
    regsub -all {</p>} $text "</p>\n" text

    # Last <p> tag
    set idx [string last "<p>" [string tolower $text]]
    if { $idx != -1 } {
        set text "[string range $text 0 [expr $idx-1]]<p style=\"margin-bottom: 0px;\">[string range $text [expr $idx+3] end]"
    }

    return $text
}



ad_proc -public ad_quotehtml { arg } {

    Quotes ampersands, double-quotes, and angle brackets in $arg.
    Analogous to ns_quotehtml except that it quotes double-quotes (which
    ns_quotehtml does not).

    @see ad_unquotehtml
} {
    return [string map {& &amp; \" &quot; < &lt; > &gt;} $arg]
}

ad_proc -public ad_unquotehtml {arg} {
    reverses ad_quotehtml

    @see ad_quotehtml
} {
    return [string map {&gt; > &lt; < &quot; \" &amp; &} $arg]
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
    set frag $html_fragment 

    set syn(A) nobr
    set syn(ADDRESS) nobr
    set syn(NOBR) nobr
    #
    set syn(FORM) discard
    #
    set syn(BLINK) remove 
    #
    set syn(TABLE) close
    set syn(FONT) close
    set syn(B) close
    set syn(BIG) close
    set syn(I) close
    set syn(S) close
    set syn(SMALL) close
    set syn(STRIKE) close
    set syn(SUB) close
    set syn(SUP) close
    set syn(TT) close
    set syn(U) close
    set syn(ABBR) close
    set syn(ACRONYM) close
    set syn(CITE) close
    set syn(CODE) close
    set syn(DEL) close
    set syn(DFN) close
    set syn(EM) close
    set syn(INS) close
    set syn(KBD) close
    set syn(SAMP) close
    set syn(STRONG) close
    set syn(VAR) close
    set syn(DIR) close
    set syn(DL) close
    set syn(MENU) close
    set syn(OL) close
    set syn(UL) close
    set syn(H1) close
    set syn(H2) close
    set syn(H3) close
    set syn(H4) close
    set syn(H5) close
    set syn(H6) close
    set syn(BDO) close
    set syn(BLOCKQUOTE) close
    set syn(CENTER) close
    set syn(DIV) close
    set syn(PRE) close
    set syn(Q) close
    set syn(SPAN) close

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
                    if {! $nobr && [expr [string length $pretag] + $out_len] > $break_soft } {
                        # first chop pretag to the right length
                        set pretag [string range $pretag 0 [expr $break_soft - $out_len - [string length $ellipsis]]]
                        # clip the last word
                        regsub "\[^ \t\n\r]*$" $pretag {} pretag
                        append out [string range $pretag 0 $break_soft]
                        set broken_p 1
                        break
                    } elseif { $nobr &&  [expr [string length $pretag] + $out_len] > $break_hard } {
                        # we are in a nonbreaking tag and are past the hard break
                        # so chop back to the point we got the nobr tag...
                        set tagptr $nobr_tagptr 
                        if { $nobr_out_point > 0 } { 
                            set out [string range $out 0 [expr $nobr_out_point - 1]]
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
            if  { $tag == "" } { 
                # if the tag is empty we might have one of the bad matched that are not eating 
                # any of the string so check for them 
                if {[string length $match] == [string length $frag]} { 
                    append out $frag
                    set frag {}
                }
            } else {
                set tag [string toupper $tag]            
                if { ![info exists syn($tag)]} {
                    # if we don't have an entry in our syntax table just tack it on 
                    # and hope for the best.
                    if { ! $discard } {
                        append  out $fulltag
                    }
                } else {
                    if { $close != "/" } {
                        # new tag 
                        # "remove" tags are just ignored here
                        # discard tags 
                        if { $discard } { 
                            if { $syn($tag) == "discard" } {
                                incr discard 
                                incr tagptr 
                                set tagstack($tagptr) $tag
                            }
                        } else {
                            switch $syn($tag) {
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
                            if { $syn($tag) == "discard"} {
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
                            if { $syn($tag) != "remove"} {
                                # if tag is a remove tag we just ignore it...
                                if {$tagptr > -1} {
                                    if {$tag != $tagstack($tagptr) } {
                                        # puts "/$tag without $tag"
                                    } else {
                                        incr tagptr -1
                                        if { $syn($tag) == "nobr"} {
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
        set end_index [expr [string length $out] -1]
        while { $end_index >= 0 && [string is space [string index $out $end_index]] } {
            incr end_index -1
        } 
        set out [string range $out 0 $end_index]
    }

    for { set i $tagptr } { $i > -1 } { incr i -1 } { 
        set tag $tagstack($i)

        # LARS: Only close tags which we aren't supposed to remove
        if { ![string equal $syn($tag) "discard"] && ![string equal $syn($tag) "remove"] } {
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
    while { $i < [string length $html] && ![string equal [string index $html $i] {>}] } {
	if { [incr count] > 1000 } {
	    error "There appears to be a programming bug in ad_parse_html_attributes_upvar: We've entered an infinite loop. We are here: \noffset $i: [string range $html $i [expr $i + 60]]"
	}
	if { [string equal [string range $html $i [expr { $i + 1 }]] "/>"] } {
	    # This is an XML-style tag ending: <... />
	    break
	}
	
	# This regexp matches an attribute name and an equal sign, if present. 
	# Also eats whitespace before or after.
	# The \A corresponds to ^, except it matches the position we're starting from, not the start of the string
	if { ![regexp -indices -start $i {\A\s*([^\s=>]+)\s*(=?)\s*} $html match attr_name_idx equal_sign_idx] } {
	    # Apparantly, there's no attribute name here. Let's eat all whitespace and lonely equal signs.
	    regexp -indices -start $i {\A[\s=]*} $html match
	    set i [expr { [lindex $match 1] + 1 }]
	} {
	    set attr_name [string tolower [string range $html [lindex $attr_name_idx 0] [lindex $attr_name_idx 1]]]
	    
	    # Move past the attribute name just found
	    set i [expr { [lindex $match 1] + 1}]
	    
	    # If there is an equal sign, we're expecting the next token to be a value
	    if { [lindex $equal_sign_idx 1] - [lindex $equal_sign_idx 0] < 0 } {
		# No equal sign, no value
		lappend attributes $attr_name
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
		    set attr_value [string range $html [expr {$i+1}] end]
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

    foreach tag $allowed_tags_list {
	set allowed_tag([string tolower $tag]) 1
    }
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
	    # The tag-opener isn't followed by USASCII letters (with or without optional inital slash)
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

		set attr_count 0
		foreach attribute $attr_list {
		    incr attr_count
		    set attr_name [lindex $attribute 0]
		    set attr_value [lindex $attribute 1]
		    
		    if { ![info exists allowed_attribute($attr_name)] && ![info exists allowed_attribute(*)] } {
			return "The attribute '$attr_name' is not allowed for $tagname tags"
		    }
		    
                    if { ![string equal [string tolower $attr_name] "style"] } {
                        if { [regexp {^\s*([^\s:]+):} $attr_value match protocol] } {
                            if { ![info exists allowed_protocol([string tolower $protocol])] && ![info exists allowed_protocol(*)] } {
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
    formatting
    is pretty stupid, but it's better than nothing.
    
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
	ad_html_to_text_put_text output [string range $html $last_tag_end [expr {$i - 1}]]

        # Check that:
        #  - we're not past the end of the string
        #  - and that the tag starts with either
        #     - alpha or
        #     - a slash, and then alpha
        # Otherwise, it's probably just a lone < character
        if { $i >= [expr $length-1] || \
                 (![string is alpha [string index $html [expr $i + 1]]] && \
                      (![string equal "/" [string index $html [expr $i + 1]]] || \
                           ![string is alpha [string index $html [expr $i + 2]]])) } {
            # Output the < and continue with next character
            ad_html_to_text_put_text output "<"
            set last_tag_end [incr i]
            continue
        }
    
	# we're inside a tag now. Find the end of it

	# make i point to the char after the <
	incr i
	set tag_start $i
	
	set count 0
	while 1 {
            if {[incr count] > 1000 } {
                # JCD: the programming bug is that an unmatched < in the input runs off forever looking for 
                # it's closing > and in some long text like program listings you can have lots of quotes 
                # before you find that >
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

	    # If the greater than sign appears before any of the string delimters, we've found the tag end.
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
	
	set full_tag [string range $html $tag_start [expr { $i - 1 }]]

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
		    if { [empty_string_p $slash] } {
			ad_html_to_text_put_text output [string repeat "*" [string index $tagname 1]]
		    }
		}
		li {
		    set output(br) 1
		    if { [empty_string_p $slash] } {
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
                        if { [empty_string_p $slash]} {
                            if { [info exists attribute_array(href)] } {
                                if { [info exists attribute_array(title)] } {
                                    set title ": '$attribute_array(title)'"
                                } else {
                                    set title ""
                                }
                                set href_no [expr [llength $href_urls] + 1]
                                lappend href_urls "\[$href_no\] $attribute_array(href) "
                                lappend href_stack "\[$href_no$title\]"
                            } elseif { [info exists attribute_array(title)] } {
                                lappend href_stack "\[$attribute_array(title)\]"
                            } else {
                                lappend href_stack {}
                            }
                        } else {
                            if { [llength $href_stack] > 0 } {
                                if { ![empty_string_p [lindex $href_stack end]] } {
                                    ad_html_to_text_put_text output " [lindex $href_stack end]"
                                }
                                set href_stack [lreplace $href_stack end end]
                            }
                        }
                    }
		}
		pre {
		    set output(p) 1
		    if { [empty_string_p $slash] } {
			incr output(pre)
		    } else {
			incr output(pre) -1
		    }
		}
		blockquote {
		    set output(p) 1
		    if { [empty_string_p $slash] } {
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
		    if { [empty_string_p $slash] && !$no_format_p } {
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

    for  { set i 0 }   { $i  < [ llength  $myHTML ] }   { incr i }  {
	set output(text) [ string map "[ lindex $myHTML $i ] [ lindex  $myChars  $i ]" $output(text) ]
    }
    #---

    return $output(text)
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
	if { [string equal $text " "] } {
	    set output(space) 1
	    return
	}
	
	# if it's nothing, do nothing
	if { [empty_string_p $text] } {
	    return
	}
	
	# if the first character is a space, set the space bit
	if { [string equal [string index $text 0] " "] } {
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
	if { ![empty_string_p $output(text)] } {
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

    # If there's a blockquote in the beginning of the text, we wouldn't have caught it before
    if { [empty_string_p $output(text)] } {
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
		if { ![empty_string_p $output(text)] } {
		    ad_html_to_text_put_newline output
		}
	    }
	    default {
		if { [expr $output(linelen) + $wordlen] > $output(maxlen) && $output(maxlen) != 0 } {
		    ad_html_to_text_put_newline output
		}
		append output(text) "$word"
		incr output(linelen) $wordlen
	    }
	}
    }
}

ad_proc util_expand_entities { html } {

    Replaces all occurrences of common HTML entities with their plaintext equivalents 
    in a way that's appropriate for pretty-printing.

    <p>

    Currently, the following entities are converted:
    &amp;lt;, &amp;gt;, &apm;quot;,  &amp;amp;, &amp;mdash; and &amp;#151;.

    <p>

    This proc is more suitable for pretty-printing that it's
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

    Unlike it's sister proc, <a href="/api-doc/proc-view?proc=util_expand_entities"><code>util_expand_entities</code></a>,
    it also expands numeric entities (#999 or #xff style).

    @author Lars Pind (lars@pinds.com)
    @creation-date October 17, 2000
} {
    array set entities { lt < gt > quot \" ob \{ cb \} amp & }

    # Expand HTML entities on the value
    for { set i [string first & $html] } \
	    { $i != -1 } \
	    { set i [string first & $html $i] } {
	
	set match_p 0
	switch -regexp -- [string index $html [expr $i+1]] {
	    # {
		switch -regexp -- [string index $html [expr $i+2]] {
		    [xX] {
			regexp -indices -start [expr $i+3] {[0-9a-fA-F]*} $html hex_idx
			set hex [string range $html [lindex $hex_idx 0] [lindex $hex_idx 1]]
			set html [string replace $html $i [lindex $hex_idx 1] \
				[subst -nocommands -novariables "\\x$hex"]]
			set match_p 1
		    }
		    [0-9] {
			regexp -indices -start [expr $i+2] {[0-9]*} $html dec_idx
			set dec [string range $html [lindex $dec_idx 0] [lindex $dec_idx 1]]
			set html [string replace $html $i [lindex $dec_idx 1] \
				[format "%c" $dec]]
			set match_p 1
		    }
		}
	    }
	    [a-zA-Z] {
		if { [regexp -indices -start [expr $i] {\A&([^\s;]+)} $html match entity_idx] } {
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
	    if { [string equal [string index $html $i] {;}] } {
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


ad_proc wrap_string {input {threshold 80}} {
    wraps a string to be no wider than 80 columns by inserting line breaks
} {
    set result_rows [list]
    set start_of_line_index 0
    while 1 {
	set this_line [string range $input $start_of_line_index [expr $start_of_line_index + $threshold - 1]]
	if { $this_line == "" } {
	    return [join $result_rows "\n"]
	}
	set first_new_line_pos [string first "\n" $this_line]
	if { $first_new_line_pos != -1 } {
	    # there is a newline
	    lappend result_rows [string range $input $start_of_line_index [expr $start_of_line_index + $first_new_line_pos - 1]]
	    set start_of_line_index [expr $start_of_line_index + $first_new_line_pos + 1]
	    continue
	}
	if { [expr $start_of_line_index + $threshold + 1] >= [string length $input] } {
	    # we're on the last line and it is < threshold so just return it
		lappend result_rows $this_line
		return [join $result_rows "\n"]
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
		return [join $result_rows "\n"]
	    } 
	}
	# OK, we have a last space pos of some sort
	set real_index_of_space [expr $start_of_line_index + $last_space_pos]
	lappend result_rows [string range $input $start_of_line_index [expr $real_index_of_space - 1]]
	set start_of_line_index [expr $start_of_line_index + $last_space_pos + 1]
    }
}




####################
#
# Wrappers to make it easier to write generic code
#
####################

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
    # text/html).  Simplies things when providing confirmation pages
    # for input destined for the content repository ...

    if { [empty_string_p $text] } {
        return ""
    }

    set valid_froms { text/enhanced text/plain text/fixed-width text/html text/xml }
    set valid_tos { text/plain text/html }
    
    # Validate procedure input
    set from [ad_decode $from "html" "text/html" "text" "text/plain" "plain" "text/plain" $from]
    if { [lsearch $valid_froms $from] == -1 } {
        error "Unknown text input format, '$from'. Valid formats are $valid_froms."
    }
    
    set to [ad_decode $to "html" "text/html" "text" "text/plain" "plain" "text/plain" $to]
    if { [lsearch $valid_tos $to] == -1 } {
        error "Unknown text input format, '$to'. Valid formats are $valid_tos."
    }
    
    # Do the conversion
    switch $from {
        text/enhanced {
	    switch $to {
                text/html {
                    set text [ad_enhanced_text_to_html $text]
		}
                text/plain {
		    set text [ad_enhanced_text_to_plain_text -maxlen $maxlen -- $text]
		}
	    }
        }
        text/plain {
	    switch $to {
                text/html {
		    set text [ad_text_to_html -- $text]
		}
                text/plain {
		    set text [wrap_string $text $maxlen]
		}
	    }
        }
        text/fixed-width {
	    switch $to {
                text/html {
		    set text "<pre>[ad_text_to_html -no_lines -- $text]</pre>"
		}
                text/plain {
		    set text [wrap_string $text $maxlen]
		}
	    }
	} 
        text/html {
	    switch $to {
                text/html {
                    # Handled below
		}
                text/plain {
		    set text [ad_html_to_text -maxlen $maxlen -- $text]
		}
	    }
	}
	text/xml {
	    switch $to {
                text/html {
                    set text "<pre>[ad_text_to_html -no_lines -- $text]</pre>"
		}
                text/plain {
		            set text [wrap_string $text $maxlen]
		}
	    }
	}	 
    }

    # Handle closing of HTML tags, truncation
    switch $to {
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
    if { [string equal $html_p t] } {
	set from html
    } else {
	set from text
    }
    return [ad_html_text_convert -from $from -to html -- $text]
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
    if { [string equal $html_p t] } {
	set from html
    } else {
	set from text
    }
    return [ad_html_text_convert -from $from -to text -- $text]
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
    string 
} {
    Truncates a string to len characters (defaults to the
    parameter TruncateDescriptionLength), adding the string provided in the ellipsis parameter if the
    string was truncated. If format is html (default), any open
    HTML tags are closed. Otherwise, it's converted to text using
    ad_html_to_text.

    The length of the resulting string, including the ellipsis, is guaranteed to be within the len specified.

    Should always be called as string_truncate [-flags ...] -- string 
    since otherwise strings which start with a - will treated as switches, and will cause an error.

    @param len       The lenght to truncate to. If zero, no truncation will occur.

    @param ellipsis  This will get put at the end of the truncated string, if the string was truncated.
                     However, this counts towards the total string length, so that the returned string 
                     including ellipsis is guaranteed to be shorter than the 'len' provided.

    @param more      This will get put at the end of the truncated string, if the string was truncated.

    @param string    The string to truncate.

    @return The truncated string, with HTML tags cloosed or
            converted to text, depending on format.

    @author Lars Pind (lars@pinds.com)
    @creation-date September 8, 2002
} {
    if { $len > 0 } {
        if { [string length $string] > $len } {
            set end_index [expr $len-[string length $ellipsis]-1]

            # Back up to the nearest whitespace
            if { ![string is space [string index $string [expr $end_index + 1]]] } {
                while { $end_index >= 0 && ![string is space [string index $string $end_index]] } {
                    incr end_index -1
                }
            }
            
            # If that laves us with an empty string, then ignore whitespace and just truncate mid-word
            if { $end_index == -1 } {
                set end_index [expr $len-[string length $ellipsis]-1]
            }
            
            # Chop off extra whitespace at the end
            while { $end_index >= 0 && [string is space [string index $string $end_index]] } {
                incr end_index -1
            } 
                
            set string [string range $string 0 $end_index]
            
            append string $ellipsis
            append string $more
        } 
    }
    return $string
}



####################
#
# Legacy stuff
#
####################


ad_proc -deprecated util_striphtml {html} {
    Deprecated. Use ad_html_to_text instead.

    @see ad_html_to_text
} {
    return [ad_html_to_text -- $html]
}


ad_proc -deprecated util_convert_plaintext_to_html { raw_string } {

    Almost everything this proc does can be accomplished with the <a
    href="/api-doc/proc-view?proc=ad_text_to_html"><code>ad_text_to_html</code></a>.
    Use that proc instead. 

    <p>

    Only difference is that ad_text_to_html doesn't check
    to see if the plaintext might in fact be HTML already by
    mistake. But we usually don't want that anyway,
    because maybe the user wanted a &lt;p&gt; tag in his
    plaintext. We'd rather let the user change our
    opinion about the text, e.g. html_p = 't'.

    @see ad_text_to_html
} {
    if { [regexp -nocase {<p>} $raw_string] || [regexp -nocase {<br>} $raw_string] } {
	# user was already trying to do this as HTML
	return $raw_string
    } else {
	return [ad_text_to_html -no_links -- $raw_string]
    }
}

ad_proc -deprecated util_maybe_convert_to_html {raw_string html_p} {
    
    This proc is deprecated. Use <a
    href="/api-doc/proc-view?proc=ad_convert_to_html"><code>ad_convert_to_html</code></a>
    instead.

    @see ad_convert_to_html

}  {
    if { $html_p == "t" } {
	return $raw_string
    } else {
	return [util_convert_plaintext_to_html $raw_string]
    }
}

ad_proc -deprecated -warn util_quotehtml { arg } {
    This proc does exactly the same as <a href="/api-doc/proc-view?proc=ad_quotehtml"><code>ad_quotehtml</code></a>. 
    Use that instead. This one will be deleted eventually.

    @see ad_quotehtml
} {
    return [ad_quotehtml $arg]
}

ad_proc -deprecated util_quote_double_quotes {arg} {
    This proc does exactly the same as <a href="/api-doc/proc-view?proc=ad_quotehtml"><code>ad_quotehtml</code></a>. 
    Use that instead. This one will be deleted eventually.

    @see ad_quotehtml
} {
    return [ad_quotehtml $arg]
}

ad_proc -deprecated philg_quote_double_quotes {arg} {
    This proc does exactly the same as <a href="/api-doc/proc-view?proc=ad_quotehtml"><code>ad_quotehtml</code></a>. 
    Use that instead. This one will be deleted eventually.

    @see ad_quotehtml
} {
    return [ad_quotehtml $arg]
}

