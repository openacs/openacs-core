# packages/acs-core-ui/www/permissions/index.tcl

ad_page_contract {
  Display all objects that the user has admin on.

  @author rhs@mit.edu
  @creation-date 2000-08-29
  @cvs-id $Id$
}

set user_id [ad_maybe_redirect_for_registration]

doc_body_append "[ad_header "Permissions"]

<h2>Permissions</h2>

[ad_context_bar "Permissions"]
<hr>

<form method=\"get\" action=\"one\">
Select an Object by Id:
<input name=\"object_id\" type=\"text\"> <input value=\"Continue\" type=\"submit\">
</form><p>

You have admin on the following objects:

<ul>
"

db_foreach adminable_objects {
  select o.object_id, acs_object.name(o.object_id) as name
  from acs_objects o, acs_object_party_privilege_map map
  where map.object_id = o.object_id
    and map.party_id = :user_id
    and map.privilege = 'admin'
} {
  doc_body_append "  <li><a href=one?[export_url_vars object_id]>$name</a></li>\n"
} if_no_rows {
  doc_body_append "  <li>(none)</li>\n"
}

doc_body_append "
</ul>

[ad_footer]
"
