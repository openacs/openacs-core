ad_page_contract {
    shows User A what User B has contributed to the community
    
    @param user_id defaults to currently logged in user if there is one
    @cvs-id $Id$
} {
    user_id:integer
} -properties {
    context:onevalue
    member_state:onevalue
    first_names:onevalue
    last_name:onevalue
    email:onevalue
    inline_portrait_state:onevalue
    portrait_export_vars:onevalue
    width:onevalue
    height:onevalue
    system_name:onevalue
    pretty_creation_date:onevalue
    show_intranet_info_p:onevalue
    show_email_p:onevalue
    intranet_info:onevalue
    url:onevalue
    bio:onevalue
    verified_user_id:onevalue
    user_contributions:multirow
    subsite_url:onevalue
}

set subsite_url [subsite::get_element -element url]

#See if this page has been overrided by a parameter in kernel 
set community_member_url [ad_parameter -package_id [ad_acs_kernel_id] CommunityMemberURL "/shared/community-member"]
if { $community_member_url != "/shared/community-member" } {
    ad_returnredirect "$community_member_url?user_id=$user_id"
    ad_script_abort
}

set verified_user_id [ad_verify_and_get_user_id]

if { [empty_string_p $user_id] } {
    if { $verified_user_id == 0 } {
	# Don't know what to do! 
	ad_return_error "Missing user_id" "We need a user_id to display the community page"
	return
    }
    set user_id $verified_user_id
}

set bind_vars [ad_tcl_vars_to_ns_set user_id]

# XXX add portraits to this page

#  if { ![db_0or1row user_information "select first_names, last_name, email, priv_email, 
#  url, banning_note, registration_date, user_state,
#  portrait_upload_date, portrait_original_width, portrait_original_height, portrait_client_file_name, bio,
#  portrait_thumbnail_width, portrait_thumbnail_height
#  from users 
#  where user_id=:user_id" -bind $bind_vars] } {
# }
    
if { ![db_0or1row user_information "select first_names, last_name, email, priv_email, url, creation_date, member_state from cc_users where user_id = :user_id" -bind $bind_vars]} {
    
    ad_return_error "No user found" "There is no community member with the user_id of $user_id"
    ns_log Notice "Could not find user_id $user_id in community-member.tcl from [ad_conn peeraddr]"
    return
}

  set bio [db_string biography "
  select attr_value
  from acs_attribute_values
  where object_id = :user_id
  and attribute_id =
     (select attribute_id
      from acs_attributes
      where object_type = 'person'
      and attribute_name = 'bio')" -default ""]

#  set bio [db_exec_plsql bio "
#  begin
#  :1 := acs_object.get_attribute (
#    object_id_in => :user_id,
#    attribute_name_in => 'bio');
#  end;"]

# Do we show the portrait?
set inline_portrait_state "none"
set portrait_export_vars [export_url_vars user_id]

if [db_0or1row portrait_info "
select i.width, i.height, cr.title, cr.description, cr.publish_date
from acs_rels a, cr_items c, cr_revisions cr, images i
where a.object_id_two = c.item_id
and c.live_revision = cr.revision_id
and cr.revision_id = i.image_id
and a.object_id_one = :user_id
and a.rel_type = 'user_portrait_rel'"] {
    # We have a portrait. Let's see if we can show it inline


    if { ![empty_string_p $width] && $width < 300 } {
	# let's show it inline
	set inline_portrait_state "inline"
    } else {
	set inline_portrait_state "link"
    }
}

# Let's see if we can show all intranet-specific information
#  set show_intranet_info_p 1
#  if { [im_enabled_p] && [ad_parameter KeepSharedInfoPrivate intranet 0] } {
#      set current_user_id [ad_get_user_id]
#      if { $current_user_id != $user_id && ![im_user_is_authorized_p $current_user_id] } {
	set show_intranet_info_p 0
#      }
#}

if { $show_intranet_info_p } {
    set intranet_info [im_user_information $user_id]
} else {

    if { $priv_email <= [ad_privacy_threshold] } {
	set show_email_p 1
    } else {
	set show_email_p 0
	# guy doesn't want his email address shown, but we can still put out 
	# the home page
    }
}

# XXX Make sure to make the following into links and this looks okay

db_multirow user_contributions  user_contributions "select at.pretty_name, at.pretty_plural, a.creation_date, acs_object.name(a.object_id) object_name
from acs_objects a, acs_object_types at
where a.object_type = at.object_type
and a.creation_user = :user_id
order by object_name, creation_date"

set context [list "Community member"]
set system_name [ad_system_name]
set pretty_creation_date [lc_time_fmt $creation_date "%q"]
set login_export_vars "return_url=[ns_urlencode [acs_community_member_url -user_id $user_id]]"

ad_return_template
