# packages/acs-core-ui/www/acs_object/permissions/index.tcl

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-08-20
  @cvs-id $Id$
} {
    object_id:integer,notnull
    {children_p "f"}
}

ad_require_permission $object_id admin

set user_id [ad_maybe_redirect_for_registration]

set name [db_string name {select acs_object.name(:object_id) from dual}]

doc_body_append "[ad_header "Permissions for $name"]

<h2>Permissions for $name</h2>

[ad_context_bar [list "./" "Permissions"] "Permissions for $name"]
<hr>

<h3>Inherited Permissions</h3>

<ul>
"

db_foreach inherited_permissions {
  select grantee_id, grantee_name, privilege
  from (select grantee_id, acs_object.name(grantee_id) as grantee_name,
               privilege, 1 as counter
        from acs_permissions_all
        where object_id = :object_id
        union all
        select grantee_id, acs_object.name(grantee_id) as grantee_name,
               privilege, -1 as counter
        from acs_permissions
        where object_id = :object_id)
  group by grantee_id, grantee_name, privilege
  having sum(counter) > 0
} {
  doc_body_append "  <li>$grantee_name, $privilege</li>\n"
} if_no_rows {
  doc_body_append "  <li>(none)</li>\n"
}

doc_body_append "
</ul>

<form method=get action=revoke>

[export_form_vars object_id]

<h3>Direct Permissions</h3>

<ul>
"

db_foreach acl {
  select grantee_id, acs_object.name(grantee_id) as grantee_name,
         privilege
  from acs_permissions
  where object_id = :object_id
} {
  doc_body_append "  <li>$grantee_name, $privilege (<font size=-1><input type=checkbox name=revoke_list value=\"$grantee_id $privilege\"></font>)</li>\n"
} if_no_rows {
  doc_body_append "  <li>(none)</li>\n"
}

set controls [list]

lappend controls "<a href=grant?[export_url_vars object_id]>Grant Permission</a>"

set context [db_string context {
  select acs_object.name(context_id)
  from acs_objects
  where object_id = :object_id
}]

if {![empty_string_p $context]} {
  db_1row security_inherit_p {
    select security_inherit_p
    from acs_objects
    where object_id = :object_id
  }


  if {$security_inherit_p == "t"} {
    lappend controls "<a href=toggle-inherit?[export_url_vars object_id]>Don't Inherit Permissions from $context</a>"
  } else {
    lappend controls "<a href=toggle-inherit?[export_url_vars object_id]>Inherit Permissions from $context</a>"
  }
}

doc_body_append "
</ul>

<blockquote>

\[ [join $controls " | "] \]

</blockquote>

<input type=submit value=\"Revoke Checked\">

</form>"

doc_body_append "<h3>Children</h3>
<blockquote>"

if [string equal $children_p "t"] {

    doc_body_append "<ul>"

    db_foreach children {
	select object_id as c_object_id,acs_object.name(object_id) as c_name
	from acs_objects o
	where context_id = :object_id
              and exists (select 1
                          from acs_object_party_privilege_map
                          where object_id = o.object_id
                          and party_id = :user_id
                          and privilege = 'admin')    
    } {
	doc_body_append "  <li><a href=one?object_id=$c_object_id>$c_name</a></li>\n"
    } if_no_rows {
	doc_body_append "  <em>(none)</em>\n"
    }

    doc_body_append "</ul>"

} else {
    db_1row children_count {
	select count(*) as num_children
	from acs_objects o
	where context_id = :object_id
              and exists (select 1
                          from acs_object_party_privilege_map
                          where object_id = o.object_id
                          and party_id = :user_id
                          and privilege = 'admin')    
    }

    set children_p "t"
    doc_body_append "<em>$num_children Children Hidden</em> "
    if {$num_children > 0} {
	doc_body_append "\[<a href=\"one?[export_url_vars object_id children_p]\">Show</a>\] "
    }
}


doc_body_append "</blockquote>


[ad_footer]"
