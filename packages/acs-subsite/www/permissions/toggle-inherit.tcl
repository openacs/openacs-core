# packages/acs-subsite/www/permissions/toggle-inherit.tcl

ad_page_contract {

  Toggles the security_inherit_p flag.

  @author rhs@mit.edu
  @creation-date 2000-09-30
  @cvs-id $Id$
} {
  object_id:integer,notnull
}

ad_require_permission $object_id admin

db_dml toggle_inherit {
  update acs_objects
  set security_inherit_p = decode(security_inherit_p, 't', 'f', 'f', 't')
  where object_id = :object_id
}

ad_returnredirect one?[export_url_vars object_id]
