ad_page_contract {
  This is the top level master template.  It allows the basic parts of an XHTML 
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
# The only function needed alread onload is acs_Focus()
#
template::add_body_script -type "text/javascript" -src "/resources/acs-subsite/core.js"

template::head::add_javascript -script {
  function acs_Focus(form_name, element_name) {
    if (document.forms == null) return;
    if (document.forms[form_name] == null) return;
    if (document.forms[form_name].elements[element_name] == null) return;
    if (document.forms[form_name].elements[element_name].type == 'hidden') return;

    document.forms[form_name].elements[element_name].focus();
  }
}

# The following (forms, list and xinha) should
# be done in acs-templating.

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
        if { [llength $css] == 2 && [llength $first] == 1 && [string range $first 0 0] ne "-"} {
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
# Temporary (?) fix to get xinha working
#
if {[info exists ::acs_blank_master(xinha)]} {
  set ::xinha_dir /resources/acs-templating/xinha-nightly/
  set ::xinha_lang [lang::conn::language]
  #
  # Xinha localization covers 33 languages, removing
  # the following restriction should be fine.
  #
  #if {$::xinha_lang ne "en" && $::xinha_lang ne "de"} {
  #  set ::xinha_lang en
  #}

  # We could add site wide Xinha configurations (.js code) into xinha_params
  set xinha_params ""

  # Per call configuration
  set xinha_plugins $::acs_blank_master(xinha.plugins)
  set xinha_options $::acs_blank_master(xinha.options)
  
  # HTML ids of the textareas used for Xinha
  set htmlarea_ids '[join $::acs_blank_master__htmlareas "','"]'
  
  template::head::add_script -type text/javascript -script "
         xinha_editors = null;
         xinha_init = null;
         xinha_config = null;
         xinha_plugins = null;
         xinha_init = xinha_init ? xinha_init : function() {
            xinha_plugins = xinha_plugins ? xinha_plugins : 
              \[$xinha_plugins\];

            // THIS BIT OF JAVASCRIPT LOADS THE PLUGINS, NO TOUCHING  
            if(!Xinha.loadPlugins(xinha_plugins, xinha_init)) return;

            xinha_editors = xinha_editors ? xinha_editors :\[ $htmlarea_ids \];
            xinha_config = xinha_config ? xinha_config() : new Xinha.Config();
            $xinha_params
            $xinha_options
            xinha_editors = 
                 Xinha.makeEditors(xinha_editors, xinha_config, xinha_plugins);
            Xinha.startEditors(xinha_editors);
         }
         //window.onload = xinha_init;
      "

  template::add_body_handler -event onload -script "xinha_init();"
  # Antonio Pisano 2015-03-27: including big javascripts in head is discouraged by current best practices for web.
  # We should consider moving every inclusion like this in the body. As consequences are non-trivial, just warn for now. 
  template::head::add_javascript -src ${::xinha_dir}XinhaCore.js
}

if { [info exists ::acs_blank_master(tinymce)] } {
    # we are using TinyMCE
    # Antonio Pisano 2015-03-27: including big javascripts in head is discouraged by current best practices for web.
    # We should consider moving every inclusion like this in the body. As consequences are non-trivial, just warn for now. 
    template::head::add_javascript -src "/resources/acs-templating/tinymce/jscripts/tiny_mce/tiny_mce_src.js" -order tinymce0
    # get the textareas where we apply tinymce
    set tinymce_elements [list]
    foreach htmlarea_id [lsort -unique $::acs_blank_master__htmlareas] {
        lappend tinymce_elements $htmlarea_id
    }			
    set tinymce_config $::acs_blank_master(tinymce.config)    

    # Figure out the language to use
    # 1st is the user language, if not available then the system one,
    # fallback to english which is provided by default

    set tinymce_relpath "packages/acs-templating/www/resources/tinymce/jscripts/tiny_mce"
    set lang_list [list [lang::user::language] [lang::system::language]]
    set tinymce_lang "en"
    foreach elm $lang_list {
        if { [file exists $::acs::rootdir/${tinymce_relpath}/langs/${elm}.js] } {
            set tinymce_lang $elm
            break
        }
    }

    # TODO : each element should have it's own init
    # Antonio Pisano 2015-03-27: including big javascripts in head is discouraged by current best practices for web.
    # We should consider moving every inclusion like this in the body. As consequences are non-trivial, just warn for now. 
    template::head::add_javascript -script "
        tinyMCE.init(\{language: \"$tinymce_lang\", $tinymce_config\});
	" -order tinymceZ
}

if { [info exists ::acs_blank_master(ckeditor4)] } {
    template::head::add_javascript -src "//cdn.ckeditor.com/4.5.2/standard/ckeditor.js"
}

if {![info exists doc(title)]} {
    set doc(title) "[ad_conn instance_name]"
    ns_log warning "[ad_conn url] has no doc(title) set."
}
# AG: Markup in <title> tags doesn't render well.
#set doc(title) [ns_striphtml $doc(title)]

if {![info exists doc(charset)]} {
    set doc(charset) [ns_config ns/parameters OutputCharset [ad_conn charset]]
}

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

# The document language is always set from [ad_conn lang] which by default 
# returns the language setting for the current user.  This is probably
# not a bad guess, but the rest of OpenACS must override this setting when
# appropriate and set the lang attribxute of tags which differ from the language
# of the page.  Otherwise we are lying to the browser.
set doc(lang) [ad_conn language]

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
    # Handle elements where the name contains a dot
    if { [regexp {^([^.]*)\.(.*)$} $focus match form_name element_name] } {
        template::add_body_handler \
            -event onload \
            -script "acs_Focus('${form_name}', '${element_name}');" \
            -identifier "focus"
    }
}

# Retrieve headers and footers
set header [template::get_header_html]
set footer [template::get_footer_html]
template::head::prepare_multirows
set event_handlers [template::get_body_event_handlers]
