ad_page_contract {			# 
    Merge two users accounts

    TODO: Support to merge more than two accounts at the same time

    @cvs-id $Id$
} {
    user_id:naturalnum,notnull
    user_id_from_search
} -properties {
    context:onevalue
    first_names:onevalue
    last_name:onevalue
} -validate {
    if_the_logged_in_user_is_crazy {
	# Just for security reasons...
	set current_user_id [ad_conn user_id]
	if { $current_user_id eq $user_id || $current_user_id eq $user_id_from_search } {
	    ad_complain "You can't merge yourself"
	}
    }
}

set context [list [list "./" "Merge"] "Merge"]

#
# Information of user_id_one
#
if { [db_0or1row one_user_portrait {}] } {
    set one_img_src "[subsite::get_element -element url]shared/portrait-bits.tcl?user_id=$user_id"
} else {
    set one_img_src "/resources/acs-admin/not_available.gif"
}

db_1row one_get_info {}

db_multirow -extend {one_item_object_url} one_user_contributions one_user_contributions { *SQL* } {
    set one_item_object_url  "[site_node::get_url_from_object_id -object_id $object_id]"
}

set user_id_one_items [callback merge::MergeShowUserInfo -user_id $user_id ]
if { $user_id_one_items ne "" } {
    set user_id_one_items_html "<ul><li><b>Packages User Information </b><ul>"
    foreach pkg_list $user_id_one_items {
	append user_id_one_items_html "<li><i>[lindex $pkg_list 0]</i><ul>"
	set length [llength $pkg_list]
	for { set idx 1} { $idx < $length } { incr idx } {
	    append user_id_one_items_html "<li>[lindex $pkg_list $idx]</li>"
	}
	append user_id_one_items_html "</ul></li>"
    }
    append user_id_one_items_html "</ul></li></ul>"
} else {
    set user_id_one_items_html ""
}

#
# Information of user_id_two
#
if { [db_0or1row two_user_portrait {}] } {
    set two_img_src "[subsite::get_element -element url]shared/portrait-bits.tcl?user_id=$user_id_from_search"
} else {
    set two_img_src "/resources/acs-admin/not_available.gif"
}

db_1row two_get_info {}

db_multirow -extend {two_item_object_url} two_user_contributions two_user_contributions { *SQL* } {
    set two_item_object_url "[site_node::get_url_from_object_id -object_id $object_id]"
}

set user_id_two_items [callback merge::MergeShowUserInfo -user_id $user_id_from_search ]
if { $user_id_two_items ne "" } {
    set user_id_two_items_html "<ul><li><b>Packages User Information </b><ul>"
    foreach pkg_list $user_id_two_items {
	append user_id_two_items_html "<li><i>[lindex $pkg_list 0]</i><ul>"
	set length [llength $pkg_list]
	for { set idx 1} { $idx < $length } { incr idx } {
	    append user_id_two_items_html "<li>[lindex $pkg_list $idx]</li>"
	}
	append user_id_two_items_html "</ul></li>"
    }
    append user_id_two_items_html "</ul></li></ul>"
} else {
    set user_id_two_items_html ""
}

template::head::add_css \
    -href "/resources/acs-admin/um-more-info.css" \
    -media all

template::add_body_script -script {
    function toggle_footer(event) {
        event.preventDefault();
        var el = document.getElementsByTagName('div');
        for(i = 0; i < el.length; i++) {
          if (el[i].className=='um-more-info') {
              el[i].className='um-more-info-off';
          } else {
              if (el[i].className=='um-more-info-off') {
                  el[i].className='um-more-info';
              }
          }
      };
      return false;
    };
    document.getElementById('toggle-footer-display-control-1').addEventListener('click', toggle_footer, false);
    document.getElementById('toggle-footer-display-control-2').addEventListener('click', toggle_footer, false);    
}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
