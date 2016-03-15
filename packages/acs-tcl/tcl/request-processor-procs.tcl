ad_library {

    The ACS Request Processor: the set of routines called upon every
    single HTTP request to an ACS server.

    @author Jon Salz (jsalz@arsdigita.com)
    @creation-date 15 May 2000
    @cvs-id $Id$
}

#####
#
#  PUBLIC API
#
#####

ad_proc -public rp_internal_redirect {
    -absolute_path:boolean
    path
} {

    Tell the request processor to return some other page.

    The path can either be relative to the current directory (e.g. "some-template") 
    relative to the server root (e.g. "/packages/my-package/www/some-template"), or
    an absolute path (e.g. "/home/donb/openacs-4/templates/some-cms-template"). 

    When there is no extension then the request processor will choose the 
    matching file according to the extension preferences.

    Parameters will stay the same as in the initial request.

    Keep in mind that if you do an internal redirect to something other than
    the current directory, relative links returned to the clients
    browser may be broken (since the client will have the original URL).

    Use rp_form_put or rp_form_update if you want to feed query variables to the redirected page.
    
    @param absolute_path If set the path is an absolute path within the host filesystem
    @param path path to the file to serve

    @see rp_form_put, rp_form_update

} {

    # protect from circular redirects

    if { ![info exists ::__rp_internal_redirect_recursion_counter] } {
        set ::__rp_internal_redirect_recursion_counter 0
    } elseif { $::__rp_internal_redirect_recursion_counter > 10 } {
        error "rp_internal_redirect: Recursion limit exceeded."
    } else {
        incr ::__rp_internal_redirect_recursion_counter
    }

    if { [string is false $absolute_path_p] } {
        if { [string index $path 0] ne "/" } {
            # it's a relative path, prepend the current location
            set path "[file dirname [ad_conn file]]/$path"
        } else {
            set path "$::acs::rootdir$path"
        }
    }

    # save the current file setting
    set saved_file [ad_conn file]

    rp_serve_abstract_file $path

    # restore the file setting. we need to do this because
    # rp_serve_abstract_file sets it to the path we internally
    # redirected to, and rp_handler will cache the file setting
    # internally in the tcl_url2file variable when PerformanceModeP is
    # switched on. This way it caches the location that was originally
    # requested, not the path that we redirected to.
    ad_conn -set file $saved_file
}

ad_proc rp_getform {} {

    This proc is a simple wrapper around AOLserver's standard ns_getform
    proc, that will create the form if it doesn't exist, so that you
    can then add values to that form. This is useful in conjunction 
    with rp_internal_redirect to redirect to a different page with 
    certain query variables set.

    @author Lars Pind (lars@pinds.com)
    @creation-date August 20, 2002

    @return the form ns_set, just like ns_getform, except it will 
    always be non-empty.
    
} {
    # The form may not exist, if there's nothing in it
    if { [ns_getform] ne "" } {
        # It's there
        return [ns_getform]
    } {
        # It doesn't exist, create a new one

        # This is the magic global Tcl variable that AOLserver uses 
        # to store the ns_set that contains the query args or form.
        global _ns_form

        # Simply create a new ns_set and store it in the global _ns_set variable
        set _ns_form [ns_set create]
        return $_ns_form
    }
}

ad_proc rp_form_put { name value } {

    This proc adds a query variable to AOLserver's internal ns_getform
    form, so that it'll be picked up by ad_page_contract and other procs 
    that look at the query variables or form supplied. This is useful
    when you do an rp_internal_redirect to a new page, and you want to
    feed that page with certain query variables.

    Note that the variable will just be appended to the form ns_set
    which may not be what you want, if it exists already you will
    now have two entries in the ns_set which may cause ad_page_contract to
    break.  Also, only simple variables may be added, not arrays.

    @author Lars Pind (lars@pinds.com)
    @creation-date August 20, 2002

    @return the form ns_set, in case you're interested. Mostly you will want to discard the result.

} {
    set form [rp_getform]
    ns_set put $form $name $value
    return $form
}

ad_proc rp_form_update { name value } {

    Identical to rp_form_put, but uses ns_set update instead.

    @return the form ns_set, in case you're interested. Mostly you will want to discard the result.

} {
    set form [rp_getform]
    ns_set update $form $name $value
    return $form
}

#
# GN: maybe this function was useful for ancient versions of Tcl, but
# unless i oversee something, it does not make any sense. The comment
# argues, that "return -code ..." ignores the error code, but then the
# function uses "return -code ..." to fix this...
#
ad_proc -deprecated ad_return { args } {

    Works like the "return" Tcl command, with one difference. Where
    "return" will always return TCL_RETURN, regardless of the -code
    switch this way, by burying it inside a proc, the proc will return
    the code you specify.

    <p>

    Why? Because "return" only sets the "returnCode" attribute of the
    interpreter object, which the function actually interpreting the
    procedure then reads and uses as the return code of the procedure.
    This proc adds just that level of processing to the statement.

    <p>

    When is that useful or necessary? Here:

    <pre>
    set errno [catch {
        return -code error "Boo!"
    } error]
    </pre>

    In this case, <code>errno</code> will always contain 2 (TCL_RETURN).
    If you use ad_return instead, it'll contain what you wanted, namely
    1 (TCL_ERROR).

} {
    return {*}$args
}

ad_proc -private rp_registered_proc_info_compare { info1 info2 } {

    A comparison predicate for registered procedures, returning -1, 0,
    or 1 depending the relative sorted order of $info1 and $info2 in the
    procedure list. Items with longer paths come first.

} {
    set info1_path [lindex $info1 1]
    set info2_path [lindex $info2 1]

    set info1_path_length [string length $info1_path]
    set info2_path_length [string length $info2_path]

    if { $info1_path_length < $info2_path_length } {
        return 1
    }
    if { $info1_path_length > $info2_path_length } {
        return -1
    }
    return 0
}

ad_proc -public ad_register_proc {
    -sitewide:boolean
    { -debug f }
    { -noinherit f }
    { -description "" }
    method path proc { arg "" }
} {

    Registers a procedure (see ns_register_proc for syntax). Use a
    method of "*" to register GET, POST, and HEAD filters. If debug is
    set to "t", all invocations of the procedure will be logged in the
    server log.

    @param sitewide specifies that the filter should be applied on a
    sitewide (not subsite-by-subsite basis).

} {
    if {$method eq "*"} {
        # Shortcut to allow registering filter for all methods. Just
        # call ad_register_proc again, with each of the three methods.
        foreach method { GET POST HEAD } {
            ad_register_proc -debug $debug -noinherit $noinherit $method $path $proc $arg
        }
        return
    }

    if {$method ni { GET POST HEAD PUT DELETE }} {
        error "Method passed to ad_register_proc must be one of GET, POST, HEAD, PUT and DELETE"
    }

    set proc_info [list $method $path $proc $arg $debug $noinherit $description [info script]]
    nsv_lappend rp_registered_procs . $proc_info
}

ad_proc -private rp_invoke_filter { conn filter_info why } {

    Invokes the filter described in $argv, writing an error message to
    the browser if it fails (unless <i>kind</i> is <code>trace</code>).

} {
    set startclicks [clock clicks -milliseconds]

    lassign $filter_info filter_index debug_p arg_count proc arg

    rp_debug -debug $debug_p "Invoking $why filter $proc"

    switch $arg_count {
        0 { set errno [catch { set result [$proc] } error] }
        1 { set errno [catch { set result [$proc $why] } error] }
        2 { set errno [catch { set result [$proc $conn $why] } error] }
        default {
            set errno [catch {
                ad_try {
                    set result [$proc $conn $arg $why]
                } ad_script_abort val {
                    set result "filter_return"
                }
            } error] 
        }
    }

    if { $errno } {
        # Uh-oh - an error occurred.
        ds_add rp [list filter [list $why [ns_conn method] [ns_conn url] $proc $arg] \
                       $startclicks [clock clicks -milliseconds] "error" $::errorInfo]
        # make sure you report catching the error!
        rp_debug "error in filter $proc for [ns_conn method] [ns_conn url]?[ns_conn query] errno is $errno message is $::errorInfo"
        rp_report_error
        set result "filter_return"

    } elseif {$result ne "filter_ok" && $result ne "filter_break" && $result ne "filter_return" } {

        set error_msg "error in filter $proc for [ns_conn method] [ns_conn url]?[ns_conn query].  Filter returned invalid result \"$result\""
        ds_add rp [list filter [list $why [ns_conn method] [ns_conn url] $proc $arg] \
                       $startclicks [clock clicks -milliseconds] "error" $error_msg]
        # report the bad filter_return message
        rp_debug -debug t -ns_log_level error $error_msg
        rp_report_error -message $error_msg
        set result "filter_return"
    } else {
        ds_add rp [list filter [list $why [ns_conn method] [ns_conn url] $proc $arg] \
                       $startclicks [clock clicks -milliseconds] $result]
    }

    rp_debug -debug $debug_p "Done invoking $why filter $proc (returning $result)"

    # JCD: Why was this here?  the rp_finish_serving_page is called inside the 
    # handlers and this handles trace filters 
    #    if {$result ne "filter_return"  } {
    #      rp_finish_serving_page
    #    }

    return $result
}

ad_proc -private rp_invoke_proc { conn argv } {

    Invokes a registered procedure.

} {
    set startclicks [clock clicks -milliseconds]

    lassign $argv proc_index debug_p arg_count proc arg

    rp_debug -debug $debug_p "Invoking registered procedure $proc"

    switch $arg_count {
        0 { set errno [catch $proc error] }
        1 { set errno [catch "$proc $arg" error] }
        default { set errno [catch {
            ad_try {
                $proc [list $conn] $arg
            } ad_script_abort val {
                # do nothing
            }
        } error] }
    }

    if { $errno } {
        # Uh-oh - an error occurred.
        ds_add rp [list registered_proc [list $proc $arg] $startclicks [clock clicks -milliseconds] "error" $::errorInfo]
        rp_debug "error in $proc for [ns_conn method] [ns_conn url]?[ns_conn query] errno is $errno message is $::errorInfo"
        rp_report_error
    } else {
        ds_add rp [list registered_proc [list $proc $arg] $startclicks [clock clicks -milliseconds]]
    }

    rp_debug -debug $debug_p "Done Invoking registered procedure $proc"

    rp_finish_serving_page
}

ad_proc -private rp_finish_serving_page {} {
    global doc_properties
    if { [info exists doc_properties(body)] } {
        rp_debug "Returning page:[info level [expr {[info level] - 1}]]: [ns_quotehtml [string range $doc_properties(body) 0 100]]"
        doc_return 200 text/html $doc_properties(body)
    }
}

ad_proc -public ad_register_filter {
    { -debug f }
    { -priority 10000 }
    { -critical f } 
    { -description "" }
    kind method path proc { arg "" }
} {

    Registers a filter that gets called during page serving. The filter
    should return one of 

    <ul>
    <li><code>filter_ok</code>, meaning the page serving will continue; 

    <li><code>filter_break</code> meaning the rest of the filters of
    this type will not be called;

    <li><code>filter_return</code> meaning the server will close the
    connection and end the request processing.
    </ul>

    @param kind Specify preauth, postauth or trace.

    @param method Use a method of "*" to register GET, POST, and HEAD
    filters.

    @param priority Priority is an integer; lower numbers indicate
    higher priority.

    @param critical If a filter is critical, page viewing will abort if
    a filter fails.

    @param debug If debug is set to "t", all invocations of the filter
    will be ns_logged.

    @param sitewide specifies that the filter should be applied on a
    sitewide (not subsite-by-subsite basis).

} {
    if {$method eq "*"} {
        # Shortcut to allow registering filter for all methods.
        foreach method { GET POST HEAD } {
           ad_register_filter -debug $debug -priority $priority -critical $critical $kind $method $path $proc $arg
        }
        return
    }

    if {$method ni { GET POST HEAD }} {
        error "Method passed to ad_register_filter must be one of GET, POST, or HEAD"
    }

    # Append the filter to the list. The list will be sorted according to priority 
    # and the filters will be bulk-registered after package-initialization. 
    # Also, the "Monitoring" package will be able to list the filters in this list.
    nsv_lappend rp_filters . \
        [list $priority $kind $method $path $proc $arg $debug $critical $description [info script]]

    # Register the filter immediately if the call is not from an *-init.tcl script.    
    if { ![apm_first_time_loading_p] } { 
        # Figure out how to invoke the filter, based on the number of arguments.
        if { [llength [info procs $proc]] == 0 } {
            # [info procs $proc] returns nothing when the procedure has been
            # registered by C code (e.g., ns_returnredirect). Assume that neither
            # "conn" nor "why" is present in this case.
            set arg_count 1
        } else {
            set arg_count [llength [info args $proc]]
        }
        
        set filter_index {}
        ns_register_filter $kind $method $path rp_invoke_filter [list $filter_index $debug $arg_count $proc $arg]
    }
}

ad_proc -private rp_html_directory_listing { dir } {

    Generates an HTML-formatted listing of a directory. This is mostly
    stolen from _ns_dirlist in an AOLserver module (fastpath.tcl).

} {
    # Create the table header.
    set list "
<table>
<tr align='left'><th>File</th><th>Size</th><th>Date</th></tr>
<tr align='left'><td colspan='3'><a href='../'>..</a></td></tr>
"

    # Loop through the files, adding a row to the table for each.
    foreach file [lsort [glob -nocomplain $dir/*]] {
        set tailHtml [ns_quotethml [file tail $file]]
        set link "<a href=\"$tailHtml\">$tailHtml</a>"

        # Build the stat array containing information about the file.
        file stat $file stat
        set size [expr {$stat(size) / 1000 + 1}]K
        set mtime $stat(mtime)
        set time [clock format $mtime -format "%d-%h-%Y %H:%M"]

        # Write out the row.
        append list "<tr align='left'><td>$link</td><td>$size</td><td>$time</td></tr>\n"
    }
    append list "</table>"
    return $list
}

#####
#
# NSV arrays used by the request processor:
#
#   - rp_filters($method,$kind), where $method in (GET, POST, HEAD)
#       and kind in (preauth, postauth, trace) A list of $kind filters
#       to be considered for HTTP requests with method $method. The
#       value is of the form
#
#             [list $priority $kind $method $path $proc $args $debug \
    #                 $critical $description $script]
#
#   - rp_registered_procs($method), where $method in (GET, POST, HEAD)
#         A list of registered procs to be considered for HTTP requests with
#         method $method. The value is of the form
#
#             [list $method $path $proc $args $debug $noinherit \
    #                   $description $script]
#
#   - rp_system_url_sections($url_section)
#         Indicates that $url_section is a system directory (like
#         SYSTEM) which is exempt from Host header checks and
#         session/security handling.
#
# ad_register_filter and ad_register_procs are used to add elements to
# these NSVs. We use lists rather than arrays for these data
# structures since "array get" and "array set" are rather expensive
# and we want to keep lookups fast.
#
#####

ad_proc -private rp_serve_resource_file { path } {

    Serve the resource file if kernel parameter settings allow this.

} {
    if { ![rp_file_can_be_public_p $path] } {
        ad_raise notfound
    }
    set expireTime [parameter::get -package_id [ad_acs_kernel_id] -parameter ResourcesExpireInterval -default 0]
    if {$expireTime != 0} {
        if {![string is integer -strict $expireTime]} {
            if {[regexp {^(\d+)d} $expireTime _ t]} {
                set expireTime [expr {60*60*24*$t}]
            } elseif {[regexp {^(\d+)h} $expireTime _ t]} {
                set expireTime [expr {60*60*$t}]
            } elseif {[regexp {^(\d+)m} $expireTime _ t]} {
                set expireTime [expr {60*$t}]
            } else {
                ns_log error "invalid expire time '$expireTime' specified"
                set expireTime 0
            }
        }
        ns_setexpires $expireTime
    }
    ns_returnfile 200 [ns_guesstype $path] $path
    return filter_return
}

ad_proc -private rp_resources_filter { why } {

    This filter runs on all URLs of the form /resources/*.  The acs-resources package
    mounts itself at /resources but we short circuit references here in order to
    maximize throughput for resource files.  We just ns_returnfile the file, no
    permissions are checked, the ad_conn structure is not initialized, etc.

    There are three mapping possibilities:

    /resources/package-key/* maps to root/packages/package-key/www/resources/*

    If that fails, we map to root/packages/acs-subsite/www/resources/*
    If that fails, we map to root/www/resources/*

    If the file doesn't exist we'll log an error and return filter_ok, which will allow
    packages mounted at "/resources" in a legacy site to work correctly.  This is a
    horrible kludge which may disappear after discussion with the gang.

    @author Don Baccus (dhogaza@pacifier.com)

} {
    ad_conn -set untrusted_user_id 0
    set path "[acs_package_root_dir [lindex [ns_conn urlv] 1]]/www/resources/[join [lrange [ns_conn urlv] 2 end] /]"
    if { [file isfile $path] } {
        return [rp_serve_resource_file $path]
    }

    set path $::acs::rootdir/www/[ns_conn url]
    if { [file isfile $path] } {
        return [rp_serve_resource_file $path]
    }
    
    set path [acs_package_root_dir acs-subsite]/www/[ns_conn url]
    if { [file isfile $path] } {
        return [rp_serve_resource_file $path]
    } 

    ns_log Warning "rp_sources_filter: file \"$path\" does not exists trying to serve as a normal request"
    return filter_ok
}

ad_proc -private rp_filter { why } {

    This is the first filter that runs for non-resource URLs. It sets up ad_conn and handles
    session security.

} {

    #####
    #
    # Initialize the environment: reset ad_conn, and populate it with
    # a few things.
    #
    #####

    ad_conn -reset
    if {[ns_info name] eq "NaviServer"} {
        # ns_conn id the internal counter by aolserver 4.5 and
        # NaviServer. The semantics of the counter were different in
        # Aolserver 4.0, when we require at least AolServer 4.5 the
        # server test could go away.
        ad_conn -set request [ns_conn id]
    } else {
        ad_conn -set request [nsv_incr rp_properties request_count]
    }
    ad_conn -set user_id 0
    ad_conn -set start_clicks [clock clicks -milliseconds]

    ds_collect_connection_info

    # -------------------------------------------------------------------------
    # Start of patch "hostname-based subsites"
    # -------------------------------------------------------------------------
    # 1. determine the root of the host and the requested URL
    set root [root_of_host [ad_host]]
    set ad_conn_url [ad_conn url]

    # 2. handle special case: if the root is a prefix of the URL, 
    #                         remove this prefix from the URL, and redirect.
    if { $root ne "" } {
        if { [regexp "^${root}(.*)$" $ad_conn_url match url] } {

            if { [regexp {^GET [^\?]*\?(.*) HTTP} [ns_conn request] match vars] } {
                append url ?$vars
            }
            if { [security::secure_conn_p] } {
                # it's a secure connection.
                ad_returnredirect -allow_complete_url https://[ad_host][ad_port]$url
                return "filter_return"
            } else {
                ad_returnredirect -allow_complete_url http://[ad_host][ad_port]$url
                return "filter_return"
            }
        }
        # Normal case: Prepend the root to the URL.
        # 3. set the intended URL
        ad_conn -set url ${root}${ad_conn_url}
        set ad_conn_url [ad_conn url]

        # 4. set urlv and urlc for consistency
        set urlv [lrange [split $root /] 1 end]
        ad_conn -set urlc [expr {[ad_conn urlc] + [llength $urlv]}]
        ad_conn -set urlv [concat $urlv [ad_conn urlv]]
    }
    # -------------------------------------------------------------------------
    # End of patch "hostname-based subsites"
    # -------------------------------------------------------------------------

    # Force the URL to look like [ns_conn location], if desired...

    # JCD:  Only do this if ForceHostP set and root is {}
    # if root non empty then we had a hostname based subsite and 
    # should not redirect since we got a hostname we know about.


    ### BLOCK NASTY YAHOO START
    set headers [ns_conn headers]
    set user_agent [ns_set iget $headers User-Agent]
    ns_log Debug "user agent is $user_agent" 

    if {[string match "*YahooSeeker*" $user_agent] 
        || [string match ".*Yahoo! Slurp.*" $user_agent]
    } {
        ns_log Notice "nasty spider $user_agent"
        ns_returnredirect "http://www.yahoo.com"
        return "filter_return"
    }
    ## BLOCK NASTY YAHOO FINISH

    if { $root eq "" 
         && [parameter::get -package_id [ad_acs_kernel_id] -parameter ForceHostP -default 0] 
     } { 
        set host_header [ns_set iget [ns_conn headers] "Host"]
        regexp {^([^:]*)} $host_header "" host_no_port
        regexp {^https?://([^:]+)} [ns_conn location] "" desired_host_no_port
        if { $host_header ne "" && $host_no_port ne $desired_host_no_port  } {
            set query [ns_getform]
            if { $query ne "" } {
                set query "?[export_entire_form_as_url_vars]"
            }
            ad_returnredirect -allow_complete_url "[ns_conn location][ns_conn url]$query"
            return "filter_return"
        }
    }

    # DRB: a bug in ns_conn causes urlc to be set to one greater than the number of URL
    # directory elements and the trailing element of urlv to be set to
    # {} if you hit the site with the host name alone.  This confuses code that
    # expects urlc to be set to the length of urlv and urlv to have a non-null
    # trailing element except in the case where urlc is 0 and urlv the empty list.

    if { [lindex [ad_conn urlv] end] == "" } {
        ad_conn -set urlc [expr {[ad_conn urlc] - 1}]
        ad_conn -set urlv [lrange [ad_conn urlv] 0 [expr {[llength [ad_conn urlv]] - 2}] ]
    }
    rp_debug -ns_log_level debug -debug t "rp_filter: setting up request: [ns_conn method] [ns_conn url] [ns_conn query]"

    if {[string length $ad_conn_url] >= 132} {
        ad_log warning "requested URL is too long ([string length $ad_conn_url] bytes, max 132); url=$ad_conn_url; reset url to /"
        set ad_conn_url /
    }
    
    if { [catch { array set node [site_node::get -url $ad_conn_url] } errmsg] } {
        # log and do nothing
        ad_log error "error within rp_filter: $errmsg"
    } else {

        if {$node(url) eq "$ad_conn_url/"} {
            ad_returnredirect $node(url)
            rp_debug "rp_filter: returnredirect $node(url)"
            rp_debug "rp_filter: return filter_return"
            return "filter_return"
        }

        ad_conn -set node_id $node(node_id)
        ad_conn -set node_name $node(name)
        ad_conn -set object_id $node(object_id)
        ad_conn -set object_url $node(url)
        ad_conn -set object_type $node(object_type)
        ad_conn -set package_id $node(object_id)
        ad_conn -set package_key $node(package_key)
        ad_conn -set package_url $node(url)
        ad_conn -set instance_name $node(instance_name)
        ad_conn -set extra_url [string range $ad_conn_url [string length $node(url)] end]
    }

    #####
    #
    # See if any libraries have changed. This may look expensive, but all it
    # does is check an NSV.
    #
    #####

    if { ![rp_performance_mode] } {
        # We wrap this in a catch, because we don't want an error here to 
        # cause the request to fail.
        if { [catch { apm_load_any_changed_libraries } error] } {
            ns_log Error "rp_filter: error apm_load_any_changed_libraries: $::errorInfo"
        }
    }
    #####
    #
    # Read in and/or generate security cookies.
    #
    #####

    # sec_handler (defined in security-procs.tcl) sets the ad_conn
    # session-level variables such as user_id, session_id, etc. we can
    # call sec_handler at this point because the previous return
    # statements are all error-throwing cases or redirects.
    # ns_log Notice "OACS= RP start"
    sec_handler
    # ns_log Notice "OACS= RP end"

    # Set locale and language of the request. We need ad_conn user_id to be set at this point
    if { [catch {
        set locale [lang::conn::locale -package_id [ad_conn package_id]]
        ad_conn -set locale $locale
        ad_conn -set language [lang::conn::language -locale $locale]
        ad_conn -set charset [lang::util::charset_for_locale $locale] 
    }] } {
        # acs-lang doesn't seem to be installed. Even though it must be installed now,
        # the problem is that if it isn't, everything breaks. So we wrap it in
        # a catch, and set locale and language to the empty strings.
        # This is a temporary work-around until it's reasonably safe
        # to assume that most people have added acs-lang to their system.
        ad_conn -set locale ""
        ad_conn -set language ""
        ad_conn -set charset ""
    }

    if {[ns_info name] eq "NaviServer"}  {
        # provide context information for background writer
        set requestor [expr {$::ad_conn(user_id) == 0 ? [ad_conn peeraddr] : $::ad_conn(user_id)}]
        catch {ns_conn clientdata [list $requestor [ns_conn url]]}
    }
    
    # Who's online
    whos_online::user_requested_page [ad_conn untrusted_user_id]

    #####
    #
    # Make sure the user is authorized to make this request. 
    #
    #####
    if { [ad_conn object_id] ne "" } {
        ad_try {
            switch -glob -- [ad_conn extra_url] {
                admin/* {
                    # double check someone has not accidentally granted
                    # admin to public and require logins for all admin pages
                    auth::require_login
                    permission::require_permission -object_id [ad_conn object_id] -privilege admin
                }
                sitewide-admin/* {
                    permission::require_permission -object_id [acs_lookup_magic_object security_context_root] -privilege admin
                }
                default {
                    permission::require_permission -object_id [ad_conn object_id] -privilege read
                }
            }
        } ad_script_abort val {
            rp_finish_serving_page
            rp_debug "rp_filter: return filter_return"
            return "filter_return"
        }
    }

    rp_debug "rp_filter: return filter_ok"
    return "filter_ok"
}

ad_proc rp_report_error {
    -message
} {

    Writes an error to the connection.

    @param message The message to write (pulled from <code>$::errorInfo</code> if none is specified).

} {
    if { ![info exists message] } {
                # We need 'message' to be a copy, because errorInfo will get overridden by some of the template parsing below
        set message $::errorInfo
    }
    set error_url "[ad_url][ad_conn url]?[export_entire_form_as_url_vars]"
    #    set error_file [template::util::url_to_file $error_url]
    set error_file [ad_conn file]
    set package_key []
    set prev_url [get_referrer]
    set feedback_id [db_nextval acs_object_id_seq]
    set user_id [ad_conn user_id]
    set bug_package_id [ad_conn package_id]
    set error_info $message
    set vars_to_export [export_vars -form { error_url error_info user_id prev_url error_file feedback_id bug_package_id }]
    
    ds_add conn error $message
    
    set params [list]
    
    #Serve the stacktrace
    set params [list [list stacktrace $message] \
                    [list user_id $user_id] \
                    [list error_file $error_file] \
                    [list prev_url $prev_url] \
                    [list feedback_id $feedback_id] \
                    [list error_url $error_url] \
                    [list bug_package_id $bug_package_id] \
                    [list vars_to_export $vars_to_export]]
    
    set error_message $message

    if {[parameter::get -package_id [ad_acs_kernel_id] -parameter RestrictErrorsToAdminsP -default 0] 
        && ![permission::permission_p -object_id [ad_conn package_id] -privilege admin] 
    } {
        set message {}
        set params [lreplace $params 0 0 [list stacktrace $message]]    
    }
    
    with_catch errmsg {
        set rendered_page [ad_parse_template -params $params "/packages/acs-tcl/lib/page-error"]
    } {
        # An error occurred during rendering of the error page
        ns_log Error "rp_report_error: Error rendering error page (!)\n$::errorInfo"
        set rendered_page "</table></table></table></h1></b></i><blockquote><pre>[ns_quotehtml $error_message]</pre></blockquote>"
    }

    ns_return 500 text/html $rendered_page

    ad_log error $error_message
}

ad_proc -private rp_path_prefixes {path} {
    Returns all the prefixes of a path ordered from most to least specific.
} {
    if {[string index $path 0] ne "/"} {
        set path "/$path"
    }
    set path [string trimright $path /]
    if { $path eq "" } {
        return "/"
    }

    set components [split $path "/"]
    set prefixes [list]
    for {set i [expr {[llength $components] -1}]} {$i > 0} {incr i -1} {
        lappend prefixes "[join [lrange $components 0 $i] "/"]/"
        lappend prefixes "[join [lrange $components 0 $i] "/"]"
    }
    lappend prefixes "/"

    return $prefixes
}

ad_proc -private rp_handler {} {

    The request handler, which responds to absolutely every HTTP request made to
    the server.

} {

    # DRB: Fix obscure case where we are served a request like GET http://www.google.com.
    # In this case AOLserver 4.0.10 (at least) doesn't run the preauth filter "rp_filter",
    # but rather tries to serve /global/file-not-found directly.  rp_handler dies a horrible
    # death if it's called without ad_conn being set up.  My fix is to simply redirect
    # to the url AOLserver substitutes if ad_conn does not exist (rp_filter begins with
    # ad_conn -reset) ...

    global ad_conn
    if { ![info exists ad_conn] } {
        ad_returnredirect [ns_conn url]
        return
    }
    if {$ad_conn(extra_url) ne "" && ![string match "*$ad_conn(extra_url)" [ns_conn url]]} {
        #
        # On internal redirects, the current ad_conn(extra_url) might be
        # from a previous request, which might have lead to a not-found
        # error pointing to a new url. This can lead to an hard-to find
        # loop which ends with a "recursion depth exceeded". There is a
        # similar problem with ad_conn(package_key) and
        # ad_conn(package_url) Therefore, we refetch the url info in case,
        # in case, and reset these values. These variables seem to be
        # sufficient to handle request processor loops, but maybe other
        # variables have to be reset either.
        #
        array set node [site_node::get -url [ad_conn url]]
        ad_conn -set extra_url [string range [ad_conn url] [string length $node(url)] end]
        ad_conn -set package_key $node(package_key)
        ad_conn -set package_url $node(url)
    }

    # JCD: keep track of rp_handler call count to prevent dev support from recording 
    # information twice when for example we get a 404 internal redirect. We should probably 
    set recursion_count [ad_conn recursion_count] 
    ad_conn -set recursion_count [incr recursion_count]

    set startclicks [clock clicks -milliseconds]
    rp_debug "rp_handler: handling request: [ns_conn method] [ns_conn url]?[ns_conn query]"
    if { [set code [catch {
        if { [rp_performance_mode] } {
            global tcl_url2file tcl_url2path_info
            if { ![catch {
                set file $tcl_url2file([ad_conn url])
                set path_info $tcl_url2path_info([ad_conn url])
            } errmsg] } {
                ad_conn -set file $file
                ad_conn -set path_info $path_info
                rp_serve_concrete_file $file
                return
            }
            rp_debug -debug t "error in rp_handler: $errmsg"
        }

        set resolve_values [concat $::acs::pageroot[string trimright [ad_conn package_url] /] \
                                [apm_package_url_resolution [ad_conn package_key]]]

        foreach resolve_value $resolve_values {
            lassign $resolve_value root match_prefix
            set extra_url [ad_conn extra_url]
            if { $match_prefix ne "" } {
                if { [string first $match_prefix $extra_url] == 0 } {
                    # An empty root indicates we should reject the attempted reference.  This
                    # is used to block references to embeded package [sitewide-]admin pages that
                    # avoid the request processor permission check
                    if { $root eq "" } {
                        break
                    }
                    set extra_url [string trimleft \
                                       [string range $extra_url [string length $match_prefix] end] /]
                } else {
                    continue
                }
            }
            ds_add rp [list notice "Trying rp_serve_abstract_file $root/$extra_url" $startclicks [clock clicks -milliseconds]]

            ad_try {
                rp_serve_abstract_file "$root/$extra_url"
                set tcl_url2file([ad_conn url]) [ad_conn file]
                set tcl_url2path_info([ad_conn url]) [ad_conn path_info]
            } notfound val {
                ds_add rp [list notice "File $root/$extra_url: Not found" $startclicks [clock clicks -milliseconds]]
                ds_add rp [list transformation [list notfound "$root / $extra_url" $val] $startclicks [clock clicks -milliseconds]]
                continue
            } redirect url {
                ds_add rp [list notice "File $root/$extra_url: Redirect" $startclicks [clock clicks -milliseconds]]
                ds_add rp [list transformation [list redirect $root/$extra_url $url] $startclicks [clock clicks -milliseconds]]
                ad_returnredirect $url
            } directory dir_index {
                ds_add rp [list notice "File $root/$extra_url: Directory index" $startclicks [clock clicks -milliseconds]]
                ds_add rp [list transformation [list directory $root/$extra_url $dir_index] $startclicks [clock clicks -milliseconds]]
                continue
            }
            return
        }

        if {[info exists dir_index]
            && ![string match "*/CVS/*" $dir_index]
        } {
            if { [nsv_get rp_directory_listing_p .] } {
                ns_returnnotice 200 "Directory listing of $dir_index" \
                    [rp_html_directory_listing $dir_index]
                return
            }
        }

        # OK, we didn't find a normal file. Let's look for a path info style thingy,
        # visiting possible file matches from most specific to least.

        foreach prefix [rp_path_prefixes $extra_url] {
            foreach resolve_value $resolve_values {
                lassign $resolve_value root match_prefix
                set extra_url [ad_conn extra_url]
                if { $match_prefix ne "" } {
                    if { [string first $match_prefix $extra_url] == 0 } {
                        set extra_url [string trimleft \
                                           [string range $extra_url [string length $match_prefix] end] /]
                    } else {
                        continue
                    }
                }
                ad_try {
                    ad_conn -set path_info \
                        [string range $extra_url [string length $prefix]-1 end]
                    rp_serve_abstract_file -noredirect -nodirectory \
                        -extension_pattern ".vuh" "$root$prefix"
                    set tcl_url2file([ad_conn url]) [ad_conn file]
                    set tcl_url2path_info([ad_conn url]) [ad_conn path_info]
                } notfound val {
                    ds_add rp [list transformation [list notfound $root$prefix $val] $startclicks [clock clicks -milliseconds]]
                    continue
                } redirect url {
                    ds_add rp [list transformation [list redirect $root$prefix $url] $startclicks [clock clicks -milliseconds]]
                    ad_returnredirect $url
                } directory dir_index {
                    ds_add rp [list transformation [list directory $root$prefix $dir_index] $startclicks [clock clicks -milliseconds]]
                    continue
                }
                return
            }
        }

        ds_add rp [list transformation [list notfound $root/$extra_url notfound] $startclicks [clock clicks -milliseconds]]
        ns_returnnotfound
    } errmsg]] } {
        if {$code == 1} {
            if {[ns_conn query] ne "" } {
                set q ?
            } else {
                set q ""
            }
            rp_debug "error in rp_handler: serving [ns_conn method] [ns_conn url]$q[ns_conn query] \n\tad_url \"[ad_conn url]\" maps to file \"[ad_conn file]\"\nerrmsg is $errmsg"
            rp_report_error
        }
    }
}

ad_proc -private rp_serve_abstract_file {
    -noredirect:boolean
    -nodirectory:boolean
    {-extension_pattern ".*"}
    path
} {
    Serves up a file given the abstract path. Raises the following
    exceptions in the obvious cases:
    <ul>
    <li>notfound  (passes back an empty value)
    <li>redirect  (passes back the url to which it wants to redirect)
    <li>directory (passes back the path of the directory)
    </ul>

    Should not be used in .vuh files or elsewhere, instead 
    use the public function rp_internal_redirect.

    @see rp_internal_redirect  
} {
    if {[string index $path end] eq "/"} {
        if { [file isdirectory $path] } {
            # The path specified was a directory; return its index file.

            # Directory name with trailing slash. Search for an index.* file.
            # Remember the name of the directory in $dir_index, so we can later
            # generate a directory listing if necessary.
            set dir_index $path
            set path "[string trimright $path /]/index"

        } else {

            # If there's a trailing slash on the path, the URL must refer to a
            # directory (which we know doesn't exist, since [file isdirectory $path]
            # returned 0).
            ad_raise notfound
        }
    }

    ### no more trailing slash.

    if { [file isfile $path] } {
        # It's actually a file.
        ad_conn -set file $path
    } else {
        # The path provided doesn't correspond directly to a file - we
        # need to glob.   (It could correspond directly to a directory.)

        if { ![file isdirectory [file dirname $path]] } {
            ad_raise notfound
        }

        ad_conn -set file [rp_concrete_file -extension_pattern $extension_pattern $path]
        
        if { [ad_conn file] eq "" } {
            
            if { [file isdirectory $path] && !$noredirect_p } {
                # Directory name with no trailing slash. Redirect to the same
                # URL but with a trailing slash.
                
                set url "[ad_conn url]/"
                if { [ad_conn query] ne "" } {
                    append url "?[ad_conn query]"
                }
                
                ad_raise redirect $url
            } else {
                if { [info exists dir_index] && !$nodirectory_p } {
                    ad_raise directory $dir_index
                } else {
                    # Nothing at all found! 404 time.
                    ad_raise notfound
                }
            }
        }
    }

    rp_serve_concrete_file [ad_conn file]
}

ad_proc -public rp_serve_concrete_file {file} {
    Serves a file.
} {
    set extension [file extension $file]
    set startclicks [clock clicks -milliseconds]

    if { [nsv_exists rp_extension_handlers $extension] } {
        set handler [nsv_get rp_extension_handlers $extension]

        #ns_log notice "check for extension handler for <$file> ==> <$handler>"

        catch {ds_init}

        if { [set errno [catch {
            ad_try {
                $handler
            } ad_script_abort val {
                # do nothing
            }
            rp_finish_serving_page
            ds_add rp [list serve_file [list $file $handler] $startclicks [clock clicks -milliseconds]]
        } error]] } {
            ds_add rp [list serve_file [list $file $handler] $startclicks [clock clicks -milliseconds] \
                           error "$::errorCode: $::errorInfo"]
            return -code $errno -errorcode $::errorCode -errorinfo $::errorInfo $error
        }
    } elseif { [rp_file_can_be_public_p $file] } {
        set type [ns_guesstype $file]
        ds_add rp [list serve_file [list $file $type] $startclicks [clock clicks -milliseconds]]
        ns_returnfile 200 $type $file
    } else {
        ad_raise notfound
    }
}

ad_proc -private rp_file_can_be_public_p { path } {
    Determines if -- absent application restrictions -- a file can be served to
    a client without violating simple security checks.  The checks and response
    do not require the initialization of ad_conn or expensive permission::
    calls.

    The proc will return page-not-found messages to the client in the case
    where the file must not be served, log a warning, and close the connection
    to the client.

    @param  path    The file to perform the simple security checks on.
    @return 0 (and close the connection!) if the file must not be served.  1 if the application should
    perform its own checks, if any.
} {
    #  first check that we are not serving a forbidden file like a .xql, a backup or CVS file                                                                                                      
    if {[file extension $path] eq ".xql"
        && ![parameter::get -parameter ServeXQLFiles -package_id [ad_acs_kernel_id] -default 0] } {
        # Can't use ad_return_exception_page because it depends upon an initialized ad_conn                                                                                                        
        ns_log Warning "An attempt was made to access an .XQL resource: {$path}."
        ns_return 404 "text/html" "Not Found"
        ns_conn close
        return 0
    }
    foreach match [parameter::get -parameter ExcludedFiles -package_id [ad_acs_kernel_id] -default {}] {
        if {[string match $match $path]} {
            # Can't use ad_return_exception_page because it depends upon an initialized ad_conn                                                                                                    
            ns_log Warning "An attempt was made to access an ExcludedFiles resource: {$path}."
            ns_return 404 "text/html" "Not Found"
            ns_conn close
            return 0
        }
    }
    return 1
}

ad_proc -private rp_concrete_file {
    {-extension_pattern ".*"}
    path
} {
    Given a path in the filesystem, returns the file that would be
    served, trying all possible extensions. Returns an empty string if
    there's no file "$path.*" in the filesystem (even if the file $path
                                                 itself does exist).
} {

    # Sub out funky characters in the pathname, so the user can't request
    # http://www.arsdigita.com/*/index (causing a potentially expensive glob
    # and bypassing registered procedures)!
    regsub -all {[^0-9a-zA-Z_/:.]} $path {\\&} path_glob

    # Grab a list of all available files with extensions.
    set files [glob -nocomplain "$path_glob$extension_pattern"]

    # Search for files in the order specified in ExtensionPrecedence,
    # include always "vuh"
    set precedence [parameter::get -package_id [ad_acs_kernel_id] -parameter ExtensionPrecedence -default tcl]
    foreach extension [concat [split [string trim $precedence] ","] vuh] {
        if { [lsearch -glob $files "*.$extension"] != -1 } {
            return "$path.$extension"
        }
    }

    # None of the extensions from ExtensionPrecedence were found - just pick
    # the first in alphabetical order.
    #
    # GN: OpenACS was trying to serve files with arbitrary extensions
    # (i.e. not included in the kernel parameter ExtensionPrecedence) in
    # case the requested file was not found.  This is quite dangerous
    # and breaks e.g. the listing of openacs.org/repository (which is a
    # directory), since the directory is moved every night into
    # openacs.org/repository.bak. With the given logic, it tries to
    # server the .bak directory as a file (which does of course not
    # work). That blind logic is not inecessary, and is actually a
    # potential attack vector.
    #
    #if { [llength $files] > 0 } {
    #  set files [lsort $files]
    #  return [lindex $files 0]
    #}

    # Nada!
    return ""
}

ad_proc -public ad_script_abort {} {
    Aborts the current running Tcl script, returning to the request processor.

    Used to stop processing after doing ad_returnredirect or other commands 
    which have already returned output to the client.
} {
    ad_raise ad_script_abort
}


ad_proc -private ad_acs_kernel_id_mem {} {

    Returns the package_id of the kernel. (not cached)

} {
    return [db_string acs_kernel_id_get {} -default 0]
}

# use proc rather than ad_proc on redefine since we don't want to see a 
# multiple define proc warning...
ad_proc -public ad_acs_kernel_id {} {
    Returns the package_id of the kernel.
} {
    set acs_kernel_id [ad_acs_kernel_id_mem]
    proc ad_acs_kernel_id {} "return $acs_kernel_id"
    return $acs_kernel_id
}

ad_proc -public ad_conn {args} {

    Returns a property about the connection. See the <a
    href="/doc/request-processor">request
    processor documentation</a> for an (almost complete) list of allowable values. 

    <p>

    If -set is passed then it sets a property.

    <p>

    If the property has not been set directly by OpenACS it will be passed on to aolservers <code>ns_conn</code>: <a href="http://www.aolserver.com/docs/devel/tcl/api/conn.html#ns_conn">http://www.aolserver.com/docs/devel/tcl/api/conn.html#ns_conn</a>. If it is not a valid option for <code>ns_conn</code> either then it will throw an error.

    Valid options for ad_conn are: request, sec_validated, browser_id, session_id, user_id, token, last_issue, deferred_dml, start_clicks, node_id, object_id, object_url, object_type, package_id, package_url, instance_name, package_key, extra_url, system_p, path_info, recursion_count.
    <p>

    Added recursion_count to properly deal with internalredirects.

} {
    global ad_conn

    set flag [lindex $args 0]
    if {[string index $flag 0] ne "-"} {
        set var $flag
        set flag "-get"
    } else {
        set var [lindex $args 1]
    }

    switch -- $flag {
        -connected_p {
            return [info exists ad_conn(request)]
        }

        -set {
            set ad_conn($var) [lindex $args 2]
        }

        -unset {
            unset ad_conn($var)
        }

        -reset {
            if {[info exists ad_conn]} {
                unset ad_conn
            }
            array set ad_conn {
                request ""
                sec_validated ""
                browser_id ""
                session_id ""
                user_id ""
                token ""
                last_issue ""
                deferred_dml ""
                start_clicks ""
                node_id ""
                object_id ""
                object_url ""
                object_type ""
                package_id ""
                package_url ""
                instance_name ""
                package_key ""
                extra_url ""
                file ""
                system_p 0
                path_info ""
                system_p 0
                recursion_count 0
                form_count -1
            }
            array unset ad_conn subsite_id
            array unset ad_conn locale
        }

        -get {
            # Special handling for the form, because "ns_conn form" can
            # cause the server to hang until the socket times out.  This
            # happens on pages handling multipart form data, where
            # ad_page_contract already has called ns_getform and has
            # retrieved all data from the client. ns_getform has its
            # own caching, so calling it instead of [ns_conn form]
            # is OK.

            switch $var {
                form {
                    return [ns_getform] 
                }
                all {
                    return [array get ad_conn]
                }
                default {
                    if { [info exists ad_conn($var)] } {
                        return $ad_conn($var)
                    }

                    # Fallback 
                    switch $var {
                        locale {
                            set ad_conn(locale) [parameter::get \
                                                     -parameter SiteWideLocale \
                                                     -package_id [apm_package_id_from_key "acs-lang"] \
                                                     -default {en_US}]
                            return $ad_conn(locale)
                        }
                        node_id {
                            # This is just a fallback, when the request
                            # processor has failed to set the actual site
                            # node, e.g. on invalid requests. When the
                            # fallback is missing, ns_conn spits out an
                            # error message since it does not know what a
                            # "node_id" is. The fallback is especially
                            # necessary, when a template is used for the
                            # error message, the templating system cannot
                            # determine the appropriate template without
                            # the node_id. In case of failure, the
                            # toplevel node_is is returned.
                            array set node [site_node::get -url /]
                            set ad_conn($var) $node(node_id)
                            ns_log notice "request processor did not set <ad_conn $var>, fallback: $ad_conn($var)"
                            return $ad_conn($var)
                        }
                        package_id {
                            # This is just a fallback, when the request
                            # processor has failed to set the actual
                            # package_id (see as wee under node_id above).
                            array set node [site_node::get -url /]
                            set ad_conn($var) $node(package_id)
                            ns_log notice "request processor did not set <ad_conn $var>, fallback: $ad_conn($var)"
                            return $ad_conn($var)
                        }
                        untrusted_user_id -
                        session_id -
                        user_id {
                            # Fallbacks, see above.
                            set ad_conn($var) 0
                            ns_log notice "request processor did not set <ad_conn $var>, fallback: $ad_conn($var)"
                            return $ad_conn($var)
                        }
                        extra_url -
                        locale -
                        language -
                        charset {
                            # Fallbacks, see above.
                            set ad_conn($var) ""
                            ns_log notice "request processor did not set <ad_conn $var>, use empty fallback value"
                            return $ad_conn($var)
                        }
                        subsite_node_id {
                            set ad_conn(subsite_node_id) [site_node::closest_ancestor_package \
                                                              -node_id [ad_conn node_id] \
                                                              -package_key [subsite::package_keys] \
                                                              -include_self \
                                                              -element "node_id"]
                            return $ad_conn(subsite_node_id)
                        }
                        subsite_id {
                            set ad_conn(subsite_id) [site_node::get_object_id \
                                                         -node_id [ad_conn subsite_node_id]]
                            return $ad_conn(subsite_id)
                        }
                        subsite_url {
                            set ad_conn(subsite_url) [site_node::get_url \
                                                          -node_id [ad_conn subsite_node_id]]
                            return $ad_conn(subsite_url)
                        }
                        vhost_subsite_url {
                            set ad_conn(vhost_subsite_url) [subsite::get_url]
                            return $ad_conn(vhost_subsite_url)
                        }
                        vhost_package_url {
                            set subsite_package_url [string range [ad_conn package_url] [string length [ad_conn subsite_url]] end]
                            set ad_conn(vhost_package_url) "[ad_conn vhost_subsite_url]$subsite_package_url"
                            return $ad_conn(vhost_package_url)
                        }
                        recursion_count {
                            # sometimes recusion_count will be uninitialized and 
                            # something will call ad_conn recursion_count - return 0 
                            # in that instance.  This is filters ahead of rp_filter which throw
                            # an ns_returnnotfound or something like that.
                            set ad_conn(recursion_count) 0
                            return 0
                        }
                        peeraddr {
                            if {[ns_config "ns/parameters" ReverseProxyMode false]} {
                                # Try to get the address provided by a
                                # reverse proxy such as NGINX via
                                # X-Forwarded-For, if available
                                set headers [ns_conn headers]
                                set i [ns_set ifind $headers "X-Forwarded-For"]
                                if {$i > -1 } {
                                    return [ns_set value $headers $i]
                                }
                            }
                            # return the physical peer address
                            return [ns_conn $var]
                        }

                        mobile_p {
                            #
                            # Check, if we are used from a mobile device (based on user_agent).
                            #
                            if {[ns_conn isconnected]} {
                                set user_agent [string tolower [ns_set get [ns_conn headers] User-Agent]]
                                set ad_conn(mobile_p) [regexp (android|webos|iphone|ipad) $user_agent]
                            } else {
                                set ad_conn(mobile_p) 0
                            }
                            return $ad_conn(mobile_p)
                        }
                        
                        default {
                            return [ns_conn $var]
                        }
                    }
                }
            }
        }

        default {
            error "ad_conn: unknown flag $flag"
        }
    }
}

ad_proc -private rp_register_extension_handler { extension args } {

    Registers a proc used to handle requests for files with a particular
    extension.

} {
    if { [llength $args] == 0 } {
        error "Must specify a procedure name"
    }
    ns_log Debug "rp_register_extension_handler: Registering [join $args " "] to handle $extension files"
    nsv_set rp_extension_handlers ".$extension" $args
}

ad_proc -private rp_handle_tcl_request {} {

    Handles a request for a .tcl file.
    Sets up the stack of datasource frames, in case the page is templated.

} {
    set ::template::parse_level [info level]
    source [ad_conn file]
}

ad_proc -private -deprecated rp_handle_adp_request {} {

    Handles a request for an .adp file.

    @see adp_parse_ad_conn_file

} {
    doc_init

    set adp [ns_adp_parse -file [ad_conn file]]

    if { [doc_exists_p] } {
        doc_set_property body $adp
        doc_serve_document
    } else {
        set content_type [ns_set iget [ad_conn outputheaders] "content-type"]
        if { $content_type eq "" } {
            set content_type "text/html"
        }
        doc_return 200 $content_type $adp
    }
}

ad_proc -private rp_handle_html_request {} {

    Handles a request for an HTML file.

} {
    ad_serve_html_page [ad_conn file]
}

if { [apm_first_time_loading_p] } {
    # Initialize nsv_sets

    nsv_array set rp_filters [list]
    nsv_array set rp_registered_procs [list]
    nsv_array set rp_extension_handlers [list]

    # The following stuff is in a -procs.tcl file rather than a -init.tcl file
    # since we want it done really really early in the startup process. Don't
    # try this at home!

    foreach method { GET POST HEAD } { nsv_set rp_registered_procs $method [list] }
}


ad_proc -private ad_http_cache_control { } {

    This adds specific headers to the http output headers for the current 
    request in order to prevent user agents and proxies from caching 
    the page.

    <p>

    It should be called only when the method to return the data to the 
    client is going to be ns_return. In other cases, e.g. ns_returnfile,
    one can assume that the returned content is not dynamic and can in
    fact be cached. Besides that, aolserver implements its own handling
    of Last-Modified headers with ns_returnfile. Also it should be
    called as late as possible - shortly before ns_return, so that 
    other code has the chance to set no_cache_control_p to 1 before
    it runs.
    
    <p>

    This proc can be disabled per request by calling
    "ad_conn -set no_http_cache_control_p 1" before this proc is reached. 
    It will not modify any headers if this variable is set to 1.
    
    <p>

    If the acs-kernel parameter CacheControlP is set to 0 then
    it's fully disabled.

    @author Tilmann Singer (tils-oacs@tils.net)

} {

    if { ![parameter::get -package_id [ad_acs_kernel_id] -parameter HttpCacheControlP -default 0]} {
        return
    }

    if { [info exists ::ad_conn(no_http_cache_control_p)] && $::ad_conn(no_http_cache_control_p) } {
        return
    }

    set headers [ad_conn outputheaders]

    # Check if any relevant header is already present - in this case
    # don't touch anything. 
    set modify_p 1

    if { [ns_set ifind $headers "cache-control"] > -1 
         || [ns_set ifind $headers "expires"] > -1 } {
        set modify_p 0
    } else {
        for { set i 0 } { $i < [ns_set size $headers] } { incr i } {
            if { [string tolower [ns_set key $headers $i]] eq "pragma" 
                 && [string tolower [ns_set value $headers $i]] eq "no-cache" 
             } {
                set modify_p 0
                break
            }
        }
    }

    # Set three headers, to be sure it won't get cached. If you are in
    # doubt, check the spec:
    # http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html

    if { $modify_p } {
        # actually add the headers
        ns_setexpires 0
        ns_set put $headers "Pragma" "no-cache"
        ns_set put $headers "Cache-Control" "no-cache"
    }
    
    # Prevent subsequent calls of this proc from adding the same
    # headers again.
    ad_conn -set no_http_cache_control_p 1
}


# -------------------------------------------------------------------------
# procs for hostname-based subsites
# -------------------------------------------------------------------------

ad_proc ad_host {} {
    Returns the hostname as it was typed in the browser,
    provided forcehostp is set to 0.
} {
    set host_and_port [ns_set iget [ns_conn headers] Host]
    if { [regexp {^([^:]+)} $host_and_port match host] } {
        return $host
    } else {
        return "unknown host"
    }
}

ad_proc ad_port {} {
    Returns the port as it was typed in the browser,
    provided forcehostp is set to 0.
} {
    set host_and_port [ns_set iget [ns_conn headers] Host]
    if { [regexp {^([^:]+):([0-9]+)} $host_and_port match host port] } {
        return ":$port"
    } else {
        return ""
    }
}

namespace eval ::acs {}

ad_proc root_of_host {host} {
    Maps a hostname to the corresponding sub-directory.
} {
    set key ::acs::root_of_host($host)
    if {[info exists $key]} {return [set $key]}
    set $key [root_of_host1 $host]
}

proc root_of_host1 {host} {
    # The main hostname is mounted at /.
    if { $host eq [ns_config ns/server/[ns_info server]/module/nssock Hostname] } {
        return ""
    }
    # Other hostnames map to subsites.
    set node_id [util_memoize [list rp_lookup_node_from_host $host]]

    if {$node_id eq ""} {
        set host [regsub "www\." $host ""]
        set node_id [util_memoize [list rp_lookup_node_from_host $host]]
    }

    if { $node_id ne "" } {
        set url [site_node::get_url -node_id $node_id]

        return [string range $url 0 end-1]
    } else {
        # Hack to provide a useful default
        return ""
    }
}

ad_proc -private rp_lookup_node_from_host { host } {
    return [db_string node_id {} -default ""]
} 



ad_proc -public request_denied_filter { why } {
    Deny serving the request
} {
    ad_return_forbidden \
        "Forbidden URL" \
        "<blockquote>No, we're not going to show you this file</blockquote>"

    return filter_return
}



if {[ns_info name] eq "NaviServer"} {
    # this is written for NaviServer 4.99.1 or newer
    foreach filter {rp_filter rp_resources_filter request_denied_filter} {
        set cmd ${filter}_aolserver
        if {[info commands $cmd] ne ""} {rename $cmd ""}
        rename $filter $cmd
        proc $filter {why} "$cmd \$why" 
    }

    set cmd rp_invoke_filter_conn
    if {[info commands $cmd] ne ""} {rename $cmd ""}
    rename rp_invoke_filter $cmd
    proc   rp_invoke_filter { why filter_info} "$cmd _ \$filter_info \$why"
    
    set cmd rp_invoke_proc_conn
    if {[info commands $cmd] ne ""} {rename $cmd ""}
    rename rp_invoke_proc   $cmd
    proc   rp_invoke_proc   { argv } "$cmd _ \$argv"
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

