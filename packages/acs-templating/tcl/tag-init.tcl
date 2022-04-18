ad_library {
    Tag Handlers for the ArsDigita Templating System

    Copyright (C) 1999-2000 ArsDigita Corporation
    Authors: Karl Goldstein         (karlg@arsdigita.com)
             Stanislav Freidin      (sfreidin@arsdigita.com)
             Christian Brechbuehler (chrisitan@arsdigita.com)

    $Id$

    This is free software distributed under the terms of the GNU Public
    License.  Full text of the license is available from the GNU Project:
    http://www.fsf.org/copyleft/gpl.html
}

#-----------------------------------------------------------
# Putting tag handlers in namespaces does not seem to work!
#-----------------------------------------------------------

template::tag tcl { chunk params } {
    #
    # Add some escaped Tcl
    #

    # if the chunk begins with = then add our own append
    if { [string index $chunk 0] eq "=" } {
        template::adp_append_code "append __adp_output [string range $chunk 1 end]"
    } else {
        template::adp_append_code $chunk
    }
}

template::tag property { chunk params } {
    #
    # Set a property for the template.  Properties are primarily for
    # the benefit of the master template to display appropriate
    # context, such as the title, navigation links, etc.
    #

    set name [ns_set iget $params name]
    set adp  [ns_set iget $params adp]
    if {$adp eq ""} {set adp 0}

    # quote dollar signs, square bracket and quotes
    regsub -all -- {[\]\[\"\\$]} $chunk {\\&} quoted_chunk
    if {$adp} {
        regsub -all -- {<tcl>} $quoted_chunk {<%} quoted_chunk
        regsub -all -- {</tcl>} $quoted_chunk {%>} quoted_chunk

        template::adp_append_code "set __adp_properties($name) \[ns_adp_parse -string \"$quoted_chunk\"\]"
    } else {
        template::adp_append_code "set __adp_properties($name) \"$quoted_chunk\""
    }
}

template::tag master { params } {
    #
    # Set the master template.
    #

    set src [ns_set iget $params src]
    set slave_properties_p [template::get_attribute master $params slave-properties-p 0]

    if {[template::util::is_true $slave_properties_p]} {
        template::adp_append_code {
            foreach {__key __value} $__args {
                if {$__key ne "__adp_slave"} {
                    set __adp_properties($__key) $__value
                }
            }
        }
    }

    # default to the site-wide master
    if {$src eq ""} {
        set src {[parameter::get -package_id [ad_conn subsite_id] -parameter DefaultMaster -default "/www/default-master"]}
    }

    template::adp_append_code [subst -nocommands {
        set __adp_master [template::util::master_to_file "$src" "\$__adp_stub"]
    }]
}

template::tag slave { params } {
    #
    # Insert the slave template
    #

    #Start developer support frame around subordinate template.
    if { [namespace which ::ds_enabled_p] ne ""
         && [namespace which ::ds_adp_start_box] ne "" } {

        ::ds_adp_start_box
    }

    template::adp_append_code {
        if { [info exists __adp_slave] } {
            append __adp_output $__adp_slave
        }
    }

    #End developer support frame around subordinate template.
    if { [namespace which ::ds_enabled_p] ne ""
         && [namespace which ::ds_adp_end_box] ne "" } {

        ::ds_adp_end_box
    }

}

ad_proc -private template::template_tag_include_helper_code {
    -command
    -src
    {-ds_avail_p 0}
} {
    if {$ds_avail_p} {
        set __DS_CODE__ {
            if {[info exists ::ds_enabled_p] && [info exists ::ds_collection_enabled_p] } {
                set __include_errors {}
                ns_cache get ds_page_bits [ad_conn request]:error __include_errors
                ns_cache set ds_page_bits [ad_conn request]:error [lappend __include_errors [list "__SRC__" $::errorInfo]]
            }
        }
    } else {
        set __DS_CODE__ ""
    }

    # Handle errors in the included snippet the following way:
    # - script-aborts are passed to the upper levels via "ad_try".
    # - If the included snippet leads to an error, include
    #   it in the result and log it in the error log

    set snippet {
        ad_try {
            append __adp_output [__COMMAND__]

        } on error {errorMsg} {
            set templateFile [template::util::url_to_file __SRC__ $__adp_stub]
            append __adp_output "Error in include template \"$templateFile\": [ns_quotehtml $errorMsg]"
            # JCD: If we have the ds_page_bits cache maybe save the error for later
            __DS_CODE__
            ad_log Error "Error in include template \"$templateFile\": $errorMsg"
        }
    }

    #
    # In order to avoid potential problems with substitution
    # patterns containing ampersand or backslashes, we use here a
    # scripted, purely string based substitution (which applies only
    # at "compilation time", therefore, performance is less critical.
    #
    # We have still to protect the case, that the passed-in $src
    # contains "__COMMAND__" which has to be protected. The
    # __DS_CODE__ is under our control, the content of __COMMAND__
    # will not be substituted.
    #
    set containsMagicString [regsub -all __COMMAND__ $src \u0001 __SRC__]

    set __COMMAND__ $command
    foreach v {__DS_CODE__ __SRC__ __COMMAND__} {
        set startPos 0
        set s ""
        set l [string length $v]
        while {1} {
            set p [string first $v $snippet $startPos]
            if {$p == -1} {
                append s [string range $snippet $startPos end]
                break
            }
            append s [string range $snippet $startPos $p-1] [set $v]
            set startPos $p
            incr startPos $l
        }
        #ns_log notice "=== include SNIPPET after $v substitution\n$s"
        set snippet $s
    }
    if {$containsMagicString} {
        regsub -all \u0001 $snippet __COMMAND__ snippet
    }
    #ns_log notice "final include SNIPPET\n$snippet"
    return $snippet
}

ad_proc -private template::template_tag_include_command {src params} {
    # pass additional arguments as key-value pairs

    set command "template::adp_parse"
    append command " \[template::util::url_to_file \"$src\" \"\$__adp_stub\"\]"
    append command " \[list"

    foreach {key value} [ns_set array $params] {
        if {$key in {src ds}} { continue }
        append command [subst { $key "$value"}]
    }
    append command "\]"
    return $command
}

ad_proc -private template::template_tag_include_helper {params} {
    Include another template in the current template
} {
    set src [ns_set iget $params src]
    set ds [ns_set iget $params ds]
    if {$ds eq ""} {set ds 1}
    set ds_avail_p [expr {[namespace which ::ds_adp_start_box] ne "" }]

    #Start developer support frame around subordinate template.
    if { $ds && [namespace which ::ds_enabled_p] ne "" && $ds_avail_p } {
        ::ds_adp_start_box -stub "\[template::util::url_to_file \"$src\" \"\$__adp_stub\"\]"
    }

    template::adp_append_code [template::template_tag_include_helper_code \
                                   -ds_avail_p [expr {[namespace which ::ds_adp_start_box] ne "" }] \
                                   -src $src \
                                   -command [template::template_tag_include_command $src $params]]

    # End developer support frame around subordinate template.
    if { $ds && [namespace which ::ds_enabled_p] ne "" && $ds_avail_p } {
        ::ds_adp_end_box -stub "\[template::util::url_to_file \"$src\" \"\$__adp_stub\"\]"
    }
}

template::tag include { params } {
    #
    # Check, if the src can be resolved against resources/templates in
    # the theme package
    #
    ns_set update $params src [template::themed_template [ns_set iget $params src]]
    template::template_tag_include_helper $params
}

template::tag widget { params } {
    #
    # <widget> is very similar to <include>, but uses widget specific
    # name resolution based on themes.  If the theme package contains
    # resources/widgets/$specifiedName it is used from
    # there. Otherwise it behaves exactly like <include> (without the
    # resources/templates/ theming)
    #
    set src [ns_set iget $params src]
    set adp_stub [template::resource_path -type widgets -style $src -relative]
    if {[file exists $::acs::rootdir/$adp_stub.adp]} {
        ns_set update $params src $adp_stub
    }
    template::template_tag_include_helper $params
}

template::tag multiple { chunk params } {
    #
    # Repeat a template chunk for each row of a multirow data source
    #

    set name      [template::get_attribute multiple $params name       ]
    set startrow  [template::get_attribute multiple $params startrow  0]
    set maxrows   [template::get_attribute multiple $params maxrows  -1]; #unlimit
    set delimiter [template::get_attribute multiple $params delimiter ""]

    set tag_id [template::current_tag]

    set i "__${tag_id}_i"

    template::adp_append_code "

  if {\[info exists $name\]} {
      upvar 0 $name __${tag_id}_swap
  }

  for { set $i [expr {1 + $startrow}] } { \$$i <= \${$name:rowcount}"

    if {$maxrows >= 0} {
        template::adp_append_code " && \$$i <= $maxrows + $startrow" \
            -nobreak
    }

    template::adp_append_code " } { incr $i } {
    upvar 0 $name:\$$i $name
  " -nobreak
    template::adp_compile_chunk $chunk

    if { $delimiter ne "" } {
        template::adp_append_code " if { \$$i < \${$name:rowcount}"

        if {$maxrows >= 0} {
            template::adp_append_code " && \$$i < $maxrows + $startrow" \
                -nobreak
        }

        template::adp_append_code " } {\n"
        template::adp_append_string $delimiter
        template::adp_append_code "\n}\n"
    }

    template::adp_append_code "}

  if {\[info exists __${tag_id}_swap\]} {
      upvar 0 __${tag_id}_swap $name
  }"
}

template::tag list { chunk params } {
    #
    # Repeat a template chunk for each item in a list
    #

    # the list tag accepts a value so that it may be used without a data
    # source in the Tcl script

    set value [ns_set iget $params value]

    # If the value exists, use it and create a fake name for it

    if { ![template::util::is_nil value] } {

        set name [ns_set iget $params name]
        if { $name eq "" } {
            set name "__ats_list_value"
        }

        template::adp_append_code [list set $name $value]
        template::adp_append_code "set $name:rowcount \[llength \$$name\]\n"

    } else {

        # Expect a data source from the Tcl script
        set name [template::get_attribute list $params name]
        template::adp_append_code "\nset {$name:rowcount} \[llength \${$name}\]\n"
    }

    template::adp_append_code "

  for { set __ats_${name}_i 0 } { \$__ats_${name}_i < \${$name:rowcount} } { incr __ats_${name}_i } {
    set $name:item \[lindex \${$name} \$__ats_${name}_i\]
    set $name:rownum \[expr {\$__ats_${name}_i + 1}\]
  "
    template::adp_compile_chunk $chunk

    template::adp_append_code "}"
}

template::tag group { chunk params } {
    #
    # Create a recursed group, generating a recursive multirow block
    # until the column name stays the same
    #

    set column [template::get_attribute group $params column]
    set delimiter [template::get_attribute group $params delimiter ""]

    # Scan the parameter stack backward, looking for the tag name

    set multiple_tag_id [template::enclosing_tag multiple]

    if {$multiple_tag_id eq {}} {
        error "No enclosing MULTIPLE tag for GROUP tag on column $column"
    }

    # Get the name of the multiple variable we're looping over
    set name [template::tag_attribute $multiple_tag_id name]

    set tag_id [template::current_tag]

    # If we're inside another group tag, we'll need to save and restore that tag's groupnum and groupnum_last_p values
    # Find enclosing group tag, if one exists
    set group_tag_id [template::enclosing_tag group]

    # Save groupnum pseudocolumns from surrounding group tag
    # We don't care about saving groupnum_last_p, since this doesn't work
    # for group tags that have other group tags inside them, since we can't know
    # if we're the last row until the inner group tag has eaten up all the
    # rows between the start of this tag and the end.
    if { $group_tag_id ne "" } {
        template::adp_append_code "
      if { \[info exists ${name}(groupnum)\] } {
        set __${tag_id}_${group_tag_id}_groupnum \$${name}(groupnum)
      }
    "
    }

    set i "__${multiple_tag_id}_i"

    # while the value of name(column) stays the same
    template::adp_append_code "
    set __${tag_id}_group_rowcount 1
    while { 1 } {
      set ${name}(groupnum) \$__${tag_id}_group_rowcount
      if { \$$i >= \${$name:rowcount} } {
        set ${name}(groupnum_last_p) 1
      } else {
        upvar 0 ${name}:\[expr {\$$i + 1}\] $name:next
        set ${name}(groupnum_last_p) \[expr {\${${name}:next(${column})} ne \$${name}($column)}\]
      }
  "

    template::adp_compile_chunk $chunk

    # look ahead to the next value and break if it is different
    # otherwise advance the cursor to the next row
    template::adp_append_code [subst -nocommands {
        if { \$$i >= \${$name:rowcount} } {
            break
        }
        upvar 0 ${name}:[expr {\$$i + 1}] $name:next
        if { \${${name}:next($column)} ne \$${name}(${column}) } {
            break
        }
    }]

    if { $delimiter ne "" } {
        template::adp_append_string $delimiter
    }

    template::adp_append_code "
      incr $i
      upvar 0 $name:\$$i $name
      incr __${tag_id}_group_rowcount
    }
  "

    # Restore saved groupnum pseudocolumns
    if { $group_tag_id ne "" } {
        set varName __${tag_id}_${group_tag_id}_groupnum
        template::adp_append_code [subst -nocommands {
            if { [info exists $varName] } {
                set ${name}(groupnum) \$$varName
            }
        }]
    }
}

template::tag grid { chunk params } {
    #
    # Repeat a template chunk consisting of a grid cell for each row
    # of a multirow data source
    #

    set name [template::get_attribute grid $params name]
    # cols must be a float for ceil to work
    set cols [template::get_attribute grid $params cols]
    # Horizontal or vertical ?
    set orientation [template::get_attribute grid $params orientation vertical]

    template::adp_append_code "
  set rows \[expr {ceil(\${$name:rowcount} / $cols.0)}\]
  for { set __r 1 } { \$__r <= \$rows } { incr __r } {
    for { set __c 1 } { \$__c <= $cols } { incr __c } {
"

    if {$orientation eq "vertical"} {
        template::adp_append_code "
      set rownum \[expr {1 + int((\$__r - 1) + ((\$__c - 1) * \$rows))}\]
"
    } else {
        template::adp_append_code "
      set rownum \[expr {1 + int((\$__c - 1) + ((\$__r - 1) * $cols))}\]
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

template::tag if { chunk params } {
    template::template_tag_if_condition $chunk $params if
}

template::tag elseif { chunk params } {
    template::template_tag_if_condition $chunk $params elseif
}

template::tag else { chunk params } {
    #
    # Append an "else" clause to the if expression
    #

    template::adp_append_code "else {" -nobreak

    template::adp_compile_chunk $chunk

    template::adp_append_code "}"
}

template::tag noparse { chunk params } {
    #
    # Output a template chunk without parsing, for preprocessed
    # templates
    #

    # escape quotes
    regsub -all -- {[\]\[""\\$]} $chunk {\\&} quoted

    template::adp_append_string $quoted
}

template::tag formwidget { params } {
    #
    # Render the HTML for the form widget, incorporating any
    # additional markup attributes specified in the template.
    #

    set id [template::get_attribute formwidget $params id]

    # get any additional HTML attributes specified by the designer
    set tag_attributes [dict remove \
                            [ns_set array $params] \
                            id]

    template::adp_append_string \
        "\[template::element render \${form:id} [list $id] { $tag_attributes } \]"
}

template::tag formhelp { params } {
    #
    # Display the help information for an element
    #

    set id [template::get_attribute formhelp $params id]

    # get any additional HTML attributes specified by the designer
    set tag_attributes [dict remove \
                            [ns_set array $params] \
                            id]

    template::adp_append_string \
        "\[template::element render_help \${form:id} [list $id] { $tag_attributes } \]"
}

template::tag formerror { chunk params } {
    #
    # Report a form error if one is specified.
    #

    set id [template::get_attribute formerror $params id]
    set type [ns_set get $params type]

    if {$type eq {}} {
        set key $id
    } else {
        set key $id:$type
    }

    template::adp_append_code "
    if \{ \[info exists formerror($key)\] \} \{
      set formerror($id) \$formerror($key)
    "

    if {$chunk eq {}} {

        template::adp_append_string "\$formerror($key)"

    } else {

        template::adp_compile_chunk $chunk
    }

    template::adp_append_code "\}"
}

template::tag formgroup { chunk params } {
    #
    # Render a group of form widgets
    #

    set id [template::get_attribute formgroup $params id]

    # get any additional HTML attributes specified by the designer
    set tag_attributes [dict remove \
                            [ns_set array $params] \
                            id]

    # generate a list of options and option labels as a data source

    template::adp_append_code \
        "template::element options \${form:id} [list $id] { $tag_attributes }"

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

template::tag formgroup-widget { chunk params } {
    #
    # Render one element from a formgroup
    #

    set id [template::get_attribute formgroup-widget $params id]

    set row [template::get_attribute formgroup-widget $params row]
    # get any additional HTML attributes specified by the designer
    set tag_attributes [dict remove \
                            [ns_set array $params] \
                            id row]

    # generate a list of options and option labels as a data source

    template::adp_append_code \
        "template::element options \${form:id} [list $id] { $tag_attributes }"

    # make sure name is a parameter to pass to the rendering tag handler
    ns_set update $params name formgroup
    ns_set update $params id formgroup
    template::adp_append_code "append __adp_output \"\$\{formgroup:${row}(widget)\} \$\{formgroup:${row}(label)\}\""

}

template::tag formtemplate { chunk params } {
    #
    # Render a form, incorporating any additional markup attributes
    # specified in the template.  Set the magic variable "form:id" for
    # elements to reference
    #

    set level [template::adp_level]
    set id [template::get_attribute formtemplate $params id]

    upvar #$level $id:properties form_properties

    template::adp_append_code [list set form:id $id]

    # Set optional attributes for the grid template
    template::adp_append_code \
        [list upvar 0 $id:properties form_properties]

    foreach varname {headers title cols} {

        set form_properties($varname) [ns_set iget $params $varname]
        template::adp_append_code \
            [list set form_properties($varname) $form_properties($varname)]
    }

    # get any additional HTML attributes specified by the designer
    set tag_attributes [dict remove \
                            [ns_set array $params] \
                            id style method title cols headers]

    template::adp_append_string \
        [subst -nocommands {[template::form render $id { $tag_attributes } ]}]

    if {[string trim $chunk] eq {}} {

        # generate the form body dynamically if none specified.
        set style [ns_set iget $params style]
        template::adp_append_string "\[template::form generate $id $style\]"

    } else {

        # compile the static form layout specified in the template
        template::adp_compile_chunk $chunk

        # Render any hidden variables that have not been rendered yet
        template::adp_append_string \
            [subst -nocommands {[template::form check_elements $id]}]
    }

    if { [info exists form_properties(fieldset)] } {
        template::adp_append_string "</fieldset>"
    }
    template::adp_append_string "</form>"
}

template::tag child { params } {
    #
    # @private tag_child
    #
    # Implements the <tt>child</tt> tag which renders a child item.
    # See the Developer Guide for more information. <br> The child tag
    # format is <blockquote><tt> &lt;child tag=<i>tag</i> index=<i>n
    # embed args</i>&gt; </blockquote>
    #
    # @param params  The ns_set id for extra HTML parameters
    #

    publish::process_tag child $params
}

template::tag relation { params } {
    #
    # @private tag_relation
    #
    # Implements the <tt>relation</tt> tag which renders a related
    # item.  See the Developer Guide for more information. <br> The
    # relation tag format is <blockquote><tt> &lt;relation
    # tag=<i>tag</i> index=<i>n embed args</i>&gt; </tt></blockquote>
    #
    # @param params  The ns_set id for extra HTML parameters
    #

    publish::process_tag relation $params
}

template::tag content { params } {
    #
    # @private tag_content
    #
    # Implements the <tt>content</tt> tag which renders the content of
    # the current item.  See the Developer Guide for more
    # information. <br> The content tag format is simply
    # <tt>&lt;content&gt;</tt>. The <tt>embed</tt> and
    # <tt>no_merge</tt> parameters are implicit to the tag.
    #
    # @param params  The ns_set id for extra HTML parameters
    #

    # Get item id/revision_id
    set item_id [publish::get_main_item_id]
    set revision_id [publish::get_main_revision_id]

    # Concatenate all other keys into the extra arguments list
    set extra_args [ns_set array $params]

    # Add code to flush the cache

    # Render the item, return the html
    set    command "publish::get_html_body \[publish::handle_item"
    append command " \$::content::item_id"
    append command " -html \{$extra_args\} -no_merge -embed"
    append command " -revision_id \[publish::get_main_revision_id\]\]"

    template::adp_append_code "append __adp_output \[$command\]"
}

template::tag include-optional { chunk params } {
    #
    # Include another template in the current template, but make some
    # other chunk dependent on whether or not the included template
    # returned something.
    #
    # This is useful if, say, you want to wrap the template with some
    # HTML, for example, a frame in a portal, but if there's nothing
    # to show, you don't want to show the frame either.
    #
    # @author Lars Pind (lars@collaboraid.net)
    #

    #
    # Check, if the src can be resolved against resources/templates in
    # the theme package
    #
    set src [template::themed_template [ns_set iget $params src]]
    set ds [ns_set iget $params ds]
    if {$ds eq ""} {set ds 1}

    #Start developer support frame around subordinate template.
    if { $ds && [namespace which ::ds_enabled_p] ne ""
         && [namespace which ::ds_adp_start_box] ne ""} {

        ::ds_adp_start_box -stub "\[template::util::url_to_file \"$src\" \"\$__adp_stub\"\]"
    }

    set command [template::template_tag_include_command $src $params]

    # __adp_include_optional_output is a list that operates like a
    # stack, so first we execute the include template, and push the
    # result onto this stack, then, if the output contained anything
    # but whitespace, we also output the chunk inside the
    # include-optional tag.  Finally, we pop the output off of the
    # __adp_include_optional_output stack.

    template::adp_append_code "ad_try { lappend __adp_include_optional_output \[$command\] } on error {errmsg} {"
    template::adp_append_code "    append __adp_output \"Error in include template \\\"\[template::util::url_to_file \"$src\" \"\$__adp_stub\"\]\\\": \[ns_quotehtml \$errmsg\]\""
    template::adp_append_code "    ad_log Error \"Error in include template \\\"\[template::util::url_to_file \"$src\" \"\$__adp_stub\"\]\\\": \$errmsg\""
    template::adp_append_code "} on ok {r} {"
    template::adp_append_code "if { \[string trim \[lindex \$__adp_include_optional_output end\]\] ne {} } {"

    template::adp_compile_chunk $chunk
    template::adp_append_code "
    }
    template::util::lpop __adp_include_optional_output
  }
  "

    #End developer support frame around subordinate template.
    if { $ds && [namespace which ::ds_enabled_p] ne ""
         && [namespace which ::ds_adp_end_box] ne "" } {
        ::ds_adp_end_box -stub [
                                subst -nocommands {[template::util::url_to_file "$src" "\$__adp_stub"]}]
    }

}

template::tag include-output { params } {
    #
    # Insert the output from the include-optional tag
    #
    # @author Lars Pind (lars@collaboraid.net)
    #

    template::adp_append_code {
        if { [info exists __adp_include_optional_output] } {
            append __adp_output [lindex $__adp_include_optional_output end]
        }
    }
}

template::tag trn { chunk params } {
    # DRB: we have to do our own variable substitution as the template
    # framework doesn't handle it for us ... being able to use page
    # variables here is consistent with the rest of the templating
    # engine.
    # LARS: Note that this version of the <TRN> tag requires a body,
    # like this: <trn key="...">default</trn>.
    # This is the way to give a default value, and is okay, because we
    # now have the #...# notation for when there's no default value.
    # Will register the key in the message catalog if it doesn't exist.

    foreach {key value} [ns_set array $params] {
        # substitute array variables
        regsub {@([a-zA-Z0-9_]+)\.([a-zA-Z0-9_.]+)@} $value {${\1(\2)}} $key
        # substitute regular variables
        regsub {@([a-zA-Z0-9_:]+)@} $value {${\1}} $key
    }

    # And this needs to be executed at page execution time due to
    # interactions with the preferences changing code.  This is
    # consistent with what the way #notation# is handled (the ad_conn
    # call is dumped into the code, not executed on the spot)

    if { ![info exists locale] } {
        # We need this to be executed at template execution time,
        # because the template's compiled code will be cached and
        # reused for many requests.
        set locale "\[ad_conn locale\]"
    } else {
        # Check to see if we should register this into the message
        # catalog
        if { [string length $locale] == 2 } {
            set locale [lang::util::default_locale_from_lang $locale]
        }

        # Check the cache
        if { ![lang::message::message_exists_p $locale $key] } {
            lang::message::register $locale $key $chunk
        }
    }

    # quote dollar signs, square bracket and quotes
    regsub -all -- {[\]\[""\\$]} $chunk {\\&} quoted_chunk

    template::adp_append_code \
        [subst -nocommands {append __adp_output [_ $locale $key $quoted_chunk]}]
}

template::tag switch { chunk params } {
    #
    # DanW: implements a switch statement just like in Tcl
    # use as follows:
    #
    # <switch flag=regexp @some_var@>
    #     <case in "foo" "bar" "baz">
    #         Foo, Bar or Baz was selected
    #     </case>
    #     <case value="a.+">
    #         A was selected
    #     </case>
    #     <case value="b.+">
    #         B was selected
    #     </case>
    #     <case value="c.+">
    #         C was selected
    #     </case>
    #     <default>
    #         Not a valid selection
    #     </default>
    # </switch>
    #
    # The flag switch is optional and it defaults to exact if not specified.
    # Valid values are exact, regexp, and glob
    #

    set sw ""
    set arg ""

    # get the switch flags and the switch var
    foreach {key value} [ns_set array $params] {
        if {$key eq $value} {
            set arg $key
        } elseif {$key eq "flag"} {
            append sw " -$value "
        }
    }

    # append the switch statement and eval tags in between

    template::adp_append_code "switch $sw -- $arg {"
    template::adp_compile_chunk $chunk
    template::adp_append_code "}"
}

template::tag case { chunk params } {
    #
    # case tag, to be used inside of the switch tag
    #

    # Scan the parameter stack backward, looking for the tag name

    set tag_id [template::enclosing_tag switch]
    if {$tag_id eq {}} {
        error "No enclosing SWITCH tag for CASE tag on value $value"
    }

    # get the case value

    set value [ns_set iget $params value]

    # insert the case statement and eval the chunk in between

    if { $value ne "" } {

        # processing <case value= ...> form

        template::adp_append_code "[list $value] {" -nobreak

        template::adp_compile_chunk $chunk

        template::adp_append_code "}"

    } else {

        # processing <case in ...> form

        set switches ""
        set size [ns_set size $params]
        set size_1 [expr {$size - 1}]

        for { set i 0 } { $i < $size } { incr i } {

            set key [ns_set key $params $i]
            set value [ns_set value $params $i]

            # pass over the first arg (syntax sugar), but check format
            if { $i == 0 } {

                if {$key ne "in" } {
                    error "Format error: should be <case in \"foo\" \"bar\" ...>"
                }

            } else {

                if {$key eq $value} {

                    # last item in list so process the chunk
                    if { $i == $size_1 } {

                        template::adp_append_code "$switches $value {" -nobreak

                        template::adp_compile_chunk $chunk

                        template::adp_append_code "}"

                    } else {

                        # previous items default to pass-through
                        append switches " $key - "
                    }

                } else {
                    error "Format error: should be <case in \"foo\" \"bar\" ...>"
                }
            }
        }
    }
}

template::tag default { chunk params } {
    #
    # default value for case statement which is a sub-tag in switch
    # tag
    #

    # Scan the parameter stack backward, looking for the tag name

    set tag_id [template::enclosing_tag switch]
    if {$tag_id eq {}} {
        error "No enclosing SWITCH tag for DEFAULT tag"
    }

    # insert the default value and evaluate the chunk

    template::adp_append_code "default {" -nobreak
    template::adp_compile_chunk $chunk
    template::adp_append_code "}"
}

template::tag contract { chunk params } {
    #
    # contract tag for adding inline
    # documentation to adp files.
    #
    # @author Ben Bytheway (ben@vrusp.com)
    #
}

template::tag comment { chunk params } {
    #
    # comment tag for adding inline
    # documentation to adp files.
    #
    # @author Ben Bytheway (ben@vrusp.com)
    #
}



template::tag box { chunk params } {
    set class [ns_set iget $params class]
    set title [ns_set iget $params title]

    template::adp_append_code [subst -nocommands {append __adp_output "
<div class='portlet-wrapper'>
<div class='portlet-header'>
<div class='portlet-title-no-controls'>
<h1>$title</h1>
</div>
</div>
<div class='portlet'>"}]
    template::adp_compile_chunk $chunk
    template::adp_append_code "append __adp_output {</div></div>}"
}


namespace eval ::template::icon {
    set ::template::icon::map {
        bootstrap-icons {
            checkbox-checked check2-square
            checkbox-unchecked square
            edit pencil-square
            eye-closed eye-slash
            eye-open eye
            file file-earmark
            form-info-sign info-square
            radio-checked check2-circle
            radio-unchecked circle
            reload arrow-clockwise
            text file-earmark-text
            watch eye
        }
        fa-icons {
            arrow-down           "fa-solid fa-arrow-down"
            arrow-up             "fa-solid fa-arrow-up"
            checkbox-checked     "fa-regular fa-square-check"
            checkbox-unchecked   "fa-regular fa-square"
            edit                 "fa-regular fa-pen-to-square"
            eye-closed           "fa-regular fa-eye-slash"
            eye-open             "fa-regular fa-eye"
            file                 "fa-regular fa-file"
            form-info-sign       "fa-solid fa-circle-info"
            radio-checked        "fa-regular fa-circle-check"
            radio-unchecked      "fa-regular fa-circle"
            reload               "fa-solid fa-arrows-rotate"
            text                 "fa-regular fa-file-lines"
            trash                "fa-regular fa-trash-can"
            watch                "fa-regular fa-eye"
        }
        glyphicons {
            checkbox-checked check
            checkbox-unchecked unchecked
            download download-alt
            edit pencil
            eye-closed eye-close
            eye-open eye-open
            file file
            form-info-sign info-sign
            radio-checked record
            radio-unchecked /shared/images/radio.gif
            reload refresh
            text file
            watch eye-open
        }
        classic {
            arrow-down /resources/acs-subsite/arrow-down.gif
            arrow-up /resources/acs-subsite/arrow-up.gif
            checkbox-checked /shared/images/checkboxchecked.gif
            checkbox-unchecked /shared/images/checkbox.gif
            edit  /shared/images/Edit16.gif
            folder /resources/file-storage/folder.gif
            list ""
            radio-checked /shared/images/radiochecked.gif
            radio-unchecked /shared/images/radio.gif
            reload ""
            trash /shared/images/Delete16.gif
            watch ""
        }
    }
}

template::tag adp:icon { params } {
    set d [::template::icon \
               -alt [ns_set iget $params alt] \
               -class [ns_set iget $params class] \
               -iconset [ns_set iget $params iconset] \
               -name [ns_set iget $params name] \
               -style [ns_set iget $params style] \
               -title [ns_set iget $params title]]
    dict with d {
        template::adp_append_string $HTML
        if {$cmd ne ""} {
            template::adp_append_code $cmd
        }
    }
}

template::tag adp:toggle_button { chunk params } {
    #
    # In case we need to determine the toolit upon every call, we have
    # to reconsider (e.g. add the toolkit to the namespace for
    # compiled code, like template::code::adp::...)
    #
    set data [expr {[template::toolkit] eq "bootstrap5" ? "data-bs" : "data"}]
    append value \
        "<button type='button'" \
        " class='[ns_set iget $params class]'" \
        " $data-toggle='[ns_set iget $params toggle]'" \
        " $data-target='[ns_set iget $params target]'>"
    template::adp_append_string $value
    template::adp_compile_chunk $chunk
    template::adp_append_string </button>
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
