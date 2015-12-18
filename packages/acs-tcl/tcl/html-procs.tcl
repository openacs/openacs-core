ad_library {
    Procs to read and manipulate HTML structures
    
    @author Antonio Pisano
    @creation-date 2015-09-26
}

namespace eval util {}

ad_proc -public util::get_node_attributes {
    -node:required
} {
    Extract attributes names and values from a tDOM node
    
    @param node tDOM node
    
    @return List in array get form of attribute names and values for node
} {
    foreach attribute [$node attributes] {
        lappend attributes $attribute [$node getAttribute $attribute]
    }
    return $attributes
}

namespace eval util {}
namespace eval util::html {}

ad_proc -public util::html::get_forms {
    -html:required
} {
    Extract every form's specification from HTML supplied
    
    @param html HTML text
    
    @return Form specification as a nested list of lists in array get form
} {
    # Parse document
    dom parse -html -keepEmpties $html doc
    set root [$doc documentElement]

    set forms [list]
    # Get every form...
    foreach f [$root selectNodes {//form}] {
        set form [list "attributes" [util::get_node_attributes -node $f]]
        set fields [list]
        # ...every input tag
        foreach input [$f selectNodes {//input}] {
            lappend fields [list tag "input" attributes [util::get_node_attributes -node $input]]
        }
        # ...every select tag with its options
        foreach select [$f selectNodes {//select}] {
            set field [list tag "select" attributes [util::get_node_attributes -node $select]]
            set options [list]
            foreach option [$f selectNodes {option}] {
                lappend options [list attributes [$option attributes] value [$option nodeValue]]
            }
            lappend field options $options
            lappend fields $field
        }
        # ...and every textarea
        foreach textarea [$f selectNodes {//textarea}] {
            set field [list tag "textarea" attributes [util::get_node_attributes -node $textarea]]
            lappend field value [$option nodeValue]
            lappend fields $field
        }
        lappend form "fields" $fields
        lappend forms $form
    }
    
    return $forms
}

ad_proc -public util::html::get_form {
    -forms:required
    {-id ""}
} {
    Extract form with the specified id from a structure as that 
    coming from <code>util::html::get_forms</code> proc.
    
    @param forms   Form structure
    @param id      HTML id of the form to be read. If structure contains only
                   one form, this parameter can be omitted, otherwise
                   the proc will throw an error.
    
    @return form structure
} {    
    if {[llength $forms] == 1} {
        return [lindex $forms 0]
    }   
    
    if {$id ne ""} {
        # We have more than one, check for supplied id
        foreach form $forms {
            array set fo $form
            array set a $fo(attributes)
            if {$a(id) eq $id} {
                return $form
            }
        }
    }
    
    error "Form was not found in supplied HTML"
}

ad_proc -public util::html::get_form_vars {
    -form:required
} {
    Read vars from a form structure as that coming out from
    <code>util::html::get_form</code>.
    
    @param form Form structure
    
    @return var specification in a form suitable for the <code>vars</code>
            argument of proc <code>export_vars</code>.
} {
    array set fo $form
    
    # Extract value from every field
    foreach field $fo(fields) {
        array unset fld
        array set fld $field
        array unset a
        array set a $fld(attributes)
        # no name, no variable
        if {![info exists a(name)] || $a(name) eq ""} continue
        set name $a(name) ; set tag $fld(tag)
        switch $tag {
            "input" {
                if {[info exists a(value)]} {
                    lappend v($name) $a(value)
                }
            }
            "textarea" {
                if {[info exists fld(value)]} {
                    lappend v($name) $fld(value)
                }
            }
            "select" {
                foreach option $fld(options) {
                    array set o $option
                    array set a $o(attributes)
                    if {[info exists a(selected)]} {
                        lappend v($name) $o(value)
                    }
                }
            }
        }
    }
    
    # Now vars must be translated in export_vars form
    set vars [list]
    foreach {name value} [array get v] {
      # Multiple values must be specified 
      # with the :multiple modifier
      if {[llength $value] > 1} {
          set name ${name}:multiple
      # Single values must be extracted 
      # from the list
      } else {
          set value [lindex $value 0]
      }
      # Formfield's name can contain colons,
      # I need to escape them.
      regsub -all {:} $name {\:} name
      lappend vars [list $name $value]
    }
    
    return $vars
}



