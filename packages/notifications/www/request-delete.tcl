
ad_page_contract {

    Remove a notification request

    @author Ben Adida (ben@openforce.net)
    @creation-date 2002-05-24
    @cvs-id $Id$
} {
    request_id:naturalnum,notnull
    return_url:localurl
}

# Security Check
permission::require_permission -object_id $request_id -privilege "admin"

# Actually Delete
notification::request::delete -request_id $request_id

# Redirect
ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
