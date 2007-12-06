ad_library {
    Contains procs to send HTML email outside of the context of
    ACS Mail package.

    @author Doug Harris (dharris@worldbank.org)
    @author Janine Sisk (jsisk@mit.edu)
    @creation-date 25 Feb 2002
    @cvs-id $Id$
}

# switched to using tcllib, its required for openacs >= 5.3
package require mime

ad_proc build_mime_message {
    text_body
    html_body
    {charset "UTF-8"}
} {
    Composes multipart/alternative email containing plain text
    and html versions of the message, parses out the headers we need,
    constructs an array  and returns it to the caller. 

    This proc is based on ad_html_sendmail, written by Doug Harris at
    the World Bank.

} {
    # convert text to charset
    set encoding [ns_encodingforcharset $charset]
    if {[lsearch [encoding names] $encoding] != -1} {
        set html_body [encoding convertto $encoding $html_body]
        set text_body [encoding convertto $encoding $text_body]
    } else {
        ns_log error "ad_html_sendmail: unknown charset passed in ($charset)"
    }

    # build body

    ## JCD: I fail to see why you would want both a base64 and a quoted-printable 
    ## version of html part of this email.  I am removing the base64 version.
    ## set base64_html_part [mime::initialize -canonical text/html -param [list charset $charset] -encoding base64 -string $html_body]
    set html_part [mime::initialize -canonical text/html \
                       -param [list charset $charset] \
                       -encoding quoted-printable \
                       -string $html_body]
    set text_part [mime::initialize -canonical text/plain \
                       -param [list charset $charset] \
                       -encoding quoted-printable \
                       -string $text_body]

    set multi_part [mime::initialize \
                        -canonical multipart/alternative \
                        -parts [list $text_part $html_part]]

    # this gives us a complete mime message, minus the headers because
    # we don't pass any in.  This code is designed to send a fully-formed
    # message out through an SMTP socket, but we're not doing that so we
    # have to hijack the process a bit.
    set mime_body [mime::buildmessage $multi_part]
    # mime-encode the periods at the beginning of a line in the
    # message text or they are lost. Most noticable when the line
    # is broken within a URL
    regsub {^\.} $mime_body {=2E} mime_body
    # the first three lines of the message are special; we need to grab
    # the info, add it to the message headers, and discard the lines
    set lines [split $mime_body \n]
    set message_data [ns_set new]

    # get mime version
    regexp {MIME-Version: (.*)} [lindex $lines 0] junk mime_version
    ns_set put $message_data MIME-Version $mime_version
    # the content id
    regexp {Content-ID: (.*)} [lindex $lines 1] junk content_id
    ns_set put $message_data Content-ID $content_id
    # and the content type and boundary
    regexp {Content-Type: (.*)} [lindex $lines 2] junk content_type
    set content_type "$content_type\n[lindex $lines 3]"
    ns_set put $message_data Content-Type $content_type

    # the rest of the lines form the message body.  We strip off the last
    # line, which is the last boundary, because ns_sendmail seems to be
    # adding another one on for us.

    ## JCD: not anymore.  maybe an aolserver 3.3 bug?  removing the clipping.
    ns_set put $message_data body [join [lrange $lines 4 end] \n]

    return $message_data
}


ad_proc parse_incoming_email {
    message
} {
    Takes an incoming message and splits it into parts.  The main goal
    of this proc is to return something that can be stuffed into the
    database somewhere, such as a forum message.  Since we aggressively
    filter HTML, the HTML tags are stripped out of the returned content.

    The message may have only plain text, plain text and HTML, or plain
    text and something else (Apple Mail uses text/enhanced, for example).
    To make our lives simpler we support only text/html as a special case;
    in all other cases the plain text is returned.
} {
    set mime [mime::initialize -string $message]
    set content [mime::getproperty $mime content]

    if { [string first "multipart" $content] != -1 } {
        set parts [mime::getproperty $mime parts]
    } else {
        set parts [list $mime]
    }

    # Expand any first-level multipart/alternative children.
    set expanded_parts [list]
    foreach part $parts {
        catch {mime::getproperty $part content} this_content 
        if { $this_content eq "multipart/alternative"} {
            foreach child_part [mime::getproperty $part parts] {
                lappend expanded_parts $child_part
            }
        } else {
            lappend expanded_parts $part
        }
    }

    foreach part $expanded_parts {
        catch {mime::getproperty $part content} this_content 
        switch $this_content {
            "text/plain" {
                if { ![info exists plain] } {
                    set plain [mime::getbody $part]
                }
            }
            "text/html" {
                if { ![info exists html] } {
                    set html [mime::getbody $part]
                }
            }
        }
    }

    if { [info exists html] } {
        set body [ad_html_to_text -- $html]
    } elseif { [info exists plain] } {
        set body $plain
    } else {
        set body $message
    }

    mime::finalize $mime -subordinates all
    return $body
}

ad_proc build_subject {
    subject
    {charset "UTF-8"}
} {
    Encode the subject, using quoted-printable, of an email message 
    and trim long lines.

    Depending on the available mime package version, it uses either
    the mime::word_encode proc to do it or local code (word_encode is
    buggy in mime < 1.5.2 )

} {

    set charset [string toupper $charset]
    set charset_code [ns_encodingforcharset $charset]
    set subject [encoding convertto $charset_code "$subject"]

    if { [catch {package require mime 1.5.2}] } {

        # encode subject with quoted-printable
        set qp_subject [mime::qp_encode "$subject\n" 1 1]

        # maxlen for each line
        # 69 = 76 - 7 where 7 is for "=?"+"?Q?+"?="
        set maxlen [expr {69 - [string length $charset]}]
        
        # Based on mime::qp_encode to trim long lines
        set result ""
        foreach line [split $qp_subject \n] {
            while {[string length $line] > $maxlen} {
                set chunk [string range $line 0 $maxlen]
                if {[regexp -- {(_[^_]*)$} $chunk dummy end]} {
                    
                    # Don't break in the middle of a word
                    set len [expr {$maxlen - [string length $end]}]
                    set chunk [string range $line 0 $len]
                    incr len
                    set line [string range $line $len end]
                } else {
                    set line [string range $line [expr {$maxlen + 1}] end]
                }
                append result "=?$charset?Q?$chunk?=\n "
            }
            append result "=?$charset?Q?$line?=\n "
        }
        # Trim off last "\n ", since the above code has the side-effect
        # of adding an extra "\n " to the encoded string.
        set result [string range $result 0 end-2]
    } else {
        set result [mime::word_encode $charset_code "quoted-printable" $subject]
    }

    return $result
}

ad_proc build_date {
    {date ""}
} {
    Depending on the available mime package version, it uses either
    the mime::parsedatetime to do it or local code (parsedatetime is
    buggy in mime < 1.5.2 )

    @param date   A 822-style date-time specification "YYYYMMDD HH:MI:SS"

} {

    if { $date eq "" } {
        set clock [clock seconds]
        set date [clock format $clock -format "%Y-%m-%d %H:%M:%S"]
    } else {
        set clock [clock scan $date]
    }

    if { [catch {package require mime 1.5.2}] } {
   
        set gmt [clock format $clock -format "%Y-%m-%d %H:%M:%S" -gmt true]
        if {[set diff [expr {($clock-[clock scan $gmt])/60}]] < 0} {
            set s -
            set diff [expr {-($diff)}]
        } else {
            set s +
        }
        set zone [format %s%02d%02d $s [expr {$diff/60}] [expr {$diff%60}]]

        set wdays_short [list Sun Mon Tue Wed Thu Fri Sat]
        set months_short [list Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]

        set wday [lindex $wdays_short [clock format $clock -format %w]]
        set mon [lindex $months_short [expr {[clock format $clock -format %m] - 1}]]

        set result [clock format $clock -format "$wday, %d $mon %Y %H:%M:%S $zone"]
    } else {
        set result [mime::parsedatetime $date proper]
    }

    return $result

}
