# main index page for notes.

ad_page_contract {

  @author rhs@mit.edu
  @creation-date 2000-10-23
  @cvs-id $Id$
} -query {
  orderby:token,notnull,optional
  color_filter_value:optional,trim,notnull
  page:naturalnum,optional
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

set color_choices {
    {Blue blue}
    {Green green}
    {Purple purple}
    {Red red}
    {Orange orange}
    {Yellow yellow}
}

template::list::create -name notes \
    -multirow template_demo_notes \
    -key "template_demo_note_id" \
    -page_size 3 \
    -page_query_name template_demo_notes_paginate \
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
