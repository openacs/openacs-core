# packages/acs-subsite/www/permissions/toggle-inherit.tcl

ad_page_contract {

  Toggles the security_inherit_p flag.

  @author rhs@mit.edu
  @creation-date 2000-09-30
  @cvs-id $Id$
} {
  object_id:integer,notnull
  {application_url ""}
}

ad_require_permission $object_id admin

permission::toggle_inherit -object_id $object_id

ad_returnredirect one?[export_vars {application_url object_id}]
