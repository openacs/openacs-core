# main index page for notes.

# Notice we have a new -query parameter, color_filter_value. If anything
# wants to activate the filter (whose name is color_filter_value) defined 
# ahead in the template::list, then it can feed the page a parameter of
# color_filter_value="something". When this happens, the filter will add 
# its where clause to template::list::filter_where_clause and therefore 
# to the query which has a call to that proc. In this case, the where claue
# will be "n.color = 'something'". Look at the filter definition in the
# list definition to see this.

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-10-23
  @cvs-id $Id$
} -query {
    orderby:token,notnull,optional
    color_filter_value:optional,trim,notnull
} -properties {
    notes:multirow
    context:onevalue
    create_p:onevalue
} -validate {
    valid_color -requires color_filter_value {
        if {$color_filter_value ni {blue green purple red orange yellow}} {
            ad_complain "Invalid value: $color_filter_value"
        }
    }
}

set package_id [ad_conn package_id]
set user_id [ad_conn user_id]

set context [list]
set create_p [permission::permission_p -object_id $package_id -privilege create]

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
#
# So, to activate the filter, say for Blue, this page is fed this:
# color_filter_value="blue"
# and notice, this is the lowercase version, the second item in each
# inner list. The first item is displayed to the user for choosing 
# among possible filter values.

set color_choices {
    {Blue blue}
    {Green green}
    {Purple purple}
    {Red red}
    {Orange orange}
    {Yellow yellow}
}

# Here's the list; notice the new -filters section. If the user chooses
# to activate the filter (presumably by manipulating some user interface),
# the filter will add its where clause to output of the call
# template::list::filter_where_clause. Look at the query; you'll see the
# call to filter_where_clause there near the bottom, in brackets.

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
	color_filter_value {
	    label "Color"
	    where_clause {
		n.color = :color_filter_value
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

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
