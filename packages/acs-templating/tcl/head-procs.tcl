ad_library {

    The template::head::* API manipulates the head section of the document that
    will be returned to the users client.  Packages should use this API to add
    package specific javascripts, CSS, link tags and meta tags to the HTML
    document.

    @author Lee Denison (lee@xarg.co.uk)
    @creation-date 2007-05-18

}

namespace eval template {}
namespace eval template::head {}

ad_proc -private template::reset_request_vars {} {
    Resets all global data structures used to manage the head section of the
    returned document.  This should be called at the beginning of any request
    handled by the templating system.
} {
    array unset ::template::head::scripts
    array unset ::template::head::links
    array unset ::template::head::metas
    array unset ::template::body_handlers
    array unset ::template::body_scripts

    set ::template::headers [list]
    set ::template::footers [list]
}

ad_proc -public template::register_urn {
    -urn:required
    -resource:required
} {

    Register a URN for a resource. These URNs provide a single place
    for e.g updating references to external resources when switching
    between a CDN and a local resource, or when a resource should be
    updated.

    We could consider a dns-prefetch for CDN requests. When the
    url-check is performed at register time, the performance for
    processing the url can be neglected.

} {
    set key ::template::head::urn($urn)
    if {[info exists $key]} {
        set old_resource [set $key]
        #
        # Prefer local URNs over non-local ones
        #
        if {[string match //* $old_resource] || [string match http* $old_resource]} {
            ns_log notice "overwrite URN: $urn <$old_resource> with <$resource>"
            set $key $resource
        } else {
            ns_log notice "keep old URN: $urn <$old_resource> instead of <$resource>"
        }
    } else {
        set $key $resource
        ns_log notice "add URN: $urn <$resource>"
    }
}


ad_proc -public template::add_script {
    {-async:boolean}
    {-charset ""}
    {-crossorigin ""}
    {-defer:boolean}
    {-integrity ""}
    {-order "0"}
    {-script ""}
    {-section "head"}
    {-src ""}
    {-type "text/javascript"}
} {
    @param async   whether execution of the script should be executed asynchronously
                   as soon as it is available
    @param charset the charset attribute of the script tag, i.e. the character
                   set of the script if it differs from the main document
    @param crossorigin  Enumerated attribute to indicate whether CORS
                   (Cross-Origin Resource Sharing) should be used
    @param defer   whether execution of the script should be deferred until after
                   the page has been loaded
    @param integrity provide hash values for W3C Subresource Integrity recommendation
    @param order   specify inclusion order
    @param script  the inline script for the body of the script tag.  This
                   parameter will be ignored if a value has been supplied for src
    @param section section, where script is added ("head" or "body")
    @param src     the src attribute of the script tag, i.e. the source url of the
                   script
    @param type    the type attribute of the script tag, e.g. 'text/javascript'
} {

    if {$section eq "head"} {
        #
        # A head script
        #
        ::template::head::add_script -type $type -defer=$defer_p -async=$async_p \
            -src $src -charset $charset -script $script -order $order \
            -crossorigin $crossorigin -integrity $integrity
    } else {
        #
        # A body script. The order is ignored.
        #
        ::template::add_body_script -type $type -defer=$defer_p -async=$async_p \
            -src $src -charset $charset -script $script \
            -crossorigin $crossorigin -integrity $integrity
    }
}

ad_proc -public template::head::add_script {
    {-async:boolean}
    {-charset ""}
    {-crossorigin ""}
    {-defer:boolean}
    {-integrity ""}
    {-order "0"}
    {-script ""}
    {-src ""}
    {-type "text/javascript"}
} {
    Add a script to the head section of the document to be returned to the
    users client.  A script library in an external file may only be included
    once; subsequent calls to add_script will replace the existing entry.
    Anonymous script blocks will be added without checking for duplicates; the
    caller must ensure that anonymous script blocks are not inadvertently added
    multiple times.  You <strong>must</strong> supply either src or script.

    @param async   whether execution of the script should be executed asynchronously
                   as soon as it is available
    @param charset the charset attribute of the script tag, i.e. the character
                   set of the script if it differs from the main document
    @param crossorigin  Enumerated attribute to indicate whether CORS
                   (Cross-Origin Resource Sharing) should be used
    @param defer   whether execution of the script should be deferred until after
                   the page has been loaded
    @param integrity provide hash values for W3C Subresource Integrity recommendation
    @param order   specify inclusion order
    @param script  the inline script for the body of the script tag.  This
                   parameter will be ignored if a value has been supplied for src
    @param src     the src attribute of the script tag, i.e. the source url of the
                   script
    @param type    the type attribute of the script tag, e.g. 'text/javascript'

} {
    if {$defer_p} {
        set defer defer
    } else {
        set defer ""
    }

    if {$async_p} {
        set async async
    } else {
        set async ""
    }

    #
    # Replace potential URN in src with resolved value
    #
    set key ::template::head::urn($src)
    if {[info exists $key]} {
        set src [set $key]
    } elseif {[string match urn:* $src]} {
        ns_log error "URN <$src> could not be resolved"
    }

    if {$src eq ""} {
        if {$script eq ""} {
            error "You must supply either -src or -script."
        }

        #
        # For the time being, not all browsers support
        # nonces. According to the specs the added 'unsafe-inline',
        # is ignored on browsers supporting nonces.
        #
        # We could restrict setting of unsafe-inline to certain
        # browsers by checking the user agent.
        #
        security::csp::require script-src 'unsafe-inline'
        #security::csp::require script-src 'strict-dynamic'

        lappend ::template::head::scripts(anonymous) $type "" $charset $defer $async $script $order $crossorigin $integrity
    } else {
        set ::template::head::scripts($src) [list $type $src $charset $defer $async "" $order $crossorigin $integrity]
    }
}

ad_proc -public template::head::flush_script {
    {-src:required}
} {

    Flush a script tag, which was previously set in the head section
    via template::add_script.  One can delete multiple entries by
    providing a glob pattern.

    @author Gustaf Neumann
    @creation-date 2018-03-09

    @param src     src attribute of the script tag, i.e. the source url of the
                   script. A glob pattern similar link in "string match" can be provided.
    @see ::template::head::add_script
} {
    array unset ::template::head::scripts $src
    flush_included $src
}


ad_proc -public template::head::add_link {
    {-crossorigin ""}
    {-href:required}
    {-integrity ""}
    {-lang ""}
    {-media ""}
    {-order "0"}
    {-rel:required}
    {-title ""}
    {-type ""}
} {
    Add a link tag to the head section of the document to be returned to the
    users client.  A given target document may only be added once for a
    specified relation; subsequent calls to add_link will replace the existing
    entry.

    @param crossorigin  Enumerated attribute to indicate whether CORS
                   (Cross-Origin Resource Sharing) should be used
    @param href    the href attribute of the link tag, e.g. the target document
                   of the link
    @param integrity provide hash values for W3C Subresource Integrity recommendation
    @param lang    the lang attribute of the link tag specifying the language
                   of its attributes if they differ from the document language
    @param media   the media attribute of the link tag describing which display
                   media this link is relevant to.  This may be a comma
    @param order   specify inclusion order
    @param rel     the rel attribute of the link tag defining the relationship
                   of the linked document to the current one, e.g. 'stylesheet'
    @param title   the title attribute of the link tag describing the target of
                   this link
    @param type    the type attribute of the link tag, e.g. 'text/css'
                   separated list of values, e.g. 'screen,print,braille'

    @see ::template::head::flush_link
} {
    set ::template::head::links($rel,$href) [list $rel $href $type $media $title $lang $order $crossorigin $integrity]
}

ad_proc -public template::head::flush_link {
    {-href:required}
    {-rel:required}
} {
    Flush a link tag, which was previously set in the head section via template::head::add_link

    @author Gustaf Neumann
    @creation-date 2018-03-09

    @param href    the href attribute of the link tag, e.g. the target document
                   of the link. A glob pattern similar link in "string match"
                   can be provided.

    @param rel     the rel attribute of the link tag defining the relationship
                   of the linked document to the current one, e.g. 'stylesheet'
    @see ::template::head::add_link
} {
    array unset ::template::head::links $rel,$href
    flush_included $href
}

ad_proc -public template::head::includes {
    {-container:required}
    {-parts:required}
} {

    Define, that a compound resource (container) contains multiple
    parts.  Container and parts are typically URLs, which are referred
    to by a "href" attribute or by link or a "src" attribute of a
    script.

    @author Gustaf Neumann
    @creation-date 2018-03-09

    @param container compound resource
    @param parts     list of resources, which are included in a compound resource (container).

    @see ::template::head::add_link
    @see ::template::head::add_script
    @see ::template::head::included_p
} {
    set ::template::head::includes($container) $parts
    foreach p $parts {
        set ::template::head::included($p) $container
    }
}

ad_proc -private template::head::included_p {
    resource
} {

    Check, if the provided resource is included by some other resource.

    @author Gustaf Neumann
    @creation-date 2018-03-09

    @param resource uri resource
    @see ::template::head::includes
} {
    return [info exists ::template::head::included($resource)]
}

ad_proc -private template::head::flush_included {
    resource
} {
    Flush a part relations ships of a compound resource

    @author Gustaf Neumann
    @creation-date 2018-03-09

    @param resource compound resource
    @see ::template::head::add_link
} {
    #ns_log notice "flush_included <$resource> includes: [array get ::template::head::includes $resource]"
    foreach {container parts} [array get ::template::head::includes $resource] {
        unset ::template::head::includes($container)
        foreach p $parts {
            unset ::template::head::included($p)
        }
    }
}



ad_proc -public template::head::add_meta {
    {-http_equiv ""}
    {-name ""}
    {-scheme ""}
    {-content ""}
    {-lang ""}
} {
    Add a meta tag to the head section of the document to be returned to the
    users client.  A meta tag with a given name or http-equiv may only be added
    once; subsequent calls to add_meta will replace the existing entry.  You
    <strong>must</strong> supply either name or http_equiv.

    @param http_equiv the http-equiv attribute of the meta tag, i.e. the
                      HTTP header which this metadata is equivalent to
                      e.g. 'content-type'
    @param name       the name attribute of the meta tag, i.e. the metadata
                      identifier
    @param scheme     the scheme attribute of the meta tag defining which
                      metadata scheme should be used to interpret the metadata,
                      e.g. 'DC' for Dublin Core (http://dublincore.org/)
    @param content    the content attribute of the meta tag, ie the metadata
                      value
    @param lang       the lang attribute of the meta tag specifying the language
                      of its attributes if they differ from the document language
} {
    variable ::template::head::metas

    if {$http_equiv eq "" && $name eq ""} {
        error "You must supply either -http_equiv or -name."
    }

    set metas($http_equiv,$name) [list \
        $http_equiv \
        $name \
        $scheme \
        $content \
        $lang \
    ]
}

ad_proc -public template::head::add_style {
    {-style:required}
    {-title ""}
    {-lang ""}
    {-media ""}
    {-type "text/css"}
} {

    Add an embedded css style declaration

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2007-11-30

    @param style CSS content to be included in the style tag
    @param type    the type attribute of the link tag, e.g. 'text/css'
    @param media   the media attribute of the link tag describing which display
                   media this link is relevant to.  This may be a comma
                   separated list of values, e.g. 'screen,print,braille'
    @param title   the title attribute of the link tag describing the target of
                   this link
    @param lang    the lang attribute of the link tag specifying the language
                   of its attributes if they differ from the document language
} {
    variable ::template::head::styles

    if {[info exists styles(anonymous)]} {
        #
        # Add this combination only once
        #
        foreach {_type _media _title _lang _style} $styles(anonymous) {
            if {$type eq $_type
                && $_media eq $media
                && $_title eq $title
                && $_lang  eq $lang
                && $_style eq $style
            } {
                return
            }
        }
    }
    lappend styles(anonymous) $type $media $title $lang $style
}

ad_proc -public template::head::add_javascript {
    {-async:boolean}
    {-charset ""}
    {-crossorigin ""}
    {-defer:boolean}
    {-integrity ""}
    {-order "0"}
    {-script ""}
    {-src ""}
} {
    Add a script of type 'text/javascript' to the head section of the document
    to be returned to the users client.  This function is a wrapper around
    template::head::add_script.  You must supply either src or script.

    @param async   whether execution of the script should be executed asynchronously
                   as soon as it is available
    @param charset the charset attribute of the script tag, i.e. the character
                   set of the script if it differs from the main document
    @param crossorigin  Enumerated attribute to indicate whether CORS
                   (Cross-Origin Resource Sharing) should be used
    @param defer   whether execution of the script should be deferred until after
                   the page has been loaded
    @param integrity provide hash values for W3C Subresource Integrity recommendation
    @param order   specify inclusion order
    @param script  the inline script for the body of the script tag.  This
                   parameter will be ignored if a value has been supplied for
                   src
    @param src     the src attribute of the script tag, i.e. the source url of the
                   script

    @see template::head::add_script
} {
    template::head::add_script \
        -defer=$defer_p -async=$async_p \
        -type text/javascript \
        -src $src \
        -charset $charset \
        -script $script \
        -order $order \
        -crossorigin $crossorigin -integrity $integrity
}

ad_proc -public template::head::add_css {
    {-alternate:boolean}
    {-href:required}
    {-media "all"}
    {-title ""}
    {-lang ""}
    {-order "0"}
} {
    Add a link tag with relation type 'stylesheet' or 'alternate stylesheet',
    and type 'text/css' to the head section of the document to be returned to
    the users client.  A given target stylesheet may only be added once;
    subsequent calls to add_css will replace the existing entry.  This function
    is a wrapper around template::head::add_link.

    @param href      the href attribute of the link tag, e.g. the target
                     stylesheet
    @param alternate sets the rel attribute of the link tag defining to
                     'alternate stylesheet' if set, sets it to 'stylesheet'
                     otherwise
    @param media     the media attribute of the link tag describing which
                     display media this link is relevant to.  This may be a
                     comma separated list of values, e.g. 'screen,print,braille'
    @param title     the title attribute of the link tag describing the target
                     of this link
    @param lang      the lang attribute of the link tag specifying the language
                     of its attributes if they differ from the document language

    @see template::head::add_link
} {
    if {$alternate_p} {
        set rel "alternate stylesheet"
    } else {
        set rel "stylesheet"
    }

    template::head::add_link -rel $rel \
        -type text/css \
        -href $href \
        -media $media \
        -title $title \
        -lang $lang \
        -order $order
}

ad_proc -public template::add_body_handler {
    {-event:required}
    {-script:required}
    {-identifier anonymous}
} {
    Adds JavaScript code to an event handler in the body tag.  Several
    JavaScript code blocks may be assigned to each handler by subsequent calls
    to template::add_body_handler.

    <p>If your script may only be added once you may supply an identifier.
    Subsequent calls to template::add_body_handler with the same identifier
    will replace your script rather than appending to it.</p>

    <p><code>event</code> may be one of:</p>
    <ul>
      <li>onload</li>
      <li>onunload</li>
      <li>onclick</li>
      <li>ondblclick</li>
      <li>onmousedown</li>
      <li>onmouseup</li>
      <li>onmouseover</li>
      <li>onmousemove</li>
      <li>onmouseout</li>
      <li>onkeypress</li>
      <li>onkeydown</li>
      <li>onkeyup</li>
    </ul>

    @param event      the event during which the supplied script should be
                      executed
    @param script     the JavaScript code to execute
    @param identifier a name, if supplied, used to ensure this JavaScript code
                      is only added to the handler once
} {
    variable ::template::body_handlers

    if {$identifier eq "anonymous"} {
        lappend body_handlers($event,anonymous) $script
    } else {
        # Even a one event handler needs to be added in a list
        # since all handlers, anonymous and specific are treated as a
        # list in blank-master.tcl
        set body_handlers($event,$identifier) [list $script]
    }
}

ad_proc -public template::add_body_script {
    {-async:boolean}
    {-charset ""}
    {-crossorigin ""}
    {-defer:boolean}
    {-integrity ""}
    {-script ""}
    {-src ""}
    {-type "text/javascript"}
} {
    Add a script to the start of the body section of the document to be returned
    to the users client. You <strong>must</strong> supply either src or script.

    @param async   whether execution of the script should be executed asynchronously
                   as soon as it is available
    @param charset the charset attribute of the script tag, i.e. the character
                   set of the script if it differs from the main document
    @param crossorigin  Enumerated attribute to indicate whether CORS
                   (Cross-Origin Resource Sharing) should be used
    @param defer   whether execution of the script should be deferred until after
                   the page has been loaded
    @param integrity provide hash values for W3C Subresource Integrity recommendation
    @param script  the inline script for the body of the script tag.  This
                   parameter will be ignored if a value has been supplied for
                   src
    @param src     the src attribute of the script tag, i.e. the source url of the
                   script
    @param type    the type attribute of the script tag, e.g. 'text/javascript'
} {

    if {$defer_p} {
        set defer defer
    } else {
        set defer ""
    }
    if {$async_p} {
        set async async
    } else {
        set async ""
    }

    if {$src eq "" && $script eq ""} {
        error "You must supply either -src or -script."
    }

    if {$script ne ""} {
        #
        # We have an inline script.
        #
        # For the time being, not all browsers support
        # nonces. According to the specs the added 'unsafe-inline',
        # is ignored on browsers supporting nonces.
        #
        # We could restrict setting of unsafe-inline to certain
        # browsers by checking the user agent.
        #
        security::csp::require script-src 'unsafe-inline'
    }

    lappend ::template::body_scripts $type $src $charset $defer $async $script $crossorigin $integrity
}


ad_proc -public template::add_header {
    {-direction "outer"}
    {-src ""}
    {-params ""}
    {-html ""}
} {
    Add a header include to the beginning of the document body.  This function
    is used by site wide services to add functionality to the beginning of a
    page.  Examples include the developer support toolbar, acs-lang translation
    interface and the acs-templating WYSIWYG editor textarea place holder.  If
    you are not implementing a site wide service, you should not be using this
    function to add content to your page.  You must supply either src or html.

    @param direction whether the header should be added as the outer most
                     page content or the inner most
    @param src       the path to the include
    @param params    a list of name, value pairs to pass as parameter to the
                     include
    @param html      literal html to include in the page.  This parameter will
                     be ignored if a values has been supplied for src.

    @see template::add_footer
} {
    variable ::template::headers

    if {$src eq ""} {
        if {$html eq ""} {
            error "You must supply either -src or -html."
        }
        set values [list literal $html ""]
    } else {
        set values [list include $src $params]
    }

    if {[info exists headers]} {
      switch -- $direction {
        outer {set headers [linsert $headers 0 $values]}
        inner {lappend headers $values}
        default {error "unknown direction $direction"}
      }
    } else {
      set headers [list $values]
    }
}

ad_proc -public template::add_footer {
    {-direction "outer"}
    {-src ""}
    {-params ""}
    {-html ""}
} {
    Add a footer include to the end of the document body.  This function
    is used by site wide services to add functionality to the end of a
    page.  Examples include the developer support toolbar, acs-lang translation
    interface and the acs-templating WYSIWYG editor textarea place holder.  If
    you are not implementing a site wide service, you should not be using this
    function to add content to your page.  You must supply either src or html.

    @param direction whether the footer should be added as the outer most
                     page content or the inner most
    @param src       the path to the include
    @param params    a list of name, value pairs to pass as parameter to the
                     include
    @param html      literal html to include in the page.  This parameter will
                     be ignored if a values has been supplied for src.

    @see template::add_footer
} {
    variable ::template::footers

    if {$src eq ""} {
        if {$html eq ""} {
            error "You must supply either -src or -html."
        }
        set values [list literal $html ""]
    } else {
        set values [list include $src $params]
    }

    if {[info exists footers]} {
      switch -- $direction {
        outer {lappend footers $values}
        inner {set footers [linsert $footers 0 $values]}
        default {error "unknown direction $direction"}
      }
    } else {
      set footers [list $values]
    }
}

ad_proc -private template::head::resolve_urn {
    resource
} {
    Replace potential URN in provided resource name with resolved
    value
} {
    set key ::template::head::urn($resource)
    if {[info exists $key]} {
        set resource [set $key]
    }
    return $resource
}

ad_proc template::head::prepare_multirows {} {
    Generate multirows for meta, css, scripts
    Called only from blank-master.tcl
} {

    # Generate the <meta> tag multirow
    variable ::template::head::metas
    template::multirow create meta name content http_equiv scheme lang
    if {[array exists metas]} {
        foreach name [array names metas] {
            foreach {http_equiv name scheme content lang} $metas($name) {
                template::multirow append meta \
                    $name \
                    $content \
                    $http_equiv \
                    $scheme \
                    $lang
            }
        }
        unset metas
    }

    # Generate the <link> tag multirow
    variable ::template::head::links

    #
    # Filter out included links, such we have to do this only once.
    #
    foreach name [array names links] {
        lassign [split $name ,] rel href
        if {[::template::head::included_p $href]} {
            template::head::flush_link -href $ref -rel $rel
        }
    }

    template::multirow create link rel type href title lang media order crossorigin integrity
    if {[array exists links]} {
        # first non alternate stylesheet
        foreach name [array names links] {
            foreach {rel href type media title lang order crossorigin integrity} $links($name) {
                if {$rel ne "alternate stylesheet"} {
                    template::multirow append link \
                        $rel \
                        $type \
                        [resolve_urn $href] \
                        $title \
                        $lang \
                        $media \
                        $order \
                        $crossorigin $integrity
                    set links($name) ""
                }
            }
        }
        # order the stylesheets before adding alternate ones
        template::multirow sort link order
        # now alternate stylesheet
        foreach name [array names links] {
            foreach {rel href type media title lang order crossorigin integrity} $links($name) {
                if {$links($name) ne ""} {
                    template::multirow append link \
                        $rel \
                        $type \
                        [resolve_urn $href] \
                        $title \
                        $lang \
                        $media \
                        $order \
                        $crossorigin $integrity
                    set links($name) ""
                }
            }
        }
        array unset links
    }

    # Generate the <style /> tag multirow
    variable ::template::head::styles
    template::multirow create ___style type title lang media style
    if {[array exists styles]} {
        foreach name [array names styles] {
            foreach {type media title lang style} $styles($name) {
                template::multirow append ___style \
                    $type \
                    $title \
                    $lang \
                    $media \
                    $style
            }
        }
        array unset styles
    }

    # Generate the head <script /> tag multirow
    variable ::template::head::scripts

    template::multirow create headscript type src charset defer async content order crossorigin integrity
    if {[array exists scripts]} {

        foreach name [array names scripts] {
            if {[::template::head::included_p $name]} {
                continue
            }

            foreach {type src charset defer async content order crossorigin integrity} $scripts($name) {
                #ns_log notice "ADD order $order src $src"
                template::multirow append headscript \
                    $type \
                    [resolve_urn $src] \
                    $charset \
                    $defer \
                    $async \
                    $content \
                    $order \
                    $crossorigin $integrity
            }
        }
        template::multirow sort headscript order
        array unset scripts
    }

    # Generate the body <script /> tag multirow
    variable ::template::body_scripts
    template::multirow create body_script type src charset defer async content crossorigin integrity
    if {[info exists body_scripts]} {
        foreach {type src charset defer async content crossorigin integrity} $body_scripts {
            template::multirow append body_script \
                $type \
                $src \
                $charset \
                $defer \
                $async \
                $content \
                $crossorigin $integrity
        }
        unset body_scripts
    }

}

ad_proc template::get_header_html {
} {
    Get headers as a chunk of html suitable for insertion into blank-master.adp
    Called only from blank-master.tcl
} {
    # Generate the body headers
    variable ::template::headers
    set header ""
    if {[info exists headers]} {
        foreach header_list $headers {
            lassign $header_list type src params
            if {$type eq "literal"} {
                append header $src
            } else {
                append header [template::adp_include $src $params]
            }
        }
        unset headers
    }
    return $header
}

ad_proc template::get_footer_html {
} {
    Get footers as a chunk of html suitable for insertion into blank-master.adp
    Called only from blank-master.tcl
} {
    # Generate the body footers
    variable ::template::footers
    set footer ""

    if {[info exists footers]} {
        foreach footer_list $footers {
            lassign $footer_list type src params
            if {$type eq "literal"} {
                append footer $src
            } else {
                set themed_template [template::themed_template $src]
                append footer [template::adp_include $themed_template $params]
            }
        }
        unset footers
    }
    return $footer
}

ad_proc template::get_body_event_handlers {
} {
    Get body event handlers specified with template::add_body_handler
} {
    #
    # Concatenate the JavaScript event handlers for the body tag
    #
    variable ::template::body_handlers
    set event_handlers ""

    if {[array exists body_handlers]} {

        #
        # Collect all entries for one event type (e.g. "onload")
        #
        foreach name [array names body_handlers] {
            set event [lindex [split $name ","] 0]
            foreach js $body_handlers($name) {
                lappend body_handlers($event) "[string trimright $js {; }];"
            }
            unset body_handlers($name)
        }

        #
        # Turn events into calls for event listener and add these via
        # add_body_script.
        #
        set js ""
        foreach {event script} [array get body_handlers] {
            #
            # Remove the "on" prefix if provided. E.g. "onload" is
            # mapped to the "load" event on "window" (UIevent). It
            # would as well be possible to map to DOM events (on
            # "document")
            # (https://developer.mozilla.org/en-US/docs/Web/Events)
            #
            regsub ^on $event "" event
            append js [subst {
                window.addEventListener('$event', function () {
                    [join $script { }]
                }, false);
            }]
        }
        if {$js ne ""} {
            template::add_body_script -script $js
        }

        unset body_handlers
    }

    return $event_handlers
}

ad_proc template::add_confirm_handler {
    {-event click}
    {-message "Are you sure?"}
    {-CSSclass "acs-confirm"}
    {-id}
    {-formfield}
} {
    Register an event handler for confirmation dialogs for elements
    either with a specified ID, CSS class, or for a formfield targeted
    by form id and field name.

    @param event     register confirm handler for this type of event
    @param id        register confirm handler for this HTML ID
    @param CSSclass  register confirm handler for this CSS class
    @param formfield register confirm handler for this formfield, specified
                     in a list of two elements in the form
                     <code>{ form_id field_name }</code>
    @param message  Message to be displayed in the confirmation dialog
    @author  Gustaf Neumann
} {
    set script [subst {
        if (!confirm('$message')) {
            event.preventDefault();
        }
    }]

    set cmd [list template::add_event_listener \
                 -event $event -script $script -preventdefault=false]

    if {[info exists id]} {
        lappend cmd -id $id
    } elseif {[info exists formfield]} {
        lappend cmd -formfield $formfield
    } else {
        lappend cmd -CSSclass $CSSclass
    }

    {*}$cmd
}

ad_proc template::add_refresh_on_history_handler {} {
    Register an event handler which will trigger a complete page
    refresh when we land on this page by accessing the browser's
    history (back and forward buttons).

    This is useful e.g. for those pages where some push interaction is
    happening and retrieving the page from the browser history would
    display it in an inconsistent state.
} {
    # courtesy of: vasleo@gmail.com from Stack Overflow
    template::add_body_script -script {
        window.addEventListener( "pageshow", function ( event ) {
            var historyTraversal = event.persisted ||
            ( typeof window.performance != "undefined" &&
              window.performance.navigation.type === 2 );
            if ( historyTraversal ) {
                window.location.reload();
            }
        });
    }
}

ad_proc template::add_event_listener {
    {-event click}
    {-CSSclass "acs-listen"}
    {-id}
    {-formfield}
    {-usecapture:boolean false}
    {-preventdefault:boolean true}
    {-script:required}
} {

    Register an event handler for elements either with a specified ID,
    CSS class, or for a formfield targeted by form id and field name.

    @param event     register handler for this type of event
    @param id        register handler for this HTML ID
    @param CSSclass  register handler for this CSS class
    @param formfield register handler for this formfield, specified
                     in a list of two elements in the form
                     <code>{ form_id field_name }</code>
    @author  Gustaf Neumann
} {
    set prevent [expr {$preventdefault_p ? "event.preventDefault();" : ""}]

    set script [subst {
        e.addEventListener('$event', function (event) {$prevent$script}, $usecapture_p);
    }]

    if {[info exists id]} {
        set script [subst {
            var e = document.getElementById('$id');
            if (e !== null) {$script}
        }]
    } elseif {[info exists formfield]} {
        lassign $formfield id name
        set script [subst {
            var e = document.getElementById('$id').elements.namedItem('$name');
            if (e !== null) {$script}
        }]
    } else {
        #
        # In case, no id is provided, use the "CSSclass"
        #
        set script [subst {
            var elems = document.getElementsByClassName('$CSSclass');
            for (var i = 0, l = elems.length; i < l; i++) {
               var e = elems\[i\];
               $script
            }
        }]
    }

    template::add_body_script -script $script
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
