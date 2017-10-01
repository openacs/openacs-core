ad_library {
    Contains procs to send HTML email outside of the context of
    ACS Mail package.

    @author Doug Harris (dharris@worldbank.org)
    @author Janine Sisk (jsisk@mit.edu)
    @creation-date 25 Feb 2002
    @cvs-id $Id$
}

# switched to using tcllib, its required for OpenACS >= 5.3
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
    # message text or they are lost. Most noticeable when the line
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
    # line, which is the last boundary, because acs_mail_lite::send seems to be
    # adding another one on for us.

    ## JCD: not anymore.  maybe an AOLserver 3.3 bug?  removing the clipping.
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
    if { [catch {set mime [mime::initialize -string $message]} err ] } {
        ns_log error "parse_incoming_email: could not parse message; error was $err"
        return ""
    }
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
        switch -- $this_content {
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

    if { [info exists plain] } {
        set body $plain
    } elseif { [info exists html] } {
        set body [ad_html_to_text -- $html]
    } else {
        set body $message
    }

    mime::finalize $mime -subordinates all
    return $body
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
