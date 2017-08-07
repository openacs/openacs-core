
if { [clock clicks -milliseconds] % 2 } {
  lappend problems is_odd "You caught the page on an odd tick."
  lappend problems another_thing "This is just another error."
}

if { [info exists problems] } {

  request error {*}$problems

  # Note that you must explicitly return from the Tcl script following an error.
  return
}

# Set up some data sources...



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
