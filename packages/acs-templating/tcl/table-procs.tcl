ad_library {
    Table widget for the ArsDigita Templating System

    @author Karl Goldstein    (karlg@arsdigita.com)
    @author Stanislav Freidin (sfreidin@arsdigita.com)
    
    @cvs-id $Id$
}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


# The table widget consists of 3 parts:
# 1). The column definition (-column_def, optional), in form
#     name {label orderby_clause presentation}
#       name  is the name for the column (required)
#       label is the pretty label for the column (defaults to name)
#       orderby_clause is the SQL order by clause that will be used to sort
#         the table (defaults to name)
#       presentation is the html code that will be shown in the table cell
#         (defaults to "@row.value@", see below)
#     The column definition will be extracted from the query results
#     if it is omitted. 
#
# 2). The SQL query that will be executed to get the rows. The orderby
#      clause will be appended to the query (-query, required).
#
# 3). The template to render the table (-style, optional). If omitted, 
#     the code inside the
#       <tablewidget> tag will be used
#
#  The widget creates two datasources:
#   "tablewidget:${name}_columns", used to render the column headers,
#     html     - the HTML to render the label
#     selected - "t" if the table is being sorted by this column, "f" otherwise
#   
#   "tablewidget:${name}_rows", used to render the rows, with the fields
#     representing the column values for the query. For each column, a field
#     called "${column_name}_html" is created which contains the presentation 
#     for the field
#
#   If the -columns_data or -rows_data switches are specified,
#   external datasources are used instead

# Create the widget data structure

namespace eval template {}
namespace eval template::widget {}
namespace eval template::widget::table {}


ad_proc -public template::widget::table::create {
  statement_name
  name
  args
} {
  Create a table widget
} {

  upvar "tablewidget:${name}" widget

  set widget(name) $name
   
  template::widget::table::get_params $name 2
  template::widget::table::prepare $statement_name $name 2
}

ad_proc -public template::widget::table::get_params {
  name
  {level 1}
} {
  Get the order by clause for the widget, other parameters (?)
} {
  
  upvar $level "tablewidget:${name}" widget

  set widget(orderby) [ns_queryget "tablewidget:${name}_orderby"]
}

ad_proc -public template::widget::table::default_column_def {
  name
  { level 2}
} {
  Create the default column definition if none exists
} {

  upvar $level "tablewidget:${name}" widget

  if { ![info exists widget(column_def)] } {
    # Get the column definition based on the first row of the datasource
    upvar $level "tw_${name}_rows:rowcount" rowcount
    if { $rowcount < 1 } {
      error "No column definition specified and no rows are available to generate the default column definition for tablewidget $name"
    }
    upvar $level "tw_${name}_rows:1" row
    set column_def [list]
    foreach name [array names row] {
      lappend column_def $name [list]
    }
    set widget(column_def) $column_def
  }
}

ad_proc -public template::widget::table::prepare {
  statement_name
  name
  {level 1}
} {
  Compose the query, if necessary, and define the datasources
} {
  
  upvar $level "tablewidget:${name}" widget
 
  # Get the rows
  if { ![info exists widget(rows_data)] } {
    if { ![info exists widget(query)] } {
      error "No row datasource available for tablewidget $name"
    }

    # fixme - need to get a statement name here
    set sql_query $widget(query)

    # Append the order by clause, if any
    if { [info exists widget(orderby)] } {
      if { ![regexp -nocase "order +by" $sql_query match] } {
        append sql_query "\n order by"
      }
      append sql_query " $widget(orderby)"
    }

    if { [info exists widget(column_def)] } {
      # Convert the column def list to an array for extra speed 
      upvar $level "tablewidget:${name}_column_def" column_arr
      array set column_arr $widget(column_def)
      set eval_code "set row(row_html) \"\"\n"

      # Process each column and append its presentation to the row html
      foreach {column_name column} $widget(column_def) {
        set presentation [lindex $column 2]
        set row_key "${column_name}_html"

        # Make sure there are no empty values that cause tables to
        # look ugly
        append eval_code "if \{ \[template::util::is_nil row($column_name) \] \} \{
            set $column_name \"&nbsp;\"
	  \} else \{
            set $column_name \$row($column_name)
	  \}
        "

        # Append to the row html  
        if { $presentation ne "" } {
          # Debug !
          regsub -all {"} $presentation {\\"} presentation  
          append eval_code "set row($row_key) \"$presentation\"\n"
	} else {
          append eval_code "set row($row_key) <td>\$$column_name</td>\n"
	}
        append eval_code "
          append row(row_html) \$row($row_key)
        "
      }

    }

    if { [info exists widget(eval)] } {
      append eval_code $widget(eval)
    }
    uplevel $level "
      db_multirow tw_${name}_rows $statement_name \{$sql_query\} \\
        \{$eval_code\}
    "
  
    # Get the column definition if it does not exist
    if { ![info exists widget(column_def)] } {
      template::widget::table::default_column_def widget \
        [expr {$level + 1}]
    }

  } else {
    uplevel $level "uplevel 0 tw_${name}_rows $widget(rows_data)"
    template::widget::table::default_column_def widget \
      [expr {$level + 1}]
  }

  # Process the rows datasource and get the columns
  if { ![info exists widget(columns_data)] } {
    upvar $level "tw_${name}_columns:rowcount" rowcount 

    # Get the base url for the page
    set url [ns_conn url]
    set the_form [ns_getform]
    set the_joiner "?"
    if { ![template::util::is_nil $the_form] } {
      foreach key [ns_set keys $the_form] {
        if { $key ne "tablewidget:${name}_orderby" } {
          append url "${the_joiner}${key}\=[ns_set get $the_form $key]"
          set the_joiner "&"
        }
      }
    }

    # Convert the column def into a multirow datasource
    set rowcount 0
    foreach {column_name column} $widget(column_def) {
      incr rowcount
      upvar $level "tw_${name}_columns:$rowcount" row
      set row(rownum) $rowcount
      set row(colnum) $rowcount
      set row(name) $column_name

      set label [lindex $column 0]
      if {$label eq ""} {
        set label $column_name
      }
      set orderby_clause [lindex $column 1]
      if {$orderby_clause eq ""} {
        set orderby_clause $column_name
      }
 
      if { [info exists widget(orderby)] && $column_name eq $widget(orderby) } {
        set row(html) "<b>$label</b>"
        set row(selected) "t"
      } else {
	set row(html)    "<a href=\"[ns_quotehtml ${url}${the_joiner}tablewidget:${name}_orderby\=$row(name)]\">"
        append row(html) "$label</a>"
        set row(selected) "f"
      }
    }
  } else {
    uplevel $level "uplevel 0 tw_${name}_columns $template(columns_data)"
  }

}

# Register the tag that actually renders the widget

template_tag tablewidget { chunk params } {

  set name [ns_set iget $params name]
  set style [ns_set iget $params style]

  # Use the style unless the template is specified in the tag
  if { $chunk eq "" } {
    if { $style eq "" } {
      template::adp_append_code "set __tablewidget_style \"$style\""
    } else {
      template::adp_append_code "set __tablewidget_style \"\$tablewidget:${name}(style)\""
    }
    set command "template::adp_parse" 
    append command " \[template::util::url_to_file \"$__tablewidget_style\" \"\$__adp_stub\"\]"
    template::adp_append_code $command 
  } else {
    template::adp_compile $chunk
  }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
