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

# don't worry too much if you don't understand the query's details;
# the point here is several columns can be displayed.
# 
# Look at the query; notice how you can have a complex expression
# come in as any name (like for creation_user_name and creation_date)
# using "<expression> as <name>"

template::list::create -name notes \
    -multirow template_demo_notes \
    -elements {
	title {
	    label "Title of Note"
	}
	creation_user_name {
	    label "Owner of Note"
	}
	creation_date {
	    label "When Note Created"
	}
	color {
	    label "Color"
	}
    }

ad_return_template
