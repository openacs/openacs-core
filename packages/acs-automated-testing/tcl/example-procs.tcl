##############################################################################
#
#   Copyright 2001, OpenACS, Peter Harper.
#
#   This file is part of acs-automated-testing
#
##############################################################################

ad_library {
    Example procedures with which to demonstrate the acs-automated-testing
    automated testing platform.
 
    @author Peter Harper (peter.harper@open-msg.com)
    @creation-date 24 July 2001
    @cvs-id $Id$
}
 
ad_proc -public aa_example_write_audit_entry {
  name
  value
} {
  @author Peter Harper
  @creation-date 24 July 2001
} {
  ns_log debug "aa_example_write_audit_entry: Auditing: $name, $value"
  return 1
}
 
ad_proc -public aa_example_write_audit_entries {
  entries
} {
  @author Peter Harper
  @creation-date 24 July 2001
} {
  foreach entry $entries {
    set name [lindex $entry 0]
    set value [lindex $entry 1]
    set result [aa_example_write_audit_entry $name $value]
    if {$result == 0} {
      return 0
    }
  }
  return 1;
}
