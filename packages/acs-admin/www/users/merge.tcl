ad_page_contract {			# 
    Merge two users accounts

    TODO: Support to merge more than two accounts at the same time

    @cvs-id $Id$
} {
    user_id
    user_id_from_search
} -properties {
    context:onevalue
    first_names:onevalue
    last_name:onevalue
}

set current_user_id [ad_conn user_id]
set return_url [ad_conn url]
set context [list [list "./" "Merge"] "Merge"]

# information of user_id one
if { [db_0or1row one_user_portrait { *SQL* }] } {
    set one_img_src "[subsite::get_element -element url]shared/portrait-bits.tcl?user_id=$user_id"
} else {
    set one_img_src "/resources/acs-admin/not_available.gif"
}


db_1row one_get_info { *SQL* }

db_multirow -extend {one_item_object_url} one_user_contributions one_user_contributions { *SQL* } {
    set one_item_object_url "/"
}


if {[db_0or1row one_select_dotlrn_user_info { *SQL* }]} {
    set one_dotlrn_user_p 1
} else {
    set one_dotlrn_user_p 0
}

set one_can_browse_p [dotlrn::user_can_browse_p -user_id $user_id]
db_multirow one_member_classes one_select_member_classes { *SQL* } {
    set role_pretty_name [dotlrn_community::get_role_pretty_name -community_id $class_instance_id -rel_type $rel_type]
}    
db_multirow one_member_clubs one_select_member_clubs { *SQL* } {
    set role_pretty_name [dotlrn_community::get_role_pretty_name -community_id $club_id -rel_type $rel_type]
}
db_multirow one_member_subgroups one_select_member_subgroups { *SQL* } {
    set role_pretty_name [dotlrn_community::get_role_pretty_name -community_id $community_id -rel_type $rel_type]
}


# information of user_id two
db_1row two_get_info { *SQL* }

db_multirow -extend {two_item_object_url} two_user_contributions two_user_contributions { *SQL* } {
    set two_item_object_url "/"
}



if { [db_0or1row two_user_portrait { *SQL* }] } {
    set two_img_src "[subsite::get_element -element url]shared/portrait-bits.tcl?user_id=$user_id_from_search"
} else {
    set two_img_src "/resources/acs-admin/not_available.gif"
}

if {[db_0or1row two_select_dotlrn_user_info { *SQL* }]} {
    set two_dotlrn_user_p 1
} else {
   set two_dotlrn_user_p 0
}

set two_can_browse_p [dotlrn::user_can_browse_p -user_id $user_id]


db_multirow two_member_classes two_select_member_classes { *SQL* } {
    set role_pretty_name [dotlrn_community::get_role_pretty_name -community_id $class_instance_id -rel_type $rel_type]
}    

db_multirow two_member_clubs two_select_member_clubs { *SQL* } {
    set role_pretty_name [dotlrn_community::get_role_pretty_name -community_id $club_id -rel_type $rel_type]
}
db_multirow two_member_subgroups two_select_member_subgroups { *SQL* } {
    set role_pretty_name [dotlrn_community::get_role_pretty_name -community_id $community_id -rel_type $rel_type]
}





