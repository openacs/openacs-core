ad_library {

    Procs for http client comunication

    @author Antonio Pisano
    @creation-date 2014-02-13
}


####################################
## New HTTP client implementation ##
####################################

namespace eval util {}
namespace eval util::http {}

ad_proc -private util::http::set_cookies {
    -resp_headers:required
    {-headers ""}
    {-cookie_names ""}
    {-pattern ""}
} {
    Extracts cookies from response headers. This is done reading every <code>set-cookie</code> header
    and populating a ns_set of request headers suitable for issuing <code>util::http</code> requests.

    @param resp_headers Response headers, in a list form as returned by <code>util::http</code> API.

    @param headers      ns_set of request headers that will be populated with extracted cookies.
                        If not specified, a new ns_set will be created. Existing cookies will be
                        overwritten.

    @param cookie_names Cookie names we want to retrieve. Other cookies will be ignored.
                        If omitted together with <code>-pattern</code> proc will include
                        every cookie.

    @param pattern      Cookies which name respects this pattern as in <code>string match</code>
                        will be included. If omitted together with <code>-cookie_names</code> proc
                        will include every cookie.

    @return ns_set of headers containing received cookies
} {
    if {$headers eq ""} {
        set headers [ns_set create headers]
    }
    set cookies [list]
    foreach {name value} $resp_headers {
        # get only set-cookie headers, ignoring case
        set name [string tolower $name]
        if {$name ne "set-cookie"} continue

        # keep only relevant part of the cookie
        set cookie [lindex [split $value ";"] 0]
        set cookie_name [lindex [split $cookie "="] 0]
        if {($cookie_names eq "" || $cookie_name in $cookie_names)
         && ($pattern      eq "" || [string match $pattern $cookie_name])} {
            lappend cookies $cookie
        }
    }
    ns_set idelkey $headers "cookie"
    set cookies [join $cookies "; "]
    ns_set put $headers "cookie" $cookies

    return $headers
}

ad_proc -public util::http::basic_auth {
    {-headers ""}
    -username:required
    -password:required
} {
    Builds BASIC authentication header for a HTTP request

    @param headers  ns_set of request headers that will be populated with auth header.
                    If not specified, a new ns_set will be created. Existing header
                    for BASIC authentication will be overwtitten.

    @param username Username for authentication

    @param password Password for authentication

    @return ns_set of headers containing authentication data
} {
    if {$headers eq ""} {
        set headers [ns_set create headers]
    }
    set h "Basic [base64::encode ${username}:$password]"
    ns_set idelkey $headers "Authorization"
    ns_set put     $headers "Authorization" $h
    return $headers
}

ad_proc -public util::http::cookie_auth {
    {-headers ""}
    {-auth_vars ""}
    {-auth_url ""}
    {-auth_form ""}
    {-auth_cookies ""}
    {-preference {native curl}}
} {
    This proc implements the generic pattern for cookie-based authentication: user
    logs in a webpage providing username, password and optionally other information
    in a form, page replies generating one or more authentication cookies by which
    user will be recognized on subsequent interaction with the server.<br>
    <br>
    By this method it is possible, for example, to authenticate on a remote OpenACS
    installation providing <code>email</code> and <code>password</code> as credentials
    to the /register/ page, and using <code>ad_session_id</code> and <code>ad_user_login</code>
    as <code>auth_cookies</code>.<br>
    <br>
    This proc takes care to submit to the login form also every other formfield on the
    login page. This is important because this (often hidden) formfields can contain tokens
    necessary for the authentication process.

    @param headers      ns_set of request headers that will be populated with auth headers.
                        If not specified, a new ns_set will be created. Existing cookies
                        will be overwritten.

    @param auth_vars    Variables issued to the login page in <code>export_vars -url</code> form.

    @param auth_url     Login url

    @param auth_cookies Cookies we should look for in the response from the login page to obtain
                        authentication data. If not specified, this will refer to every cookie
                        received into <code>set-cookie</code> response headers.

    @auth_form          Form to put our data into. If not specified, there must be only one form
                        on the login page, otherwise proc will throw an error.

    @return ns_set of headers containing authentication data
} {
    if {$headers eq ""} {
        set headers [ns_set create headers]
    }

    # Normalize url. Slashes at the end can make
    # the same url don't look the same for the
    # server, if we retrieve the same url from
    # the 'action' attribute of the form.
    set auth_url [string trimright $auth_url "/"]
    set base_url [split $auth_url "/"]
    set base_url [lindex $base_url 0]//[lindex $base_url 2]

    # Call login url to obtain login form
    array set r [util::http::get -url $auth_url -preference $preference]

    # Get cookies from response
    util::http::set_cookies \
      -resp_headers $r(headers) \
      -headers      $headers \
      -cookie_names $auth_cookies

    # Obtain and export form vars not provided explicitly
    set form [util::html::get_forms -html $r(page)]
    set form [util::html::get_form -forms $form -id $auth_form]

    array set f $form
    array set a $f(attributes)
    # Action could be different from original login url
    # I take that from form attributes.
    if {[info exists a(action)]} {
        set auth_url ${base_url}${a(action)}
        set auth_url [string trimright $auth_url "/"]
    }

    set formvars [util::html::get_form_vars -form $form]
    set formvars [export_vars -exclude $auth_vars $formvars]
    # Export vars provided explicitly in caller scope
    set auth_vars [uplevel [list export_vars -url $auth_vars]]
    # Join form vars with our vars
    set formvars [join [list $formvars $auth_vars] "&"]

    # Call login url with authentication parameters. Just retrieve the first response, as it
    # is common for login pages to redirect somewhere, but we just need to steal the cookies.
    array set r [util::http::post \
        -url $auth_url -body $formvars \
        -headers $headers -max_depth 0 -preference $preference]

    # Get cookies from response
    util::http::set_cookies \
      -resp_headers $r(headers) \
      -headers      $headers \
      -cookie_names $auth_cookies

    return $headers
}

ad_proc -public util::http::available {
    -url
    {-preference {native curl}}
    -force_ssl:boolean
    -spool:boolean
} {

    Check, if for the given url and preferences the current
    installation supports util::http::* . If not, please use
    NaviServer, configure nsssl, and/or install curl.

    @param preference decides which available implementation prefer
    in respective order. Choice is between 'native', based on ns_ api,
    available for NaviServer only and giving the best performances and
    'curl', which wraps the command line utility (available on every
    system with curl installed).

    @param force_ssl specifies whether we want to use SSL despite the
    url being in http:// form. Default behavior is to use SSL on
    https:// urls only.

} {
    if {$force_ssl_p || [string match "https://*" $url]} {
        set apis [lindex [apis] 1]
    } else {
        set apis [lindex [apis] 0]
    }

    # just allow spool when NaviServer os 4.99.6 or newer
    if {$spool_p && [apm_version_names_compare [ns_info patchlevel] "4.99.6"] == -1} {
        if {"native" in $apis} {
            set index [lsearch $apis "native"]
            set apis [lreplace $apis $index $index]
        }
    }

    foreach p $preference {
       if {$p in $apis} {
           return $p
       }
    }

    return ""
}

ad_proc -private util::http::native_https_api_not_cached {
} {
    Obtains the right https native API
} {
    # Since NaviServer 4.99.12 ns_http handles also https
    if {[apm_version_names_compare \
             [ns_info patchlevel] "4.99.12"] >= 0} {
        return [info commands ns_http]
    }
    # Default: check if we have ns_ssl
    return [info commands ns_ssl]
}

ad_proc -private util::http::native_https_api {
} {
    Obtains implemented apis for http communication
} {
    set key ::util::http::native_https_api
    if {[info exists $key]} {
        return [set $key]
    } else {
        return [set $key [util::http::native_https_api_not_cached]]
    }
}

ad_proc -private util::http::apis_not_cached {
} {
    Obtains implemented apis for http communication
} {
    set http  [list]
    set https [list]
    if {[util::which curl] ne ""} {
        lappend http  "curl"
        lappend https "curl"
    }

    if {[info commands ns_http] ne ""} {
        lappend http  "native"
    }

    if {[util::http::native_https_api] ne ""} {
        lappend https "native"
    }

    return [list $http $https]
}

ad_proc -private util::http::apis {
} {
    Obtains implemented apis for http communication
} {
    set key ::util::http::apis
    if {[info exists $key]} {
        return [set $key]
    } else {
        return [set $key [util::http::apis_not_cached]]
    }
}


#
## Procs common to both implementations
#

ad_proc -private util::http::get_channel_settings {
    content_type
} {
    Helper proc to get encoding based on content_type (From xotcl/tcl/http-client-procs)
} {
    # In the following, I realise a IANA/MIME charset resolution
    # scheme which is compliant with RFC 3023 which deals with
    # treating XML media types properly.
    #
    # see http://tools.ietf.org/html/rfc3023
    #
    # This makes the use of [ns_encodingfortype] obsolete as this
    # helper proc does not consider RFC 3023 at all. In the future,
    # RFC 3023 support should enter a revised [ns_encodingfortype],
    # for now, we fork.
    #
    # The mappings between Tcl encoding names (as shown by [encoding
    # names]) and IANA/MIME charset names (i.e., names and aliases in
    # the sense of http://www.iana.org/assignments/character-sets) is
    # provided by ...
    #
    # i. a static, built-in correspondence map: see nsd/encoding.c
    # ii. an extensible correspondence map (i.e., the ns/charsets
    # section in config.tcl).
    #
    # For mapping charset to encoding names, I use
    # [ns_encodingforcharset].
    #
    # Note, there are also alternatives for resolving IANA/MIME
    # charset names to Tcl encoding names, however, they all have
    # issues (non-extensibility from standard configuration sites,
    # incompleteness, redundant thread-local storing, scripted
    # implementation):
    # 1. tcllib/mime package: ::mime::reversemapencoding()
    # 2. tdom: tDOM::IANAEncoding2TclEncoding(); see lib/tdom.tcl

    #
    # RFC 3023 support (at least in my reading) demands the following
    # resolution order (see also Section 3.6 in RFC 3023), when
    # applied along with RFC 2616 (see especially Section 3.7.1 in RFC 2616)
    #
    # (A) Check for the "charset" parameter on certain (!) media types:
    # an explicitly stated, yet optional "charset" parameter is
    # permitted for all text/* media subtypes (RFC 2616) and selected
    # the XML media type classes listed by RFC 3023 (beyond the text/*
    # media type; e.g. "application/xml*", "*/*+xml", etc.).
    #
    # (B) If the "charset" is omitted, certain default values apply (!):
    #
    #    (B.1) RFC 3023 text/* registrations default to us-ascii (!),
    #    and not iso-8859-1 (overruling RFC 2616).
    #
    #   (B.2) RFC 3023 application/* and non-text "+xml" registrations
    #    are to be left untreated (in our context, no encoding
    #    filtering is to be applied -> "binary")
    #
    #   (B.3) RFC 2616 text/* registration (if not covered by B.1)
    #   default to iso-8859-1
    #
    #   (B.4) RFC 4627 json defaults to utf-8
    #
    # (C) If neither A or B apply (e.g., because an invalid charset
    # name was given to the charset parameter), we default to
    # "binary". This corresponds to the behaviour of
    # [ns_encodingfortype].  Also note, that the RFCs 3023 and 2616 do
    # not state any procedure when "invalid" charsets etc. are
    # identified. I assume, RFC-compliant clients have to ignore them
    # which means keep the channel in- and output unfiltered (encoding
    # = "binary"). This requires the client of the *HttpRequest* to
    # treat the data accordingly.
    #

    set enc ""
    if {[regexp {^text/.*$|^.*/json.*$|^.*/xml.*$|^.*\+xml.*$} $content_type]} {
        # Case (A): Check for an explicitly provided charset parameter
        if {[regexp {;\s*charset\s*=([^;]*)} $content_type _ charset]} {
            set enc [ns_encodingforcharset [string trim $charset]]
        }
        # Case (B.1)
        if {$enc eq "" && [regexp {^text/xml.*$|text/.*\+xml.*$} $content_type]} {
            set enc [ns_encodingforcharset us-ascii]
        }

        # Case (B.3)
        if {$enc eq "" && [string match "text/*" $content_type]} {
            set enc [ns_encodingforcharset iso-8859-1]
        }
        # Case (B.4)
        if {$enc eq "" && $content_type eq "application/json"} {
          set enc [ns_encodingforcharset utf-8]
        }
    }
    # Cases (C) and (B.2) are covered by the [expr] below.
    set enc [expr {$enc eq "" ? "binary" : $enc}]

    return $enc
}

ad_proc util::http::get {
    -url
    {-headers ""}
    {-timeout 30}
    {-max_depth 10}
    -force_ssl:boolean
    -gzip_response:boolean
    -spool:boolean
    {-preference {native curl}}
} {
    Issue an http GET request to <code>url</code>.

    @param headers specifies an ns_set of extra headers to send
    to the server when doing the request.  Some options exist that
    allow to avoid the need to specify headers manually, but headers
    will always take precedence over options.

    @param gzip_response informs the server that we are
    capable of receiving gzipped responses.  If server complies to our
    indication, the result will be automatically decompressed.

    @param force_ssl specifies whether we want to use SSL
    despite the url being in http:// form.  Default behavior is to use
    SSL on https:// urls only.

    @param spool enables file spooling of the request on the file
    specified. It is useful when we expect large responses from the
    server. The result is spooled to a temporary file, the name is
    returned in the file component of the result.

    @param preference decides which available implementation prefer
    in respective order. Choice is between 'native', based on ns_ api,
    available for NaviServer only and giving the best performances and
    'curl', which wraps the command line utility (available on every
    system with curl installed).

    @param timeout Timeout in seconds. The value can be an integer,
    a floating point number or an ns_time value.

    @return Returns the data as dict with elements <code>headers</code>, <code>page</code>,
    <code>file</code>, <code>status</code>, and <code>modified</code>.

} {
    return [util::http::request \
                -url             $url \
                -method          GET \
                -headers         $headers \
                -timeout         $timeout \
                -max_depth       $max_depth \
                -preference      $preference \
                -force_ssl=$force_ssl_p \
                -gzip_response=$gzip_response_p \
                -spool=$spool_p]
}

ad_proc util::http::post {
    -url
    {-files {}}
    -base64:boolean
    {-formvars ""}
    {-body ""}
    {-max_body_size 25000000}
    {-headers ""}
    {-timeout 30}
    {-max_depth 10}
    -force_ssl:boolean
    -multipart:boolean
    -gzip_request:boolean
    -gzip_response:boolean
    -post_redirect:boolean
    -spool:boolean
    {-preference {native curl}}
} {
    Implement client-side HTTP POST request.

    @param body is the payload for the request and will be
    passed as is (useful for many purposes, such as webDav).  A
    convenient way to specify form variables through this argument is
    passing a string obtained by <code>export_vars -url</code>.

    @param max_body_size this value in number of characters will tell
    how big can the whole body payload get before we start spooling
    its content to a file. This is important in case of big file
    uploads, when keeping the entire request in memory is just not
    feasible. The handling of the spooling is taken care of in the
    api. This value takes into account also the encoding required by
    the content type, so its value could not reflect the exact length
    of body's string representation.

    @param files File upload can be specified using actual files on the
    filesystem or binary strings of data using the <code>-files</code>
    parameter.  <code>-files</code> must be a dict (flat list of key value pairs).
    Keys of <code>-files</code> parameter are:

    <ul>
    <li>data: binary data to be sent. If set, has precedence on 'file' key</li>
    <li>file: path for the actual file on filesystem</li>
    <li>filename: name the form will receive for this file</li>
    <li>fieldname: name the field this file will be sent as</li>
    <li>mime_type: mime_type the form will receive for this file</li>
    </ul>

    If 'filename' is missing and an actual file is being sent, it will
    be set as the same name as the file.<br/> If 'mime_type' is
    missing, it will be guessed from 'filename'. If result is */* or
    an empty mime_type, 'application/octet-stream' will be used<br/>
    If <code>-base64</code> flag is set, files will be base64 encoded
    (useful for some kind of form).

    @param -formvars Other form variables can be passes in<code>-formvars</code>
    easily by the use of <code>export_vars -url</code> and will be
    translated for the proper type of form. URL variables, as with GET
    requests, are also sent, but an error is thrown if URL variables
    conflict with those specified in other ways.

    <p> Default behavior is to build payload as an
    'application/x-www-form-urlencoded' payload if no files are
    specified, and 'multipart/form-data' otherwise. If
    <code>-multipart</code> flag is set, format will be forced to
    multipart.

    @param headers specifies an ns_set of extra headers to send to the
    server when doing the request.  Some options exist that allow to
    avoid the need to specify headers manually, but headers will
    always take precedence over options.

    @param gzip_request informs the server that we are sending data
    in gzip format. Data will be automatically compressed.  Notice
    that not all servers can treat gzipped requests properly, and in
    such cases response will likely be an error.

    @param gzip_response informs the server that we are capable of
    receiving gzipped responses.  If server complies to our
    indication, the result will be automatically decompressed.

    @param force_ssl specifies whether we want to use SSL despite the
    url being in http:// form.  Default behavior is to use SSL on
    https:// urls only.

    @param spool enables file spooling of the request on the file
    specified. It is useful when we expect large responses from the
    server. The result is spooled to a temporary file, the name is
    returned in the file component of the result.

    @param post_redirect decides what happens when we are POSTing and
    server replies with 301, 302 or 303 redirects. RFC 2616/10.3.2
    states that method should not change when 301 or 302 are returned,
    and that GET should be used on a 303 response, but most HTTP
    clients fail in respecting this and switch to a GET request
    independently. This options forces this kinds of redirect to
    conserve their original method.

    @param max_depth is the maximum number of redirects the proc is
    allowed to follow. A value of 0 disables redirection. When max
    depth for redirection has been reached, proc will return response
    from the last page we were redirected to. This is important if
    redirection response contains data such as cookies we need to
    obtain anyway. Be aware that when following redirects, unless
    it is a code 303 redirect, url and POST urlencoded variables will
    be sent again to the redirected host. Multipart variables won't be
    sent again.  Sending to the redirected host can be dangerous, if
    such host is not trusted or uses a lower level of security.

    @param preference decides which available implementation prefer in
    respective order. Choice is between 'native', based on ns_ api,
    available for NaviServer only and giving the best performances and
    'curl', which wraps the command line utility (available on every
    system with curl installed).

    @param timeout Timeout in seconds. The value can be an integer,
    a floating point number or an ns_time value.

    @return Returns the data as dict with elements <code>headers</code>, <code>page</code>,
    <code>file</code>, <code>status</code>, and <code>modified</code>.

} {
    set this_proc [lindex [info level 0] 0]

    # Retrieve variables sent by the URL...
    set vars [lindex [split $url ?] 1]
    foreach var [split $vars &] {
        set var [split $var =]
        set key [lindex $var 0]
        set urlvars($key) 1
    }

    # Check whether we don't have multiple variable definition in url
    # and payload.
    foreach var [split $formvars &] {
        set var [split $var =]
        set key [lindex $var 0]
        if {[info exists urlvars($key)]} {
            return -code error "${this_proc}:  Variable '$key' already specified as url variable"
        }
    }

    if {$headers eq ""} {
        set headers [ns_set create headers]
    }

    set req_content_type [ns_set iget $headers "content-type"]
    
    set payload {}
    set payload_file {}
    set payload_file_fd {}

    # Request will be multipart if required by the flag, if we have
    # files or if set up manually by the headers
    if {$multipart_p ||
        $files ne {} ||
        [string match -nocase "*multipart/form-data*" $req_content_type]} {

        # delete every manually set content-type header...
        while {[ns_set ifind $headers "Content-type"] >= 0} {
            ns_set idelkey $headers "Content-type"
        }
        # ...replace it with our own...
        set boundary [ns_sha1 [list [clock clicks -milliseconds] [clock seconds]]]
        set req_content_type "multipart/form-data; boundary=$boundary"        
        ns_set put $headers "Content-type" $req_content_type
        # ...and get the proper encoding for the content.
        set enc [util::http::get_channel_settings $req_content_type]

        # Transform files into binaries
        foreach file $files {
            unset -nocomplain f
            array set f $file

            if {![info exists f(data)]} {
                if {![info exists f(file)]} {
                    return -code error "${this_proc}:  No file specified"
                }
                if {![file exists $f(file)]} {
                    return -code error "${this_proc}:  Error reading file: $f(file) not found"
                }
                if {![file readable $f(file)]} {
                    return -code error "${this_proc}:  Error reading file: $f(file) permission denied"
                }

                if {![info exists f(filename)]} {
                    set f(filename) [file tail $f(file)]
                }
            }

            foreach key {filename fieldname} {
                if {![info exists f($key)]} {
                    return -code error "${this_proc}:  '$key' missing for file POST"
                }
            }

            # Check that we don't already have this var specified in the url
            if {[info exists urlvars($f(fieldname))]} {
                return -code error "${this_proc}:  file field '$f(fieldname)' already specified as url variable"
            }
            # Track form variables sent as files
            set filevars($f(fieldname)) 1

            if {![info exists f(mime_type)]} {
                set f(mime_type) [ns_guesstype $f(filename)]
                if {$f(mime_type) in {"*/*" ""}} {
                    set f(mime_type) "application/octet-stream"
                }
            }

            if {$base64_p} {
                set transfer_encoding base64
            } else {
                set transfer_encoding binary
            }

            set content [list --$boundary \
                             \r\n \
                             "Content-Disposition: form-data; " \
                             "name=\"$f(fieldname)\"; filename=\"$f(filename)\"" \
                             \r\n \
                             "Content-Type: $f(mime_type)" \
                             \r\n \
                             "Content-transfer-encoding: $transfer_encoding" \
                             \r\n \
                             \r\n]
            set app [append_to_payload \
                         -content [join $content ""] \
                         $enc \
                         $max_body_size \
                         $payload \
                         $payload_file \
                         $payload_file_fd]
            lassign $app payload payload_file payload_file_fd

            if {[info exists f(data)]} {
                set app [append_to_payload \
                             -content $f(data) \
                             $enc \
                             $max_body_size \
                             $payload \
                             $payload_file \
                             $payload_file_fd]
            } else {
                set app [append_to_payload \
                             -file $f(file) \
                             $enc \
                             $max_body_size \
                             $payload \
                             $payload_file \
                             $payload_file_fd]
            }
            lassign $app payload payload_file payload_file_fd

            set app [append_to_payload \
                         -content \r\n \
                         $enc \
                         $max_body_size \
                         $payload \
                         $payload_file \
                         $payload_file_fd]
            lassign $app payload payload_file payload_file_fd

        }

        # Translate urlencoded vars into multipart variables
        foreach formvar [split $formvars &] {
            set formvar [split $formvar  =]
            set key [lindex $formvar 0]
            set val [join [lrange $formvar 1 end] =]

            if {[info exists filevars($key)]} {
                return -code error "${this_proc}:  Variable '$key' already specified as file variable"
            }

            set content [list --$boundary \
                             \r\n \
                             "Content-Disposition: form-data; name=\"$key\"" \
                             \r\n \
                             \r\n \
                             $val \
                             \r\n]
            set app [append_to_payload \
                         -content [join $content ""] \
                         $enc \
                         $max_body_size \
                         $payload \
                         $payload_file \
                         $payload_file_fd]
            lassign $app payload payload_file payload_file_fd

        }

        set content "--$boundary--\r\n"
        set app [append_to_payload \
                     -content $content \
                     $enc \
                     $max_body_size \
                     $payload \
                     $payload_file \
                     $payload_file_fd]
        lassign $app payload payload_file payload_file_fd
        
    } else {
        # If people specified a content type we won't overwrite it,
        # otherwise this will be a 'application/x-www-form-urlencoded'
        # payload
        if {$req_content_type eq ""} {
            set req_content_type "application/x-www-form-urlencoded"
            ns_set put $headers "Content-type" $req_content_type
        }
        set enc [util::http::get_channel_settings $req_content_type]
        set payload $formvars
    }

    # Body will be appended as is to the payload
    set app [append_to_payload \
                 -content $body \
                 $enc \
                 $max_body_size \
                 $payload \
                 $payload_file \
                 $payload_file_fd]
    lassign $app payload payload_file payload_file_fd

    if {$payload_file_fd ne ""} {close $payload_file_fd}
    
    return [util::http::request \
                -method          POST \
                -body            $payload \
                -body_file       $payload_file \
                -delete_body_file \
                -headers         $headers \
                -url             $url \
                -timeout         $timeout \
                -max_depth       $max_depth \
                -preference      $preference \
                -force_ssl=$force_ssl_p \
                -gzip_request=$gzip_request_p \
                -gzip_response=$gzip_response_p \
                -post_redirect=$post_redirect_p \
                -spool=$spool_p]

}

ad_proc -private util::http::append_to_payload {
    {-content ""}
    {-file ""}
    -base64:boolean
    encoding
    max_size
    payload
    spool_file
    wfd
} {
    Appends content to a POST payload making sure this doesn't exceed
    given max size. When this happens, proc creates a spool file and
    writes there the content.

    @return a list in the format {total_payload spooling_file
            spooling_file_handle}

} {
    set payload_size [string length $payload]

    if {$file eq ""} {
        if {$encoding ne "binary"} {set content [encoding convertto $encoding $content]}
        set content_size [string length $content]
    } else {
        # At first check length by file size, so we don't have to read
        # anything...
        set content_size [file size $file]
        set rfd [open $file r]
        fconfigure $rfd -translation binary
    }

    # ...file as it is could be small enough, now let's check with
    # encoding...
    if {$spool_file eq "" &&
        $payload_size + $content_size <= $max_size &&
        $file ne ""} {
        set content [read $rfd]; close $rfd
        if {$base64_p} {set content [base64::encode $content]}
        if {$encoding ne "binary"} {set content [encoding convertto $encoding $content]}
        set content_size [string length $content]
    }

    if {$spool_file eq "" &&
        $payload_size + $content_size <= $max_size} {
        return [list ${payload}${content} {} {}]
    } else {
        if {$spool_file eq ""} {
            set spool_file [ad_tmpnam]
            set wfd [open $spool_file w]
            # Flush previously collected payload. As it was already
            # properly encoded, use the binary translation...
            fconfigure $wfd -translation binary
            puts -nonewline $wfd $payload
            # ...then switch to the proper one.
            fconfigure $wfd -translation $encoding
        }
        if {$file ne ""} {
            if {$base64_p} {
                # TODO: it's tricky to base64 encode without slurping
                # the whole file (exec + pipes?)
                error "Base64 encoding currently supported only for in-memory file POSTing"
            }
            fcopy $rfd $wfd
            close $rfd
        } else {
            puts -nonewline $wfd $content
        }
        return [list {} $spool_file $wfd]
    }
}

ad_proc -private util::http::follow_redirects {
    -url
    -method
    -status
    -location
    {-body ""}
    {-body_file ""}
    -delete_body_file:boolean
    {-headers ""}
    {-timeout 30}
    {-depth 0}
    {-max_depth 10}
    -force_ssl:boolean
    -multipart:boolean
    -gzip_request:boolean
    -gzip_response:boolean
    -post_redirect:boolean
    -spool:boolean
    -preference {native curl}
} {
    Follow redirects. This proc is required because we want
    to be able to follow a redirect until a certain depth and
    then stop without throwing an error.<br>
    <br>
    Happens at times that even a redirect page contains
    very important information we want to be able to reach.
    An example could be authentication headers. By putting
    redirection handling here we can force a common behavior between
    the two implementations, that otherwise would not be possible.

    @param body is the payload for the request and will be passed as
    is (useful for many purposes, such as webDav).  A convenient way
    to specify form variables through this argument is passing a
    string obtained by <code>export_vars -url</code>.  <p> Default
    behavior is to build payload as an
    'application/x-www-form-urlencoded' payload if no files are
    specified, and 'multipart/form-data' otherwise. If
    <code>-multipart</code> flag is set, format will be forced to
    multipart.

    @param body_file is an alternative way to specify the payload,
    useful in cases such as the upload of big files by POST. If
    specified, will have precedence over the <code>body</code>
    parameter. Content of the file won't be encoded according with the
    content type of the request as happen with <code>body</code>

    @param delete_body_file decides whether remove body payload file
    once the request is over.

    @param headers specifies an ns_set of extra headers to send to the
    server when doing the request.  Some options exist that allow to
    avoid the need to specify headers manually, but headers will
    always take precedence over options.

    @param gzip_request informs the server that we are sending data
    in gzip format. Data will be automatically compressed.  Notice
    that not all servers can treat gzipped requests properly, and in
    such cases response will likely be an error.

    @param gzip_response informs the server that we are capable of
    receiving gzipped responses.  If server complies to our
    indication, the result will be automatically decompressed.

    @param force_ssl specifies whether we want to use SSL despite the
    url being in http:// form.  Default behavior is to use SSL on
    https:// urls only.

    @param spool enables file spooling of the request on the file
    specified. It is useful when we expect large responses from the
    server. The result is spooled to a temporary file, the name is
    returned in the file component of the result.

    @param post_redirect decides what happens when we are POSTing and
    server replies with 301, 302 or 303 redirects. RFC 2616/10.3.2
    states that method should not change when 301 or 302 are returned,
    and that GET should be used on a 303 response, but most HTTP
    clients fail in respecting this and switch to a GET request
    independently. This options forces this kinds of redirect to
    conserve their original method.

    @param max_depth is the maximum number of redirects the proc is
    allowed to follow. A value of 0 disables redirection. When max
    depth for redirection has been reached, proc will return response
    from the last page we were redirected to. This is important if
    redirection response contains data such as cookies we need to
    obtain anyway. Be aware that when following redirects, unless
    it is a code 303 redirect, url and POST urlencoded variables will
    be sent again to the redirected host. Multipart variables won't be
    sent again. Sending to the redirected host can be dangerous, if
    such host is not trusted or uses a lower level of security.

    @param preference decides which available implementation prefer in
    respective order. Choice is between 'native', based on ns_ api,
    available for NaviServer only and giving the best performances and
    'curl', which wraps the command line utility (available on every
    system with curl installed).

    @param timeout Timeout in seconds. The value can be an integer,
    a floating point number or an ns_time value.

    @return Returns the data as dict with elements <code>headers</code>, <code>page</code>,
    <code>file</code>, <code>status</code>, and <code>modified</code> from the last
    followed redirect, or an empty string if request was not a redirection.

} {
    ## Redirection management ##

    # Don't follow if page was not modified or this was not a proper redirect:
    # not the right status code, missing location.
    if {$status == 304 || ![string match "3??" $status] || $location eq ""} {
        return ""
    }

    # Other kinds of redirection...
    # Decide by which method follow the redirect
    if {$method eq "POST"} {
        if {$status in {301 302 303} && !$post_redirect_p} {
            set method "GET"
        }
    }

    #
    # A redirect from http might point to https, which in turn
    # might not be configured. So we have to go through
    # util::http::request again.
    #
    set this_proc ::util::http::request

    set urlvars [list]

    # ...retrieve redirect location variables...
    set locvars [lindex [split $location ?] 1]
    if {$locvars ne ""} {
        lappend urlvars $locvars
    }

    lappend urlvars [lindex [split $url ?] 1]

    # If we have POST payload and we are following by GET, put the payload into url vars.
    if {$method eq "GET" && $body ne ""} {
        set req_content_type [ns_set iget $headers "content-type"]
        set multipart_p [string match -nocase "*multipart/form-data*" $req_content_type]
        # I decided to don't translate into urlvars a multipart payload.
        # This makes sense if we think that in a multipart payload we have
        # many informations, such as mime_type, which cannot be put into url.
        # Receiving a GET redirect after a POST is very common, so I won't throw an error
        if {!$multipart_p} {
            if {$gzip_request_p} {
                set body [zlib gunzip $body]
            }
            lappend urlvars $body
        }
    }

    # Unite all variables into location URL
    set urlvars [join $urlvars &]

    if {$urlvars ne ""} {
        set location ${location}?${urlvars}
    }

    if {$method eq "GET"} {
        return [$this_proc \
                    -method          GET \
                    -url             $location \
                    -headers         $headers \
                    -timeout         $timeout \
                    -depth           $depth \
                    -max_depth       $max_depth \
                    -force_ssl=$force_ssl_p \
                    -gzip_response=$gzip_response_p \
                    -post_redirect=$post_redirect_p \
                    -spool=$spool_p \
                    -preference $preference]
    } else {
        return [$this_proc \
                    -method          POST \
                    -url             $location \
                    -body            $body \
                    -body_file       $body_file \
                    -delete_body_file=$delete_body_file_p \
                    -headers         $headers \
                    -timeout         $timeout \
                    -depth           $depth \
                    -max_depth       $max_depth \
                    -force_ssl=$force_ssl_p \
                    -gzip_request=$gzip_request_p \
                    -gzip_response=$gzip_response_p \
                    -post_redirect=$post_redirect_p \
                    -spool=$spool_p \
                    -preference $preference]
    }
}

ad_proc -private util::http::request {
    -url
    {-method GET}
    {-headers ""}
    {-body ""}
    {-body_file ""}
    -delete_body_file:boolean
    {-timeout 30}
    {-depth 0}
    {-max_depth 10}
    -force_ssl:boolean
    -gzip_request:boolean
    -gzip_response:boolean
    -post_redirect:boolean
    -spool:boolean
    {-preference {native curl}}
} {
    Issue an HTTP request either GET or POST to the url specified.

    @param headers specifies an ns_set of extra headers to send to the
    server when doing the request.  Some options exist that allow to
    avoid the need to specify headers manually, but headers will
    always take precedence over options.

    @param body is the payload for the request and will be passed as
    is (useful for many purposes, such as webDav).  A convenient way
    to specify form variables for POST payloads through this argument
    is passing a string obtained by <code>export_vars -url</code>.

    @param body_file is an alternative way to specify the payload,
    useful in cases such as the upload of big files by POST. If
    specified, will have precedence over the <code>body</code>
    parameter. Content of the file won't be encoded according with the
    content type of the request as happen with <code>body</code>

    @param delete_body_file decides whether remove body payload file
    once the request is over.

    @param gzip_request informs the server that we are sending data
    in gzip format. Data will be automatically compressed.  Notice
    that not all servers can treat gzipped requests properly, and in
    such cases response will likely be an error.

    @param gzip_response informs the server that we are capable of
    receiving gzipped responses.  If server complies to our
    indication, the result will be automatically decompressed.

    @param force_ssl specifies whether we want to use SSL despite the
    url being in http:// form. Default behavior is to use SSL on
    https:// urls only.

    @param spool enables file spooling of the request on the file
    specified. It is useful when we expect large responses from the
    server. The result is spooled to a temporary file, the name is
    returned in the file component of the result.

    @param post_redirect decides what happens when we are POSTing and
    server replies with 301, 302 or 303 redirects. RFC 2616/10.3.2
    states that method should not change when 301 or 302 are returned,
    and that GET should be used on a 303 response, but most HTTP
    clients fail in respecting this and switch to a GET request
    independently. This options forces this kinds of redirect to
    conserve their original method. Notice that, as from RFC, a 303
    redirect won't send again any data to the server, as specification
    says we can assume variables to have been received.

    @param max_depth is the maximum number of redirects the proc is
    allowed to follow. A value of 0 disables redirection. When max
    depth for redirection has been reached, proc will return response
    from the last page we were redirected to. This is important if
    redirection response contains data such as cookies we need to
    obtain anyway. Be aware that when following redirects, unless
    it is a code 303 redirect, url and POST urlencoded variables will
    be sent again to the redirected host. Multipart variables won't be
    sent again.  Sending to the redirected host can be dangerous, if
    such host is not trusted or uses a lower level of security.

    @param preference decides which available implementation prefer
    in respective order. Choice is between 'native', based on ns_ api,
    available for NaviServer only and giving the best performances and
    'curl', which wraps the command line utility (available on every
    system with curl installed).

    @param timeout Timeout in seconds. The value can be an integer,
    a floating point number or an ns_time value.

    @return Returns the data as dict with elements <code>headers</code>, <code>page</code>,
    <code>file</code>, <code>status</code>, and <code>modified</code>.

} {
    set this_proc [lindex [info level 0] 0]

    set impl [available -url $url -force_ssl=$force_ssl_p -preference $preference -spool=$spool_p]
    if {$impl eq ""} {
        return -code error "${this_proc}:  HTTP client functionalities for this protocol are not available with current system configuration."
    }

    return [util::http::${impl}::request \
                -method          $method \
                -body            $body \
                -body_file       $body_file \
                -delete_body_file=$delete_body_file_p \
                -headers         $headers \
                -url             $url \
                -timeout         $timeout \
                -depth           $depth \
                -max_depth       $max_depth \
                -force_ssl=$force_ssl_p \
                -gzip_request=$gzip_request_p \
                -gzip_response=$gzip_response_p \
                -post_redirect=$post_redirect_p \
                -spool=$spool_p]
}


#
## Native NaviServer implementation
#

namespace eval util::http::native {}

ad_proc -private util::http::native::timeout {input} {

    Convert the provided value to a ns_time format
    used by NaviServer

} {
    if {[string is integer -strict $input]} {
        return $input:0
    } elseif {[string is double -strict $input]} {
        set secs [expr {int($input)}]
        return $secs:[expr {($input - $secs)*1000000}]
    }
    return $input
}

ad_proc -private util::http::native::request {
    -url
    {-method GET}
    {-headers ""}
    {-body ""}
    {-body_file ""}
    -delete_body_file:boolean
    {-timeout 30}
    {-depth 0}
    {-max_depth 10}
    -force_ssl:boolean
    -gzip_request:boolean
    -gzip_response:boolean
    -post_redirect:boolean
    -spool:boolean
} {

    Issue an HTTP request either GET or POST to the url specified.
    This is the native implementation based on NaviServer HTTP api.

    @param headers specifies an ns_set of extra headers to send to the
    server when doing the request.  Some options exist that allow to
    avoid the need to specify headers manually, but headers will
    always take precedence over options.

    @param body is the payload for the request and will be passed as
    is (useful for many purposes, such as webDav).  A convenient way
    to specify form variables for POST payloads through this argument
    is passing a string obtained by <code>export_vars -url</code>.

    @param body_file is an alternative way to specify the payload,
    useful in cases such as the upload of big files by POST. If
    specified, will have precedence over the <code>body</code>
    parameter. Content of the file won't be encoded according with the
    content type of the request as happen with <code>body</code>

    @param delete_body_file decides whether remove body payload file
    once the request is over.

    @param gzip_request informs the server that we are sending data
    in gzip format. Data will be automatically compressed.  Notice
    that not all servers can treat gzipped requests properly, and in
    such cases response will likely be an error.

    @param gzip_response informs the server that we are capable of
    receiving gzipped responses.  If server complies to our
    indication, the result will be automatically decompressed.

    @param force_ssl specifies whether we want to use SSL despite the
    url being in http:// form. Default behavior is to use SSL on
    https:// urls only.

    @param spool enables file spooling of the request on the file
    specified. It is useful when we expect large responses from the
    server. The result is spooled to a temporary file, the name is
    returned in the file component of the result.

    @param post_redirect decides what happens when we are POSTing and
    server replies with 301, 302 or 303 redirects. RFC 2616/10.3.2
    states that method should not change when 301 or 302 are returned,
    and that GET should be used on a 303 response, but most HTTP
    clients fail in respecting this and switch to a GET request
    independently. This options forces this kinds of redirect to
    conserve their original method. Notice that, as from RFC, a 303
    redirect won't send again any data to the server, as specification
    says we can assume variables to have been received.

    @param max_depth is the maximum number of redirects the proc is
    allowed to follow. A value of 0 disables redirection. When max
    depth for redirection has been reached, proc will return response
    from the last page we were redirected to. This is important if
    redirection response contains data such as cookies we need to
    obtain anyway. Be aware that when following redirects, unless
    it is a code 303 redirect, url and POST urlencoded variables will
    be sent again to the redirected host. Multipart variables won't be
    sent again.  Sending to the redirected host can be dangerous, if
    such host is not trusted or uses a lower level of security.

    @param timeout Timeout in seconds. The value can be an integer,
    a floating point number or an ns_time value.

    @return Returns the data as dict with elements <code>headers</code>, <code>page</code>,
    <code>file</code>, <code>status</code>, and <code>modified</code>.

} {
    set this_proc [lindex [info level 0] 0]

    if {![regexp "^(https|http)://*" $url]} {
        return -code error "${this_proc}:  Invalid url:  $url"
    }

    # Check whether we will use ssl or not
    if {$force_ssl_p || [string match "https://*" $url]} {
        set http_api [util::http::native_https_api]
        if {$http_api eq ""} {
            return -code error "${this_proc}:  SSL not enabled"
        }
    } else {
        set http_api "ns_http"
    }

    if {$headers eq ""} {
        set headers [ns_set create headers]
    }

    # Determine whether we want to gzip the request.
    # Servers uncapable of treating such requests will likely throw an error...
    set req_content_encoding [ns_set iget $headers "content-encoding"]
    if {$req_content_encoding ne ""} {
        set gzip_request_p [string match "*gzip*" $req_content_encoding]
    } elseif {$gzip_request_p} {
        ns_set put $headers "Content-Encoding" "gzip"
    }

    # See if we want the response to be gzipped by headers or options
    # Server can decide to ignore this and serve the encoding he desires.
    # I also say to server that whatever he can give me will do, in case.
    set req_accept_encoding [ns_set iget $headers "accept-encoding"]
    if {$req_accept_encoding ne ""} {
        set gzip_response_p [string match "*gzip*" $req_accept_encoding]
    } elseif {$gzip_response_p} {
        ns_set put $headers "Accept-Encoding" "gzip, */*"
    }

    # zlib is mandatory when requiring compression
    if {$gzip_request_p || $gzip_response_p} {
        if {[info commands zlib] eq ""} {
            return -code error "${this_proc}:  zlib support not enabled"
        }
    }

    ## Encoding of the request

    # Any conversion or encoding of the payload should happen only at
    # the first request and not on redirects
    if {$depth == 0} {
        set content_type [ns_set iget $headers "content-type"]
        if {$content_type eq ""} {
            set content_type "text/plain; charset=[ns_config ns/parameters OutputCharset iso-8859-1]"
        }

        set enc [util::http::get_channel_settings $content_type]
        if {$enc ne "binary"} {
            set body [encoding convertto $enc $body]
        }

        if {$gzip_request_p} {
            set body [zlib gzip $body]
        }
    }


    ## Issuing of the request

    set queue_cmd [list $http_api queue \
                       -timeout [timeout $timeout] \
                       -method $method \
                       -headers $headers]
    if {$body_file ne ""} {
        lappend queue_cmd -body_file $body_file
    } elseif {$body ne ""} {
        lappend queue_cmd -body $body
    }
    lappend queue_cmd $url

    set resp_headers [ns_set create resp_headers]
    set wait_cmd [list $http_api wait -headers $resp_headers -status status]
    if {$spool_p} {
        lappend wait_cmd -spoolsize 0 -file spool_file
        set page ""
    } else {
        lappend wait_cmd -result page
    }

    if {$gzip_response_p} {
        # NaviServer since 4.99.6 can decompress response transparently
        if {[apm_version_names_compare [ns_info patchlevel] "4.99.5"] == 1} {
            lappend wait_cmd -decompress
        }
    }
    
    # Queue call to the url and wait for response
    {*}$wait_cmd [{*}$queue_cmd]

    if {[info exists spool_file]} {
        set page "${this_proc}: response spooled to '$spool_file'"
    } else {
        set spool_file ""
    }

    # Get values from response headers, then remove them
    set content_type     [ns_set iget $resp_headers content-type]
    set content_encoding [ns_set iget $resp_headers content-encoding]
    set location         [ns_set iget $resp_headers location]
    set last_modified    [ns_set iget $resp_headers last-modified]
    # Move in a list to be returned to the caller
    set r_headers [ns_set array $resp_headers]
    ns_set free $resp_headers


    # Redirection handling
    if {$depth <= $max_depth} {
        incr depth
        set redirection [util::http::follow_redirects \
                             -url             $url \
                             -method          $method \
                             -status          $status \
                             -location        $location \
                             -body            $body \
                             -body_file       $body_file \
                             -delete_body_file=$delete_body_file_p \
                             -headers         $headers \
                             -timeout         $timeout \
                             -depth           $depth \
                             -max_depth       $max_depth \
                             -force_ssl=$force_ssl_p \
                             -gzip_request=$gzip_request_p \
                             -gzip_response=$gzip_response_p \
                             -post_redirect=$post_redirect_p \
                             -spool=$spool_p \
                             -preference "native"]
        if {$redirection ne ""} {
            return $redirection
        }
    }

    if {$delete_body_file_p} {
        file delete -force -- $body_file
    }

    ## Decoding of the response

    # If response was compressed and our NaviServer
    # is prior 4.99.6, we have to decompress on our own.
    if {$content_encoding eq "gzip"} {
      if {[apm_version_names_compare [ns_info patchlevel] "4.99.5"] == 1} {
        if {$spool_file eq "" } {
            set page [zlib gunzip $page]
        }
      }
    }

    # Translate into proper encoding
    set enc [util::http::get_channel_settings $content_type]
    if {$enc ne "binary"} {
        set page [encoding convertfrom $enc $page]
    }


    return [list \
                headers  $r_headers \
                page     $page \
                file     $spool_file \
                status   $status \
                modified $last_modified]
}


#
## Curl wrapper implementation
#

namespace eval util::http::curl {}

ad_proc -private util::http::curl::version_not_cached {
} {
    Gets Curl's version number.
} {
    set version [lindex [exec curl --version] 1]
}

ad_proc -private util::http::curl::version {
} {
    Gets Curl's version number.
} {
    set key ::util::http::curl::version
    if {[info exists $key]} {
        return [set $key]
    } else {
        return [set $key [util::http::curl::version_not_cached]]
    }
}

ad_proc -private util::http::curl::timeout {input} {

    Convert the provided timeout value to a format suitable for curl.
    Since curl versions before 7.32.0 just accept integer, the
    granularity is set to seconds. On doubt, the value is rounded up.

} {
    if {[string is integer -strict $input]} {
        return $input
    } elseif {[string is double -strict $input]} {
        set secs    [expr {int($input)}]
        set secfrac [expr {$input - $secs}]
        if {$secfrac < 0.001} { return [expr {$secs + 1}] }
        return $secs
    } elseif {[regexp {^([0-9]+):([0-9]*)$} $input _ secs microsecs]} {
        if {$microsecs > 1000} { return [expr {$secs + 1}] }
        return $secs
    }
    return $input
}

ad_proc -private util::http::curl::request {
    -url
    {-method GET}
    {-headers ""}
    {-body ""}
    {-body_file ""}
    -delete_body_file:boolean
    {-files {}}
    {-timeout 30}
    {-depth 0}
    {-max_depth 10}
    -force_ssl:boolean
    -gzip_request:boolean
    -gzip_response:boolean
    -post_redirect:boolean
    -spool:boolean
} {

    Issue an HTTP request either GET or POST to the url specified.
    This is the curl wrapper implementation, used on AOLserver and
    when ssl native capabilities are not available.

    @param headers specifies an ns_set of extra headers to send to the
    server when doing the request.  Some options exist that allow to
    avoid the need to specify headers manually, but headers will
    always take precedence over options.

    @param body is the payload for the request and will be passed as
    is (useful for many purposes, such as webDav).  A convenient way
    to specify form variables for POST payloads through this argument
    is passing a string obtained by <code>export_vars -url</code>.

    @param body_file is an alternative way to specify the payload,
    useful in cases such as the upload of big files by POST. If
    specified, will have precedence over the <code>body</code>
    parameter. Content of the file won't be encoded according with the
    content type of the request as happen with <code>body</code>

    @param delete_body_file decides whether remove body payload file
    once the request is over.

    @param gzip_request informs the server that we are sending data
    in gzip format. Data will be automatically compressed.  Notice
    that not all servers can treat gzipped requests properly, and in
    such cases response will likely be an error.

    @param files curl is natively capable to send files via POST
    requests, and exploiting it can be desirable to send very large
    files via POST, because no extra space will be required on the
    disk to prepare the request payload using this feature. Files by
    this parameter are couples in the form <code>{ form_field_name
    file_path_on_filesystem }</code>

    @param gzip_response informs the server that we are
    capable of receiving gzipped responses.  If server complies to our
    indication, the result will be automatically decompressed.

    @param force_ssl is ignored when using curl http client
    implementation and is only kept for cross compatibility.

    @param spool enables file spooling of the request on the file
    specified. It is useful when we expect large responses from the
    server. The result is spooled to a temporary file, the name is
    returned in the file component of the result.

    @param post_redirect decides what happens when we are POSTing and
    server replies with 301, 302 or 303 redirects. RFC 2616/10.3.2
    states that method should not change when 301 or 302 are returned,
    and that GET should be used on a 303 response, but most HTTP
    clients fail in respecting this and switch to a GET request
    independently. This options forces this kinds of redirect to
    conserve their original method.
    Be aware that curl allows the POSTing of 303 requests only since
    version 7.26. Versions prior than this will follow 303 redirects
    by GET method. If following by POST is a requirement, please
    consider switching to the native http client implementation, or
    update curl.

    @param max_depth is the maximum number of redirects the proc is
    allowed to follow. A value of 0 disables redirection. When max
    depth for redirection has been reached, proc will return response
    from the last page we were redirected to. This is important if
    redirection response contains data such as cookies we need to
    obtain anyway. Be aware that when following redirects, unless
    it is a code 303 redirect, url and POST urlencoded variables will
    be sent again to the redirected host. Multipart variables won't be
    sent again.  Sending to the redirected host can be dangerous, if
    such host is not trusted or uses a lower level of security.

    @param timeout Timeout in seconds. The value can be an integer, a
    floating point number or an ns_time value. Since curl versions
    before 7.32.0 just accept integer, the granularity is set to
    seconds.

    @return Returns the data as dict with elements <code>headers</code>, <code>page</code>,
    <code>file</code>, <code>status</code>, and <code>modified</code>.

} {
    set this_proc [lindex [info level 0] 0]

    if {![regexp "^(https|http)://*" $url]} {
        return -code error "${this_proc}:  Invalid url:  $url"
    }

    if {$headers eq ""} {
        set headers [ns_set create headers]
    }

    # Determine whether we want to gzip the request.
    # Default is no, can't know whether the server accepts it.
    # We could at the http api level (TODO?)
    set req_content_encoding [ns_set iget $headers "content-encoding"]
    if {$req_content_encoding ne ""} {
        set gzip_request_p [string match "*gzip*" $req_content_encoding]
    } elseif {$gzip_request_p} {
        ns_set put $headers "Content-Encoding" "gzip"
    }

    # Curls accepts gzip by default, so if gzip response is not required
    # we have to ask explicitly for a plain text enconding
    set req_accept_encoding [ns_set iget $headers "accept-encoding"]
    if {$req_accept_encoding ne ""} {
        set gzip_response_p [string match "*gzip*" $req_accept_encoding]
    } elseif {!$gzip_response_p} {
        ns_set put $headers "Accept-Encoding" "utf-8"
    }

    # zlib is mandatory when compressing the input
    if {$gzip_request_p} {
        if {[info commands zlib] eq ""} {
            return -code error "${this_proc}:  zlib support not enabled"
        }
    }

    ## Encoding of the request

    # Any conversion or encoding of the payload should happen only at
    # the first request and not on redirects
    if {$depth == 0} {
        set content_type [ns_set iget $headers "content-type"]
        if {$content_type eq ""} {
            set content_type "text/plain; charset=[ns_config ns/parameters OutputCharset iso-8859-1]"
        }

        set enc [util::http::get_channel_settings $content_type]
        if {$enc ne "binary"} {
            set body [encoding convertto $enc $body]
        }

        if {$gzip_request_p} {
            set body [zlib gzip $body]
        }
    }

    ## Issuing of the request

    set cmd [list exec curl -s]

    if {$spool_p} {
        set spool_file [ad_tmpnam]
        lappend cmd -o $spool_file
    } else {
        set spool_file ""
    }

    if {$timeout ne ""} {
        lappend cmd --connect-timeout [timeout $timeout]
    }

# Antonio Pisano 2015-09-28: curl can follow redirects
# out of the box, but its behavior is to throw an error
# when maximum depth has been reached. I want it to
# return even a 3** page without complaining.
#     # Set redirection up to max_depth
#     if {$max_depth ne ""} {
#         lappend cmd -L --max-redirs $max_depth
#     }

    if {$method eq "GET"} {
        lappend cmd -G
    }

    # Files to be sent natively by curl by the -F option
    foreach f $files {
        if {[llength $f] != 2} {
            return -code error "${this_proc}:  invalid -files parameter: $files"
        }
        set f [join $f "=@"]
        lappend cmd -F $f
    }

    # If required, we'll follow POST request redirections by GET
    if {!$post_redirect_p} {
        lappend cmd --post301 --post302
        if {[apm_version_names_compare [version] "7.26"] >= 0} {
            lappend cmd --post303
        }
    }

    # Curl can decompress response transparently
    if {$gzip_response_p} {
        lappend cmd --compressed
    }

    # Unfortunately, as we are interacting with a shell, there is no
    # way to escape content easily and safely. Even when body is
    # passed as a Tcl variable, we just write its content to a file
    # and let it be read by curl.
    set create_body_file_p [expr {$body_file eq ""}]
    if {$create_body_file_p} {
        set body_file [ad_tmpnam]
        set wfd [open $body_file w]
        fconfigure $wfd -translation binary
        puts -nonewline $wfd $body
        close $wfd
    }
    lappend cmd --data-binary "@${body_file}"

    # Return response code together with webpage
    lappend cmd -w " %\{http_code\}"

    # Add headers to the command line
    foreach {key value} [ns_set array $headers] {
        if {$value eq ""} {
            set value ";"
        } else {
            set value ": $value"
        }
        set header "${key}${value}"
        lappend cmd -H "$header"
    }

    # Dump response headers into a tempfile to get them
    set resp_headers_tmpfile [ad_tmpnam]
    lappend cmd -D $resp_headers_tmpfile
    lappend cmd $url
    
    set response [{*}$cmd]

    # Parse headers from dump file
    set resp_headers [ns_set create resp_headers]
    set rfd [open $resp_headers_tmpfile r]
    while {[gets $rfd line] >= 0} {
        set line [split $line ":"]
        set key [lindex $line 0]
        set value [join [lrange $line 1 end] ":"]
        ns_set put $resp_headers $key [string trim $value]
    }
    close $rfd

    # Get values from response headers, then remove them
    set content_type  [ns_set iget $resp_headers content-type]
    set last_modified [ns_set iget $resp_headers last-modified]
    set location      [ns_set iget $resp_headers location]
    # Move in a list to be returned to the caller
    set r_headers [ns_set array $resp_headers]
    ns_set free $resp_headers

    set status [string range $response end-2 end]
    set page   [string range $response 0 end-4]

    # Redirection handling
    if {$depth <= $max_depth} {
        incr depth
        set redirection [util::http::follow_redirects \
                             -url             $url \
                             -method          $method \
                             -status          $status \
                             -location        $location \
                             -body            $body \
                             -body_file       $body_file \
                             -delete_body_file=$delete_body_file_p \
                             -headers         $headers \
                             -timeout         $timeout \
                             -depth           $depth \
                             -max_depth       $max_depth \
                             -force_ssl=$force_ssl_p \
                             -gzip_request=$gzip_request_p \
                             -gzip_response=$gzip_response_p \
                             -post_redirect=$post_redirect_p \
                             -spool=$spool_p \
                             -preference "curl"]
        if {$redirection ne ""} {
            return $redirection
        }
    }

    if {$spool_file ne ""} {
        set page "${this_proc}: response spooled to '$spool_file'"
    }

    # Translate into proper encoding
    set enc [util::http::get_channel_settings $content_type]
    if {$enc ne "binary"} {
        set page [encoding convertfrom $enc $page]
    }

    # Delete temp files
    file delete -- $resp_headers_tmpfile
    if {$create_body_file_p || $delete_body_file_p} {
        file delete -force -- $body_file
    }

    return [list \
                headers  $r_headers \
                page     $page \
                file     $spool_file \
                status   $status \
                modified $last_modified]
}

ad_proc -public util::get_http_status {
    -url
    {-use_get_p 1}
    {-timeout 30}
} {
    Returns the HTTP status code, e.g., 200 for a normal response
    or 500 for an error, of a URL.  By default this uses the GET method
    instead of HEAD since not all servers will respond properly to a
    HEAD request even when the URL is perfectly valid.  Note that
    this means that the server may be sucking down a lot of bits that it
    doesn't need.
} {
    set result [util::http::request \
                    -url             $url \
                    -method          [expr {$use_get_p ? "GET" : "HEAD"}] \
                    -timeout         $timeout]
    return [dict get $result status]
}


ad_proc -public util::link_responding_p {
    -url
    {-list_of_bad_codes "404"}
} {
    Returns 1 if the URL is responding (generally we think that anything other than 404 (not found) is okay).

    @see util::get_http_status
} {
    if { [catch { set status [util::get_http_status -url $url] } errmsg] } {
        # got an error; definitely not valid
        return 0
    } else {
        # we got the page but it might have been a 404 or something
        if { $status in $list_of_bad_codes } {
            return 0
        } else {
            return 1
        }
    }
}


#########################
## Deprecated HTTP api ##
#########################

ad_proc -deprecated -public util_link_responding_p {
    url
    {list_of_bad_codes "404"}
} {
    Returns 1 if the URL is responding (generally we think that anything other than 404 (not found) is okay).

    @see util::link_responding_p
} {
    util::link_responding_p -url $url -list_of_bad_codes $list_of_bad_codes
}

ad_proc -public -deprecated util_get_http_status {
    url
    {use_get_p 1}
    {timeout 30}
} {
    Returns the HTTP status code, e.g., 200 for a normal response
    or 500 for an error, of a URL.  By default this uses the GET method
    instead of HEAD since not all servers will respond properly to a
    HEAD request even when the URL is perfectly valid.  Note that
    this means AOLserver may be sucking down a lot of bits that it
    doesn't need.

    @see util::get_http_status
} {
    return [util::get_http_status -url $url -use_get_p $use_get_p -timeout $timeout]
}

ad_proc -deprecated -public ad_httpget {
    -url
    {-headers ""}
    {-timeout 30}
    {-depth 0}
} {
    Just like ns_httpget, but first headers is an ns_set of
    headers to send during the fetch.

    ad_httpget also makes use of Conditional GETs (if called with a
    Last-Modified header).

    Returns the data in array get form with array elements page status modified.

    @see util::http::get
} {
    ns_log debug "Getting {$url} {$headers} {$timeout} {$depth}"

    if {[incr depth] > 10} {
        return -code error "ad_httpget:  Recursive redirection:  $url"
    }

    lassign [ns_httpopen GET $url $headers $timeout] rfd wfd headers
    close $wfd

    set response [ns_set name $headers]
    set status [lindex $response 1]
    set last_modified [ns_set iget $headers last-modified]

    if {$status == 302 || $status == 301} {
        set location [ns_set iget $headers location]
        if {$location ne ""} {
            ns_set free $headers
            close $rfd
            return [ad_httpget -url $location -timeout $timeout -depth $depth]
        }
    } elseif { $status == 304 } {
        # The requested variant has not been modified since the time specified
        # A conditional get didn't return anything.  return an empty page and
        set page {}

        ns_set free $headers
        close $rfd
    } else {
        set length [ns_set iget $headers content-length]
        if { $length eq "" } {set length -1}

        set type [ns_set iget $headers content-type]
        set_encoding $type $rfd

        set err [catch {
            while 1 {
                set buf [_ns_http_read $timeout $rfd $length]
                append page $buf
                if { "" eq $buf } break
                if {$length > 0} {
                    incr length -[string length $buf]
                    if {$length <= 0} break
                }
            }
        } errMsg]
        ns_set free $headers
        close $rfd

        if {$err} {
            return -code error -errorinfo $::errorInfo $errMsg
        }
    }

    # order matters here since we depend on page content
    # being element 1 in this list in util_httpget
    return [list page $page \
                status $status \
                modified $last_modified]
}

ad_proc -deprecated -public util_httpget {
    url {headers ""} {timeout 30} {depth 0}
} {
    util_httpget simply calls util::http::get which also returns
    status and last_modfied

    @see util::http::get
} {
    return [dict get [util::http::get -url $url -headers $headers -timeout $timeout -depth $depth] page]
}

# httppost; give it a URL and a string with formvars, and it
# returns the page as a Tcl string
# formvars are the posted variables in the following form:
#        arg1=value1&arg2=value2

# in the event of an error or timeout, -1 is returned

ad_proc -deprecated -public util_httppost {url formvars {timeout 30} {depth 0} {http_referer ""}} {
    Returns the result of POSTing to another Web server or -1 if there is an error or timeout.
    formvars should be in the form \"arg1=value1&arg2=value2\".
    <p>
    post is encoded as application/x-www-form-urlencoded.  See util_http_file_upload
    for file uploads via post (encoded multipart/form-data).
    <p>
    @see util_http_file_upload
} {
    if { [catch {
        if {[incr depth] > 10} {
            return -code error "util_httppost:  Recursive redirection:  $url"
        }
        set http [util_httpopen POST $url "" $timeout $http_referer]
        set rfd [lindex $http 0]
        set wfd [lindex $http 1]

        #headers necessary for a post and the form variables

        _ns_http_puts $timeout $wfd "Content-type: application/x-www-form-urlencoded \r"
        _ns_http_puts $timeout $wfd "Content-length: [string length $formvars]\r"
        _ns_http_puts $timeout $wfd \r
        _ns_http_puts $timeout $wfd "$formvars\r"
        flush $wfd
        close $wfd

        set rpset [ns_set new [_ns_http_gets $timeout $rfd]]
        while 1 {
            set line [_ns_http_gets $timeout $rfd]
            if { $line eq "" } break
            ns_parseheader $rpset $line
        }

        set headers $rpset
        set response [ns_set name $headers]
        set status [lindex $response 1]
        if {$status == 302} {
            set location [ns_set iget $headers location]
            if {$location ne ""} {
                ns_set free $headers
                close $rfd
                return [util_httpget $location {}  $timeout $depth]
            }
        }
        set length [ns_set iget $headers content-length]
        if { "" eq $length } {set length -1}
        set type [ns_set iget $headers content-type]
        set_encoding $type $rfd
        set err [catch {
            while 1 {
                set buf [_ns_http_read $timeout $rfd $length]
                append page $buf
                if { "" eq $buf } break
                if {$length > 0} {
                    incr length -[string length $buf]
                    if {$length <= 0} break
                }
            }
        } errMsg]
        ns_set free $headers
        close $rfd
        if {$err} {
            return -code error -errorinfo $::errorInfo $errMsg
        }
    } errmgs ] } {return -1}
    return $page
}

# system by Tracy Adams (teadams@arsdigita.com) to permit AOLserver to POST
# to another Web server; sort of like ns_httpget

ad_proc -deprecated -public util_httpopen {
    method
    url
    {rqset ""}
    {timeout 30}
    {http_referer ""}
} {
    Like ns_httpopen but works for POST as well; called by util_httppost
} {

    if { ![string match "http://*" $url] } {
        return -code error "Invalid url \"$url\":  _httpopen only supports HTTP"
    }
    set url [split $url /]
    set hp [split [lindex $url 2] :]
    set host [lindex $hp 0]
    set port [lindex $hp 1]
    if { [string match $port ""] } {set port 80}
    set uri /[join [lrange $url 3 end] /]
    set fds [ns_sockopen -nonblock $host $port]
    set rfd [lindex $fds 0]
    set wfd [lindex $fds 1]
    if { [catch {
        _ns_http_puts $timeout $wfd "$method $uri HTTP/1.0\r"
        _ns_http_puts $timeout $wfd "Host: $host\r"
        if {$rqset ne ""} {
            for {set i 0} {$i < [ns_set size $rqset]} {incr i} {
                _ns_http_puts $timeout $wfd \
                    "[ns_set key $rqset $i]: [ns_set value $rqset $i]\r"
            }
        } else {
            _ns_http_puts $timeout $wfd \
                "Accept: */*\r"

            _ns_http_puts $timeout $wfd "User-Agent: Mozilla/1.01 \[en\] (Win95; I)\r"
            _ns_http_puts $timeout $wfd "Referer: $http_referer \r"
        }

    } errMsg] } {
        #close $wfd
        #close $rfd
        if { [info exists rpset] } {ns_set free $rpset}
        return -1
    }
    return [list $rfd $wfd ""]

}

ad_proc -deprecated -public util_http_file_upload { -file -data -binary:boolean -filename
    -name {-mime_type */*} {-mode formvars}
    {-rqset ""} url {formvars {}} {timeout 30}
    {depth 10} {http_referer ""}
} {
    Implement client-side HTTP file uploads as multipart/form-data as per
    RFC 1867.
    <p>

    Similar to <a href="proc-view?proc=util_httppost">util_httppost</a>,
    but enhanced to be able to upload a file as <tt>multipart/form-data</tt>.
    Also useful for posting to forms that require their input to be encoded
    as <tt>multipart/form-data</tt> instead of as
    <tt>application/x-www-form-urlencoded</tt>.

    <p>

    The switches <tt>-file /path/to/file</tt> and <tt>-data
    $raw_data</tt> are mutually exclusive.  You can specify one or the
    other, but not both.  NOTE: it is perfectly valid to not specify
    either, in which case no file is uploaded, but form variables are
    encoded using <tt>multipart/form-data</tt> instead of the usual
    encoding (as noted aboved).

    <p>

    If you specify either <tt>-file</tt> or <tt>-data</tt> you
    <strong>must</strong> supply a value for <tt>-name</tt>, which is
    the name of the <tt>&lt;INPUT TYPE="file" NAME="..."&gt;</tt> form
    tag.

    <p>

    Specify the <tt>-binary</tt> switch if the file (or data) needs
    to be base-64 encoded.  Not all servers seem to be able to handle
    this.  (For example, http://mol-stage.usps.com/mml.adp, which
            expects to receive an XML file doesn't seem to grok any kind of
            Content-Transfer-Encoding.)

    <p>

    If you specify <tt>-file</tt> then <tt>-filename</tt> is optional
    (it can be inferred from the name of the file).  However, if you
    specify <tt>-data</tt> then it is mandatory.

    <p>

    If <tt>-mime_type</tt> is not specified then <tt>ns_guesstype</tt>
    is used to try and find a mime type based on the <i>filename</i>.
    If <tt>ns_guesstype</tt> returns <tt>*/*</tt> the generic value
    of <tt>application/octet-stream</tt> will be used.

    <p>

    Any form variables may be specified in one of four formats:
    <ul>
    <li><tt>array</tt> (list of key value pairs like what [array get] returns)
    <li><tt>formvars</tt> (list of url encoded formvars, i.e. foo=bar&x=1)
    <li><tt>ns_set</tt> (an ns_set containing key/value pairs)
    <li><tt>vars</tt> (a list of Tcl vars to grab from the calling environment)
    </ul>

    <p>

    <tt>-rqset</tt> specifies an ns_set of extra headers to send to
    the server when doing the POST.

    <p>

    timeout, depth, and http_referer are optional, and are included
    as optional positional variables in the same order they are used
    in <tt>util_httppost</tt>.  NOTE: <tt>util_http_file_upload</tt> does
    not (currently) follow any redirects, so depth is superfulous.

    @author Michael A. Cleverly (michael@cleverly.com)
    @creation-date 3 September 2002

    @see util::http::post
} {

    # sanity checks on switches given
    if {$mode ni {formvars array ns_set vars}} {
        error "Invalid mode \"$mode\"; should be one of: formvars,\
            array, ns_set, vars"
    }

    if {[info exists file] && [info exists data]} {
        error "Both -file and -data are mutually exclusive; can't use both"
    }

    if {[info exists file]} {
        if {![file exists $file]} {
            error "Error reading file: $file not found"
        }

        if {![file readable $file]} {
            error "Error reading file: $file permission denied"
        }

        set fp [open $file]
        fconfigure $fp -translation binary
        set data [read $fp]
        close $fp

        if {![info exists filename]} {
            set filename [file tail $file]
        }

        if {$mime_type eq "*/*" || $mime_type eq ""} {
            set mime_type [ns_guesstype $file]
        }
    }

    set boundary [ns_sha1 [list [clock clicks -milliseconds] [clock seconds]]]
    set payload {}

    if {[info exists data] && [string length $data]} {
        if {![info exists name]} {
            error "Cannot upload file without specifing form variable -name"
        }

        if {![info exists filename]} {
            error "Cannot upload file without specifing -filename"
        }

        if {$mime_type eq "*/*" || $mime_type eq ""} {
            set mime_type [ns_guesstype $filename]

            if {$mime_type eq "*/*" || $mime_type eq ""} {
                set mime_type application/octet-stream
            }
        }

        if {$binary_p} {
            set data [base64::encode base64]
            set transfer_encoding base64
        } else {
            set transfer_encoding binary
        }

        append payload --$boundary \
            \r\n \
            "Content-Disposition: form-data; " \
            "name=\"$name\"; filename=\"$filename\"" \
            \r\n \
            "Content-Type: $mime_type" \
            \r\n \
            "Content-transfer-encoding: $transfer_encoding" \
            \r\n \
            \r\n \
            $data \
            \r\n
    }


    set variables [list]
    switch -- $mode {
        array {
            set variables $formvars
        }

        formvars {
            foreach formvar [split $formvars &] {
                set formvar [split $formvar  =]
                set key [lindex $formvar 0]
                set val [join [lrange $formvar 1 end] =]
                lappend variables $key $val
            }
        }

        ns_set {
            for {set i 0} {$i < [ns_set size $formvars]} {incr i} {
                set key [ns_set key $formvars $i]
                set val [ns_set value $formvars $i]
                lappend variables $key $val
            }
        }

        vars {
            foreach key $formvars {
                upvar 1 $key val
                lappend variables $key $val
            }
        }
    }

    foreach {key val} $variables {
        append payload --$boundary \
            \r\n \
            "Content-Disposition: form-data; name=\"$key\"" \
            \r\n \
            \r\n \
            $val \
            \r\n
    }

    append payload --$boundary-- \r\n

    if { [catch {
        if {[incr depth -1] <= 0} {
            return -code error "util_http_file_upload:\
                Recursive redirection: $url"
        }

        lassign [util_httpopen POST $url $rqset $timeout $http_referer] rfd wfd

        _ns_http_puts $timeout $wfd \
            "Content-type: multipart/form-data; boundary=$boundary\r"
        _ns_http_puts $timeout $wfd "Content-length: [string length $payload]\r"
        _ns_http_puts $timeout $wfd \r
        _ns_http_puts $timeout $wfd "$payload\r"
        flush $wfd
        close $wfd

        set rpset [ns_set new [_ns_http_gets $timeout $rfd]]
        while 1 {
            set line [_ns_http_gets $timeout $rfd]
            if { $line eq "" } break
            ns_parseheader $rpset $line
        }

        set headers $rpset
        set response [ns_set name $headers]
        set status [lindex $response 1]
        set length [ns_set iget $headers content-length]
        if { "" eq $length } { set length -1 }
        set type [ns_set iget $headers content-type]
        set_encoding $type $rfd
        set err [catch {
            while 1 {
                set buf [_ns_http_read $timeout $rfd $length]
                append page $buf
                if { "" eq $buf } break
                if {$length > 0} {
                    incr length -[string length $buf]
                    if {$length <= 0} break
                }
            }
        } errMsg]

        ns_set free $headers
        close $rfd

        if {$err} {
            return -code error -errorinfo $::errorInfo $errMsg
        }
    } errmsg] } {
        if {[info exists wfd] && $wfd in [file channels]} {
            close $wfd
        }

        if {[info exists rfd] && $rfd in [file channels]} {
            close $rfd
        }

        set page -1
    }

    return $page
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
