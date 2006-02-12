# packages/notes/www/delete.tcl

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-10-23
  @cvs-id $Id$
} {
  note_id:integer,notnull,multiple
}

foreach note_id $note_id {
    ad_require_permission $note_id delete

    package_exec_plsql -var_list [list [list note_id $note_id]] note del
}

ad_returnredirect "./"
