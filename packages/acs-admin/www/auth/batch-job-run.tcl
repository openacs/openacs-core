ad_page_contract {
    Manually runs a batch synchronization.
    
    @author Peter Marklund
    @creation-date 2003-09-11
} {
    authority_id:naturalnum,notnull
}

auth::authority::get -authority_id $authority_id -array authority

set page_title "Run batch job"
set authority_page_url [export_vars -base authority { {authority_id $authority(authority_id)} }]
set context [list [list "." "Authentication"] [list $authority_page_url "$authority(pretty_name)"] $page_title]

set job_id [auth::authority::batch_sync -authority_id $authority_id]

set job_url [export_vars -base batch-job { job_id }]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
