# /www/master-default.tcl
#
# Set basic attributes and provide the logical defaults for variables that
# aren't provided by the slave page.
#
# Author: Kevin Scaldeferri (kevin@arsdigita.com)
# Creation Date: 14 Sept 2000
# $Id$
#

# fall back on defaults

if { [template::util::is_nil doc_type] } { 
    set doc_type {<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">}
}

if { [template::util::is_nil title] } { 
    set title [ad_conn instance_name]  
}

#AG: Markup in <title> tags doesn't render well.
set title [ns_striphtml $title]


if { ![info exists header_stuff] } {
    set header_stuff {} 
}


# Attributes

multirow create attribute key value

set onload {}

# Handle htmlArea widget, which needs special javascript and css in the page header
global acs_blank_master__htmlareas
if { [info exists acs_blank_master__htmlareas] } {
    foreach htmlarea_id $acs_blank_master__htmlareas {
        append header_stuff "<script type=\"text/javascript\">var editor_var_${htmlarea_id} = new HTMLArea(\"${htmlarea_id}\");</script>"
        lappend onload "acs_initHtmlArea(editor_var_${htmlarea_id}, '${htmlarea_id}');"
    }
}

if { ![template::util::is_nil focus] } {
    # Handle elements where the name contains a dot
    if { [regexp {^([^.]*)\.(.*)$} $focus match form_name element_name] } {
        lappend onload "acs_Focus('${form_name}', '${element_name}');"
    }
}

multirow append attribute onload [join $onload " "]

# Additional Body Attributes

if {[exists_and_not_null body_attributes]} {
    foreach body_attribute $body_attributes {
	multirow append attribute [lindex $body_attribute 0] [lindex $body_attribute 1]
    }
} else {
    set body_attributes ""
}

# Header links (stylesheets, javascript)
multirow create header_links rel type href media
multirow append header_links "stylesheet" "text/css" "/resources/acs-templating/lists.css" "all"
multirow append header_links "stylesheet" "text/css" "/resources/acs-templating/forms.css" "all"
multirow append header_links "stylesheet" "text/css" "/resources/acs-subsite/default-master.css" "all"

# Developer-support: We include that here, so that master template authors don't have to worry about it

if { [llength [namespace eval :: info procs ds_show_p]] == 1 } {
    set developer_support_p 1
} else {
    set developer_support_p 0
}

set translator_mode_p [lang::util::translator_mode_p]

set openacs_version [ad_acs_version]

# Toggle translator mode link

set acs_lang_url [apm_package_url_from_key "acs-lang"]
if { [empty_string_p $acs_lang_url] } {
    set lang_admin_p 0
} else {
    set lang_admin_p [permission::permission_p \
                          -object_id [site_node::get_element -url $acs_lang_url -element object_id] \
                          -privilege admin \
                          -party_id [ad_conn untrusted_user_id]]
}
set toggle_translator_mode_url [export_vars -base "${acs_lang_url}admin/translator-mode-toggle" { { return_url [ad_return_url] } }]

