ad_page_contract {
  This is the top level master template.  It allows the basic parts of an XHTML 
  document to be set through convenient data structures without introducing 
  anything site specific.

  You MUST supply the following variables:

  @property doc(title)        The document title, ie. <title /> tag.
  @property doc(title_lang)   The language of the document title, if different
                              from the document language.

  The document output can be customised by supplying the following variables:

  @property doc(type)         The declared xml DOCTYPE.
  @property doc(charset)      The document character set.
  @property body(id)          The id attribute of the body tag.
  @property body(class)       The class of the body tag.
  @property meta:multirow     A multirow of <meta> tags to render.
  @property link:multirow     A multirow of <link> tags to render.
  @property script:multirow   A multirow of <script> tags to render in the head.
  @property body_script:multirow   A multirow of <script> tags to render in the body.

  ad_conn -set language       Must be used to override the document language
                              if necessary.

  The following event handlers can be customised by supplying the appropriate 
  variable.  Each variable is a list of valid javascript code fragments to be
  executed in order.

  @property body(onload)
  @property body(onunload)
  @property body(onclick)
  @property body(ondblclick)
  @property body(onmousedown)
  @property body(onmouseup)
  @property body(onmouseover)
  @property body(onmousemove)
  @property body(onmouseout)
  @property body(onkeypress)
  @property body(onkeydown)
  @property body(onkeyup)

  @author Kevin Scaldeferri (kevin@arsdigita.com)
          Lee Denison (lee@xarg.co.uk)
  @creation-date 14 Sept 2000

  $Id$
}

if {[template::util::is_nil doc(type)]} { 
    set doc(type) {<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">}
}

if {[template::util::is_nil doc(charset)]} {
    set doc(charset) [ad_conn charset]
}

# The document language is always set from [ad_conn lang] which by default 
# returns the language setting for the current user.  This is probably
# not a bad guess, but the rest of OpenACS must override this setting when
# appropriate and set the lang attribute of tags which differ from the language
# of the page.  Otherwise we are lying to the browser.
set doc(lang) [ad_conn language]

# AG: Markup in <title> tags doesn't render well.
set doc(title) [ns_striphtml $doc(title)]

if {![template::multirow exists meta]} {
    template::multirow create meta name content http_equiv scheme lang
}

if {![template::multirow exists link]} {
    template::multirow create link rel type href title lang media
}

if {![template::multirow exists script]} {
    template::multirow create script type src charset defer content
}
template::multirow append script text/javascript /resources/acs-subsite/core.js "" "" ""

if {![template::multirow exists body_script]} {
    template::multirow create body_script type src charset defer content
}

# Handle richtext widgets, which needs special javascript and css 
# in the page header and body.

# DRB: This stuff really doesn't belong here - templating should probably be setting
# this stuff up.  But for now ... at least it's using the new multirows correctly.

global acs_blank_master__htmlareas acs_blank_master

if { [info exists acs_blank_master__htmlareas] } {

    if {[info exists acs_blank_master(rte)]} {
        set rte_dir /resources/acs-templating/rte/
        foreach htmlarea_id [lsort -unique $acs_blank_master__htmlareas] {
            lappend body(onload) "acs_rteInit('${htmlarea_id}');"
        }
        template::multirow append script text/javascript ${rte_dir}richtext.js "" "" ""
        template::multirow append body_script text/javascript "" "" "" "
        initRTE(\"${rte_dir}images/\", \"$rte_dir\", \"${rte_dir}rte.css\");
        "
    }

    if { [info exists acs_blank_master(xinha)] } {
        set xinha_dir /resources/acs-templating/xinha-nightly/
        set editor_lang [expr { $doc(lang) eq "en" || $doc(lang) eq "de" ? $doc(lang) : "en" }]
        template::multirow append script text/javascript "" "" "" "
            _editor_url  = \"$xinha_dir\";
            _editor_lang = \"$editor_lang\";
        "
        template::multirow append script text/javascript ${xinha_dir}htmlarea.js "" "" ""
        template::multirow append body_script text/javascript "" "" "" "
	    xinha_editors = null;
	    xinha_init = null;
	    xinha_config = null;
	    xinha_plugins = null;
	    xinha_init = xinha_init ? xinha_init : function()
	    \{
	        xinha_plugins = xinha_plugins ? xinha_plugins :
	        \[$acs_blank_master(xinha.plugins)\];
	        // THIS BIT OF JAVASCRIPT LOADS THE PLUGINS, NO TOUCHING  :)
	        if(!HTMLArea.loadPlugins(xinha_plugins, xinha_init)) return;
	        xinha_editors = xinha_editors ? xinha_editors :
	        \['[join $acs_blank_master__htmlareas ',']'\];
                xinha_config = xinha_config ? xinha_config() : new HTMLArea.Config();
                $acs_blank_master(xinha.options)
                xinha_editors = HTMLArea.makeEditors(xinha_editors, xinha_config, xinha_plugins);
                HTMLArea.startEditors(xinha_editors);
            \}
	    window.onload = xinha_init;
        "
    }
}

# Concatenate the javascript event handlers for the body tag
if {[array exists body]} {
    foreach name [array names body -glob "on*"] {
        append event_handlers " ${name}=\""

        foreach javascript $body($name) {
            append event_handlers "[string trimright $javascript "; "]; "
        }

        append event_handlers "\""
    }
}

# DRB: Devsup toolbar moved here temporarily until we rewrite things so package can push
# tool bars up to the blank master.

# Determine whether developer support is installed and enabled
#
set developer_support_p [expr {
    [llength [info procs ::ds_show_p]] == 1 && [ds_show_p]
}]

if {$developer_support_p} {
    template::multirow append link \
        stylesheet \
        "text/css" \
        "/resources/acs-developer-support/acs-developer-support.css" \
        "Developer Support Styles" \
        en \
        "all"
}
