ad_page_contract {
    Page for adding and editing an authority.

    @author Peter Marklund
    @creation-date 2003-09-08
} {
    authority_id:naturalnum,optional
    {ad_form_mode display}
}

set page_title ""
if { [info exists authority_id] && $authority_id ne "" } {
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

    {-section "gen" {legendtext \#acs-admin.General\#}}
    {pretty_name:text
        {html {size 50}}
        {label "\#acs-admin.Name\#"}
    }

    {short_name:text,optional
        {html {size 50}}
        {label "\#acs-admin.Short_Name\#"}
        {mode {[ad_decode $local_authority_p 1 "display" ""]}}
        {help_text "[_ acs-admin.Authority_short_name_help_text]"}
    }

    {enabled_p:text(radio)
        {label "\#acs-admin.Enabled\#"}
        {options {{[_ acs-admin.Yes] t} {[_ acs-admin.No] f}}}
    }

    {help_contact_text:richtext,optional
        {html {cols 60 rows 13}}
        {label "\#acs-admin.Help_contact_text\#"}
        {help_text "[_ acs-admin.Help_contact_help_text]"}
    }

    {-section "auth" {legendtext \#acs-admin.Authentication\#}}

    {auth_impl_id:integer(select),optional
        {label "\#acs-admin.Authentication\#"}
        {options {[acs_sc::impl::get_options -empty_label "--Disabled--" -contract_name auth_authentication]}}
    }

    {-section "pwmngt" {legendtext \#acs-admin.Password_Management\#}}

    {pwd_impl_id:integer(select),optional
        {label "\#acs-admin.Password_Management\#"}
        {options {[acs_sc::impl::get_options -empty_label "--Disabled--" -contract_name auth_password]}}
    }

    {forgotten_pwd_url:text,optional
        {html {size 50}}
        {label "\#acs-admin.Recover_password_URL\#"}
        {help_text "[_ acs-admin.Recover_password_URL_help_text]"}
    }
    {change_pwd_url:text,optional
        {html {size 50}}
        {label "\#acs-admin.Change_password_URL\#"}
        {help_text "[_ acs-admin.Change_password_URL_help_text]"}
    }

    {-section "accreg" {legendtext \#acs-admin.Account_Registration\#}}

    {register_impl_id:integer(select),optional
        {label "\#acs-admin.Account_Registration\#"}
        {options {[acs_sc::impl::get_options -empty_label "--Disabled--" -contract_name auth_registration]}}
    }

    {register_url:text,optional
        {html {size 50}}
        {label "\#acs-admin.Account_registration_URL\#"}
        {help_text "[_ acs-admin.Account_reg_URL_help_text]"}
    }

    {-section "ondemsyn" {legendtext \#acs-admin.On-Demand_Sync\#}}

    {user_info_impl_id:integer(select),optional
        {label "\#acs-admin.User_Info\#"}
        {options {[acs_sc::impl::get_options -empty_label "--Disabled--" -contract_name auth_user_info]}}
        {help_text "[_ acs-admin.User_Info_help_text]"}
    }

    {-section "batchsyn" {legendtext \#acs-admin.Batch_Synchronization\#}}

    {batch_sync_enabled_p:text(radio)
        {label "\#acs-admin.Batch_sync_enabled\#"}
        {options {{[_ acs-admin.Yes] t} {[_ acs-admin.No] f}}}
    }

    {get_doc_impl_id:integer(select),optional
        {label "\#acs-admin.GetDocument_implementation\#"}
        {options {[acs_sc::impl::get_options -empty_label "--Disabled--" -contract_name auth_sync_retrieve]}}
    }

    {process_doc_impl_id:integer(select),optional
        {label "\#acs-admin.ProcessDocument_implementation\#"}
        {options {[acs_sc::impl::get_options -empty_label "--Disabled--" -contract_name auth_sync_process]}}
    }
}

# For the local authority we allow only limited editing
# Is this the local authority?
set local_authority_p 0
if { $authority_exists_p && $authority_id eq [auth::authority::local] } {
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

        if {$element_name in $local_editable_elements} {
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
        set help_contact_text [template::util::richtext::set_property contents $help_contact_text \
                                   $element_array(help_contact_text)]
        if { $element_array(help_contact_text_format) eq "" } {
            set element_array(help_contact_text_format) "text/enhanced"
        }
        set help_contact_text_format [template::util::richtext::set_property format $help_contact_text \
                                          $element_array(help_contact_text_format)]
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
        if { $var_name ne "authority_id" } {
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
    ad_script_abort
}

# Show recent batch jobs for existing authorities

list::create \
    -name batch_jobs \
    -multirow batch_jobs \
    -key job_id \
    -elements {
        start_time_pretty {
            label "\#acs-admin.Start_time\#"
            link_url_eval {$job_url}
        }
        end_time_pretty {
            label "\#acs-admin.End_time\#"
        }
        run_time {
            label "\#acs-admin.Run_time\#"
            html { align right }
        }
        num_actions {
            label "\#acs-admin.Actions\#"
            html { align right }
        }
        num_problems {
            label "\#acs-admin.Problems\#"
            html { align right }
        }
        actions_per_minute {
            label "\#acs-admin.Actions_Minute\#"
            html { align right }
        }
        short_message {
            label "\#acs-admin.Message\#"
        }
        interactive_pretty {
            label "\#acs-admin.Interactive\#"
            html { align center }
        }
    }

set display_batch_history_p [expr {$authority_exists_p && $ad_form_mode eq "display"}]
if { $display_batch_history_p } {

    set yes [_ acs-kernel.common_Yes]
    set no  [_ acs-kernel.common_No]

    db_multirow -extend {
        job_url
        start_time_pretty
        end_time_pretty
        interactive_pretty
        short_message
        actions_per_minute
        run_time
        run_time_seconds
    } batch_jobs select_batch_jobs {
        select job_id,
               to_char(job_start_time, 'YYYY-MM-DD HH24:MI:SS') as start_time_ansi,
               to_char(job_end_time, 'YYYY-MM-DD HH24:MI:SS') as end_time_ansi,
               snapshot_p,
               (select count(*) from auth_batch_job_entries
                where job_id = auth_batch_jobs.job_id) as num_actions,
               (select count(*) from auth_batch_job_entries
                 where job_id = auth_batch_jobs.job_id
                   and not success_p) as num_problems,
               interactive_p,
               message
        from   auth_batch_jobs
        where  authority_id = :authority_id
                order by start_time_ansi
    } {
        set run_time_seconds [expr {[clock scan $end_time_ansi -format "%Y-%m-%d %H:%M:%S"] -
                                    [clock scan $start_time_ansi -format "%Y-%m-%d %H:%M:%S"]}]

        set job_url [export_vars -base batch-job { job_id }]

        set start_time_pretty [lc_time_fmt $start_time_ansi "%x %X"]
        set end_time_pretty [lc_time_fmt $end_time_ansi "%x %X"]

        set interactive_pretty [expr {$interactive_p eq "t" ? $yes : $no}]
        set short_message [string_truncate -len 30 -- $message]

        set actions_per_minute {}
        if { $run_time_seconds > 0 && $num_actions > 0 } {
            set actions_per_minute [expr {round(60.0 * $num_actions / $run_time_seconds)}]
        }
        set run_time [util::interval_pretty -seconds $run_time_seconds]
    }
    if { [info exists get_doc_impl_id] && $get_doc_impl_id ne ""
         && [info exists process_doc_impl_id] && $process_doc_impl_id ne "" } {
        set batch_sync_run_url [export_vars -base batch-job-run { authority_id }]
        template::add_confirm_handler \
            -id batch-sync-run \
            -message "Are you sure you want to run a batch job to sync the user database now?"
    } else {
        # If there's neither a driver, nor any log history to display, hide any mention of batch jobs
        if { ${batch_jobs:rowcount} == 0 } {
            set display_batch_history_p 0
        }
    }
}

set context [list [list "." "Authentication"] $page_title]

if { [info exists authority_id] && $authority_id ne "" } {
    set num_users [lc_numeric [db_string num_users_in_auhtority {
        select count(*) from users where authority_id = :authority_id
    }]]
} else {
    set num_users 0
}
set show_users_url [export_vars -base ../users/complex-search { authority_id { target one } }]


# This code should be executed for non-local authorities in the following types of requests:
# - initial request of the form (display mode)
# - The form is being submitted (display mode)
set initial_request_p [expr {[form get_action authority] eq ""}]
set submit_p [form is_valid authority]
if { ($initial_request_p || $submit_p) && !$local_authority_p } {

    # Add parameter links for implementations in display mode
    foreach element_name [auth::authority::get_sc_impl_columns] {
        # Only offer link if there is an implementation chosen and that implementation has
        # parameters to configure
        if { [info exists element_array($element_name)] && $element_array($element_name) ne ""
             && [auth::driver::get_parameters -impl_id $element_array($element_name)] ne ""
         } {
            set configure_url [export_vars -base authority-parameters { authority_id }]
            break
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
