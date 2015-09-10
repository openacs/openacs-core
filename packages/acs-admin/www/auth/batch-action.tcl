ad_page_contract {
    Display all information about a certain batch import operation.

    @author Peter marklund (peter@collaboraid.biz)
    @creation-date 2003-09-10
} {
    entry_id:naturalnum,notnull
}

auth::sync::job::get_entry -entry_id $entry_id -array batch_action
auth::sync::job::get -job_id $batch_action(job_id) -array batch_job

set page_title "One batch action"

set context [list [list "." "Authentication"] \
                  [list [export_vars -base authority { {authority_id $batch_action(authority_id)} }] \
                        "$batch_job(authority_pretty_name)"] \
                  [list [export_vars -base batch-job {{job_id $batch_action(job_id)}}] "One batch job"] \
                 $page_title]

ad_form -name batch_action_form \
        -mode display \
        -display_buttons {} \
        -form {
            {entry_time:text(inform)
                {label "Timestamp"}
            }
            {operation:text(inform)
                {label "Action type"}
            }
            {username:text(inform)
                {label "Username"}
            }
            {user_id:text(inform)
                {label "User"}
            }
            {success_p:text(inform)
                {label "Success"}
            }
            {message:text(inform)
                {label "Message"}
            }
            {element_messages:text(inform)
                {label "Element messages"}
            }            
        } -on_request {
            foreach element_name [array names batch_action] {
                # Prettify certain elements
                if { [regexp {_p$} $element_name] } {
                    set $element_name [ad_decode $batch_action($element_name) "t" "Yes" "No"]
                } elseif { $element_name eq "user_id" && $batch_action($element_name) ne "" } {
                    if { [catch {set $element_name [acs_community_member_link -user_id $batch_action($element_name)]}] } {
                        set $element_name $batch_action($element_name)
                    }
                } elseif { $element_name eq "element_messages" && $batch_action($element_name) ne "" } {
                    array set messages_array $batch_action($element_name)
                    append $element_name "<ul>"
                    foreach message_name [array names messages_array] {
                        append $element_name "<li>$message_name - $messages_array($message_name)</li>"
                    }
                    append $element_name "</ul>"
                } else {
                    set $element_name $batch_action($element_name)
                }
            }
        }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
