# Massage the requesterror array into a list data source

foreach key [array names requesterror] {
  lappend requesterrors $requesterror($key)
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
