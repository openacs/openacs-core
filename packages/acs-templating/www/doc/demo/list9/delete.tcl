# packages/notes/www/delete.tcl

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-10-23
  @cvs-id $Id$
} {
  template_demo_note_id:naturalnum,notnull,multiple
} -validate {
    csrf { csrf::validate }
}

foreach template_demo_note_id $template_demo_note_id {
    permission::require_permission -object_id $template_demo_note_id -privilege delete

    package_exec_plsql \
	-var_list [list [list template_demo_note_id $template_demo_note_id]] \
	template_demo_note \
	del
}

# We've successfully processed the submission.
# Clear the pagination cache.

cache flush notes*

ad_returnredirect "./"

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
