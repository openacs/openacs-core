ad_page_contract {
  A tiny chat client

  @author Gustaf Neumann (gustaf.neumann@wu-wien.ac.at)
  @creation-date Jan 31, 2006
  @cvs-id $Id$

} -query {
  m:oneof(add_msg|get_new|subscribe|login|get_all)
  id:integer
  s
  msg:optional,allhtml
  class:token
  {mode ""}
}

#
# Ensure chat is supported on this system. This currently requires the
# xowiki package.
#
if {[namespace which ::xo::ChatClass] eq "" ||
    ![::xo::ChatClass is_chat_p $class]} {
  ns_returnnotfound
  ad_script_abort
}

#
# We need an object to enforce permissions. If the chat id is not that
# of an object, we will use the package id.
#
set object_id [db_string lookup_object {
  select object_id
    from acs_objects
  where object_id = :id
} -default [ad_conn package_id]]

if {[acs_object::is_type_p \
         -object_id $object_id \
         -object_types chat_room]} {
  #
  # chat package has its own permission checking
  #
  set class ::chat::Chat
} else {
  #
  # On other types of objects, we at least make sure the user can
  # read.
  #
  ::permission::require_permission \
      -object_id $object_id \
      -privilege "read"
}

#ns_log notice "### chat.tcl mode <$mode> class <$class>"
#ns_log notice "--chat m=$m session_id=$s [clock format [lindex [split $s .] 1] -format %H:%M:%S] mode=$mode"
$class create c1 -destroy_on_cleanup -chat_id $id -session_id $s -mode $mode
switch -- $m {
  add_msg {
    #ns_log notice "--c call c1 $m '$msg'"
    ns_return 200 application/json [c1 $m $msg]
  }
  get_new {
    ns_return 200 application/json [c1 $m]
  }
  subscribe {
    #
    # This method might take the current connection for the
    # subscription. If this is the case, the connection is after
    # this call already closed. Otherwise return a short acknowledge
    # (or error message) for termination.
    #
    set _ [c1 $m]
    if {[ns_conn isconnected]} {
      ns_return 200 text/html [subst {<HTML><body>$_</body></HTML>}]
    }
  }
  login -
  get_all {
    set _ [c1 $m]
    ns_return 200 text/html [subst {<HTML><body>$_</body></HTML>}]
  }
}

ad_script_abort

#ns_log notice "--chat.tcl $m: returns '$_'"

# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
