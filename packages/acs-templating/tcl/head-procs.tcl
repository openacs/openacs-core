ad_library {

    The template::head::* api manipulates the head section of the document that
    will be returned to the users client.  Packages should use this api to add
    package specific javascripts, CSS, link tags and meta tags to the HTML
    document.

    @author Lee Denison (lee@xarg.co.uk)
    @creation-date 2007-05-18

}

namespace eval template {}
namespace eval template::head {}

ad_proc -private template::reset_request_vars {} {
    Resets all global datastructures used to manage the head section of the
    returned document.  This should be called at the beginning of any request
    handled by the templating system.
} {
    variable ::template::head::scripts
    array unset scripts
    array set scripts [list]

    variable ::template::head::links
    array unset links
    array set links [list]

    variable ::template::head::metas
    array unset metas
    array set metas [list]

    variable ::template::body_handlers
    array unset body_handlers
    array set body_handlers [list]

    variable ::template::body_scripts
    array unset body_scripts
    set body_scripts [list]

    variable ::template::headers
    set headers [list]
    variable ::template::footers
    set footers [list]
}

ad_proc -public template::head::add_script {
    {-type:required}
    {-defer:boolean}
    {-src ""}
    {-charset ""}
    {-script ""}
    {-order "0"}
} {
    Add a script to the head section of the document to be returned to the
    users client.  A script library in an external file may only be included 
    once; subsequent calls to add_script will replace the existing entry.  
    Anonymous script blocks will be added without checking for duplicates; the 
    caller must ensure that anonymous script blocks are not inadvertantly added 
    multiple times.  You <strong>must</strong> supply either src or script.

    @param type    the type attribute of the script tag, eg. 'text/javascript'
    @param defer   whether execution of the script should be defered until after
                   the page has been loaded
    @param src     the src attribute of the script tag, ie. the source url of the
                   script
    @param charset the charset attribute of the script tag, ie. the character 
                   set of the script if it differs from the main document
    @param script  the inline script for the body of the script tag.  This 
                   parameter will be ignored if a value has been supplied for
                   src
} {
    variable ::template::head::scripts

    if {$defer_p} {
        set defer defer
    } else {
        set defer ""
    }

    if {$src eq ""} {
        if {$script eq ""} {
            error "You must supply either -src or -script."
        }

        lappend scripts(anonymous) $type "" $charset $defer $script $order
    } else {
        set scripts($src) [list $type $src $charset $defer "" $order]
    }
}

ad_proc -public template::head::add_link {
    {-rel:required}
    {-href:required}
    {-type ""}
    {-media ""}
    {-title ""}
    {-lang ""}
    {-order "0"}
} {
    Add a link tag to the head section of the document to be returned to the
    users client.  A given target document may only be added once for a 
    specified relation; subsequent calls to add_link will replace the existing 
    entry.  

    @param rel     the rel attribute of the link tag defining the relationship
                   of the linked document to the current one, eg. 'stylesheet'
    @param href    the href attribute of the link tag, eg. the target document
                   of the link
    @param type    the type attribute of the link tag, eg. 'text/css'
    @param media   the media attribute of the link tag describing which display
                   media this link is relevant to.  This may be a comma 
                   separated list of values, eg. 'screen,print,braille'
    @param title   the title attribute of the link tag describing the target of
                   this link 
    @param lang    the lang attribute of the link tag specifying the language 
                   of its attributes if they differ from the document language
} {
    variable ::template::head::links

    set links($rel,$href) [list $rel $href $type $media $title $lang $order]
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

    @param http_equiv the http-equiv attribute of the meta tag, ie. the 
                      HTTP header which this metadata is equivalent to
                      eg. 'content-type'
    @param name       the name attribute of the meta tag, ie. the metadata 
                      identifier
    @param scheme     the scheme attribute of the meta tag defining which 
                      metadata scheme should be used to interpret the metadata, 
                      eg. 'DC' for Dublin Core (http://dublincore.org/)
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
    @param type    the type attribute of the link tag, eg. 'text/css'
    @param media   the media attribute of the link tag describing which display
                   media this link is relevant to.  This may be a comma 
                   separated list of values, eg. 'screen,print,braille'
    @param title   the title attribute of the link tag describing the target of
                   this link 
    @param lang    the lang attribute of the link tag specifying the language 
                   of its attributes if they differ from the document language
} {
    variable ::template::head::styles

    lappend styles(anonymous) $type $media $title $lang $style
 
}

ad_proc -public template::head::add_javascript {
    {-defer:boolean}
    {-src ""}
    {-charset ""}
    {-script ""}
    {-order "0"}
} {
    Add a script of type 'text/javascript' to the head section of the document 
    to be returned to the users client.  This function is a wrapper around 
    template::head::add_script.  You must supply either src or script.

    @param defer   whether execution of the script should be defered until after
                   the page has been loaded
    @param src     the src attribute of the script tag, ie. the source url of the
                   script
    @param charset the charset attribute of the script tag, ie. the character 
                   set of the script if it differs from the main document
    @param script  the inline script for the body of the script tag.  This 
                   parameter will be ignored if a value has been supplied for
                   src

    @see template::head::add_script
} {
    template::head::add_script -defer=$defer_p \
        -type text/javascript \
        -src $src \
        -charset $charset \
        -script $script \
        -order $order
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

    @param href      the href attribute of the link tag, eg. the target 
                     stylesheet
    @param alternate sets the rel attribute of the link tag defining to 
                     'alternate stylesheet' if set, sets it to 'stylesheet' 
                     otherwise
    @param media     the media attribute of the link tag describing which 
                     display media this link is relevant to.  This may be a 
                     comma separated list of values, eg. 'screen,print,braille'
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
    Adds javascript code to an event handler in the body tag.  Several 
    javascript code blocks may be assigned to each handler by subsequent calls 
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
    @param script     the javascript code to execute
    @param identifier a name, if supplied, used to ensure this javascript code
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
    {-type:required}
    {-defer:boolean}
    {-src ""}
    {-charset ""}
    {-script ""}
} {
    Add a script to the start of the body section of the document to be returned
    to the users client. You <strong>must</strong> supply either src or script.

    @param type    the type attribute of the script tag, eg. 'text/javascript'
    @param defer   whether execution of the script should be defered until after
                   the page has been loaded
    @param src     the src attribute of the script tag, ie. the source url of the
                   script
    @param charset the charset attribute of the script tag, ie. the character 
                   set of the script if it differs from the main document
    @param script  the inline script for the body of the script tag.  This 
                   parameter will be ignored if a value has been supplied for
                   src
} {
    variable ::template::body_scripts

    if {$defer_p} {
        set defer defer
    } else {
        set defer ""
    }

    if {$src eq "" && $script eq ""} {
        error "You must supply either -src or -script."
    }

    lappend body_scripts $type $src $charset $defer $script
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
      switch $direction {
	outer {set headers [concat [list $values] $headers]}
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
      switch $direction {
	outer {lappend footers $values}
	inner {set footers [concat [list $values] $footers]}
	default {error "unknown direction $direction"}
      }
    } else {
      set footers [list $values]
    }
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
    template::multirow create link rel type href title lang media order
    if {[array exists links]} {
        # first non alternate stylesheet
        foreach name [array names links] {
            foreach {rel href type media title lang order} $links($name) {
                if {$rel ne "alternate stylesheet"} {
                    template::multirow append link \
                        $rel \
                        $type \
                        $href \
                        $title \
                        $lang \
                        $media \
                        $order
                    set links($name) ""
                }
            }
        }
        # order the stylesheets before adding alternate ones
        template::multirow sort link order
        # now alternate stylesheet
        foreach name [array names links] {
            foreach {rel href type media title lang order} $links($name) {
                if {$links($name) ne ""} {
                    template::multirow append link \
                        $rel \
                        $type \
                        $href \
                        $title \
                        $lang \
                        $media \
                        $order
                    set links($name) ""
                }
            }
        }
        unset links
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
        unset styles
    }

    # Generate the head <script /> tag multirow
    variable ::template::head::scripts
    template::multirow create headscript type src charset defer content order
    if {[array exists scripts]} {
        foreach name [array names scripts] {
            foreach {type src charset defer content order} $scripts($name) {
                template::multirow append headscript \
                    $type \
                    $src \
                    $charset \
                    $defer \
                    $content \
                    $order
            }
        }
        template::multirow sort headscript order
        unset scripts
    }

    # Generate the body <script /> tag multirow
    variable ::template::body_scripts
    template::multirow create body_script type src charset defer content
    if {[info exists body_scripts]} {
        foreach {type src charset defer content} $body_scripts {
            template::multirow append body_script \
                $type \
                $src \
                $charset \
                $defer \
                $content
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
            set type [lindex $header_list 0]
            set src [lindex $header_list 1]
            set params [lindex $header_list 2]
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
            set type [lindex $footer_list 0]
            set src [lindex $footer_list 1]
            set params [lindex $footer_list 2]
            if {$type eq "literal"} {
                append footer $src
            } else {
                append footer [template::adp_include $src $params]
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
    # Concatenate the javascript event handlers for the body tag
    variable ::template::body_handlers
    set event_handlers ""
    if {[array exists body_handlers]} {
        
        foreach name [array names body_handlers] {
            set event [lindex [split $name ","] 0]
            # ns_log notice "event $event name $name JS !!!$body_handlers($name)!!!"
            foreach javascript $body_handlers($name) {
                lappend body_handlers($event) "[string trimright $javascript {; }];"
            }
            unset body_handlers($name)
        }
        
        # Now create the event handlers string
        foreach {event script} [array get body_handlers] {
            append event_handlers " " $event = \" [join $script { }] \"
        }
        unset body_handlers
    }

    return $event_handlers
}
