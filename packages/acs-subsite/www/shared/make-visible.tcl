ad_page_contract {
    Make user visible.
} {
    {return_url ""}
}

auth::require_login

whos_online::unset_invisible [ad_conn user_id]

if { $return_url eq "" } {
    set return_url [ad_pvt_home]
}

ad_returnredirect -message [_ acs-subsite.Online_status_set_visible] -- $return_url


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
