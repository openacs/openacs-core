ad_page_contract {
    Interactive shell for executing commands in OpenACS

    @author Nis Jorgensen
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
        {label {Input Tcl Script}}
        {html {cols 80 rows 10}}
    }
} -on_submit {
    if { "POST" ne [ns_conn method] } {
        set out "You cannot use GET to invoke a script on this page.\nClick OK to resubmit the form as a POST."
    } else {
        if {[catch {set out [uplevel 1 [string map {"\\\r\n" " "} $script]]}]} {
            set out "ERROR:\n$::errorInfo"
        }
    }
}

template::head::add_style -style {
    #script {
        border:1px solid #999999;
        width:100%;
        margin:5px 0;
        padding:3px;
        background-color: #f6f6f6;
        font-family: monospace;
        font-size: small;
        color: darkblue;    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
