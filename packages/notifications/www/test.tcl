
# Send it all out
foreach interval [notification::get_all_intervals] {
    notification::sweep::sweep_notifications -interval_id [lindex $interval 1]
}

doc_body_append "done"
