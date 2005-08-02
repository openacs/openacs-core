ad_page_contract {
    Simple page for adding users to permissions list.
} {
    return_url
}

set context [list [list $return_url "Permissions"] "[_ acs-subsite.Add_User]"]
set title "[_ acs-subsite.Add_User]"

