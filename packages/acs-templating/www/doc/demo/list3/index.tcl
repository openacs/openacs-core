# main index page for notes.

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-10-23
  @cvs-id $Id$
} -query {
  orderby:optional,token,notnull
} -properties {
  notes:multirow
  context:onevalue
  create_p:onevalue
}

set package_id [ad_conn package_id]
set user_id [ad_conn user_id]

set context [list]
set create_p [permission::permission_p -object_id $package_id -privilege create]

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
    } \
    -orderby {
	default_value title,asc
	title {
	    label "Title of Note"
	    orderby n.title
	}
	creation_user_name {
	    label "Owner of Note"
	    orderby creation_user_name
	}
	creation_date {
	    label "When Note Created"
	    orderby o.creation_date
	}
        color {
	    label "Color"
	    orderby n.color
	}
    }

db_multirow template_demo_notes template_demo_notes {}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
