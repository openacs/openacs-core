ad_library {

    Provides a variety of non-ACS-specific utilities, including
    the procs to support the who's online feature.

    @author Various (acs@arsdigita.com)
    @creation-date 13 April 2000
    @cvs-id $Id$
}


if {[ns_info name] ne "NaviServer"} {
    return
}

#-------------------------------------------------------------------------
# NaviServer implementation of ad_url(en|de)code* procs
#-------------------------------------------------------------------------

ad_proc -public ad_urlencode_folder_path {path} {
    Perform an urlencode operation on the segments of the provided
    folder (for a full folder path rather than path segments as in
            ad_urlencode_path).
    @see ad_urlencode_path
} {
    return [ns_urlencode -part path -- {*}[split $path /]]
}

ad_proc -public ad_urlencode_path { string } {
    Encode provided string with url-encoding for paths segments
    (instead of query segments) as defined in RFC 3986
} { 
    return [ns_urlencode -part path -- $string]
}

ad_proc -public ad_urldecode_path { string } {
    Decode provided string with url-encoding for paths segments
    (instead of query segments) as defined in RFC 3986
} {
    return [ns_urldecode -part path -- $string]
}

ad_proc -public ad_urlencode_query { string } {
    Encode provided string with url-encoding for query segments
    (instead of paths) as defined in RFC 3986
} { 
    return [ns_urlencode -part query -- $string]
}

ad_proc -public ad_urldecode_query { string } {
    Decode provided string with url-encoding for query segments
    (instead of path segments) as defined in RFC 3986
} {
    return [ns_urldecode -part query -- $string]
}

#-------------------------------------------------------------------------
# Cookie operations based on NaviServer primitives
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
    ns_deletecookie -domain $domain -path $path -replace t -secure $secure -- $name
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
    ns_getcookie -include_set_cookies $include_set_cookies -- $name $default
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


    if { $expire == "f"} {
        set expire -1
    } elseif {$max_age ne ""} {
        if {$max_age eq "inf"} {
            set expire -1
        } else {
            set expire [expr {[ns_time] + $max_age}]
        }
    }

    ns_setcookie -discard $discard -domain $domain -expires $expire -path $path \
        -replace $replace -scriptable $scriptable -secure $secure -- \
        $name $value
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
    uplevel [list ns_mutex eval $mutex $script]
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

