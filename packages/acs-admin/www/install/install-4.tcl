ad_page_contract {
    Install from local file system
} {
    {repository_url ""}
    {success_p:boolean 0}
}

if { $repository_url ne "" } {
    set parent_page_title "Install From OpenACS Repository"
    set parent_page_url [export_vars -base install {repository_url}]
} else {
    set parent_page_title "Install From Local File System"
    set parent_page_url [export_vars -base install]
}

if { $success_p } {
    set page_title "Installation Complete"
} else {
    set page_title "Installation Failed"
}

set context [list [list "." "Install Software"] [list $parent_page_url $parent_page_title] $page_title]


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
