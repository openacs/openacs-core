ad_page_contract {
    Make user invisible.
} {
    {return_url:localurl ""}
}

auth::require_login

whos_online::set_invisible [ad_conn user_id]

if { $return_url eq "" } {
    set return_url [ad_pvt_home]
}

ad_returnredirect -message [_ acs-subsite.Online_status_set_invisible] -- $return_url


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
