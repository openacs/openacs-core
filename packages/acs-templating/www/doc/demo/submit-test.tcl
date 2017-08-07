form create submit_test
element create submit_test name -label "Name" \
  -widget text -datatype text -size 20
element create submit_test over -label "I am over 18" \
  -widget submit -datatype text
element create submit_test under -label "I am young and impressionable" \
  -widget submit -datatype text

if { [form is_valid submit_test] } {
  form get_values submit_test over under name
  if { ![template::util::is_nil over] } {
    set text "Naughty-naughty, $name."
  } elseif { ![template::util::is_nil under] } {
    set text "Quick ! Close your eyes, young $name !"
  }
} else {
  set text "SUBMIT already !"
}
  

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
