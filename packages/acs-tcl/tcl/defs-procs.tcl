ad_library {
    ACS-specific general utility routines.

    @author Philip Greenspun (philg@arsdigita.com)

    @author Many others at ArsDigita and in the OpenACS community.
    @creation-date 2 April 1998
    @cvs-id $Id$
}

ad_proc -public ad_acs_version_no_cache {} {
    The OpenACS version of this instance. Uses the version name
    of the acs-kernel package.

    @author Peter Marklund
} {
    apm_version_get -package_key acs-kernel -array kernel

    return $kernel(version_name)
}
ad_proc -public ad_acs_version {} {
    The OpenACS version of this instance. Uses the version name
    of the acs-kernel package.

    @author Peter Marklund
} {
    set key ::acs::version
    if {[info exists $key]} {return [set $key]}
    set $key [util_memoize ad_acs_version_no_cache]
}

ad_proc -public ad_acs_release_date {} {
    The OpenACS release date of this instance. Uses the release date
    of the acs-kernel package.

    @author Peter Marklund
} {
    apm_version_get -package_key acs-kernel -array kernel

    return $kernel(release_date)
}

ad_proc -public ad_host_administrator {} {
    As defined in the HostAdministrator kernel parameter.

    @return The e-mail address of a technical person who can fix problems
} {
    return [parameter::get -package_id [ad_acs_kernel_id] -parameter HostAdministrator]
}

ad_proc -public ad_outgoing_sender {} {
    @return The email address that will sign outgoing alerts
} {
    return [parameter::get -package_id [ad_acs_kernel_id] -parameter OutgoingSender]
}

ad_proc -public ad_system_name {} {
    This is the main name of the Web service that you're offering
    on top of the OpenACS Web Publishing System.
} {
    return [parameter::get -package_id [ad_acs_kernel_id] -parameter SystemName]
}


ad_proc -public ad_pvt_home {} {
    This is the URL of a user's private workspace on the system, usually
    [subsite]/pvt/home.tcl
} {
    return "[subsite::get_element -element url -notrailing][parameter::get -package_id [ad_acs_kernel_id] -parameter HomeURL]"
}

ad_proc -public ad_admin_home {} {
   Returns the directory for the admin home.
} {
    return "[subsite::get_element -element url]admin"
}

# is this accurate? (rbm, aug 2002)

ad_proc -public ad_package_admin_home { package_key } {
    @return directory for the especified package's admin home.
} {
    return "[ad_admin_home]/$package_key"
}

ad_proc -public ad_pvt_home_name {} {
    This is the name that will be used for the user's workspace (usually "Your Workspace").
    @return the name especified for the user's workspace in the HomeName kernel parameter.
} {
    return [lang::util::localize [parameter::get -package_id [ad_acs_kernel_id] -parameter HomeName]]
}

ad_proc -public ad_pvt_home_link {} {
    @return the html fragment for the /pvt link
} {
    return "<a href=\"[ad_pvt_home]\">[ad_pvt_home_name]</a>"
}

ad_proc -public ad_site_home_link {} {
    @return a link to the user's workspace if the user is logged in. Otherwise, a link to the page root.
} {
    if { [ad_conn user_id] != 0 } {
        return "<a href=\"[ad_pvt_home]\">[subsite::get_element -element name]</a>"
    } else {
        # we don't know who this person is
        return "<a href=\"[subsite::get_element -element url]\">[subsite::get_element -element name]</a>"
    }
}

ad_proc -public ad_system_owner {} {
    Person who owns the service
    this person would be interested in user feedback, etc.
} {
    return [parameter::get -package_id [ad_acs_kernel_id] -parameter SystemOwner]
}


ad_proc -public ad_publisher_name {} {
    A human-readable name of the publisher, suitable for
    legal blather.
} {
    return [parameter::get -package_id [ad_acs_kernel_id] -parameter PublisherName]
}

ad_proc -public ad_url {} {
    This will be called by email alerts. Do not use ad_conn location
    @return the system url as defined in the kernel parameter SystemURL.
    @see util::configured_location
    @see util_current_location
} {
    return [parameter::get -package_id [ad_acs_kernel_id] -parameter SystemURL]
}

ad_proc -public acs_community_member_page {} {
    @return the url for the community member page
} {
    return "[subsite::get_element -element url -notrailing][parameter::get \
                -package_id [ad_acs_kernel_id] -parameter CommunityMemberURL]"
}

ad_proc -public acs_community_member_url {
    {-user_id:required}
} {
    @return the url for the community member page of a particular user
} {
    return [export_vars -base [acs_community_member_page] user_id]
}

ad_proc -public acs_community_member_link {
    {-user_id:required}
    {-label ""}
} {
    @return the link of the community member page of a particular user
    @see acs_community_member_url
} {
    if {$label eq ""} {
        acs_user::get -user_id $user_id -array user
        set label "$user(first_names) $user(last_name)"
    }
    set href [acs_community_member_url -user_id $user_id]
    return [subst {<a href="[ns_quotehtml $href]">$label</a>}]
}

ad_proc -public acs_community_member_admin_url {
    {-user_id:required}
} {
    @return the url for the community member admin page of a particular user
} {
    return [export_vars -base [parameter::get -package_id [ad_acs_kernel_id] -parameter CommunityMemberAdminURL] { user_id }]
}

ad_proc -public acs_community_member_admin_link {
    {-user_id:required}
    {-label ""}
} {
    @return the HTML link of the community member page of a particular admin user.
} {
    if {$label eq ""} {
        set label [expr {[person::person_p -party_id $user_id] ?
                         [acs_user::get_element \
                              -user_id $user_id -element name] : $user_id}]
    }
    set href [acs_community_member_admin_url -user_id $user_id]
    return [subst {<a href="[ns_quotehtml $href]">$label</a>}]
}


ad_proc -public ad_return_string_as_file {
    -string:required
    -filename:required
    -mime_type:required
} {
    Return a string as the content of a file

    @param string Content of the file to be sent back
    @param filename Name of the file to be returned
    @param mime_type Mime Type of the file being returned
} {
    ns_set put [ns_conn outputheaders] "Content-Disposition" "attachment; filename=\"$filename\""
    ns_return 200 $mime_type $string
}

ad_proc -public ad_return_complaint {
    exception_count
    exception_text
} {
    Return a page complaining about the user's input
    (as opposed to an error in our software, for which ad_return_error
    is more appropriate)

    @param exception_count Number of exceptions. Used to say either 'a problem' or 'some problems'.

    @param exception_text HTML chunk to go inside an UL tag with the error messages.
} {
    set complaint_template [parameter::get_from_package_key \
                                -package_key "acs-tcl" \
                                -parameter "ReturnComplaint" \
                                -default "/packages/acs-tcl/lib/ad-return-complaint"]
    ns_return 422 text/html [ad_parse_template \
                                 -params [list [list exception_count $exception_count] \
                                               [list exception_text $exception_text]] \
                                         $complaint_template]

    # raise abortion flag, e.g., for templating
    set ::request_aborted [list 422 "Problem with Your Input"]
}


ad_proc ad_return_exception_page {
    status
    title
    explanation
} {
    Returns an exception page.

    @author Unknown

    @param status HTTP status to be returned (e.g. 500, 404)
    @param title Title to be used for the error (will be shown to user)
    @param explanation Explanation for the exception.
} {
    set error_template [parameter::get_from_package_key \
                            -package_key "acs-tcl" \
                            -parameter "ReturnError" \
                            -default "/packages/acs-tcl/lib/ad-return-error"]
    set page [ad_parse_template -params [list [list title $title] [list explanation $explanation]] $error_template]
    if {$status > 399
        && [string match {*; MSIE *} [ns_set iget [ad_conn headers] User-Agent]]
        && [string length $page] < 512 } {
        append page [string repeat " " [expr {513 - [string length $page]}]]
    }

    ns_return $status text/html $page

    # raise abortion flag, e.g., for templating
    set ::request_aborted [list $status $title]
}


ad_proc ad_return_error {
    title
    explanation
} {
    Returns a page with the HTTP 500 (Error) code,
    along with the given title and explanation.  Should be used
    when an unexpected error is detected while processing a page.
} {
    ad_return_exception_page 500 $title $explanation
}

ad_proc ad_return_warning {
    title
    explanation
} {
    Returns a page with the HTTP 200 (Success) code, along with
    the given title and explanation.  Should be used when an
    exceptional condition arises while processing a page which
    the user should be warned about, but which does not qualify
    as an error.
} {
    ad_return_exception_page 200 $title $explanation
}

ad_proc ad_return_forbidden {
    {title ""}
    {explanation ""}
} {
    Returns a page with the HTTP 403 (Forbidden) code, along with
    the given title and explanation.  Should be used by
    access-control filters that determine whether a user has
    permission to request a particular page.

    Title and explanation are optional. If 'title' is not specified,
    then a default localized system message will be displayed. If
    'explanation' is not specified, it will default to the title.
} {
    if { $title eq "" } {
        set title [_ acs-subsite.403_message]
    }
    if { $explanation eq "" } {
        set explanation $title
    }
    ad_return_exception_page 403 $title $explanation
}

ad_proc ad_return_if_another_copy_is_running {
    {max_simultaneous_copies 1}
    {call_adp_break_p 0}
} {
    Returns a page to the user about how this server is busy if
    another copy of the same script is running.  Then terminates
    execution of the thread.  Useful for expensive pages that do
    sequential searches through database tables, etc.  You don't
    want to tie up all of your database handles and deny service
    to everyone else.

    The call_adp_break_p argument is essential
    if you are calling this from an ADP page and want to avoid the
    performance hit of continuing to parse and run.

    This proc is dangerous, and needs to be rewritten. See:
    http://openacs.org/forums/message-view?message_id=203381
} {
    # first let's figure out how many are running and queued
    set this_connection_url [ad_conn url]
    set n_matches 0
    foreach connection [ns_server active] {
        set query_connection_url [lindex $connection 4]
        if { $query_connection_url == $this_connection_url } {
            # we got a match (we'll always get at least one
            # since we should match ourselves)
            incr n_matches
        }
    }
    if { $n_matches > $max_simultaneous_copies } {
        ad_return_warning "Too many copies" "This is an expensive page for our server, which is already running the same program on behalf of some other users.  Please try again at a less busy hour."
        # blow out of the caller as well
        if {$call_adp_break_p} {
            # we were called from an ADP page; we have to abort processing
            ns_adp_break
        }
        return -code return
    }
    # we're okay
    return 1
}

ad_proc ad_pretty_mailing_address_from_args {
    line1
    line2
    city
    state
    postal_code
    country_code
} {
    Returns a prettily formatted address with country name, given
    an address.

    @author Unknown
    @author Roberto Mello
} {
    set lines [list]
    if { $line2 eq "" } {
        lappend lines $line1
    } elseif { $line1 eq "" } {
        lappend lines $line2
    } else {
        lappend lines $line1
        lappend lines $line2
    }
    lappend lines "$city, $state $postal_code"
    if { $country_code ne "" && $country_code ne "us" } {
        lappend lines [ad_country_name_from_country_code $country_code]
    }
    return [join $lines "\n"]
}


# for pages that have optional decoration

ad_proc ad_decorate_top {
    simple_headline
    potential_decoration
} {
    Use this for pages that might or might not have an image
    defined in ad.ini; if the second argument isn't the empty
    string, ad_decorate_top will make a one-row table for the
    top of the page
} {
    if { $potential_decoration eq "" } {
        return $simple_headline
    } else {
        return "<table cellspacing=10><tr><td>$potential_decoration<td>$simple_headline</tr></table>"
    }
}

ad_proc -private ad_requested_object_id {} {

    @return The requested object id, or if it is not available, the kernel id.

} {
    set package_id ""
    #  Use the object id stored in ad_conn.
    if { [ad_conn -connected_p] } {
        set package_id [ad_conn package_id]
    }

    if { $package_id eq "" } {
        if { [catch {
            set package_id [ad_acs_kernel_id]
        }] } {
            set package_id 0
        }
    }
    return $package_id
}

ad_proc -public ad_parameter_from_file {
    name
    {package_key ""}
} {
    This proc returns the value of a parameter that has been set in the
    parameters/ad.ini file.

    Note: <strong>The use of the parameters/ad.ini file is discouraged.</strong>  Some sites
    need it to provide instance-specific parameter values that are independent of the contents of the
    apm_parameter tables.

    @param name The name of the parameter.
    @return The parameter of the object or if it doesn't exist, the default.
} {

    # The below is really a hack because none of the calls to ad_parameter in the system
    # actually call 'ad_parameter param_name acs-kernel'.

    if { $package_key eq "" || $package_key eq "acs-kernel"} {
        return [ns_config "ns/server/[ns_info server]/acs" $name]
    }

    return [ns_config "ns/server/[ns_info server]/acs/$package_key" $name]
}


ad_proc -private ad_parameter_cache {
    -set
    -delete:boolean
    -global:boolean
    key
    parameter_name
} {

    Manages the cache for ad_parameter.
    @param set Use this flag to indicate a value to set in the cache.
    @param delete Delete the value from the cache
    @param global If true, global param, false, instance param
    @param key Specifies the key for the cache'd parameter, either the package instance
     id (instance parameter) or package key (global parameter).
    @param parameter_name Specifies the parameter name that is being cached.
    @return The cached value.

} {
    if {$delete_p} {
        if {[nsv_exists ad_param_$key $parameter_name]} {
            nsv_unset ad_param_$key $parameter_name
        }
        return
    }
    if {[info exists set]} {
        nsv_set "ad_param_${key}" $parameter_name $set
        return $set
    } elseif { [nsv_exists ad_param_$key $parameter_name] } {
        return [nsv_get ad_param_$key $parameter_name]
    } elseif { $global_p } {
        set value [db_string select_global_parameter_value {
            select apm_parameter_values.attr_value
            from   apm_parameters, apm_parameter_values
            where  apm_parameter_values.package_id is null
            and    apm_parameter_values.parameter_id = apm_parameters.parameter_id
            and    apm_parameters.parameter_name = :parameter_name
            and    apm_parameters.package_key = :key
        } -default ""]
    } else {
        set value [db_string select_instance_parameter_value {} -default ""]
    }
    nsv_set "ad_param_${key}" $parameter_name $value
    return $value
}

ad_proc -private ad_parameter_cache_all {} {
    Loads all package instance parameters into the proper nsv arrays
} {
    # Cache all parameters for enabled packages. .
    db_foreach parameters_get_all {
        select v.package_id, p.parameter_name, v.attr_value
        from apm_parameters p, apm_parameter_values v
        where p.parameter_id = v.parameter_id
    } {
        ad_parameter_cache -set $attr_value $package_id $parameter_name
    }
}

# returns particular parameter values as a Tcl list (i.e., it selects
# out those with a certain key)

ad_proc -public ad_parameter_all_values_as_list {
    {-package_id ""}
    name {subsection ""}
} {

    Returns multiple values for a parameter as a list.

} {
    return [join [parameter::get -package_id $package_id -parameter $name ] " "]
}

ad_proc doc_return {args} {

    A wrapper to be used instead of ns_return.  It calls
    <code>db_release_unused_handles</code> prior to calling ns_return.
    This should be used instead of <code>ns_return</code> at the bottom
    of every non-templated user-viewable page.

} {
    # AOLserver/NaviServer releases handles automatically since ages
    #db_release_unused_handles
    ad_http_cache_control
    ns_return {*}$args
}

ad_proc -public ad_return_url {
    -urlencode:boolean
    -qualified:boolean
    {extra_args {}}
} {

    Build a return url suitable for passing to a page you expect to return back
    to the current page.

    <p>

    Example for direct inclusion in a link:

    <pre>
    ad_returnredirect "foo?return_url=[ad_return_url -url_encode]"
    </pre>

    Example setting a variable to be used by export_vars:

    <pre>
    set return_url [ad_return_url]
    set edit_link [export_vars -base edit item_id return_url]
    </pre>

    Example setting a variable with extra_vars:

    <pre>
    set return_url [ad_return_url [list some_id $some_id] [some_other_id $some_other_id]]
    </pre>

    @author Don Baccus (dhogaza@pacifier.com)

    @param urlencode If true url-encode the result
    @param qualified If provided the return URL will be fully qualified including http or https.
    @param extra_args A list of {name value} lists to append to the query string

} {

    set query_list [export_entire_form_as_url_vars]

    foreach {extra_arg} $extra_args {
        lappend query_list [join $extra_arg "="]
    }

    if { [llength $query_list] == 0 } {
        set url [ns_conn url]
    } else {
        set url "[ns_conn url]?[join $query_list &]"
    }

    if { $qualified_p } {
        # Make the return_url fully qualified
        set url [security::get_qualified_url $url]
    }

    if { $urlencode_p } {
        set url [ns_urlencode $url]
    }
    return $url
}

ad_proc -public ad_progress_bar_begin {
    {-title:required}
    {-message_1 ""}
    {-message_2 ""}
    {-template "/packages/acs-tcl/lib/progress-bar"}
} {
    Return a progress bar.

    <p>Example:

    <pre>ad_progress_bar_begin -title "Installing..." -message_1 "Please wait..." -message_2 "Will continue automatically"</pre>

    <pre>...</pre>

    <pre>ad_progress_bar_end -url $next_page</pre>

    @param title     The title of the page
    @param message_1 Message to display above the progress bar.
    @param message_2 Message to display below the progress bar.
    @param template  Name of template to use. Default value is recommended.

    @see ad_progress_bar_end
} {
    db_release_unused_handles
    ad_http_cache_control

    ReturnHeaders
    ns_write [ad_parse_template \
                  -params [list \
                               [list doc(title) $title] \
                               [list title $title] \
                               [list message_1 $message_1] \
                               [list message_2 $message_2]] \
                  $template]
}

ad_proc -public ad_progress_bar_end {
    {-url:required}
    {-message_after_redirect ""}
} {
    Ends the progress bar by causing the browser to redirect to a new URL.

    @see ad_progress_bar_begin
} {
    util_user_message -message $message_after_redirect
    ns_write "<script type='text/javascript' nonce='$::__csp_nonce'>window.location='$url';</script>"
    ns_conn close
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
