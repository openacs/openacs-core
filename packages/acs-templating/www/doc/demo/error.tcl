
if { [clock clicks -milliseconds] % 2 } {
  lappend problems is_odd "You caught the page on an odd tick."
  lappend problems another_thing "This is just another error."
}

if { [info exists problems] } {

  eval request error $problems

  # Note that you must explicitly return from the tcl script following an error.
  return
}

# Set up some data sources...


