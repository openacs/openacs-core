# Tag Handlers for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein    	  (karlg@arsdigita.com)
#          Stanislav Freidin 	  (sfreidin@arsdigita.com)
#          Christian Brechbuehler (chrisitan@arsdigita.com)

# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

#-----------------------------------------------------------
# Putting tag handlers in namespaces does not seem to work!
#-----------------------------------------------------------

# Add some escaped Tcl

template_tag tcl { chunk params } {

  # if the chunk begins with = then add our own append
  if { [string index $chunk 0] == "=" } {
    template::adp_append_code "append __adp_output [string range $chunk 1 end]"
  } else {
    template::adp_append_code $chunk
  }
}

# Set a property for the template.  Properties are primarily for the
# benefit of the master template to display appropriate context,
# such as the title, navigation links, etc.

template_tag property { chunk params } {

  set name [ns_set iget $params name]

  # quote dollar signs, square bracket and quotes
  regsub -all {[\]\[""\\$]} $chunk {\\&} quoted_chunk

  template::adp_append_code "set __adp_properties($name) \"$quoted_chunk\""
}

# Set the master template.

template_tag master { params } {

  set src [ns_set iget $params src]

  # default to the site-wide master
  if {[empty_string_p $src]} {
    set src "\[ad_parameter -package_id \[ad_conn subsite_id\]\
             DefaultMaster dummy \"/www/default-master\"\]"
  }
  
  template::adp_append_code "
    set __adp_master \[template::util::url_to_file \"$src\" \"\$__adp_stub\"\]"
}

# Insert the slave template

template_tag slave { params } {

  template::adp_append_code "
    if { \[info exists __adp_slave\] } {
      append __adp_output \$__adp_slave
    }
  "
}

# Include another template in the current template

template_tag include { params } {

  set src [ns_set iget $params src]

  # pass additional arguments as key-value pairs

  set command "template::adp_parse"
  append command " \[template::util::url_to_file \"$src\" \"\$__adp_stub\"\]"
  append command " \[list"

  for { set i 0 } { $i < [ns_set size $params] } { incr i } {

    set key [ns_set key $params $i]
    if { [string equal $key src] } { continue }
    
    set value [ns_set value $params $i]

    append command " $key \"$value\"";	# is $value quoted sufficiently?
  }
  append command "\]"

  template::adp_append_code "append __adp_output \[$command\]"
}

# Repeat a template chunk for each row of a multirow data source

template_tag multiple { chunk params } {

  set name     [template::get_attribute multiple $params name       ]
  set startrow [template::get_attribute multiple $params startrow  0]
  set maxrows  [template::get_attribute multiple $params maxrows  -1]; #unlimit

  template::adp_append_code "

  for { set __i [expr 1 + $startrow] } { \$__i <= \${$name:rowcount}"

  if {$maxrows >= 0} {
    template::adp_append_code " && \$__i <= [expr $maxrows + $startrow]" \
	-nobreak
  }
  
  template::adp_append_code " } { incr __i } {
    upvar 0 $name:\$__i $name
  " -nobreak
  template::adp_compile_chunk $chunk

  template::adp_append_code "}"
}  

# Repeat a template chunk for each item in a list

template_tag list { chunk params } {

  # the list tag accepts a value so that it may be used without a data
  # source in the tcl script

  set value [ns_set iget $params value]

  # If the value exists, use it and create a fake name for it

  if { ![template::util::is_nil value] } {

    template::adp_append_code "\nset __ats_list_value \[list $value\]\n"

    set name "__ats_list_value"
    template::adp_append_code "\nset $name:rowcount [llength $value]\n"

  } else {

    # Expect a data source from the tcl script
    set name [template::get_attribute list $params name]
    template::adp_append_code "\nset $name:rowcount \[llength \$$name\]\n"
  }
  
  template::adp_append_code "

  for { set __ats_i 0 } { \$__ats_i < \${$name:rowcount} } { incr __ats_i } {
    set $name:item \[lindex \$$name \$__ats_i\]
    set $name:rownum \[expr \$__ats_i + 1\]
  "
  template::adp_compile_chunk $chunk

  template::adp_append_code "}"
}  

# Create a recursed group, generating a recursive multirow block until the 
# column name stays the same

template_tag group { chunk params } {

  set column [template::get_attribute group $params column]

  # Scan the parameter stack backward, looking for the tag name

  set name [template::get_enclosing_tag multiple]

  if { [string equal $name {}] } {
    error "No enclosing MULTIPLE tag for GROUP tag on column $column"
  }    

  # while the value of name(column) stays the same
  template::adp_append_code "
    set __ats_group_rowcount 1
    while { 1 } {
      set ${name}(groupnum) \$__ats_group_rowcount
  "

  template::adp_compile_chunk $chunk     

  # look ahead to the next value and break if it is different
  # otherwise advance the cursor to the next row
  template::adp_append_code "
      if { \$__i == \${$name:rowcount} } {
        break
      }
      upvar 0 ${name}:\[expr \$__i + 1\] $name:next 
      if { !\[string equal \${${name}:next($column)} \$${name}($column)\] } { 
        break
      }
      incr __i
      upvar 0 $name:\$__i $name
      incr __ats_group_rowcount
    }
  "
}

# Repeat a template chunk consisting of a grid cell for each row of a
# multirow data source

template_tag grid { chunk params } {

  set name [template::get_attribute grid $params name]
  # cols must be a float for ceil to work
  set cols [template::get_attribute grid $params cols]
  # Horizontal or vertical ?
  set orientation [template::get_attribute grid $params orientation vertical]

  template::adp_append_code "
  set rows \[expr ceil(\${$name:rowcount} / $cols.0)\]
  for { set __r 1 } { \$__r <= \$rows } { incr __r } {
    for { set __c 1 } { \$__c <= $cols } { incr __c } {
"

  if { [string equal $orientation vertical] } {
    template::adp_append_code "
      set rownum \[expr 1 + int((\$__r - 1) + ((\$__c - 1) * \$rows))\]
"
  } else {
    template::adp_append_code "
      set rownum \[expr 1 + int((\$__c - 1) + ((\$__r - 1) * $cols))\]
" 
  }

  template::adp_append_code "
      upvar 0 $name:\$rownum $name
      set ${name}(rownum) \$rownum
      set ${name}(row) \$__r
      set ${name}(col) \$__c
  "

  template::adp_compile_chunk $chunk

  template::adp_append_code "
    }
  }"
}

template_tag if { chunk params } {

  template_tag_if_condition $chunk $params if
}

template_tag elseif { chunk params } {

  template_tag_if_condition $chunk $params elseif
}


# Append an "else" clause to the if expression

template_tag else { chunk params } {

  template::adp_append_code "else {" -nobreak

  template::adp_compile_chunk $chunk

  template::adp_append_code "}"  
}

# Output a template chunk without parsing, for preprocessed templates

template_tag noparse { chunk params } {

  # escape quotes
  regsub -all {[\]\[""\\$]} $chunk {\\&} quoted

  template::adp_append_string $quoted
}

# Render the HTML for the form widget, incorporating any additional
# markup attributes specified in the template.

template_tag formwidget { params } {

  set id [template::get_attribute formwidget $params id]

  # get any additional HTML attributes specified by the designer
  set tag_attributes [template::util::set_to_list $params id]

  template::adp_append_string \
    "\[template::element render \${form:id} $id { $tag_attributes } \]"
}

# Display the help information for an element

template_tag formhelp { params } {

  set id [template::get_attribute formwidget $params id]

  # get any additional HTML attributes specified by the designer
  set tag_attributes [template::util::set_to_list $params id]

  template::adp_append_string \
    "\[template::element render_help \${form:id} $id { $tag_attributes } \]"
}

# Report a form error if one is specified.

template_tag formerror { chunk params } {

  set id [template::get_attribute formwidget $params id]
  set type [ns_set get $params type]

  if { [string equal $type {}] } {
    set key $id
  } else {
    set key $id:$type
  }

  template::adp_append_code "
    if \{ \[info exists formerror($key)\] \} \{
      set formerror($id) \$formerror($key)
    "

  if { [string equal $chunk {}] } {

    template::adp_append_string "\$formerror($key)"

  } else {

    template::adp_compile_chunk $chunk
  }

  template::adp_append_code "\}"
}

# Render a group of form widgets

template_tag formgroup { chunk params } {

  set id [template::get_attribute formwidget $params id]

  # get any additional HTML attributes specified by the designer
  set tag_attributes [template::util::set_to_list $params id]

  # generate a list of options and option labels as a data source

  template::adp_append_code \
    "template::element options \${form:id} $id { $tag_attributes }"

  # make sure name is a parameter to pass to the rendering tag handler
  ns_set update $params name formgroup
  ns_set update $params id formgroup

  # Use the multiple or grid tag to render the form group depending on 
  # whether the cols attribute was specified
  
  if { [ns_set find $params cols] == -1 } {
    template_tag_multiple $chunk $params
  } else {
    template_tag_grid $chunk $params
  }
}

# Render a form, incorporating any additional markup attributes
# specified in the template.  Set the magic variable "form:id"
# for elements to reference

template_tag formtemplate { chunk params } {

  set level [template::adp_level]

  set id [template::get_attribute formtemplate $params id]

  upvar #$level $id:properties form_properties

  template::adp_append_code "set form:id \"$id\""

  # Set optional attributes for the grid template
  template::adp_append_code "
    upvar 0 \"$id:properties\" form_properties"

  foreach varname {headers title cols} {

    set form_properties($varname) [ns_set iget $params $varname]

    template::adp_append_code "
      set form_properties($varname) \"$form_properties($varname)\"
    "
  }

  # get any additional HTML attributes specified by the designer
  set tag_attributes [template::util::set_to_list $params \
    id style method title cols headers]

  template::adp_append_string \
      "\[template::form render $id { $tag_attributes } \]"

  if { [string equal [string trim $chunk] {}] } {

    # generate the form body dynamically if none specified.
    set style [ns_set iget $params style]
    template::adp_append_string "\[template::form generate $id $style\]"

  } else {

    # compile the static form layout specified in the template
    template::adp_compile_chunk $chunk
   
    # Render any hidden variables that have not been rendered yet
    template::adp_append_string \
    "\[template::form check_elements $id\]"
  }

  template::adp_append_string "</form>"
}


# @private tag_child
#
# Implements the <tt>child</tt> tag which renders a child item.
# See the Developer Guide for more information. <br>
# The child tag format is 
# <blockquote><tt>
# &lt;child tag=<i>tag</i> index=<i>n embed args</i>&gt;
# </blockquote>
#
# @param params  The ns_set id for extra HTML parameters

template_tag child { params } {
  publish::process_tag child $params
}

# @private tag_relation
#
# Implements the <tt>relation</tt> tag which renders a related item.
# See the Developer Guide for more information. <br>
# The relation tag format is 
# <blockquote><tt>
# &lt;relation tag=<i>tag</i> index=<i>n embed args</i>&gt;
# </tt></blockquote>
#
# @param params  The ns_set id for extra HTML parameters

template_tag relation { params } {
  publish::process_tag relation $params
}


# @private tag_content
#
# Implements the <tt>content</tt> tag which renders the content
# of the current item.
# See the Developer Guide for more information. <br>
# The content tag format is simply <tt>&lt;content&gt;</tt>. The
# <tt>embed</tt> and <tt>no_merge</tt> parameters are implicit to
# the tag.
#
# @param params  The ns_set id for extra HTML parameters

template_tag content { params } {

  # Get item id/revision_id
  set item_id [publish::get_main_item_id]
  set revision_id [publish::get_main_revision_id]

  # Concatenate all other keys into the extra arguments list
  set extra_args [publish::set_to_pairs $params]

  # Add code to flush the cache

  # Render the item, return the html
  set    command "publish::get_html_body \[publish::handle_item"
  append command " \$::content::item_id"
  append command " -html \{$extra_args\} -no_merge -embed"
  append command " -revision_id \[publish::get_main_revision_id\]\]"

  template::adp_append_code "append __adp_output \[$command\]" 
}
