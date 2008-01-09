# packages/acs-mail-lite/tcl/utils-procs.tcl

ad_library {
    
    Helper procs to build email messages
    
    @author Emmanuelle Raffenne (eraffenne@gmail.com)
    @creation-date 2007-12-16
    @arch-tag: 820de9a9-533f-4fc3-b11d-2c9fb616a620
    @cvs-id $Id$
}

namespace eval acs_mail_lite {}
namespace eval acs_mail_lite::utils {}

package require mime

ad_proc acs_mail_lite::utils::build_subject {
    {-charset "UTF-8"}
    subject
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

ad_proc acs_mail_lite::utils::build_date {
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

ad_proc acs_mail_lite::utils::build_body {
    {-mime_type "text/plain"}
    {-charset "UTF-8"}
    body
} {
    Encode the body using quoted-printable and build the alternative
    part if necessary

    Return a list of message tokens
} {

    # Encode the body 
    set encoding [ns_encodingforcharset $charset]
    set body [encoding convertto $encoding $body]

    if { $mime_type eq "text/plain" } {
        # Set the message token
        set message_token [mime::initialize \
                               -canonical "$mime_type" \
                               -param [list charset $charset] \
                               -encoding "quoted-printable" \
                               -string "$body"]
    } else {
        set message_html_part [mime::initialize \
                                   -canonical "text/html" \
                                   -param [list charset $charset] \
                                   -encoding "quoted-printable" \
                                   -string "$body"]
        set message_text_part [mime::initialize \
                                   -canonical "text/plain" \
                                   -param [list charset $charset] \
                                   -encoding "quoted-printable" \
                                   -string [ad_html_to_text "$body"]]
        
        set message_token [mime::initialize \
                               -canonical "multipart/alternative" \
                               -parts [list $message_text_part $message_html_part]]
    }

    return [list $message_token]
}
