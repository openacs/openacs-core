ad_page_contract {
    Install from local file system
} {
    {repository_url ""}
    {success_p 0}
}

if { ![empty_string_p $repository_url] } {
    set parent_page_title "Install From OpenACS Repository"
} else {
    set parent_page_title "Install From Local File System"
}

if { $success_p } {
    set page_title "Installation Complete"
} else {
    set page_title "Installation Failed"
}

set context [list [list "." "Install Software"] [list "install" $parent_page_title] $page_title]

