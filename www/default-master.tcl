# /www/master-default.tcl
#
# Set basic attributes and provide the logical defaults for variables that
# aren't provided by the slave page.
#
# Author: Kevin Scaldeferri (kevin@arsdigita.com)
# Creation Date: 14 Sept 2000
# $Id$
#


# Pull out the package_id of the subsite closest to our current node
set pkg_id [site_node_closest_ancestor_package "acs-subsite"]

# see if we have the parameter in the closest acs-subsite package
# to override this file in favor of the site-specific master
set have_site_master_p [ad_parameter -package_id $pkg_id UseSiteSpecificMaster dummy "0"]

if {$have_site_master_p} {

    ad_return_template "/www/site-specific-master"
}


# fall back on defaults for title, signatory and header_stuff

if [template::util::is_nil title]     { set title        [ad_system_name]  }
if [template::util::is_nil signatory] { set signatory    [ad_system_owner] }
if ![info exists header_stuff]        { set header_stuff {}                }


# Attributes

template::multirow create attribute key value

template::multirow append \
    attribute bgcolor [ad_parameter -package_id $pkg_id bgcolor   dummy "white"]
template::multirow append \
    attribute text    [ad_parameter -package_id $pkg_id textcolor dummy "black"]

if { [info exists prefer_text_only_p]
     && $prefer_text_only_p == "f"
     && [ad_graphics_site_available_p] } {
  template::multirow append attribute background \
    [ad_parameter -package_id $pkg_id background dummy "/graphics/bg.gif"]
}

if { ![template::util::is_nil focus] } {
  template::multirow append \
    attribute onLoad "javascript:document.${focus}.focus()"
}


# Developer-support

if { [llength [namespace eval :: info procs ds_link]] == 1 } {
     set ds_link "[ds_link]"
} else {
    set ds_link ""
}



