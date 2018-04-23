# packages/acs-core-ui/www/acs_object/permissions/revoke-2.tcl

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-08-20
  @cvs-id $Id$
} {
  object_id:naturalnum,notnull
  revoke_list:multiple
  { operation "" }
  {application_url ""}
}

permission::require_permission -object_id $object_id -privilege admin

if {$operation eq "Yes"} {
    db_transaction {
        foreach item $revoke_list {
            lassign $item party_id privilege
            permission::revoke -party_id $party_id -object_id $object_id -privilege $privilege
        }
    }
}

ad_returnredirect [export_vars -base one {object_id application_url}]
ad_script_abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
