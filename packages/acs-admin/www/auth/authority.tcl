ad_page_contract {
    Page for adding and editing an authority.

    @author Peter Marklund
    @creation-date 2003-09-08
} {
    authority_id:integer,optional
    {ad_form_mode display}
}

if { [exists_and_not_null authority_id] } {
    # Initial request in display or edit mode or a submit of the form
    set page_title "One Authority"
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

set context [list [list "." "Authentication"] $page_title]

set form_widgets_full {

    authority_id:key(acs_object_id_seq)

    {short_name:text
        {html {size 50}}
        {label "Short name"}
        {help_text "This is a string which can be used to identify this authority. Use lower-case, and no spaces."}
    }

    {pretty_name:text
        {html {size 50}}
        {label "Pretty name"}
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

    {help_contact_text:text(textarea),optional
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

ad_form -name authority_form \
        -mode $ad_form_mode \
        -form $form_widgets \
        -edit_request {

    auth::authority::get -authority_id $authority_id -array element_array

    foreach element_name [array names element_array] {
        set $element_name $element_array($element_name)
    }

} -new_data {

    foreach var_name [template::form::get_elements -no_api authority_form] {
            set element_array($var_name) [set $var_name]
    }

    set element_array(sort_order) ""

    auth::authority::create \
        -authority_id $authority_id \
        -array element_array

} -edit_data {

    foreach var_name [template::form::get_elements -no_api authority_form] {
        if { ![string equal $var_name "authority_id"] } {
            set element_array($var_name) [set $var_name]
        }
    }

    auth::authority::edit \
        -authority_id $authority_id \
        -array element_array
} 

# Show recent batch jobs for existing authorities
set display_batch_history_p [expr $authority_exists_p && [string equal $ad_form_mode "display"]]
if { $display_batch_history_p } {
    
    list::create \
        -name batch_jobs \
        -multirow batch_jobs \
        -key job_id \
        -elements {
            job_id {
                label "Job ID"
                link_url_eval {$job_url}
            }
            pretty_start_time {
                label "Start time"
            }
            pretty_end_time {
                label "End time"
            }            
            num_actions {
                label "Number of actions"
            }
            num_problems {
                label "Number of problems"
            }
        }

    db_multirow -extend { job_url } batch_jobs select_batch_jobs {
        select job_id,
               to_char(job_start_time, 'YYYY-MM-DD HH24:MI:SS') as pretty_start_time,
               to_char(job_end_time, 'YYYY-MM-DD HH24:MI:SS') as pretty_end_time,
               snapshot_p,
               (select count(e1.entry_id)
                from   auth_batch_job_entries e1
                where  e1.job_id = auth_batch_jobs.job_id) as num_actions,
                (select count(e2.entry_id)
                 from   auth_batch_job_entries e2
                 where  e2.job_id = auth_batch_jobs.job_id
                 and    e2.success_p = 'f') as num_problems
        from auth_batch_jobs
        where authority_id = :authority_id
    } {
        set job_url [export_vars -base batch-job { job_id }]
    }
}
