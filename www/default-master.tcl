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

if { [template::util::is_nil subnavbar_link] } {
    set subnavbar_link ""
}


if { [template::util::is_nil title] } {
    set title [ad_conn instance_name]
}

if { [template::util::is_nil signatory] } {
    set signatory [ad_system_owner]
}

if { ![template::util::is_nil context] } {
    set cmd [list ad_context_bar --]
    foreach elem $context {
        lappend cmd $elem
    }
    set context_bar [eval $cmd]
}

if { [template::util::is_nil context_bar] } {
    set context_bar [ad_context_bar]
}


# Attributes

template::multirow create attribute key value

# Pull out the package_id of the subsite closest to our current node
set pkg_id [site_node_closest_ancestor_package "acs-subsite"]

#template::multirow append \
#    attribute bgcolor [ad_parameter -package_id $pkg_id bgcolor   dummy "white"]
#template::multirow append \
#    attribute text    [ad_parameter -package_id $pkg_id textcolor dummy "black"]

if { [info exists prefer_text_only_p]
     && $prefer_text_only_p == "f"
     && [ad_graphics_site_available_p] } {
  template::multirow append attribute background \
    [ad_parameter -package_id $pkg_id background dummy "/graphics/bg.gif"]
}

# Developer-support

if { [llength [namespace eval :: info procs ds_link]] == 1 } {
     set ds_link "[ds_link]"
} else {
    set ds_link ""
}

# Curriculum bar

if { [apm_package_installed_p curriculum] } {
    set curriculum_bar_p 1
} else {
    set curriculum_bar_p 0
}
