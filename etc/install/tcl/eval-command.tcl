ad_page_contract {
    This is a page script to be put on a test server that enables us to execute
    arbitrary Tcl commands and retrieve the results. This is a temporary solution
    to allow us to access the OpenACS Tcl API for as long as Tclwebtest is not running
    inside OpenACS.
  
    @author Peter Marklund
} {
    tcl_command
}

# Commenting out as this forces scripts to keep an admin login but we want to test with
# student accounts as well
#if { ![acs_user::site_wide_admin_p -user_id [ad_conn user_id]] } {
#    ad_return_forbidden "Permission Denied" "You don't have permission to access this page"
#}

set result [eval $tcl_command]

ns_return 200 text/plain $result
