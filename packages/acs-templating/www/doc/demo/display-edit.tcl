ad_page_contract {
} {
  {grid ""}
} -properties {}

if { [info exists cancel] } {
  ad_returnredirect [ad_conn url]
  ad_script_abort
}

form create sandwich -mode display -cancel_url [ad_conn url]

element create sandwich grid \
  -label "grid" -optional \
  -datatype text -widget hidden

element create sandwich nickname -html { size 30 } \
  -label "Sandwich Name" -datatype text  -section "Name"

element create sandwich protein \
 -label "Protein" -datatype text -widget radio \
 -options { {Bacon bacon} {Chicken chicken} {Beef beef} } -section "Contents"

element create sandwich vitamins \
 -label "Vitamins" -datatype text -widget checkbox -optional \
 -options { {Lettuce lettuce} {Tomato tomato} \
            {Pickle pickle} {Sprouts sprouts} } -section "Contents"

element create sandwich comments \
 -label "Comments" -datatype text -widget textarea -optional -section "Details" -help_text "For your own sake."

element create sandwich creation_date \
    -label "Created date" -datatype date -widget date -optional -format {Month DD, YYYY} -section "Details"



# Set defaults
if { [form is_request sandwich] } {
  element set_properties sandwich vitamins -value {tomato}
  # or: element set_value sandwich vitamins tomato
  element set_properties sandwich grid -value $grid
}

# Choose standard or gridded output
if {[element get_value sandwich grid] == "t"} {
  ad_return_template sandwich-grid
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
