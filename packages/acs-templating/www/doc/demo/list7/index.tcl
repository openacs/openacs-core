# main index page for notes.

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-10-23
  @cvs-id $Id$
} -query {
  orderby:optional
  color:optional
} -properties {
  notes:multirow
  context:onevalue
  create_p:onevalue
}

set package_id [ad_conn package_id]
set user_id [ad_conn user_id]

set context [list]
set create_p [ad_permission_p $package_id create]

set actions [list]

if { $create_p } {
    lappend actions "Create Note" add-edit "Create Note"
}

# the following structure is a "list of lists". Each list describes a 
# different choice value; the first item is the displayed name of the 
# choice and the second is the value passed back as the value of the
# choice.
#
# Normally, you'd have a database query where the items in the select
# list of the query will appear in each inner list in order; again, 
# the first would be a displayed name and the second would be the 
# value that the form would send back as the choice. Note that this
# could be a primary key in a table, maybe an object ID.
#
# Since the colors column is a text column and not implemented as a
# separate table with a numeric key column, the value will be the 
# name of the color.

set color_choices {
    {Blue blue}
    {Green green}
    {Red red}
    {Orange orange}
    {Yellow yellow}
}

# Here's the list; notice the new -filters section

template::list::create -name notes \
    -multirow template_demo_notes \
    -key "template_demo_note_id" \
    -actions $actions \
    -bulk_actions {
	"Delete Checked Notes" "delete" "Delete Checked Notes"
    } \
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
    -filters {
	color {
	    label "Color"
	    where_clause {
		n.color = :color
	    }
	    values $color_choices
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

db_multirow -extend { view_url } template_demo_notes template_demo_notes {} {
    set view_url [export_vars -base view-one { template_demo_note_id }]
}

ad_return_template
