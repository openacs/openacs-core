request create -params {
  id -datatype integer -label "ID"
  key -datatype keyword -label "Key"
}


if { ! [request is_valid] } { return }

