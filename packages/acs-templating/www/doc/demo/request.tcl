request create -params {
  id -datatype integer -label "ID"
  key -datatype keyword -label "Key"
}


if { ! [request is_valid] } { return }


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
