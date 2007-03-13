ad_page_contract {
  Accepts and translates deprecated master template variables.
  Writes a warning message to the log in each case.

  @author Lee Denison (lee@xarg.co.uk)
  @creation-date: 2007-02-18

  $Id$
}

if { [template::util::is_nil title] } {
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

if { ![template::util::is_nil focus] } {
    ns_log warning "blank-compat: property focus is deprecated in blank-master - focus should be handled in site-master."

    # Handle elements where the name contains a dot
    if { [regexp {^([^.]*)\.(.*)$} $focus match form_name element_name] } {
        lappend body(onload) "acs_Focus('${form_name}', '${element_name}');"
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
