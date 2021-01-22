ad_page_contract {
  This is the top level master template.  It allows the basic parts of an HTML 
  document to be set through convenient data structures without introducing 
  anything site specific.

  You should NEVER need to modify this file.  
  
  Most of the time your pages or master templates should not directly set this
  file in their <master> tag.  They should instead use site-master with 
  provides a set of standard OpenACS content.  Only pages which need to return
  raw HTML should use this template directly.

  When using this template directly you MUST supply the following variables:

  @property doc(title)        The document title, ie. <title /> tag.
  @property doc(title_lang)   The language of the document title, if different
                              from the document language.

  The document output can be customised by supplying the following variables:

  @property doc(type)         The declared xml DOCTYPE.
  @property doc(charset)      The document character set.
  @property body(id)          The id attribute of the body tag.
  @property body(class)       The class of the body tag.

  ad_conn -set language       Must be used to override the document language
                              if necessary.

  To add a CSS or Javascripts to the <head> section of the document you can 
  call the corresponding template::head::add_* functions within your page.

  @see template::head::add_css
  @see template::head::add_javascript

  More generally, meta, link and script tags can be added to the <head> section
  of the document by calling their template::head::add_* function within your
  page.

  @see template::head::add_meta
  @see template::head::add_link
  @see template::head::add_script

  Javascript event handlers, such as onload, an be added to the <body> tag by 
  calling template::add_body_handler within your page.

  @see template::add_body_handler

  Finally, for more advanced functionality see the documentation for 
  template::add_body_script, template::add_header and template::add_footer.

  @see template::add_body_script
  @see template::add_header
  @see template::add_footer
 
  @author Kevin Scaldeferri (kevin@arsdigita.com)
    Lee Denison (lee@xarg.co.uk)
    Gustaf Neumann
    
  @creation-date 14 Sept 2000

  $Id$
}

if {![info exists doc(type)]} { 
    set doc(type) {<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">}
}

#
# Add standard meta tags
#
template::head::add_meta \
    -name generator \
    -lang en \
    -content "OpenACS version [ad_acs_version]"

# Add standard javascript
#
# Include core.js inclusion to the bottom of the body.

template::add_body_script -type "text/javascript" -src "/resources/acs-subsite/core.js"

#
# Add css for the current subsite, defaulting to the old list/form css which was
# hard-wired in previous versions of OpenACS.

set cssList [parameter::get -package_id [ad_conn subsite_id] -parameter ThemeCSS -default ""]
if {![string is list $cssList]} {
    ns_log error "ignore value in ThemeCSS, since it is not a valid list: $cssList"
} elseif { [llength $cssList] > 0 } {

    # DRB: Need to handle two cases, the lame first attempt and the more complete current
    # attempt which allows you to specify all of the parameters to template::head::add_css
    # (sigh, remove this kludge for 5.5.1).  We need to handle the old case so upgrades
    # to 5.5 for mgh and various of my sites work correctly.
    #
    # The following syntaxes are supported
    #
    # 1) pairs:                       {/resources/acs-templating/lists.css all} ...
    # 2) nested list of pairs:        {{href /resources/acs-templating/lists.css} {media all} ... } ...
    # 3) flat list of -att val pairs: {-href /resources/acs-templating/lists.css -media all ... } ...
    #

    foreach css $cssList {
	set first [lindex $css 0]
        if { [llength $css] == 2 && [llength $first] == 1 && [string index $first 0] ne "-"} {
            template::head::add_css -href $first -media [lindex $css 1]
        } elseif {[llength $first] == 2} {
	    set params [list]
            foreach param $css {
                lappend params -[lindex $param 0] [lindex $param 1]
            }
	    if {[catch {template::head::add_css {*}$params} errorMsg]} {
		ns_log error $errorMsg
	    }
        } else {
	    if {![string match -* [lindex $css 0]]} {
		error "CSS specification '$css' is incorrect"
	    }
	    if {[catch {template::head::add_css {*}$css} errorMsg]} {
		ns_log error $errorMsg
	    }
	}	    
    }

} else {
    template::head::add_css \
        -href "/resources/acs-templating/lists.css" \
        -media "all"
    template::head::add_css \
        -href "/resources/acs-templating/forms.css" \
        -media "all"
}

#
# Add js files via ThemeJS for the current subsite, similar to
# ThemeCSS.  Syntax is the flat list syntax (3) from ThemeCSS, valid
# parameters are determined by template::add_script. It is possible to
# add head and body scripts.

set jsSpecs [parameter::get -package_id [ad_conn subsite_id] -parameter ThemeJS -default ""]
if {![string is list $jsSpecs]} {
    ns_log error "ignore value in ThemeJS since it is not a valid list: $jsSpecs"
} else {
    foreach jsSpec $jsSpecs {
	if {[catch {template::add_script {*}$jsSpec} errorMsg]} {
	    ns_log error $errorMsg
	}
    }
}
#
# Render richtext widgets: The richtext widgets require typically a
# single configuration for all richtext widgets of a certain type on a
# page (that might require a list of the HTML IDs of all affected
# textareas).
#
::template::util::richtext::render_widgets

#
# Get the basic content info like title and charset for the head of
# the page.
#

if {![info exists doc(title)]} {
    set doc(title) [ad_conn instance_name]
    ns_log warning "[ad_conn url] has no doc(title) set, fallback to instance_name."
}

if {![info exists doc(charset)]} {
    set doc(charset) [ns_config ns/parameters OutputCharset [ad_conn charset]]
}

#
# The document language is always set from [ad_conn lang] which by default 
# returns the language setting for the current user.  This is probably
# not a bad guess, but the rest of OpenACS must override this setting when
# appropriate and set the lang attribute of tags which differ from the language
# of the page.  Otherwise we are lying to the browser.
#
set doc(lang) [ad_conn language]


template::head::add_meta \
    -content "text/html; charset=$doc(charset)" \
    -http_equiv "content-type"
#
# The following meta tags are unknwon for HTML5, therefore discouraged
#
# template::head::add_meta \
#     -content "text/css" \
#     -http_equiv "Content-Style-Type"
# template::head::add_meta \
#     -content "text/javascript" \
#     -http_equiv "Content-Script-Type"


# Determine if we should be displaying the translation UI
#
if {[lang::util::translator_mode_p]} {
    template::add_footer -src "/packages/acs-lang/lib/messages-to-translate"
}

# Determine if developer support is installed and enabled
#
if {[llength [info commands ::ds_show_p]] == 1 && [ds_show_p]} {
    template::head::add_css \
        -href "/resources/acs-developer-support/acs-developer-support.css" \
        -media "all"
 
    template::add_header -src "/packages/acs-developer-support/lib/toolbar"
    template::add_footer -src "/packages/acs-developer-support/lib/footer"
}

if {[info exists focus] && $focus ne ""} {
    #
    # Handle only values of focus where the provided name contains a
    # dot.
    #
    if { [regexp {^([^.]*)\.(.*)$} $focus match form_name element_name] } {
        set focus_script {
            function acs_Focus(form_name, element_name) {
                if (document.forms == null) return;
                if (document.forms[form_name] == null) return;
                if (document.forms[form_name].elements[element_name] == null) return;
                if (document.forms[form_name].elements[element_name].type == 'hidden') return;
                
                document.forms[form_name].elements[element_name].focus();
            };
        }
        append focus_script "acs_Focus('${form_name}', '${element_name}');\n"
        template::add_body_script -script $focus_script
    } else {
        ns_log warning "blank-master: variable focus has invalid value '$focus'"
    }
}

#
# Retrieve headers and footers
#
set header [template::get_header_html]
set footer [template::get_footer_html]

#
# Body event handlers are converted into body_scripts
#
template::get_body_event_handlers

#
# Build multirows: this has to be done after get_body_event_handlers
# to include these body_scripts as well.
#
template::head::prepare_multirows

#
# Add the content security policy. Since this is the blank master, we
# are defensive and check, if the system has already support for it
# via the CSPEnabledP kernel parameter. Otherwise users would be
# blocked out.
#
if {[parameter::get -parameter CSPEnabledP -package_id [ad_acs_kernel_id] -default 0]
    && [info commands ::security::csp::render] ne ""
} {
    set csp [::security::csp::render]
    if {$csp ne ""} {

        set ua [ns_set iget [ns_conn headers] user-agent]
        if {[regexp {Trident/.*rv:([0-9]{1,}[\.0-9]{0,})} $ua]} {
            set field X-Content-Security-Policy
        } else {
            set field Content-Security-Policy
        }

        ns_set put [ns_conn outputheaders] $field $csp
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
