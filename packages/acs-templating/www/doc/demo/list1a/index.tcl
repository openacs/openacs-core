# main index page for notes.

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-10-23
  @cvs-id $Id$
} -properties {
  notes:multirow
}

set package_id [ad_conn package_id]
set user_id    [ad_conn user_id]

db_multirow template_demo_notes template_demo_notes {}

template::list::create -name notes \
    -multirow template_demo_notes \
    -elements {
	title {
	    label "Title of Note"
	}
    }

ad_return_template
