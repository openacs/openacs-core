# Expects properties:
#   title
#   focus
#   header_stuff
#   section
#   subnavbar_link

if { ![info exists section] } {
    set section {}
}

if { ![info exists header_stuff] } {
    set header_stuff {}
}

if { ![info exists subnavbar_link] } {
    set subnavbar_link {}
}

# This will set 'sections' and 'subsections' multirows
subsite::define_pageflow -section $section
subsite::get_section_info -array section_info

# Find the subsite we belong to
set subsite_url [site_node_closest_ancestor_package_url]
array set subsite_sitenode [site_node::get -url $subsite_url]
set subsite_node_id $subsite_sitenode(node_id)
set subsite_name $subsite_sitenode(instance_name)

# Where to find the stylesheet
set css_url "/resources/acs-subsite/group-master.css"

# Context bar
if { [template::util::is_nil no_context_p] } {
    if { ![template::util::is_nil context] } {
        set cmd [list ad_context_bar --]
        foreach elem $context {
            lappend cmd $elem
        }
        set context_bar [eval $cmd]
    }

    if [template::util::is_nil context_bar] { 
        set context_bar [ad_context_bar]
    }
} else {
    set context_bar {}
}

if { [string equal [ad_conn url] $subsite_url] } {
    set subsite_url {}
}
