ad_page_contract {

    @author Natalia Pérez (nperper@it.uc3m.es)
    @creation-date 2005-03-28

} {
    object_id:naturalnum,notnull
    request_id:naturalnum,multiple
    type_id:naturalnum,notnull
    return_url:localurl
}

set package_id [ad_conn package_id]
permission::require_permission -object_id $package_id -privilege create

set request_ids $request_id
foreach request_id $request_ids {
    # Security Check
    notification::security::require_admin_request -request_id $request_id

    # Actually Delete
    notification::request::delete -request_id $request_id
}

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
