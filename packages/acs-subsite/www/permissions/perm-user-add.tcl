ad_page_contract {
    Simple page for adding users to permissions list.
} {
    return_url:localurl
}

set context [list [list $return_url "Permissions"] "[_ acs-subsite.Add_User]"]
set title "[_ acs-subsite.Add_User]"


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
