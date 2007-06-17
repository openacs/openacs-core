ad_page_contract {
  This is the highest level site specific master template.

  @author Lee Denison (lee@xarg.co.uk)

  $Id$
}

if {![info exists doc(title)] || $doc(title) eq ""} {
    set doc(title) [ad_conn instance_name]

    # There is no way to determine the language of instance_name so we guess
    # that it is the same as the site wide locale setting - if not this must
    # be overridden
    set doc(title_lang) [lindex [split [lang::system::site_wide_locale] _] 0]
}

if {![info exists body(onload)]} {
    set body(onload) [list]
}

if {![template::multirow exists meta]} {
    template::multirow create meta name content http_equiv scheme lang
}

if {![template::multirow exists link]} {
    template::multirow create link rel type href title lang media
}

if {![template::multirow exists script]} {
    template::multirow create script type src charset defer content
}

#
# Add standard meta tags
#
template::multirow append meta \
    generator \
    "OpenACS version [ad_acs_version]" \
    {} \
    {} \
    en
    
#
# Add standard css
#
template::multirow append link \
    stylesheet \
    "text/css" \
    "/resources/acs-templating/lists.css" \
    "" \
    en \
    "all"

template::multirow append link \
    stylesheet \
    "text/css" \
    "/resources/acs-templating/forms.css" \
    "" \
    en \
    "all"

template::multirow append link \
    stylesheet \
    "text/css" \
    "/resources/acs-subsite/site-master.css" \
    "Standard OpenACS Styles" \
    en \
    "all"

#
# Process focus variable in onload
# 
if { ![template::util::is_nil focus] } {
    # Handle elements where the name contains a dot
    if { [regexp {^([^.]*)\.(.*)$} $focus match form_name element_name] } {
        lappend body(onload) "acs_Focus('${form_name}', '${element_name}');"
    }
}

#
# Fire subsite callbacks to get header content
# 
# TODO: LJD - these callbacks should append to the relevant multirows to ensure
# TODO  accessibility standards compliant output
#
append head [join [callback subsite::get_extra_headers] "\n"]
set body(onload) [concat $body(onload) [callback subsite::header_onload]]

# 
# Add WYSIWYG editor content
#
global acs_blank_master__htmlareas acs_blank_master

if {[info exists acs_blank_master__htmlareas]
    && [llength $acs_blank_master__htmlareas] > 0} {
    
    # 
    # Add RTE scripts if we are using RTE
    #
    if {[info exists acs_blank_master(rte)]} {
        foreach htmlarea_id [lsort -unique $acs_blank_master__htmlareas] {
          lappend body(onload) "acs_rteInit('${htmlarea_id}')"
        }

        template::multirow append script \
            "text/javascript" \
            "/resources/acs-templating/rte/richtext.js" 
    }

    # 
    # Add Xinha scripts if we are using Xinha
    #
    if {[info exists acs_blank_master(xinha)]} {
        set xinha_dir /resources/acs-templating/xinha-nightly/
        set xinha_plugins $acs_blank_master(xinha.plugins)
        set xinha_params ""
        set xinha_options $acs_blank_master(xinha.options)
        set xinha_lang [lang::conn::language]

        if {$xinha_lang ne "en" && $xinha_lang ne "de"} {
            set xinha_lang en
        }

        template::multirow append script "text/javascript" {} {} {} "
            _editor_url = \"$xinha_dir\";
            _editor_lang = \"$xinha_lang\";"

        template::multirow append script \
            "text/javascript" \
            "${xinha_dir}htmlarea.js"

        set htmlarea_ids '[join $acs_blank_master__htmlareas "','"]'
    }
}

#
# Determine if we should be displaying the translation UI
#
set translator_mode_p [lang::util::translator_mode_p]

