ad_page_contract {
    Page displaying info about a single batch job.

    @author Peter Marklund
    @creation-date 2003-09-09
} {
    job_id
    page:optional
}

auth::sync::job::get -job_id $job_id -array batch_job

set page_title "Batch Job \"$batch_job(job_id)\""
set context [list [list "." "Authentication"] [list [export_vars -base authority { {authority_id $batch_job(authority_id)} }] "Authority \"$batch_job(authority_pretty_name)\""] $page_title]

ad_form -name batch_job_form \
        -mode display \
        -display_buttons {} \
        -form {
            {job_id:text(inform)
                {label "Job ID"}                
            }
            {authority_pretty_name:text(inform)
                {label "Authority name"}                
            }            
            {job_start_time:text(inform)
                {label "Start time"}                
            }
            {job_end_time:text(inform)
                {label "End time"}                
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
            {run_time_seconds:text(inform)
                {label "Runtime seconds"}
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
                    set $element_name $batch_job($element_name)
                }               
            }

            set document_download "<a href=\"[export_vars -base batch-document-download { job_id }]\">download</a>"
        }

set pagination_sql {
    select entry_id
    from auth_batch_job_entries
    where job_id = :job_id    
}

list::create \
    -name batch_actions \
    -multirow batch_actions \
    -key entry_id \
    -page_query $pagination_sql \
    -page_size 100 \
    -elements {
        entry_id {
            label "Action ID"
            link_url_eval {$entry_url}
        }
        entry_time {
            label "Timestamp"
        }
        operation {
            label "Type of operation"
        }
        username {
            label "Username"
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
            job_id {}
    }

db_multirow -extend { entry_url short_message } batch_actions select_batch_actions {
    select entry_id,
           to_char(entry_time, 'YYYY-MM-DD HH24:MI:SS') as entry_time,
           operation,
           username,
           user_id,
           success_p,
           message,
           element_messages
    from auth_batch_job_entries
    where job_id = :job_id
} {
    set entry_url [export_vars -base batch-action { entry_id }]
    
    # Use message and element_messages to display one short message in the table
    if { ![empty_string_p $message] } {
        set short_message $message
    } elseif { [llength $element_messages] == 1} {
        # Only one element message - use it
        set short_message [lindex $element_messages 1]
    } elseif { [llength $element_messages] > 1 } {
        # Several element messages
        set short_message "Problems with elements"
    } else {
        set short_message ""
    }
    set short_message [string_truncate -len 25 $short_message]
}
