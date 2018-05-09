# main index page for notes.

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-10-23
  @cvs-id $Id$
} -query {
  orderby:token,optional
} -properties {
  notes:multirow
  context:onevalue
  create_p:onevalue
} -validate {
    valid_orderby -requires orderby {
        if {![regexp {,(asc|desc)$} $orderby]} {
            ad_complain "Invalid value for orderby"
        }
    }
}

set package_id [ad_conn package_id]
set user_id [ad_conn user_id]

set context [list]
set create_p [permission::permission_p -object_id $package_id -privilege create]

# Here, we are adding a link for every row. The title of the note
# will become a link to a page that will view the note in its entirety.
#
# Notice in the title element of this, where we add "link_url_col view_url"

template::list::create -name notes \
    -multirow template_demo_notes \
    -elements {
	title {
	    label "Title of Note"
	    link_url_col view_url
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
	    label "User"
	    orderby creation_user_name
	}
	creation_date {
	    label "Date"
	    orderby o.creation_date
	}
	color {
	    label "Color"
	    orderby n.color
	}
    }

# how to get the variable per row, which will be the link target?
#
# first, we extend the multirow so that it contains an additional
# column (other than the columns in the select list from the query).
#
# The name of that column is view_url, and we're using export_vars
# to actually form the value. This invocation of db_multirow has an
# extra parameter at the end, which is a block of code to execute.
# In this block, we set the extra column variable we told it about
# with the -extend {} parameter.
#
# This variable will then be available to anything that reads the
# multirow, which for this case is the template::list::create call
# above.

db_multirow -extend { view_url } template_demo_notes template_demo_notes {} {
    set view_url [export_vars -base view-one { template_demo_note_id }]
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
