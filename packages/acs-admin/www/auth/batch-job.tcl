ad_page_contract {
    Page displaying info about a single batch job.

    @author Peter Marklund
    @creation-date 2003-09-09
} {
    job_id:naturalnum,notnull
    page:naturalnum,optional
    success_p:boolean,optional
}

auth::sync::job::get -job_id $job_id -array batch_job

set page_title "\#acs-admin.One_batch_job\#"
set context [list \
                 [list "." "[_ acs-admin.Authentication]"] \
                 [list [export_vars -base authority { {authority_id $batch_job(authority_id)} }] "$batch_job(authority_pretty_name)"] $page_title]

ad_form \
    -name batch_job_form \
    -mode display \
    -display_buttons {} \
    -form {
        {authority_pretty_name:text(inform)
            {label "\#acs-admin.Authority_name\#"}
        }
        {job_start_time:text(inform)
            {label "\#acs-admin.Start_time\#"}
        }
        {job_end_time:text(inform)
            {label "\#acs-admin.End_time\#"}
        }
        {run_time_seconds:text(inform)
            {label "\#acs-admin.Running_time\#"}
            {after_html " [_ acs-admin.seconds]"}
        }
        {interactive_p:text(inform)
            {label "\#acs-admin.Interactive\#"}
        }
        {snapshot_p:text(inform)
            {label "\#acs-admin.Snapshot\#"}
        }
        {message:text(inform)
            {label "\#acs-admin.Message"}
        }
        {creation_user:text(inform)
            {label "\#acs-admin.Creation_user\#"}
        }
        {doc_start_time:text(inform)
            {label "\#acs-admin.Document_start_time\#"}
        }
        {doc_end_time:text(inform)
            {label "\#acs-admin.Document_end_time\#"}
        }
        {doc_status:text(inform)
            {label "\#acs-admin.Document_status\#"}
        }
        {doc_message:text(inform)
            {label "\#acs-admin.Document_message\#"}
        }
        {document_download:text(inform)
            {label "\#acs-admin.Document\#"}
        }
        {num_actions:text(inform)
            {label "\#acs-admin.Number_of_actions\#"}
        }
        {num_problems:text(inform)
            {label "\#acs-admin.Number_of_problems\#"}
        }
    } -on_request {
        foreach element_name [array names batch_job] {
            # Make certain columns pretty for display
            if { [regexp {_p$} $element_name] } {
                set $element_name [ad_decode $batch_job($element_name) "t" "Yes" "No"]
            } elseif { $element_name eq "creation_user" && $batch_job($element_name) ne "" } {
                set $element_name [acs_community_member_link -user_id $batch_job($element_name)]
            } else {
                set $element_name [ns_quotehtml $batch_job($element_name)]
            }
        }

        set job_start_time [lc_time_fmt $batch_job(job_start_time) "%x %X"]
        set job_end_time [lc_time_fmt $batch_job(job_end_time) "%x %X"]

        set document_download "<a href=\"[export_vars -base batch-document-download { job_id }]\">[_ acs-admin.download]</a>"
    }

list::create \
    -name batch_actions \
    -multirow batch_actions \
    -key entry_id \
    -page_size 100 \
    -page_query_name pagination \
    -elements {
        entry_time_pretty {
            label "\#acs-admin.Timestamp\#"
            link_url_eval {$entry_url}
            link_html { title "\#acs-admin.View_log_entry\#" }
        }
        operation {
            label "\#acs-admin.Operation\#"
        }
        username {
            label "\#acs-admin.Username\#"
            link_url_col user_url
        }
        success_p {
            label "\#acs-admin.Success\#"
            display_template {
                <if @batch_actions.success_p;literal@ true>
                  <font color="green">\#acs-admin.Yes\#</font>
                </if>
                <else>
                  <font color="red">\#acs-admin.No\#</font>
                </else>
            }
        }
        short_message {
            label "\#acs-admin.Message\#"
        }
    } -filters {
        job_id {
            hide_p 1
        }
        success_p {
            label "\#acs-admin.Success\#"
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
           exists (select 1 from users where user_id = e.user_id) as user_exists_p
    from   auth_batch_job_entries e
    where  [template::list::page_where_clause -name batch_actions]
    [template::list::filter_where_clauses -and -name batch_actions]
    order  by entry_id
" {
    set entry_url [export_vars -base batch-action { entry_id }]

    # Use message and element_messages to display one short message in the table
    if { $message ne "" } {
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

    if { $user_exists_p && $user_id ne ""  } {
        set user_url [acs_community_member_admin_url -user_id $user_id]
    } else {
        set user_url {}
    }

    set entry_time_pretty [lc_time_fmt $entry_time_ansi "%x %X"]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
