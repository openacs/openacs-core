ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-08-20
  @cvs-id $Id$
} {
  object_id:naturalnum,notnull
  {revoke_list:multiple,optional {}}
  {application_url ""}
}

permission::require_permission -object_id $object_id -privilege admin

if {[llength $revoke_list] == 0} {
  ad_returnredirect [export_vars -base ./ {object_id}]
  ad_script_abort
}

set title "Revoke Confirm"
set context [list $title]

set body [subst {
    <h2>Revoke Confirm</h2>

    <hr>
    Are you sure you want to remove the following entries from the access
    control list of [acs_object_name $object_id]?
    <ul>
}]

foreach item $revoke_list {
    lassign $item party_id privilege
    append body [subst {
        <li>[acs_object_name $party_id]</li>
    }]
}

append body [subst {
    </ul>
    <form method="get" action="revoke-2">
    [export_vars -form {object_id application_url}]
}]

foreach item $revoke_list {
    append body [subst {
        <input type="hidden" name="revoke_list" value="$item">
    }]
}

append body {
    <input name="operation" type="submit" value="Yes"> <input name="operation" type="submit" value="No">
    </form>
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
