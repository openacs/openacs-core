ad_page_contract {
    Interactive shell for executing commands in OpenACS

    @author Gustaf Neumann
} {
} -properties {
    out
}

ds_require_permission [ad_conn package_id] "admin"

set nsShellURL [ns_config ns/server/[ns_info server]/module/nsshell url {}]
set page_title "NaviServer Shell"
set context [list $page_title]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
