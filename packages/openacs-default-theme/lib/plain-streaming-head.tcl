# The streaming head template provides means for styling streaming
# HTML output and supports the standard title and navigation bar
# conventions.  It can be used e.g. like in the following:
#
# set title "Contents of Loaded Package"
# set context [list [list "." "Package Manager"] [list "package-load" "Load a New Package"] $title]
# ad_return_top_of_page [ad_parse_template -params [list context title] \
#			   "/packages/openacs-default-theme/lib/plain-streaming-head"]
#
#
set separator :
set system_name [ad_system_name]
set untrusted_user_id [ad_conn untrusted_user_id]
set user_name [person::name -person_id $untrusted_user_id]
set whos_online_url [subsite::get_element -element url]shared/whos-online
set num_users_online [lc_numeric [whos_online::num_users]]

ad_context_bar_multirow -- $context

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
