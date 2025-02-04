ad_library {
    ACS-specific general utility routines.

    @author Philip Greenspun (philg@arsdigita.com)

    @author Many others at ArsDigita and in the OpenACS community.
    @creation-date 2 April 1998
    @cvs-id $Id$
}

ad_proc -public ad_acs_version {} {
    The OpenACS version of this instance. Uses the version name
    of the acs-kernel package.

    @author Peter Marklund
} {
    return [acs::per_thread_cache eval -key acs-tcl.acs_version {
        apm_version_get -package_key acs-kernel -array kernel
        set kernel(version_name)
    }]
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
    return [parameter::get -package_id $::acs::kernel_id -parameter HostAdministrator]
}

ad_proc -public ad_outgoing_sender {} {
    @return The email address that will sign outgoing alerts
} {
    return [parameter::get -package_id $::acs::kernel_id -parameter OutgoingSender]
}

ad_proc -public ad_system_name {} {
    This is the main name of the Web service that you're offering
    on top of the OpenACS Web Publishing System.
} {
    return [parameter::get -package_id $::acs::kernel_id -parameter SystemName]
}


ad_proc -public ad_pvt_home {} {
    This is the URL of a user's private workspace on the system, usually
    [subsite]/pvt/home.tcl
} {
    return "[subsite::get_element -element url -notrailing][parameter::get -package_id $::acs::kernel_id -parameter HomeURL]"
}

ad_proc -public ad_admin_home {} {
    Returns the directory for the admin home.
} {
    return "[subsite::get_element -element url]admin"
}

ad_proc -deprecated ad_package_admin_home { package_key } {
    @return directory for the especified package's admin home.

    # is this accurate? (rbm, aug 2002)

    DEPRECATED: a package URL may not have anything to do with the
                package key. Furthermore, the admin pages are normally located in
                "-package-/admin" and not in "/admin/-package-".
                One is better off generating package URLs by way of the site_nodes.

    @see site_node::get_url
    @see site_node::get_from_object_id
} {
    return "[ad_admin_home]/$package_key"
}

ad_proc -public ad_pvt_home_name {} {
    This is the name that will be used for the user's workspace (usually "Your Workspace").
    @return the name especified for the user's workspace in the HomeName kernel parameter.
} {
    return [lang::util::localize [parameter::get -package_id $::acs::kernel_id -parameter HomeName]]
}

ad_proc -public ad_pvt_home_link {} {
    @return the HTML fragment for the /pvt link
} {
    return "<a href='[ad_pvt_home]'>[ad_pvt_home_name]</a>"
}

ad_proc -public ad_site_home_link {} {
    @return a link to the user's workspace if the user is logged in. Otherwise, a link to the page root.
} {
    if { [ad_conn user_id] != 0 } {
        return "<a href='[ad_pvt_home]'>[subsite::get_element -element name]</a>"
    } else {
        # we don't know who this person is
        return "<a href='[subsite::get_element -element url]'>[subsite::get_element -element name]</a>"
    }
}

ad_proc -public ad_system_owner {} {
    Person who owns the service
    this person would be interested in user feedback, etc.
} {
    return [parameter::get -package_id $::acs::kernel_id -parameter SystemOwner]
}


ad_proc -public ad_publisher_name {} {
    A human-readable name of the publisher, suitable for
    legal blather.
} {
    return [parameter::get -package_id $::acs::kernel_id -parameter PublisherName]
}

ad_proc -public ad_url {} {
    This will be called by email alerts. Do not use ad_conn location
    @return the system url as defined in the kernel parameter SystemURL.
    @see util::configured_location
    @see util_current_location
} {
    return [parameter::get -package_id $::acs::kernel_id -parameter SystemURL]
}

ad_proc -public acs_community_member_page {} {
    @return the URL for the community member page
} {
    set url [parameter::get \
                 -package_id $::acs::kernel_id \
                 -parameter CommunityMemberURL]
    return "[subsite::get_element -element url -notrailing]$url"
}

ad_proc -public acs_community_member_url {
    {-user_id:required}
} {
    @return the URL for the community member page of a particular user
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
        set user [acs_user::get -user_id $user_id]
        set label "[dict get $user first_names] [dict get $user last_name]"
    }
    set href [acs_community_member_url -user_id $user_id]
    return [subst {<a href="[ns_quotehtml $href]">$label</a>}]
}

ad_proc -public acs_community_member_admin_url {
    {-user_id:required}
} {
    @return the URL for the community member admin page of a particular user
} {
    set url [parameter::get \
                 -package_id $::acs::kernel_id \
                 -parameter CommunityMemberAdminURL]
    return [export_vars -base $url { user_id }]
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
    try {
        set html [ad_parse_template \
                      -params [list [list exception_count $exception_count] \
                                   [list exception_text $exception_text]] \
                      $complaint_template]
    } on error {} {
        set html [lang::util::localize $exception_text]
    }

    ns_return 422 text/html $html

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
    set page [ad_parse_template \
                  -params [list [list title $title] [list explanation $explanation]] \
                  $error_template]
    if {$status >= 400
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
    if {[ns_conn isconnected]} {
        ad_return_exception_page 500 $title $explanation
    } else {
        ns_log error "ad_return_error called without a connection: $title\n$explanation"
    }
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
} {
    # Note: on AOLServer, ns_server was seemingly dangerous. This
    # should not affect NaviServer though, see
    # http://openacs.org/forums/message-view?message_id=203381

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
        ad_return_warning "Too many copies" \
            "This is an expensive page for our server, which is already running the same program on behalf of some other users.  Please try again at a less busy hour."
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

ad_proc -deprecated ad_decorate_top {
    simple_headline
    potential_decoration
} {
    Use this for pages that might or might not have an image
    defined in ad.ini; if the second argument isn't the empty
    string, ad_decorate_top will make a one-row table for the
    top of the page

    DEPRECATED: use the template system, e.g. master and slave tags to
                achieve better control of headers.

    @see /doc/acs-templating/tagref/master
    @see /doc/acs-templating/tagref/slave
    @see /doc/acs-templating/tagref/include
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
        set package_id $::acs::kernel_id
    }
    return $package_id
}

ad_proc -public ad_parameter_from_configuration_file {
    name
    {package_key ""}
} {
    Return the value of a parameter that has been set in the
    configuration file. It is possible to set

    Example snippets of the configuration file:
    <pre>
       ns_section ns/server/$server/acs {
           ns_param CSPEnabledP 1
           ns_param PasswordHashAlgorithm "argon2-12288-3-1 scram-sha-256  salted-sha1"
       }
       ns_section ns/server/$server/acs/acs-templating {
           ns_param UseHtmlAreaForRichtextP 2
       }
       ns_section ns/server/$server/acs/xowiki {
           ns_param MenuBar 1
       }
    </pre>
    Note that kernel parameters have no package key included in the
    section name of the configuration file (see above).

    @param name The name of the parameter.
    @param package_key package key of the package from
           which the parameter value is to be retrieved. When the
           package_key is omitted, the kernel parameters are assumed
    @return The parameter of the object or if it doesn't exist, the default.
} {

    # The below is really a hack because none of the calls to ad_parameter in the system
    # actually call 'ad_parameter param_name acs-kernel'.

    if { $package_key eq "" || $package_key eq "acs-kernel"} {
        return [ns_config "ns/server/[ns_info server]/acs" $name]
    }

    return [ns_config "ns/server/[ns_info server]/acs/$package_key" $name]
}

ad_proc -public -deprecated ad_parameter_from_file {
    name
    {package_key ""}
} {
    Old version of ad_parameter_from_configuration_file

    @see ad_parameter_from_configuration_file
} {
    return [ad_parameter_from_configuration_file $name $package_key]
}



#
# There are three implementation of "ad_parameter_cache":
# 1) for cachingmode none
# 2) via "nsv_dict" (cluster aware)
# 3) via "nsv" (not cluster aware)

if {[ns_config "ns/parameters" cachingmode "per-node"] eq "none"} {
    #
    # If caching mode is "none", the "ad_parameter_cache" is
    # essentially a no-op stub, but it is used for interface
    # compatibility.
    #
    # TODO: One should essentially define more more cachetype for
    # nsv_caching in acs-cache-procs to reduce redundancy and for
    # providing higher orthogonality.
    #
    ad_proc -public ad_parameter_cache {
        -set
        -delete:boolean
        -global:boolean
        key
        parameter_name
    } {

        Stub for a parameter cache, since "cachingmode" is "none".

        @param set Use this flag to indicate a value to set in the cache.
        @param delete Delete the value from the cache
        @param global If true, global param, false, instance param
        @param key Specifies the key for the cache'd parameter, either the package instance
        id (instance parameter) or package key (global parameter).
        @param parameter_name Specifies the parameter name that is being cached.
        @return The cached value.

    } {
        if {$delete_p} {
            return
        }
        if {[info exists set]} {
            return $set
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
            set value [db_string select_instance_parameter_value {
                select apm_parameter_values.attr_value
                from   apm_parameters, apm_parameter_values
                where  apm_parameter_values.package_id = :key
                and    apm_parameter_values.parameter_id = apm_parameters.parameter_id
                and    apm_parameters.parameter_name = :parameter_name
            } -default ""]
        }
        return $value
    }

} elseif {[::acs::icanuse "nsv_dict"]} {

    if {![nsv_array exists ad_param]} {
        nsv_set ad_param . .
    }

    ad_proc -private ad_parameter_cache_flush_dict {
        key
        parameter_name
    } {
        Flush a single value from the nsv cache.

        This proc is necessary in cases, where a node writes a new
        parameter value before it has read the old one.

        Since a plain "nsv_dict unset ad_param $key $parameter_name"
        raises an exception, when the pair does not exist, and we do
        not want to allow in cluster requests arbitrary "catch"
        commands, we allow "ad_parameter_cache_flush_dict" instead.
        Probably, the best solution is to add support for

            nsv_dict unset -nocomplain -- ad_param $key $parameter_nam

        The existing nsv_dict was built after Tcl's "dict unset",
        which does not have the "-nocomplain" option either. However,
        an atomic operation would certainly be preferable over an exists/unset
        pair, which is no acceptable solution.

    } {
        catch {nsv_dict unset ad_param $key $parameter_name}
    }


    ad_proc -public ad_parameter_cache {
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
            acs::clusterwide ad_parameter_cache_flush_dict $key $parameter_name
            acs::per_request_cache flush -pattern acs-tcl.ad_param-$key
            return
        }
        if {[info exists set]} {
            nsv_dict set ad_param $key $parameter_name $set
            acs::per_request_cache flush -pattern acs-tcl.ad_param-$key
            return $set
        }
        #
        # Keep the parameter dict in a per-request cache to reduce
        # potentially high number of nsv locks, when parameters of a
        # package are queried a high number of times per request
        # (without this we see on some sites > 100 locks on this nsv
        # per request).
        #
        set dict [acs::per_request_cache eval -no_cache "" -key acs-tcl.ad_param-$key {
            if {[nsv_get ad_param $key result]} {
                #ns_log notice "ad_parameter_cache $key $parameter_name not cached"
                set result
            } else {
                set result ""
            }
        }]
        if {[dict exists $dict $parameter_name]} {
            #ns_log notice "ad_parameter_cache $key $parameter_name get from dict"
            return [dict get $dict $parameter_name]
        }
        if { $global_p } {
            set value [db_string select_global_parameter_value {
                select apm_parameter_values.attr_value
                from   apm_parameters, apm_parameter_values
                where  apm_parameter_values.package_id is null
                and    apm_parameter_values.parameter_id = apm_parameters.parameter_id
                and    apm_parameters.parameter_name = :parameter_name
                and    apm_parameters.package_key = :key
            } -default ""]
        } else {
            set value [db_string select_instance_parameter_value {
                select apm_parameter_values.attr_value
                from   apm_parameters, apm_parameter_values
                where  apm_parameter_values.package_id = :key
                and    apm_parameter_values.parameter_id = apm_parameters.parameter_id
                and    apm_parameters.parameter_name = :parameter_name
            } -default ""]
        }
        nsv_dict set ad_param $key $parameter_name $value
        return $value
    }
} else {
    ad_proc -public ad_parameter_cache {
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
            set value [db_string select_instance_parameter_value {
                select apm_parameter_values.attr_value
                from   apm_parameters, apm_parameter_values
                where  apm_parameter_values.package_id = :key
                and    apm_parameter_values.parameter_id = apm_parameters.parameter_id
                and    apm_parameters.parameter_name = :parameter_name
            } -default ""]
        }
        nsv_set "ad_param_${key}" $parameter_name $value
        return $value
    }
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

ad_proc -deprecated ad_parameter_all_values_as_list {
    {-package_id ""}
    name {subsection ""}
} {

    Returns multiple values for a parameter as a list.

    DEPRECATED: this proc does not do much that joining a string
    coming from a parameter, which does not make an invalid string
    into a list. Best to take the value from the parameter directly
    and rely on proper quoting by the user. Furthermore, the
    'subsection' argument is not used anywhere.

    @see parameter::get
    @see join

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
    {-path_encode:boolean true}
    {-qualified:boolean}
    {-exclude ""}
    {-formvars}
    {-default_url .}
    {extra_args ""}
} {

    Build a return url suitable for passing to a page you expect to return back
    to the current page. Per default, the result is URL-encoded
    (like the result of "export_vars" or ":pretty_link").

    <p>

    Example for direct inclusion in a link:

    <pre>
    ad_returnredirect "foo?return_url=[ad_return_url]"
    </pre>

    Example setting a variable to be used by export_vars:

    <pre>
    set return_url [ad_return_url]
    set edit_link [export_vars -base edit item_id return_url]
    </pre>

    Example setting a variable with extra_vars:

    <pre>
    set return_url [ad_return_url [list [list some_id $some_id] [list some_other_id $some_other_id]]]
    </pre>

    @author Don Baccus (dhogaza@pacifier.com)

    @param path_encode If false do no URL-encode the result
    @param default_url When there is no connection, fall back to this URL
    @param qualified If provided the return URL will be fully qualified including http or https.
    @param exclude list of form variables to be excluded in the result (negative selection)
    @param formvars A list of query/form variables potentially included in the returnurl.
           Per default, all form vars are exported. By providing this positive
           selection, only these will be used. If you specify this empty, no variables are included.
    @param extra_args A list of {name value} lists to append to the query string

} {

    if { $urlencode_p } {
        ns_log warning "deprecated flag -urlencode; result is encoded per default"
    }

    if {[ns_conn isconnected]} {
        if {[info exists formvars]} {
            set query_list [export_vars -formvars $formvars]
        } else {
            set query_list [export_vars -exclude $exclude -entire_form]
        }
        set base_url [ns_conn url]
    } else {
        set query_list ""
        set base_url $default_url
    }

    if { $path_encode_p } {
        set base_url [ns_urlencode $base_url]
    }

    if { [llength $query_list] == 0 } {
        set url $base_url
    } else {
        set url "${base_url}?[join $query_list &]"
    }

    if {[llength $extra_args] > 0} {
        #
        # Deactivate base encode, since the input URL is already
        # encoded as requested.
        #
        set url [export_vars -base $url -no_base_encode $extra_args]
    }

    if { $qualified_p } {
        # Make the return_url fully qualified
        set url [security::get_qualified_url $url]
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

    util_return_headers
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

    @param url must be a properly encoded URL, such as returned by "export_vars"

    @see ad_progress_bar_begin
} {
    util_user_message -message $message_after_redirect
    #
    # Using "ns_quotehtml" on the URL leads to overquoting, e.g., when running the
    # the end of install-from-repository.
    #
    ns_write "<script type='text/javascript' nonce='[security::csp::nonce]'>window.location='$url';</script>"
    ns_conn close
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
