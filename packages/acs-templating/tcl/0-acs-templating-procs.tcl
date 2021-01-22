ad_library {
    Initialize namespaces, global macros and filters for ArsDigita Templating
    System

    @author Karl Goldstein (karlg@arsdigita.com)

    @cvs-id $Id$
}

# Initialize namespaces used by template procs

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


ad_proc -public template_tag { name arglist body } {
    Generic wrapper for registered tag handlers.
} {

  # LARS:
  # We only ns_adp_registerscript the tag if it hasn't already been registered
  # (if the proc doesn't exist).
  # This makes debugging templating tags so much easier, because you don't have
  # to restart the server each time.
  set exists_p [llength [info commands template_tag_$name]]

  switch [llength $arglist] {

    1 { 

      # empty tag
      eval "proc template_tag_$name { params } {
	
	template::adp_tag_init $name
	
	$body

        return \"\"
      }"

      if { !$exists_p } {
        ns_adp_registerscript $name template_tag_$name 
      }
    }

    2 { 

      # balanced tag so push on/pop off tag name and parameters on a stack
      eval "proc template_tag_$name { chunk params } {
	
	template::adp_tag_init $name

	variable template::tag_stack
	lappend tag_stack \[list $name \$params\]
	
	$body

	template::util::lpop tag_stack

        return \"\"
      }"

      if { !$exists_p } {
        ns_adp_registerscript $name /$name template_tag_$name 
      }
    }

    default { error [_ acs-templating.Tag_handler_invalid_number_of_args] }
  }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
