# /packages/acs-tcl/lib/page-error.tcl 

ad_page_contract {
    
    @author Victor Guerra (guerra@galileo.edu)
    @creation-date 2005-02-03
    @arch-tag: 983f3d87-40c8-4327-8873-c6a01ba7d875
    @cvs-id $Id$
} {
    {bug_number ""}
}

set show_patch_status open
set user_agent_p 1
set error_info $stacktrace
set comment_action 0



set return_url $prev_url

if {$user_id eq 0} {
    set user_name "[_ acs-tcl.Public_User]"
    set public_userm_email [parameter::get -package_id [ad_acs_kernel_id] -parameter HostAdministrator -default ""]
} else {
    db_1row get_user_info { *SQL* }
    set public_userm_email $user_email
}

set send_email_p [parameter::get -package_id [ad_acs_kernel_id] -parameter SendErrorEmailP -default 0]
set system_name [ad_system_name]
set subject "[_ acs-tcl.lt_Error_Report_in_ad_sy] ( [_ acs-tcl.File ] $error_file )"
set found_in_version ""
set send_to [parameter::get -package_id [ad_acs_kernel_id] -parameter HostAdministrator -default "[ad_system_owner]"]

set error_desc_email "
 --------------------------------------------------------<br>
                   [_ acs-tcl.Error_Report]<br>
 --------------------------------------------------------<br>
<b>[_ acs-tcl.Previus]</b> $return_url<br>
<b>[_ acs-tcl.Page]</b> $error_url<br>
<b>[_ acs-tcl.File]</b> $error_file<br>
<b>[_ acs-tcl.User_Name]</b> $user_name<br>
<b>[_ acs-tcl.lt_User_Id_of_the_user_t]</b> $user_id<br>
<b>IP:</b> [ns_conn peeraddr]<br>
<b>[_ acs-tcl.Browser_of_the_user]</b> [ad_quotehtml [ns_set get [ns_conn headers] User-Agent]]<br>
<br>
-----------------------------<br>
[_ acs-tcl.Error_details]<br>
-----------------------------<br>
<pre>[ad_quotehtml $error_info]</pre>
<br>
------------------------------<br>
<br>
<br>
[_ acs-tcl.lt_NB_This_error_was_sub]"

if { $bug_number eq "" && $send_email_p} {
    ns_sendmail "$send_to" $public_userm_email $subject $error_desc_email
}
set bt_instance [parameter::get -package_id [ad_acs_kernel_id] \
		     -parameter BugTrackerInstance -default ""]

if { ![empty_string_p $bt_instance] } {
    array set community_info [site_node::get -url "${bt_instance}/[bug_tracker::package_key]"]
    set bt_package_id $community_info(package_id)
    set auto_submit_p [parameter::get -parameter AutoSubmitErrorsP -package_id $bt_package_id -default 0]
} else {
    set auto_submit_p 0
}

if {$auto_submit_p && $user_id > 0} {
    # Is this project using multiple versions?
    set versions_p [bug_tracker::versions_p]
    
    # Paches enabled for this project?
    set patches_p [bug_tracker::patches_p]
    
    set enabled_action_id [form get_action bug_edit]
    
    set exist_bug [db_string search_bug {} -default ""]
    if { [empty_string_p $exist_bug]} {
	
	#Submit the new Bug into the Bug - Tracker && Into the
	# Auto_bugs tabble
	set bug_id [db_nextval acs_object_id_seq]
	
	set keyword_ids [list]
        foreach {category_id category_name} [bug_tracker::category_types -package_id $bt_package_id] {
	    lappend keyword_ids [bug_tracker::get_default_keyword -parent_id $category_id -package_id $bt_package_id]
        }
		
        bug_tracker::bug::new \
	    -bug_id $bug_id \
	    -package_id $bt_package_id \
	    -component_id [bug_tracker::conn component_id] \
	    -found_in_version $found_in_version \
	    -summary $subject \
	    -description $error_desc_email \
	    -desc_format text/html \
	    -keyword_ids $keyword_ids \
	    -user_id $user_id
	
	bug_tracker::bugs_exist_p_set_true -package_id $bt_package_id
        db_dml insert_auto_bug { *SQL* }
    } else {
	
	#Comment on the Existing Bug even if the user dont want to add
	# commentaries 
	# If the bug is closed or fixed we have to reopen the bug
        array set row [list]
	set bug_id $exist_bug
	
	if {[empty_string_p $bug_number]} {
	    db_dml increase_reported_times { *SQL* }
	}
	
	# Get the bug data
	bug_tracker::bug::get -bug_id $bug_id -array bug -enabled_action_id $enabled_action_id
	
        set case_id [workflow::case::get_id \
			 -object_id $bug_id \
			 -workflow_short_name [bug_tracker::bug::workflow_short_name]]
        foreach available_enabled_action_id [workflow::case::get_available_enabled_action_ids -case_id $case_id] {
	    workflow::case::enabled_action_get -enabled_action_id $available_enabled_action_id -array enabled_action
	    workflow::action::get -action_id $enabled_action(action_id) -array available_action
	    if [string match "*Reopen*" $available_action(pretty_name)] {
		bug_tracker::bug::edit \
		    -bug_id $bug_id \
		    -enabled_action_id $available_enabled_action_id \
		    -description "<b> [_ acs-tcl.reopened_auto ] </b>" \
		    -desc_format text/html \
		    -array row \
		    -entry_id $bug(entry_id)
	    }
	    if [string match "*Comment*" $available_action(pretty_name)] {
		set comment_action $available_enabled_action_id
	    }
        }
	
	bug_tracker::bug::edit \
	    -bug_id $bug_id \
	    -enabled_action_id $comment_action \
	    -description $error_desc_email \
	    -desc_format text/html \
	    -array row \
	    -entry_id $bug(entry_id)
    }
      
    set case_id [workflow::case::get_id \
		     -object_id $bug_id \
		     -workflow_short_name [bug_tracker::bug::workflow_short_name]]
    set workflow_id [bug_tracker::bug::get_instance_workflow_id -package_id $bt_package_id]
    
#    set enabled_action_id [form get_action bug_edit]
    
    # Registration required for all actions
    set action_id ""
    #if { ![empty_string_p $enabled_action_id] } {
    #	workflow::case::enabled_action_get -enabled_action_id $enabled_action_id -array enabled_action
    #	set action_id $enabled_action(action_id)
    #    }
    
    set times_rep [db_string select_times_reported {} -default 0 ]
    
    ad_form -name bug_edit -export {comment_action reopen_action bt_instance bt_package_id user_id bug_package_id} -form {
	{bug_number_display:text(inform)
	    {label "[bug_tracker::conn Bug] \\\#"}
	    {mode display}
	}
	{component_id:integer(select),optional
	    {label "[_ bug-tracker.Component]"}
	    {options {[bug_tracker::components_get_options]}}
	    {mode display}
	}
	{summary:text(text)
	    {label "[_ bug-tracker.Summary]"}
	    {before_html "<b>"}
	    {after_html "</b>"}
	    {mode display}
	    {html {size 50}}
	}
	{pretty_state:text(inform)
	    {label "[_ bug-tracker.Status]"}
	    {before_html "<b>"}
	    {after_html  "</b>"}
	    {mode display}
	}
	{resolution:text(select),optional
	    {label "[_ bug-tracker.Resolution]"}
	    {options {[bug_tracker::resolution_get_options]}}
	    {mode display}
	}
	{previus_url:text(inform)
	    {label "[_ acs-tcl.Previus]"}
	    {value $prev_url}
	}
	{err_url:text(inform)
	    {label "[_ acs-tcl.Page]"}
	    {value $error_url}
	}
	{err_file:text(inform)
	    {label "[_ acs-tcl.File]"}
	    {value $error_file}
	}
	{times_reported:text(inform)
	{label "[_ acs-tcl.Times_reported]"}
	    {value $times_rep}
	}
    }
    
    foreach {category_id category_name} [bug_tracker::category_types] {
	ad_form -extend -name bug_edit -form [list \
						  [list "${category_id}:integer(select)" \
						       [list label $category_name] \
						       [list options [bug_tracker::category_get_options -parent_id $category_id]] \
						       [list mode display] \
						      ] \
						 ]
    }
   ad_form -extend -name bug_edit -form {
       {found_in_version:text(select),optional
	   {label "[_ bug-tracker.Found_in_Version]"}
	   {options {[bug_tracker::version_get_options -include_unknown]}}
	   {mode display}
       }
   }
    
    workflow::case::role::add_assignee_widgets -case_id $case_id -form_name bug_edit
    
    ad_form -extend -name bug_edit -form {
	{user_agent:text(inform)
	    {label "[_ bug-tracker.User_Agent]"}
	    {mode display}
	}
	{fix_for_version:text(select),optional
	    {label "[_ bug-tracker.Fix_for_Version]"}
	    {options {[bug_tracker::version_get_options -include_undecided]}}
	    {mode display}
	}
	{fixed_in_version:text(select),optional
	    {label "[_ bug-tracker.Fixed_in_Version]"}
	    {options {[bug_tracker::version_get_options -include_undecided]}}
	    {mode display}
    }
	{description:richtext(richtext),optional
	    {label "[_ bug-tracker.Description]"}
	    {html {cols 60 rows 13}}
	}
	{return_url:text(hidden)
	    {value $return_url}
	}
	{bug_number:key}
	{entry_id:integer(hidden),optional}
    } -on_submit {

	array set row [list]
	
#	if { ![empty_string_p $enabled_action_id] } {
#	    foreach field [workflow::action::get_element -action_id $action_id -element edit_fields] {
#		set row($field) [element get_value bug_edit $field]
#	    }
#	    foreach {category_id category_name} [bug_tracker::category_types] {
#		set row($category_id) [element get_value bug_edit $category_id]
#	    }
#	}
	
	set description [element get_value bug_edit description]
	set error_desc_html "
 -------------------------------------------------------- <br>
                   [_ acs-tcl.Error_Report] <br>
 -------------------------------------------------------- <br>
<br><b>[_ acs-tcl.Previus]</b> $prev_url
<br><b>[_ acs-tcl.Page]</b> $error_url
<br><b>[_ acs-tcl.File]</b> $error_file
<br><b>[_ acs-tcl.User_Name]</b> $user_name
<br><b>[_ acs-tcl.lt_User_Id_of_the_user_t]</b> $user_id
<br>[_ acs-tcl.Browser_of_the_user]</b> [ad_quotehtml [ns_set get [ns_conn headers] User-Agent]]
<br><br><b>[_ acs-tcl.User_comments]</b>  
<br>
[template::util::richtext::get_property contents $description] <br>
<br>"
 
  foreach available_enabled_action_id [workflow::case::get_available_enabled_action_ids -case_id $case_id] {
            workflow::case::enabled_action_get -enabled_action_id $available_enabled_action_id -array enabled_action
            workflow::action::get -action_id $enabled_action(action_id) -array available_action
            if [string match "*Comment*" $available_action(pretty_name)] {
                set comment_action $available_enabled_action_id
            }
        }

   
     bug_tracker::bug::edit \
            -bug_id $bug_id \
            -enabled_action_id $comment_action \
            -description [template::util::richtext::get_property contents $description] \
            -desc_format [template::util::richtext::get_property format $description] \
            -array row \
            -entry_id [element get_value bug_edit entry_id]
    
     ad_returnredirect $return_url
    ad_script_abort
   } -edit_request {
      # ID form complains if -edit_request is missing
}


if { ![form is_valid bug_edit] } {
    
    # Get the bug data
    bug_tracker::bug::get -bug_id $bug_id -array bug -enabled_action_id $enabled_action_id
    
    
    # Make list of form fields
    set element_names {
        bug_number component_id summary pretty_state resolution
        found_in_version user_agent fix_for_version fixed_in_version
        bug_number_display entry_id
    }
    
    # update the element_name list and bug array with category stuff
    foreach {category_id category_name} [bug_tracker::category_types] {
        lappend element_names $category_id
        set bug($category_id) [cr::keyword::item_get_assigned -item_id $bug(bug_id) -parent_id $category_id]
        if {[string compare $bug($category_id) ""] == 0} {
            set bug($category_id) [bug_tracker::get_default_keyword -parent_id $category_id]
        }
    }
    # Display value for patches
    set bug(patches_display) "[bug_tracker::get_patch_links -bug_id $bug(bug_id) -show_patch_status $show_patch_status] &nbsp; \[ <a href=\"patch-add?[export_vars { { bug_number $bug(bug_number) } { component_id $bug(component_id) } }]\">[_ bug-tracker.Upload_Patch]</a> \]"
    
    # Hide elements that should be hidden depending on the bug status
    foreach element $bug(hide_fields) {
        element set_properties bug_edit $element -widget hidden
    }
    
    if { !$versions_p } {
        foreach element { found_in_version fix_for_version fixed_in_version } {
            if { [info exists bug_edit:$element] } {
                element set_properties bug_edit $element -widget hidden
            }
        }
    }
    
    if { !$patches_p } {
        foreach element { patches } {
            if { [info exists bug_edit:$element] } {
                element set_properties bug_edit $element -widget hidden
            }
        }
    }
    
    # Optionally hide user agent
    if { !$user_agent_p } {
        element set_properties bug_edit user_agent -widget hidden
    }
    
    
    # Set regular element values
    foreach element $element_names {
	
        # check that the element exists
        if { [info exists bug_edit:$element] && [info exists bug($element)] } {
            if {[form is_request bug_edit]
                || [string equal [element get_property bug_edit $element mode] display] } {
                if { [string first "\#" $bug($element)] == 0 } {
                    element set_value bug_edit $element [lang::util::localize $bug($element)]
                } else {
                    element set_value bug_edit $element $bug($element)
                }
            }
        }
    }
    # Add empty option to resolution code
    if { ![empty_string_p $enabled_action_id] } {
        if { [lsearch [workflow::action::get_element -action_id $action_id -element edit_fields] "resolution"] == -1 } {
            element set_properties bug_edit resolution -options [concat {{{} {}}} [element get_property bug_edit resolution options]]
        }
    } else {
        element set_properties bug_edit resolution -widget hidden
    }

    # Get values for the role assignment widgets
    workflow::case::role::set_assignee_values -case_id $case_id -form_name bug_edit

    # Set values for elements with separate display value
    foreach element {
        patches
    } {
        # check that the element exists
        if { [info exists bug_edit:$element] } {
            element set_properties bug_edit $element -display_value $bug(${element}_display)
        }
    }

    # Set values for description field
    
    ad_form -name bug_history -has_submit 1 -form {
	{history:text(inform)
	    {label "[_ acs-tcl.User_comments]"}
	    {value ""}
	}
    }
    
    element set_properties bug_history history \
	-after_html [workflow::case::get_activity_html -case_id $case_id -action_id $action_id]
}

}    
    

