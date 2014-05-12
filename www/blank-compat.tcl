ad_page_contract {
  Accepts and translates deprecated master template variables.
  Writes a warning message to the log in each case.

  @author Lee Denison (lee@xarg.co.uk)
  @creation-date: 2007-02-18

  $Id$
}

if { ![info exists title] } {
    set title [ad_conn instance_name]
}

if {![array exists doc]} {
    array set doc [list]
}

set translations [list \
    doc_type doc(type) \
    title doc(title) \
    header_stuff head \
    on_load body(onload) \
]

foreach {from to} $translations {
    if {[info exists $from]} {
        ns_log warning "blank-compat: [ad_conn file] uses deprecated property $from instead of $to."
        set $to [set $from]
    } else {
        set $to {}
    }
}

if {[exists_and_not_null body_attributes]} {
    foreach body_attribute $body_attributes {
        if {[lsearch {
            id
            class
            onload 
            onunload 
            onclick 
            ondblclick 
            onmousedown 
            onmouseup 
            onmouseover 
            onmousemove 
            onmouseout 
            onkeypress 
            onkeydown 
            onkeyup
        } [lindex $body_attribute 0] >= 0]} {
            ns_log warning "blank-compat: [ad_conn file] uses deprecated property body_attribute for [lindex $body_attribute 0] instead of body([lindex $body_attribute 0])."
            set body([lindex $body_attribute 0]) [lindex $body_attribute 1]
        } else {
            ns_log error "blank-compat: [ad_conn file] uses deprecated property body_attribute for [lindex $body_attribute 0] which is no longer supported!"
        }
    }
}

if {![template::multirow exists link]} {
    template::multirow create link rel type href title lang media
}

# DRB: this shouldn't really be in blank master, there should be some way for the templating
# package to associate a particular css file with pages that use particular form or list
# templates.  Therefore I'll put the hard-wired values in blank-compat for the moment.
multirow append link stylesheet text/css /resources/acs-templating/lists.css "" [ad_conn language] all
multirow append link stylesheet text/css /resources/acs-templating/forms.css "" [ad_conn language] all

if {![template::multirow exists script]} {
    template::multirow create script type src charset defer async content
}

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

