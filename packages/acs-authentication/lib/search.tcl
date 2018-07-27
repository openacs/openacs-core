ad_page_contract {
    Includable page to search users in any authority
    
    To grant permission on an object
    Including page can pass in 
    add_permissions (list of Label, URL)
    object_id
    privilege

    OR
    To add a member of a group
    add_to_subsite (list of label url)
    add_to_main_site (optional) (list of label url)
    group_id (optional default to subsite application group)
    rel_type (default to membership_rel)

} {
    {search_text ""}
    {authority_id:naturalnum,notnull ""}
    orderby:token,optional
}

set authority_options [auth::authority::get_authority_options]
set default_authority_id [lindex $authority_options 0 1]
if {$authority_id eq ""} {
    set authority_id $default_authority_id
}

if {![info exists rel_type] || $rel_type eq ""} {
    set rel_type membership_rel
} 
if {![info exists package_id] || $package_id eq ""} {
    set package_id [ad_conn subsite_id]
}

if {![info exists return_url] || $return_url eq ""} {
    set return_url [ad_return_url]
}
set selected_authority_id $authority_id

set bulk_actions [list]
# we need a base url for adding a user to the site (main subsite or dotlrn, etc...)
if {[info exists add_to_main_site]} {
    foreach elm $add_to_main_site {
	lappend bulk_actions $elm
    }
}

# we need a base url for adding a user to a specific community (subsite or dotlrn class instance etc...) (optional)
if {[info exists add_to_subsite]} {
    foreach elm $add_to_subsite {
	lappend bulk_actions $elm
    }
} 
if {[info exists add_to_subsite] && [llength $add_to_subsite]} {
   set add_user_url [lindex $add_to_subsite 1]
    set add_user_label [lindex $add_to_subsite 0]
} elseif {[info exists add_to_main_site]} {
    set add_user_url [lindex $add_to_main_site 1]
    set add_user_label "[_ acs-authentication.Add_to_system_name [list system_name [ad_system_name]]]"
}
if {[info exists add_permission] && [llength $add_permission]} {
    set add_user_url [lindex $add_permission 1]
    set add_user_label [lindex $add_permission 0]
    lappend bulk_actions $add_user_label $add_user_url $add_user_label
}
if {![regexp {\?} $add_user_url]} {
    set add_user_url "$add_user_url?"
}
if {![info exists group_id] || $group_id eq ""} {
    set group_id [application_group::group_id_from_package_id -package_id $package_id]
}
# generate authority links

template::multirow create users \
    first last username email auth_status group_member_p create_account_url actions extra_attributes user_id authority_id

ns_log debug "MEMBER SEARCH TCL level='[template::adp_level]' [uplevel \#[template::adp_level] "info vars"]"

 template::list::create \
    -no_data "Search returned no results" \
    -name users \
    -multirow users \
    -key userkey \
    -has_checkboxes \
    -bulk_action_export_vars { authority_id return_url object_id group_id } \
    -filters {search_text {} authority_id {} object_id {}} \
    -elements [list \
     checkbox {
	 display_template {<if @users.first@ not nil and @users.last@ not nil and @users.email@ not nil and @users.group_member_p@ false><input type="checkbox" name="userkey" value="@users.username@ @users.authority_id@" /></if>}} \
		   first [list label "First Name" link_url_eval "\[export_vars -base \"$member_url\" {user_id} \]"] \
		   last [list label "Last Name"  link_url_eval "\[export_vars -base \"$member_url\" {user_id} \]"] \
		   username [list label "Username" link_url_eval "\[export_vars -base \"$member_url\" {user_id} \]"] \
		   email {label "Email"} \
		   auth_status { label "Status" } \
		   actions [list label "Actions" display_template [subst {
		       <if @users.first@ not nil and @users.last@ not nil and @users.email@ not nil
		       and @users.group_member_p@ false><a href="[ns_quotehtml ${add_user_url}&userkey=@users.username@+@users.authority_id@&authority_id=${authority_id}&return_url=[ad_urlencode ${return_url}]&group_id=$group_id]" class=button>$add_user_label</a></if>
		   }]] \
		   extra_attributes {label "Extra Attributes"} \
		   user_id [list hide_p [expr {!$admin_p}] label "" display_template [subst {
		       <if @users.user_id@ not nil><a href="[ns_quotehtml $member_admin_url?user_id=@users.user_id@]">User Admin Page</a></if>
		   }]] \
		  ] -bulk_actions $bulk_actions \
    -orderby {
	first {orderby first_names}
	last {orderby last_name}
	username {orderby username}
	email {orderby email}
	auth_status {orderby auth_status}
    }

template::multirow create authorities authority_id pretty_name local_authority_p search_url form_include

foreach option_list [auth::authority::get_authority_options] {
    set this_authority_id [lindex $option_list 1]
    set local_authority_p [string match $this_authority_id [auth::authority::local]]
    if {$local_authority_p} {
	set local_authority_id $this_authority_id
	set form_include /packages/acs-authentication/lib/local-search
    } else {
	set form_include [acs_sc::invoke \
			      -impl_id [auth::authority::get_element -authority_id $this_authority_id -element search_impl_id] \
			      -operation FormInclude]
    }
    if {$this_authority_id eq $selected_authority_id} {
	set selected_form_include $form_include
    }
    template::multirow append authorities \
	$this_authority_id \
	[lindex $option_list 0] \
	$local_authority_p \
	[export_vars -base [ad_conn url] -no_empty {{authority_id $this_authority_id} search_text object_id}] \
	$form_include
}

#template::multirow sort authorities -decreasing authority_id

if {$selected_authority_id eq ""} {
    set selected_authority_id $default_authority_id
}
set authority_id $selected_authority_id

#set search_form_html [template::adp_include $selected_form_include [list authority_id $selected_authority_id search_text $search_text return_url $return_url orderby $orderby]]

#<include src="@authorities.form_include@" authority_id="@authorities.authority_id@" search_text="@search_text@" return_url="@return_url@" orderby="@orderby@">
if {![info exists orderby]} {
    set orderby ""
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
