ad_library {

    Provides procedures that are modified or created by the guys at Polyxena.

    @author rockola@mail.com
    @creation-date 2001/09/11

}


ad_proc px_multirow_nav { nav_items_list {current_url ""} } {
    Creates a multirow variable named "navigation" in the caller's context. This contains text and urls for links and info about whether the link should be highlit (or not). It also tells if the link should be treated as a sub-category (or not). Useful for building dynamic navigation sections of any design. Keeps track of packages and content sections.
} {

    upvar navigation navigation

    if { [empty_string_p $current_url] } {
       	set current_url [ns_conn url]
	regexp ^(.*/) $current_url current_url_stripped
    }
    set current_topdir "/[lindex [split $current_url_stripped /] 1]/"

    template::multirow create navigation item url subdir_p visible_p chosen_p sublevel_p
    
    foreach nav_item_list $nav_items_list {
	set href_url [lindex $nav_item_list 0]
	set link_content [lindex $nav_item_list 1]
	set sublink_p [lindex $nav_item_list 2]
	set topdir "/[lindex [split $href_url /] 1]/"
	set sublink_visible_p 0
	if { $sublink_p && $topdir == $current_topdir } {
	    set sublink_visible_p 1
	}
	set chosen_p 0
	set sublevel_p 0
	if { [string compare $current_url_stripped $href_url] == 0 } {
	    set chosen_p 1
	    if { ![string compare $current_url $current_url_stripped] == 0 } {
		set sublevel_p 1
	    }
	}
	template::multirow append navigation $link_content $href_url $sublink_p $sublink_visible_p $chosen_p $sublevel_p
    }
    
}
