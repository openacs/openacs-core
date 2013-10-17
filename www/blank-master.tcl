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
template::head::add_javascript -src "/resources/acs-subsite/core.js"

# The following (forms, list and xinha) should
# be done in acs-templating.

#
# Add css for the current subsite, defaulting to the old list/form css which was
# hard-wired in previous versions of OpenACS.

set css [parameter::get -package_id [ad_conn subsite_id] -parameter ThemeCSS -default ""]
if { $css ne "" } {

    # DRB: Need to handle two cases, the lame first attempt and the more complete current
    # attempt which allows you to specify all of the parameters to template::head::add_css
    # (sigh, remove this kludge for 5.5.1).  We need to handle the old case so upgrades
    # to 5.5 for mgh and various of my sites work correctly.

    foreach css $css {
        if { [llength $css] == 2 && [llength [lindex $css 0]] == 1 } {
            template::head::add_css -href [lindex $css 0] -media [lindex $css 1]
        } else {
	    set params [list]
            foreach param $css {
                lappend params -[lindex $param 0] [lindex $param 1]
            }
            template::head::add_css {*}$params
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
  template::head::add_javascript -src ${::xinha_dir}XinhaCore.js
}

if { [info exists ::acs_blank_master(tinymce)] } {
    # we are using TinyMCE
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
    template::head::add_javascript -script "
        tinyMCE.init(\{language: \"$tinymce_lang\", $tinymce_config\});
	" -order tinymceZ
}

if {![info exists doc(title)]} {
    set doc(title) "[ad_conn instance_name]"
    ns_log warning "[ad_conn url] has no doc(title) set."
}
# AG: Markup in <title> tags doesn't render well.
set doc(title) [ns_striphtml $doc(title)]

if {![info exists doc(charset)]} {
    set doc(charset) [ns_config ns/parameters OutputCharset [ad_conn charset]]
}

template::head::add_meta \
    -content "text/html; charset=$doc(charset)" \
    -http_equiv "content-type"

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
