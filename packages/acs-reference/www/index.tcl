ad_page_contract {

    Main Index page for reference data. 

    @author Jon Griffin (jon@jongriffin.com)
    @creation-date 2001-08-26
    @cvs-id $Id$
} {
} -properties {
  context_bar:onevalue
  package_id:onevalue
  user_id:onevalue
  title:onevalue
}

set title "Reference Data"
set package_id [ad_conn package_id]
set context_bar [list $title]
set user_id [ad_conn user_id]

set admin_p [permission::permission_p -object_id $package_id -privilege admin]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
