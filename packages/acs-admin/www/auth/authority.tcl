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
    }        

    {enabled_p:text(radio)
        {label "Enabled"}
        {options {{Yes t} {No f}}}
        {value t}
    }

    {auth_impl_id:integer(select),optional
        {label "Authentication implementation"}
        {options {[acs_sc::impl::get_options -exclude_names local -empty_option -contract_name auth_authentication]}}
    }

    {pwd_impl_id:integer(select),optional
        {label "Password implementation"}
        {options {[acs_sc::impl::get_options -exclude_names local -empty_option -contract_name auth_password]}}
    }

    {register_impl_id:integer(select),optional
        {label "Register implementation"}
        {options {[acs_sc::impl::get_options -exclude_names local -empty_option -contract_name auth_registration]}}
    }

    {forgotten_pwd_url:text,optional
        {html {size 50}}
        {label "Forgotten password URL"}
        {help_text "URL that users are sent to when they have forgotten their password. Any username in this url must be on the syntax foo={username} and {username} will be replaced with the real username"}
    }        
    {change_pwd_url:text,optional
        {html {size 50}}
        {label "Change password URL"}
        {help_text "URL where users can change their password. Any username in this url must be on the syntax foo={username} and {username} will be replaced with the real username"}
    }        
    {register_url:text,optional
        {html {size 50}}
        {label "Register URL"}
        {help_text "URL where users register for a new account."}
    }        

    {help_contact_text:richtext,optional
        {html {cols 60 rows 13}} 
        {label "Help contact text"}
        {help_text "Contact information (phone, email, etc.) to be displayed as a last resort when people are having problems with an authority."}
    }        

    {batch_sync_enabled_p:text(radio)
        {label "Batch sync enabled"}
        {options {{Yes t} {No f}}}
        {value f}
        {section {Batch Synchronization}}
    }

    {snapshot_p:text(radio)
        {label "Use snapshot synchronization?"}
        {options {{Yes t} {No f}}}
        {value f}
    }

    {get_doc_impl_id:integer(select),optional
        {label "GetDocument implementation"}
        {options {[acs_sc::impl::get_options -empty_option -contract_name auth_getdoc]}}
    }

    {process_doc_impl_id:integer(select),optional
        {label "ProcessDocument implementation"}
        {options {[acs_sc::impl::get_options -empty_option -contract_name auth_processdoc]}}
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
        -edit_request {

    auth::authority::get -authority_id $authority_id -array element_array

    set page_title $element_array(pretty_name)

    foreach element_name [array names element_array] {
        set $element_name $element_array($element_name)
    }
    
    if { !$local_authority_p } {
        set help_contact_text [template::util::richtext::create]
        set help_contact_text [template::util::richtext::set_property contents $help_contact_text $element_array(help_contact_text)]

        if { [empty_string_p $element_array(help_contact_text_format)] } {
            set element_array(help_contact_text_format) "text/enhanced"
        }

        set help_contact_text [template::util::richtext::set_property format $help_contact_text  $element_array(help_contact_text_format)]
        
        # Parameter links for implementations
        foreach element_name [auth::authority::get_sc_impl_columns] {
            # Only offer link if there is an implementation chosen
            if { [exists_and_not_null element_array($element_name)] } {
                set old_label [element get_property authority $element_name label]
                set configure_url [export_vars -base authority-parameters { authority_id {column_name $element_name}}]
                element set_properties authority $element_name -label "$old_label <a href=\"$configure_url\">set parameters</a>"
            }
        }
    }

} -new_data {

    foreach var_name [template::form::get_elements -no_api authority] {
            set element_array($var_name) [set $var_name]
    }

    set element_array(sort_order) ""
    set element_array(short_name) ""

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
    }

    auth::authority::edit \
        -authority_id $authority_id \
        -array element_array
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
        num_actions {
            label "Actions"
            html { align right }
        }
        num_problems {
            label "Problems"
            html { align right }
        }
        interactive_pretty {
            label "Interactive"
            html { align center }
        }
    }

set display_batch_history_p [expr $authority_exists_p && [string equal $ad_form_mode "display"]]
if { $display_batch_history_p } {
    
    db_multirow -extend { job_url start_time_pretty end_time_pretty interactive_pretty } batch_jobs select_batch_jobs {
        select job_id,
               to_char(job_start_time, 'YYYY-MM-DD HH24:MI:SS') as start_time_ansi,
               to_char(job_end_time, 'YYYY-MM-DD HH24:MI:SS') as end_time_ansi,
               snapshot_p,
               (select count(e1.entry_id)
                from   auth_batch_job_entries e1
                where  e1.job_id = auth_batch_jobs.job_id) as num_actions,
                (select count(e2.entry_id)
                 from   auth_batch_job_entries e2
                 where  e2.job_id = auth_batch_jobs.job_id
                 and    e2.success_p = 'f') as num_problems,
               interactive_p
        from auth_batch_jobs
        where authority_id = :authority_id
    } {
        set job_url [export_vars -base batch-job { job_id }]

        set start_time_pretty [lc_time_fmt $start_time_ansi "%x %X"]
        set end_time_pretty [lc_time_fmt $end_time_ansi "%x %X"]

        set interactive_pretty [ad_decode $interactive_p "t" "Yes" "No"]
    }
}

set context [list [list "." "Authentication"] $page_title]

set batch_sync_run_url [export_vars -base batch-job-run { authority_id }]

if { $authority_exists_p && !$local_authority_p && [empty_string_p [element get_property authority help_contact_text value]] } {
    error hello
    # TODO: Ask Lars how we can avoid the problem with the empty format field
    # without this kludge
    set help_contact_text [template::util::richtext::create]
    set help_contact_text [template::util::richtext::set_property format $help_contact_text "text/enhanced"]

    element set_properties authority help_contact_text -value $help_contact_text
}