ad_page_contract {
  @Author Nis Jorgensen
} {
  {script:optional,allhtml {}}
  } -properties {
  result
}

ds_require_permission [ad_conn package_id] "admin"

set page_title "OpenACS Shell"
set context $page_title

if { ![acs_user::site_wide_admin_p] } {
    ad_return_warning "Error" "Sorry, only site-wide admins may use this."
    ad_script_abort
}

set result ""

ad_form -name shell -form {
    {
      script:text(textarea),nospell
      {label {Input tcl_script}}
      {html {cols 80 rows 10}}
    }
  } -on_submit {
    if {[catch {set result [uplevel $script]}]} {
      global errorInfo
      set result "ERROR:\n$errorInfo"
    }
  }
