ad_include_contract {
    Renders the body scripts into the page

    @see template::collect_body_scripts
}

ns_log notice "BODY_SCRIPTS called"
template::get_body_event_handlers
template::prepare_body_script_multirow
