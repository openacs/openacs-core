# /pvt/home.tcl

ad_page_contract {
    user's workspace page
    @cvs-id $Id$
} -properties {
    system_name:onevalue
    context_bar:onevalue
    full_name:onevalue
    email:onevalue
    url:onevalue
    screen_name:onevalue
    bio:onevalue
    portrait_state:onevalue
    portrait_publish_date:onevalue
    portrait_title:onevalue
    export_user_id:onevalue
    ad_url:onevalue
}

set user_id [ad_verify_and_get_user_id]

# If there are requirements to fulfill.

#  if {![string compare [db_string pvt_home_check_requirements {
#      select user_fulfills_requirements_p(:user_id) from dual
#  }] "f"]} {
#      ad_returnredirect "fulfill-requirements"
#      return
#  }

#  # if this user is part of intranet employees, send 'em over!
#  if { [im_enabled_p] } {
#      if { [im_user_is_employee_p $user_id] } {
#  	ad_returnredirect [im_url_stub]
#  	return
#      }	
#      if { [im_user_is_customer_p $user_id] } {
#  	set portal_extension [ad_parameter PortalExtension portals .ptl]
#  	set group_name [ad_parameter CustomerPortalName intranet "Customer Portals"]
#  	regsub -all { } [string tolower $group_name] {-} group_name_in_link 
#  	ad_returnredirect "/portals/${group_name_in_link}-1$portal_extension"
#  	return
#      }	
#  }

set user_exists_p [db_0or1row pvt_home_user_info {
    select first_names, last_name, email, url,
    nvl(screen_name,'&lt none set up &gt') as screen_name
    from cc_users 
    where user_id=:user_id
}]

set bio [db_string biography "
select attr_value
from acs_attribute_values
where object_id = :user_id
and attribute_id =
   (select attribute_id
    from acs_attributes
    where object_type = 'person'
    and attribute_name = 'bio')" -default ""]

if { ! $user_exists_p } {
    if {$user_id == 0} {
	ad_redirect_for_registration
	return
    }
    ad_return_error "Account Unavailable" "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason.  You can visit <a href=\"/register/logout\">the log out page</a> and then start over."
    return
}

if { ![empty_string_p $first_names] || ![empty_string_p $last_name] } {
    set full_name "$first_names $last_name"
} else {
    set full_name "name unknown"
}

set system_name [ad_system_name]

if [ad_parameter SolicitPortraitP "user-info" 0] {
    # we have portraits for some users 
    if ![db_0or1row get_portrait_info "
    select cr.publish_date, nvl(cr.title,'your portrait') as portrait_title
    from cr_revisions cr, cr_items ci, acs_rels a
    where cr.revision_id = ci.live_revision
    and  ci.item_id = a.object_id_two
    and a.object_id_one = :user_id
    and a.rel_type = 'user_portrait_rel'
    "] {
	set portrait_state "upload"
    } else {
	set portrait_state "show"
	set portrait_publish_date [util_AnsiDatetoPrettyDate $publish_date]
    }
} else {
    set portrait_state "none"
}


# [ad_decorate_top "<h2>$full_name</h2>
# workspace at [ad_system_name]
# " [ad_parameter WorkspacePageDecoration pvt]]

set header [ad_header "$full_name's workspace at $system_name"]

if {[ad_conn package_url] == "/"} {
  set context_bar [ad_context_bar "[ad_pvt_home_name]"]
} else {
  set context_bar [ad_context_bar "Home"]
}

#  set site_map [ad_parameter SiteMap content]

#  if ![empty_string_p $site_map] {
#      append page_content "\n<p>\n<li><a href=\"$site_map\">site map</a>\n"
#  }

#  db_foreach pvt_home_administration_group_info {
#      select ug.group_id, ug.group_name, ai.url as ai_url
#      from  user_groups ug, administration_info ai
#      where ug.group_id = ai.group_id
#      and ad_group_member_p ( :user_id, ug.group_id ) = 't'
#  } {
#      append admin_items "<li><a href=\"$ai_url\">$group_name</a>\n"
#  }

#  if [info exists admin_items] {
#      append page_content "<p>

#  <li>You have the following administrative roles for this site:
#  <ul>
#  $admin_items
#  </ul>
#  <P>
#  "
#  }

#  db_foreach pvt_home_non_administration_info {
#      select ug.group_id, ug.group_name, ug.short_name
#      from user_groups ug
#      where ug.group_type <> 'administration'
#      and ad_group_member_p ( :user_id, ug.group_id ) = 't'
#  } {

#      append group_items "<li><a href=\"[ug_url]/[ad_urlencode $short_name]/\">$group_name</a>\n"
#  }

#  if [info exists group_items] {
#      append page_content "<p>

#  <li>You're a member of the following groups:
#  <ul>
#  $group_items
#  </ul>
#  <P>
#  "
#  }

# if { [ad_parameter IntranetEnabledP intranet 0] == 1 } {
#    # Right now only employees can see the intranet
#    # append page_content "    <li><a href=\"[ad_parameter IntranetUrlStub intranet "/intranet"]\">Intranet</a><p>\n"
#}

set export_user_id [export_url_vars user_id]
set ad_url [ad_url]


set interest_items ""

#  db_foreach pvt_home_categories_list {
#      select c.category, c.category_id, 
#      decode(ui.category_id,NULL,NULL,'t') as selected_p
#      from categories c, (select * 
#  			from users_interests 
#  			where user_id = :user_id 
#  			and interest_level > 0) ui
#      where c.enabled_p = 't' 
#      and c.category_id = ui.category_id(+)
#  } {

#      if { $selected_p == "t" } {
#  	append interest_items "<input name=category_id type=checkbox value=\"$category_id\" CHECKED> $category<br>\n"
#      } else {
#  	append interest_items "<input name=category_id type=checkbox value=\"$category_id\"> $category<br>\n"
#      }
#  }

#  if ![empty_string_p $interest_items] {
#      append page_content "
#  <h3>Your Interests (According to Us)</h3>

#  <form method=POST action=\"interests-update\">
#  <blockquote>
#  $interest_items
#  <br>
#  <br>
#  <input type=submit value=\"Update Interests\">
#  </blockquote>
#  </form>
#  "
#  }

ad_return_template

