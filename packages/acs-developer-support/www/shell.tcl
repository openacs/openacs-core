ad_page_contract {
    @Author Nis Jorgensen
} {
    {script:optional,allhtml {}}
} -properties {
    out
}

ds_require_permission [ad_conn package_id] "admin"

if { ![acs_user::site_wide_admin_p] } {
    ad_return_warning "Error" "Sorry, only site-wide admins may use this."
    ad_script_abort
}

set page_title "OpenACS Shell"
set context [list $page_title]

set out {}

ad_form -name shell -form {
    {
        script:text(textarea),nospell
        {label {Input tcl_script}}
        {html {cols 80 rows 10}}
    }
} -on_submit {
    if { ![string equal POST [ns_conn method]] } {
        set out "You cannot use GET to invoke a script on this page.\nClick OK to resubmit the form as a POST."
    } else {
        if {[catch {set out [uplevel 1 [string map {"\\\r\n" " "} $script]]}]} {
            global errorInfo
            set out "ERROR:\n$errorInfo"
        }
    }
}
