ad_page_contract {
    Page for adding and editing an authority.

    @author Peter Marklund
    @creation-date 2003-09-08
} {
    authority_id:integer,optional
    {ad_form_mode display}
}

set page_title ""
if { [exists_and_not_null authority_id] } {
    # Initial request in display or edit mode or a submit of the form
    set authority_exists_p [db_string authority_exists_p {
        select count(*)
        from auth_authorities
        where authority_id = :authority_id
    }]
} else {
    # Initial request in add mode
    set page_title "New Authority"
    set ad_form_mode edit
    set authority_exists_p 0
}

set form_widgets_full {

    authority_id:key(acs_object_id_seq)

    {pretty_name:text
        {html {size 50}}
        {label "Name"}
        {section "General"}
    }        

    {short_name:text,optional
        {html {size 50}}
        {label "Short Name"}
        {mode {[ad_decode $local_authority_p 1 "display" ""]}}
        {help_text "This is used when referring to the authority in parameters etc. Even if you need to change the display name above, this should stay unchanged."}
    }        

    {enabled_p:text(radio)
        {label "Enabled"}
        {options {{Yes t} {No f}}}
    }

    {help_contact_text:richtext,optional
        {html {cols 60 rows 13}} 
        {label "Help contact text"}
        {help_text "Contact information (phone, email, etc.) to be displayed as a last resort when people are having problems with an authority."}
    }        
    {auth_impl_id:integer(select),optional
        {label "Authentication"}
        {section "Authentication"}
        {options {[acs_sc::impl::get_options -empty_label "--Disabled--" -contract_name auth_authentication]}}
    }

    {pwd_impl_id:integer(select),optional
        {label "Password management"}
        {section "Password Management"}
        {options {[acs_sc::impl::get_options -empty_label "--Disabled--" -contract_name auth_password]}}
    }

    {forgotten_pwd_url:text,optional
        {html {size 50}}
        {label "Recover password URL"}
        {help_text "Instead of a password management driver, you may provide a URL to which users are sent when they need help recovering their password. Any username in this url must be on the syntax foo={username} and {username} will be replaced with the real username."}
    }        
    {change_pwd_url:text,optional
        {html {size 50}}
        {label "Change password URL"}
        {help_text "Instead of a password management driver, you may provide a URL to which users are sent when they want to change their password. Any username in this url must be on the syntax foo={username} and {username} will be replaced with the real username."}
    }        

    {register_impl_id:integer(select),optional
        {label "Account registration"}
        {section "Account Registration"}
        {options {[acs_sc::impl::get_options -empty_label "--Disabled--" -contract_name auth_registration]}}
    }

    {register_url:text,optional
        {html {size 50}}
        {label "Account registration URL"}
        {help_text "URL where users register for a new account."}
    }        

    {user_info_impl_id:integer(select),optional
        {label "User Info"}
        {section "On-Demand Sync"}
        {options {[acs_sc::impl::get_options -empty_label "--Disabled--" -contract_name auth_user_info]}}
        {help_text "The implementation for getting user information from the authority in real-time"}
    }

    {batch_sync_enabled_p:text(radio)
        {label "Batch sync enabled"}
        {options {{Yes t} {No f}}}
        {section {Batch Synchronization}}
    }

    {get_doc_impl_id:integer(select),optional
        {label "GetDocument implementation"}
        {options {[acs_sc::impl::get_options -empty_label "--Disabled--" -contract_name auth_sync_retrieve]}}
    }

    {process_doc_impl_id:integer(select),optional
        {label "ProcessDocument implementation"}
        {options {[acs_sc::impl::get_options -empty_label "--Disabled--" -contract_name auth_sync_process]}}
    }
}

# For the local authority we allow only limited editing
# Is this the local authority?
set local_authority_p 0
if { $authority_exists_p && [string equal $authority_id [auth::authority::local]] } {
    set local_authority_p 1
}

if { $local_authority_p } {
    # Local authority
    # The form elements we use for local authority
    set local_editable_elements {
        authority_id
        pretty_name
        short_name
        forgotten_pwd_url
        change_pwd_url
        register_url
    }

    foreach element $form_widgets_full {
        regexp {^[a-zA-Z_]+} [lindex $element 0] element_name

        if { [lsearch -exact $local_editable_elements $element_name] != -1 } {
            lappend form_widgets $element
        }
    }
} else {
    # Not local authority - use full form
    set form_widgets $form_widgets_full
}

ad_form -name authority \
    -mode $ad_form_mode \
    -form $form_widgets \
    -cancel_url "." \
    -new_request {
        set enabled_p t
        set batch_sync_enabled_p f
    } \
    -edit_request {
            
    auth::authority::get -authority_id $authority_id -array element_array

    set page_title $element_array(pretty_name)

    foreach element_name [array names element_array] {
        set $element_name $element_array($element_name)
    }

    if { !$local_authority_p } {
        # Set the value of the help_contact_text element - both contents and format attributes
        set help_contact_text [template::util::richtext::create]
        set help_contact_text [template::util::richtext::set_property contents $help_contact_text $element_array(help_contact_text)]
        if { [empty_string_p $element_array(help_contact_text_format)] } {
            set element_array(help_contact_text_format) "text/enhanced"
        }
        set help_contact_text [template::util::richtext::set_property format $help_contact_text  $element_array(help_contact_text_format)]     
    }

} -new_data {

    set page_title $pretty_name

    foreach var_name [template::form::get_elements -no_api authority] {
        set element_array($var_name) [set $var_name]
    }

    set element_array(sort_order) ""

    if { !$local_authority_p } {
        set element_array(help_contact_text) [template::util::richtext::get_property contents $help_contact_text]
        set element_array(help_contact_text_format) [template::util::richtext::get_property format $help_contact_text]
    }

    auth::authority::create \
        -authority_id $authority_id \
        -array element_array

} -edit_data {

    foreach var_name [template::form::get_elements -no_api authority] {
        if { ![string equal $var_name "authority_id"] } {
            set element_array($var_name) [set $var_name]
        }
    }

    if { !$local_authority_p } {
        set element_array(help_contact_text) [template::util::richtext::get_property contents $help_contact_text]
        set element_array(help_contact_text_format) [template::util::richtext::get_property format $help_contact_text]
        if { [info exists element_array(short_name)] } {
            unset element_array(short_name)
        }
    }

    auth::authority::edit \
        -authority_id $authority_id \
        -array element_array
} -after_submit {
    ad_returnredirect [export_vars -base [ad_conn url] { authority_id }]
}

# Show recent batch jobs for existing authorities

list::create \
    -name batch_jobs \
    -multirow batch_jobs \
    -key job_id \
    -elements {
        start_time_pretty {
            label "Start time"
            link_url_eval {$job_url}
        }
        end_time_pretty {
            label "End time"
        }            
        run_time {
            label "Run time"
            html { align right }
        }
        num_actions {
            label "Actions"
            html { align right }
        }
        num_problems {
            label "Problems"
            html { align right }
        }
        actions_per_minute {
            label "Actions/Minute"
            html { align right }
        }
        short_message {
            label "Message"
        }
        interactive_pretty {
            label "Interactive"
            html { align center }
        }
    }

set display_batch_history_p [expr $authority_exists_p && [string equal $ad_form_mode "display"]]
if { $display_batch_history_p } {
    
    db_multirow -extend { 
        job_url 
        start_time_pretty
        end_time_pretty
        interactive_pretty 
        short_message 
        actions_per_minute
        run_time
    } batch_jobs select_batch_jobs {} {
        set job_url [export_vars -base batch-job { job_id }]

        set start_time_pretty [lc_time_fmt $start_time_ansi "%x %X"]
        set end_time_pretty [lc_time_fmt $end_time_ansi "%x %X"]

        set interactive_pretty [ad_decode $interactive_p "t" "Yes" "No"]
        
        set short_message [string_truncate -len 30 -- $message]

        set actions_per_minute {}
        if { $run_time_seconds > 0 && $num_actions > 0 } {
            set actions_per_minute [expr round(60.0 * $num_actions / $run_time_seconds)]
        }
        set run_time [util::interval_pretty -seconds $run_time_seconds]
    }
    if { [exists_and_not_null get_doc_impl_id] && [exists_and_not_null process_doc_impl_id] } {
        set batch_sync_run_url [export_vars -base batch-job-run { authority_id }]
    } else {
        # If there's neither a driver, nor any log history to display, hide any mention of batch jobs
        if { ${batch_jobs:rowcount} == 0 } {
            set display_batch_history_p 0
        }
    }
}

set context [list [list "." "Authentication"] $page_title]

if { [exists_and_not_null authority_id] } {
    set num_users [lc_numeric [db_string num_users_in_auhtority { select count(*) from users where authority_id = :authority_id }]]
} else {
    set num_users 0
}
set show_users_url [export_vars -base ../users/complex-search { authority_id { target one } }]


# This code should be executed for non-local authorities in the following types of requests:
# - initial request of the form (display mode)
# - The form is being submitted (display mode)
set initial_request_p [empty_string_p [form get_action authority]]
set submit_p [form is_valid authority]
if { ($initial_request_p || $submit_p) && !$local_authority_p } {

    # Add parameter links for implementations in display mode
    foreach element_name [auth::authority::get_sc_impl_columns] {
        # Only offer link if there is an implementation chosen and that implementation has
        # parameters to configure
        if { [exists_and_not_null element_array($element_name)] && 
             ![empty_string_p [auth::driver::get_parameters -impl_id $element_array($element_name)]]} {
            
            set configure_url [export_vars -base authority-parameters { authority_id }]
            break
        }
    }    
}
