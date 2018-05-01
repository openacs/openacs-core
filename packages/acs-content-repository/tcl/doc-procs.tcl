###################################
#
# Process function headers and return comments in JavaDoc format. sort of.
#
##################################

namespace eval doc {


    ad_proc -public package_info { package_name info_ref } {
	Set up a data source with overall package info
	(overview, see also, etc.)
    } {
        
        upvar $info_ref info
        
        set info_source [db_string get_info ""]
        
# Delete leading stars and dashes
        regsub -all -line -- {^( |--|\*|/\*\*|\*/)*} $info_source "" info_source
        
# Get the comment block
        regexp {[^@]*} $info_source comment
        set info(comment) $comment
        
        if {[regexp {@see (.*)} $info_source x see]} {
            foreach s [split $see ","] {
                # strip braces
                regsub {\{([^\}]+)\}} $s {\1} s
                lappend see_links $s
            }
        }
        if { [info exists see_links] } {
            set info(see) $see_links
        }
    }


    ad_proc -public get_proc_header { proc_name package_name doc_ref code_ref { db "" } } {
	Retrieve the function header for a specific function
	and parse out the javadoc comment.
    } {

    variable start_text;
    variable end_text;

    upvar $doc_ref  doc
    upvar $code_ref code

    set header [db_string get_header ""]

    # Get JavaDoc block, if any
    if { [regexp {/\*\*(.*)\*/} $header match] } {
      # Strip off the leading --, *, /**, */
      regsub -all -line -- {^( |--|\*|/\*\*|\*/)*} $match "" doc
      # Take the doc out of the code
      regsub  -- { *--/\*\*.*\*/(\n*)} $header "" code
    } else {
      set doc ""
      set code $header
    }
  }

 
    ad_proc -public parse_proc_header { doc_block code_block param_ref tags_ref code_ref {level 2}} {
	Parse the header block and prepare the datasources:
	Prepare a multirow datasource for the param tags
	Prepare a onerow datasource for all the other tags
    } {
  
    upvar $level "${param_ref}:rowcount" param_rowcount   
    upvar $level $tags_ref tags
    set param_rowcount 0

    set tags(code) $code_block
        
    # Go through all the tags and stick them in the appropriate datasources
    set remaining_doc $doc_block 
    while { [regexp {[^@]*@([a-zA-Z0-9_-]+) +([^@]*)(.*?)} $remaining_doc match tag data remaining_doc] } {
      if { [string equal -nocase $tag "param"] } {
        if { [regexp {([^ ]+) +(.*)} $data match name value] } {
          incr param_rowcount
          upvar $level "${param_ref}:$param_rowcount" row
          set row(name) $name
          set row(value) $value
          set row(rownum) $param_rowcount
	}
      } else {
        set tags($tag) [string trim $data]
      }
    }

    # Get all the stuff that is not a tag (at the top)
    if { ![info exists tags(header)] } {
      set doc_head ""
      regexp {[^@]*} $doc_block doc_head
      set tags(header) $doc_head
    }

    # Determine whether we have a procedure or a function
    if { ![info exists tags(type)] } {
      if { [regexp -nocase -line {(procedure|function) .*$} $code_block match type] } {
        set tags(type) [string totitle $type]
      } else {
        set tags(type) "Subprogram"
      }
    }

    upvar $level $code_ref code
    set code $code_block
  }


    ad_proc -public get_proc_doc { proc_name package_name param_ref tags_ref code_ref args } {
	Query the database and prepare the datasources
	The user should call this procedure
    } {
 
    upvar $tags_ref tags

    set opts(db) ""
    template::util::get_opts $args

    get_proc_header $proc_name $package_name doc_block code_block $opts(db)
    parse_proc_header $doc_block $code_block $param_ref $tags_ref $code_ref

    # Get the proc name
    if { ![info exists tags(name)] } {
      set tags(name) "${package_name}.${proc_name}"
    }

    # Modify the "see" tag to dislplay links
    if { [info exists tags(see)] } {
      if { ![info exists opts(link_url_stub)] } {
        # Just remove the links
        regsub -all {\{([^\}]*)\}} $tags(see) {\1} new_see
        set tags(see) $new_see
      } else {
        if { ![info exists opts(link_package_name)] } {
          set opts(link_package_name) package_name
	}
        if { ![info exists opts(link_proc_name)] } {
          set opts(link_proc_name) proc_name
	}
       
        regsub -all {\&} $opts(link_url_stub) {\\\&} stub
        set subspec "<a href=\"${stub}${opts(link_package_name)}=\\1\\&$opts(link_proc_name)=\\2\">\\1.\\2</a>"
        regsub -all {\{([a-zA-Z0-9_]+)\.([a-zA-Z0-9_]+)\}} $tags(see) $subspec new_see
        set tags(see) $new_see
      }        
    }

  }

    ad_proc -public package_list { {db ""} } {
	Return a list of all the packages in the data model, in form
	{ {label value} {label value} ... }
    } {

	set result [db_list_of_lists get_packages ""]
	
	return $result
    }  

    ad_proc -public func_list { package_name {db ""} } {
	Return a list of all the function creation headers in a package, in form { value value ... }
    } {

      set result [db_list_of_lists get_funcs ""]

    set line_opts [list]
    foreach line $result {
      # Only get lines in form "procedure proc_name..." or "function func_name..."
      if { [regexp {(procedure|function)[^a-zA-Z0-9_]*([a-zA-Z0-9_]+)} $line match type name] && 
	   ![regexp {\-\-} $line match]} {
        lappend line_opts [list "[string totitle $type] [string tolower $name]" \
                            [string tolower $name]]
      }
    }
 
    return $line_opts
  }  


    ad_proc -public func_multirow { package_name result_ref {db ""} } {
	Return a multirow datatsource for all the functions
	{ value value ... }
    } {

    upvar "${result_ref}:rowcount" result_rowcount
    set result_rowcount 0

    # Get each line that contains "procedure" or "function" in it
    # Pretty risky... The like query should be improved to return 
    # fewer false matches
    db_multirow result get_functions "" {

      # Only insert a row into the datasource if it looks like a procedure
      # or function definition
      # Maybe this should ignore comments, too ? [^-]* at the beginning
      if { [regexp {(procedure|function)[^a-zA-Z0-9_]*([a-zA-Z0-9_]+)} \
             $line_header match type name] && 
	   ![regexp {\-\-} $line_header match]} {
        incr result_rowcount
        upvar "${result_ref}:${result_rowcount}" result_row
        set result_row(rownum) $result_rowcount
        set result_row(type) [string totitle $type]
        set result_row(name) [string tolower $name]
      }
    }
  }   
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
