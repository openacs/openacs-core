# packages/acs-core-ui/www/acs_object/permissions/grant.tcl

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-08-20
  @cvs-id $Id$
} {
  object_id:integer,notnull
}

ad_require_permission $object_id admin

set name [db_string name {select acs_object.name(:object_id) from dual}]

doc_body_append "[ad_header "Grant Permission on $name"]

<h2>Grant Permission on $name</h2>

[ad_context_bar [list ./?[export_url_vars object_id] "Permissions for $name"] "Grant"]
<hr>

<form method=get action=grant-2>
[export_form_vars object_id]

<input type=submit value=Grant>

<select name=privilege>
"
db_foreach privileges {
  select privilege
  from acs_privileges
  order by privilege
} {
  doc_body_append "<option value=$privilege>$privilege</option>\n"
}

doc_body_append "
</select>
on $name to
<select name=party_id>
"

db_foreach parties {
  select party_id, acs_object.name(party_id) as name
  from parties
} {
  doc_body_append "<option value=$party_id>$name</option>\n"
}

doc_body_append "
</select>

</form>

[ad_footer]
"
