ad_library {

    Provides a variety of compatibility functions for AOLserver,
    including url(en|de)code, cookie management, ad_mutex_eval,
    ns_md5, ns_parseurl, and ns_getcontent.

    @author Gustaf Neumann
}

if {[ns_info name] eq "NaviServer"} {
    return
}

#-------------------------------------------------------------------------
# AOLserver implementation of ad_url(en|de)code* procs
#-------------------------------------------------------------------------

ad_proc -public ad_urlencode_folder_path {path} {
    Perform an urlencode operation on the segments of the provided
    folder (for a full folder path rather than path segments as in
            ad_urlencode_path).
    @see ad_urlencode_path
} {
    set segments {}
    foreach segment [split $path /] {
        lappend segments [ns_urlencode $segment]
    }
    return [join $segments /]
}

ad_proc -public ad_urlencode_path { string } {
    Encode provided string with url-encoding for path segments;
    same as ad_urlencode, since AOLserver does not support this difference
} {
    return [ad_urlencode $string]
}

ad_proc -public ad_urldecode_path { string } {
    Decode provided string with url-encoding for path segments;
    same as ns_urldecode, since AOLserver does not support this difference
} {
    return [ns_urldecode $string]
}

ad_proc -public ad_urlencode_query { string } {
    Encode provided string with url-encodingfor path segments;
    same as ad_urlencode, since AOLserver does not support this difference
} {
    return [ad_urlencode $string]
}

ad_proc -public ad_urldecode_query { string } {
    Decode provided string with url-encoding for path segments;
    same as ns_urldecode, since AOLserver does not support this difference
} {
    return [ns_urldecode $string]
}


#-------------------------------------------------------------------------
# Cookie operations based on AOLserver primitives
#-------------------------------------------------------------------------

ad_proc -public ad_unset_cookie {
    {-secure f}
    {-domain ""}
    {-path "/"}
    name
} {
    Un-sets a cookie.

    @see ad_get_cookie
    @see ad_set_cookie
} {
    ad_set_cookie -replace t -expire t -max_age 0 \
        -secure $secure -domain $domain -path $path \
        $name ""
}

#
# Get Cookie
#
ad_proc -public ad_get_cookie {
    { -include_set_cookies t }
    name
    { default "" }
} {
    Returns the value of a cookie, or $default if none exists.

    @see ad_set_cookie
    @see ad_unset_cookie
} {

    if { $include_set_cookies == "t" } {
        set headers [ns_conn outputheaders]
        set nr_headers [ns_set size $headers]
        for { set i 0 } { $i < $nr_headers } { incr i } {
            if { [string tolower [ns_set key $headers $i]] eq "set-cookie"
                 && [regexp "^$name=(\[^;\]*)" [ns_set value $headers $i] match value]
             } {
                return [ns_urldecode $value]
            }
        }
    }

    set headers [ns_conn headers]
    set cookie [ns_set iget $headers Cookie]

    if { [regexp " $name=(\[^;\]*)" " $cookie" match value] } {

        # If the cookie was set to a blank value we actually stored two quotes.  We need
        # to undo the kludge on the way out.

        if { $value eq "\"\"" } {
            set value ""
        }
        return [ns_urldecode $value]
    }

    return $default
}

#
# Set Cookie
#
ad_proc -public ad_set_cookie {
    {-replace f}
    {-secure f}
    {-expire f}
    {-max_age ""}
    {-domain ""}
    {-path "/"}
    {-discard f}
    {-scriptable t}
    name
    {value ""}
} {

    Sets a cookie.  Cookies are name/value pairs stored in a client's
    browser and are typically sent back to the server of origin with
    each request.

    @param max_age specifies the maximum age of the cookies in
    seconds (consistent with RFC 2109). max_age "inf" specifies cookies
    that never expire. The default behavior is to issue session
    cookies.

    @param expire specifies whether we should expire (clear) the cookie.
    Setting Max-Age to zero ought to do this, but it doesn't in some browsers
    (tested on IE 6).

    @param path specifies a subset of URLs to which this cookie
    applies. It must be a prefix of the URL being accessed.

    @param domain specifies the domain(s) to which this cookie
    applies. See RFC2109 for the semantics of this cookie attribute.

    @param secure specifies to the user agent that the cookie should
    only be transmitted back to the server of secure transport.

    @param replace forces the current output headers to be checked for
    the same cookie. If the same cookie is set for a second time
    without the replace option being specified, the client will
    receive both copies of the cookie.

    @param discard instructs the user agent to discard the cookie when
    the user agent terminates.

    @param scriptable If the scriptable option is false or not given
    the cookie is unavailable to JavaScript on the client. This can
    prevent cross site scripting attacks (XSS) on clients which
    support the HttpOnly option. Set -scriptable to true if you need
    to access the cookie via javascript. For compatibility reasons
    with earlier versions, OpenACS 5.8 has the default set to
    "true". OpenACS 5.9 will have the flag per default set to "false".

    @param value is autmatically URL encoded.

    @see ad_get_cookie
    @see ad_unset_cookie
} {
    set headers [ad_conn outputheaders]
    if { $replace } {
        # Try to find an already-set cookie named $name.
        for { set i 0 } { $i < [ns_set size $headers] } { incr i } {
            if { [string tolower [ns_set key $headers $i]] eq "set-cookie"
                 && [string match "$name=*" [ns_set value $headers $i]]
             } {
                ns_set delete $headers $i
            }
        }
    }

    # need to set some value, so we put "" as the cookie value
    if { $value eq "" } {
        set cookie "$name=\"\""
    } else {
        set cookie "$name=[ns_urlencode $value]"
    }

    if { $path ne "" } {
        append cookie "; Path=$path"
    }

    if { $discard != "f" } {
        append cookie "; Discard"
    } elseif { $max_age eq "inf" } {
        if { $expire == "f"} {
            #
            # netscape seemed unhappy with huge max-age, so we use
            # expires which seems to work on both netscape and IE
            #
            append cookie "; Expires=Mon, 01-Jan-2035 01:00:00 GMT"
        }
    } elseif { $max_age ne "" } {
        #
        # We know $max_age is also not "inf"
        #
        append cookie "; Max-Age=$max_age"
        if {$expire == "f"} {
            # Reinforce Max-Age via "Expires", unless user required
            # immediate expiration
            set expire_time [util::cookietime [expr {[ns_time] + $max_age}]]
            append cookie "; Expires=$expire_time"
        }
    }

    if {$expire != "f"} {
        append cookie "; Expires=Tue, 01-Jan-1980 01:00:00 GMT"
    }

    if { $domain ne "" } {
        append cookie "; Domain=$domain"
    }

    if { $secure == "t" } {
        append cookie "; Secure"
    }

    if { $scriptable == "f" } {
        # Prevent access to this cookie via JavaScript
        append cookie "; HttpOnly"
    }

    ns_log Debug "OACS Set-Cookie: $cookie"
    ns_set put $headers "Set-Cookie" $cookie
}


#-------------------------------------------------------------------------
# Provide a clean way of handling exceptions in mutexed regions
# (between locking and unlocking of an mutex). Should be used probably
# on more places in OpenACS.
#-------------------------------------------------------------------------

ad_proc -public ad_mutex_eval {mutex script} {

    Compatibility proc for handling differences between NaviServer
    and AOLserver since AOLserver does not support "ns_mutex
    eval".

    @author Gustaf Neumann

} {
    ns_mutex lock $mutex
    ad_try {
        set result [uplevel $script]
    } on error {errorMsg} {
        error $errorMsg
    } finally {
        ns_mutex unlock $mutex
    }
    return $result
}


#-------------------------------------------------------------------------
# In case, we are not running under NaviServer, provide a proc
# compatible with NaviServer's built in ns_md5
#-------------------------------------------------------------------------
ad_proc ns_md5 {value} {
    Emulation of NaviServer's ns_md5

    @author Gustaf Neumann
} {
    package require md5
    return [md5::Hex [md5::md5 -- $value]]
}

#-------------------------------------------------------------------------
# In case, we are not running under NaviServer, provide a proc
# compatible with NaviServer's built in ns_parseurl.
#-------------------------------------------------------------------------

ad_proc ns_parseurl {url} {
    Emulation of NaviServer's ns_parseurl

    @author Gustaf Neumann
} {
    #puts stderr url=$url
    set result ""
    if {[regexp {^([a-zA-Z]+):(.*)$} $url . proto url]} {
        #
        # a protocol was specified
        #
        lappend result proto $proto
    }
    if {[regexp {^//([^/]+)(/?.*)$} $url . host url]} {
        #
        # two slashes -> host is specified
        #
        if {[regexp {^\[(.*)\]:([0-9]+)$} $host . host port]} {
            # IP literal notation followed by port
            lappend result host $host port $port
        } elseif {[regexp {^\[(.*)\]$} $host . host port]} {
            # IP literal notation followed with no port
            lappend result host $host
        } elseif {[regexp {^(.*):([0-9]+)$} $host . host port]} {
            lappend result host $host port $port
        } else {
            lappend result host $host
        }
    }
    if {[regexp {^/(.*)/([^/]+)$} $url . path tail]} {
        lappend result path $path tail $tail
    } elseif {[regexp {^/([^/]+)$} $url . tail]} {
        lappend result path "" tail $tail
    } elseif {$url in {"/" ""}} {
        lappend result path {} tail {}
    } else {
        lappend result tail $url
    }
    return $result
}

#-------------------------------------------------------------------------
# In case, we are not running under NaviServer, provide a proc
# compatible with NaviServer's built-in ns_getcontent.  This function
# returns the content of a request as file or as string, no matter,
# whether it was spooled during upload into a file or not. Currently,
# this compatibility function does not support fully the binary flag
# (binary state of "ns_conn content" and "ns_conn contentchannel"
# unclear). File reading in spool case could be done more efficiently
# when necessary by reading content chunkwise. When the maintenance
# state of AOLserver does not change, this won't be necessary.
# -------------------------------------------------------------------------

nsf::proc ns_getcontent {{-as_file true} {-binary true}} {
    set NS_CONN_FILECONTENT 0x80
    if {$as_file} {
        #
        # If the file was not spooled, obtainit via [ns_conn content]
        # as write it to a file.
        #
        set result [ad_tmpnam]
        set F [open $result w]
        if {$binary} {
            fconfigure $F -translation binary -encoding binary
        }
        if {[ns_conn flags] & $NS_CONN_FILECONTENT} {
            #
            # This can be done more efficiently when necessary by
            # reading content chunkwise. When the maintenance state of
            # AOLserver does not change, this won't be necessary.
            #
            set content [read [ns_conn contentchannel]]
        } else {
            set content [ns_conn content]
        }
        puts -nonewline $F $content
        close $F
    } else {
        #
        # Return the result as a string
        #
        if {[ns_conn flags] & $NS_CONN_FILECONTENT} {
            set result [read [ns_conn contentchannel]]
        } else {
            set result [ns_conn content]
        }
    }
    return $result
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
