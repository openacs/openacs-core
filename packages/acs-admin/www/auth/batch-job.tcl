ad_page_contract {
    Page displaying info about a single batch job.

    @author Peter Marklund
    @creation-date 2003-09-09
} {
    job_id
    page:optional
    success_p:boolean,optional
}

auth::sync::job::get -job_id $job_id -array batch_job

set page_title "One batch job"
set context [list \
                 [list "." "Authentication"] \
                 [list [export_vars -base authority { {authority_id $batch_job(authority_id)} }] "$batch_job(authority_pretty_name)"] $page_title]

ad_form \
    -name batch_job_form \
    -mode display \
    -display_buttons {} \
    -form {
        {authority_pretty_name:text(inform)
            {label "Authority name"}                
        }            
        {job_start_time:text(inform)
            {label "Start time"}                
        }
        {job_end_time:text(inform)
            {label "End time"}                
        }
        {run_time_seconds:text(inform)
            {label "Running time"}
            {after_html " seconds"}
        }
        {interactive_p:text(inform)
            {label "Interactive"}
        }
        {snapshot_p:text(inform)
            {label "Snapshot"}                
        }            
        {message:text(inform)
            {label "Message"}                
        }            
        {creation_user:text(inform)
            {label "Creation user"}                
        }            
        {doc_start_time:text(inform)
            {label "Document start time"}
        }            
        {doc_end_time:text(inform)
            {label "Document end time"}                
        }            
        {doc_status:text(inform)
            {label "Document status"}                
        }            
        {doc_message:text(inform)
            {label "Document message"}                
        }            
        {document_download:text(inform)
            {label "Document"}
        }
        {num_actions:text(inform)
            {label "Number of actions"}
        }
        {num_problems:text(inform)
            {label "Number of problems"}
        }
    } -on_request {
        foreach element_name [array names batch_job] {
            # Make certain columns pretty for display
            if { [regexp {_p$} $element_name] } {
                set $element_name [ad_decode $batch_job($element_name) "t" "Yes" "No"]
            } elseif { [string equal $element_name "creation_user"] && ![empty_string_p $batch_job($element_name)] } {
                set $element_name [acs_community_member_link -user_id $batch_job($element_name)]
            } else {
                set $element_name [ad_quotehtml $batch_job($element_name)]
            }               
        }

        set job_start_time [lc_time_fmt $batch_job(job_start_time) "%x %X"]
        set job_end_time [lc_time_fmt $batch_job(job_end_time) "%x %X"]

        set document_download "<a href=\"[export_vars -base batch-document-download { job_id }]\">download</a>"
    }

list::create \
    -name batch_actions \
    -multirow batch_actions \
    -key entry_id \
    -page_size 100 \
    -page_query_name pagination \
    -elements {
        entry_time_pretty {
            label "Timestamp"
            link_url_eval {$entry_url}
            link_html { title "View log entry" }
        }
        operation {
            label "Operation"
        }
        username {
            label "Username"
            link_url_col user_url
        }
        success_p {
            label "Success"
            display_template {
                <if @batch_actions.success_p@ eq "t">
                  <font color="green">Yes</font>
                </if>
                <else>
                  <font color="red">No</font>
                </else>
            }
        }
        short_message {
            label "Message"
        }
    } -filters {
        job_id {
            hide_p 1
        }
        success_p {
            label "Success"
            values {
                { Success t }
                { Failure f }
            }
            where_clause {
                success_p = :success_p
            }
            default_value f
        }
    }

db_multirow -extend { entry_url short_message entry_time_pretty user_url } batch_actions select_batch_actions "
    select entry_id,
           to_char(entry_time, 'YYYY-MM-DD HH24:MI:SS') as entry_time_ansi,
           operation,
           username,
           user_id,
           success_p,
           message,
           element_messages,
           (select count(*) from users u2 where u2.user_id = user_id) as user_exists_p
    from   auth_batch_job_entries
    where  [template::list::page_where_clause -name batch_actions]
    [template::list::filter_where_clauses -and -name batch_actions]
    order  by entry_id
" {
    set entry_url [export_vars -base batch-action { entry_id }]
    
    # Use message and element_messages to display one short message in the table
    if { ![empty_string_p $message] } {
        set short_message $message
    } elseif { [llength $element_messages] == 2 } {
        # Only one element message - use it
        set short_message $element_messages
    } elseif { [llength $element_messages] > 0 } {
        # Several element messages
        set short_message "Problems with elements"
    } else {
        set short_message ""
    }
    set short_message [string_truncate -len 75 -- $short_message]

    if { $user_exists_p && ![empty_string_p $user_id]  } {
        set user_url [acs_community_member_admin_url -user_id $user_id]
    } else {
        set user_url {}
    }

    
    set entry_time_pretty [lc_time_fmt $entry_time_ansi "%x %X"]
}
