ad_page_contract {
  @cvs-id $Id$
} {
  {grid:boolean ""}
} -properties {}

set title "Sandwich Demo"

form create sandwich -has_submit 1 \
    -elements {
        grid -label "grid" -optional -datatype text -widget hidden
    
        nickname -html { size 30 } -label "Sandwich Name" -datatype text
    
        protein -label "Protein" -datatype text -widget radio \
            -options { \
                           {Bacon bacon} \
                           {Chicken chicken} \
                           {Beef beef} \
                       }
    
        vitamins -label "Vitamins" -datatype text -widget checkbox -optional \
            -options { \
                           {Lettuce lettuce} \
                           {Tomato tomato} \
                           {Pickle pickle} \
                           {Sprouts sprouts} \
                       }
        
        ok -widget submit -label Submit
    }

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
