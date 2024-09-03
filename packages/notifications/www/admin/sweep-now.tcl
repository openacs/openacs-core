ad_page_contract {
    Sweep notifications immediately
}

notification::sweep::sweep_notifications -interval_id [notification::interval::get_id_from_name -name "instant"]

ad_returnredirect .


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
