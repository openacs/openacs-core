ad_library {

  @author rhs@mit.edu
  @creation-date 2000-09-09
  @cvs-id $Id$
}

ad_proc -private ad_raise {exception {value ""}} {
  @author rhs@mit.edu
  @creation-date 2000-09-09

  Raise an exception.

  If you use this I will kill you.
} {
  return -code error -errorcode [list "AD" "EXCEPTION" $exception] $value
}

ad_proc -private ad_try {code args} {

  @author rhs@mit.edu
  @creation-date 2000-09-09

  Executes $code, catches any exceptions thrown by ad_raise and runs
  any matching exception handlers.

  If you use this I will kill you.

  @see with_finally 
  @see with_catch
} {
  global errorInfo errorCode

  if {[set errno [catch {uplevel $code} result]]} {
    if {$errno == 1 && [string equal [lindex $errorCode 0] "AD"] && \
	[string equal [lindex $errorCode 1] "EXCEPTION"]} {
      set exception [lindex $errorCode 2]

      set matched 0
      for {set i 0} {$i < [llength $args]} {incr i 3} {
	if {[string match [lindex $args $i] $exception]} {
	  set matched 1
	  break
	}
      }

      if $matched {
	upvar [lindex $args [expr $i + 1]] var
	set var $result
	set errno [catch {uplevel [lindex $args [expr $i + 2]]} result]
      }
    }

    return -code $errno -errorcode $errorCode -errorinfo $errorInfo $result
  }
}
