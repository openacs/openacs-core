ad_page_contract {
  @cvs-id $Id$
} {
  {grid ""}
} -properties {}


form create sandwich

element create sandwich grid \
  -label "grid" -optional \
  -datatype text -widget hidden

element create sandwich nickname -html { size 30 } \
  -label "Sandwich Name" -datatype text

element create sandwich protein \
 -label "Protein" -datatype text -widget radio \
 -options { {Bacon bacon} {Chicken chicken} {Beef beef} }

element create sandwich vitamins \
 -label "Vitamins" -datatype text -widget checkbox -optional \
 -options { {Lettuce lettuce} {Tomato tomato} \
            {Pickle pickle} {Sprouts sprouts} }

# Set defaults
if { [form is_request sandwich] } {
  element set_properties sandwich vitamins -value {tomato}
  # or: element set_value sandwich vitamins tomato
  element set_properties sandwich grid -value $grid
}

# Choose standard or gridded output
if {[element get_value sandwich grid] eq "t"} {
  ad_return_template sandwich-grid
}
