ad_page_contract {
  @cvs-id $Id$
} {
  component_id:token,notnull
  package_key:nohtml
} -properties {
  title:onevalue
  context_bar:onevalue
  component_desc:onevalue
  component_file:onevalue
  component_body:onevalue
}

set title "Component $component_id ($package_key)"
set context [list $title]

set component_bodys {}
foreach component [nsv_get aa_test components] {
    if {$component_id eq [lindex $component 0] && $package_key eq [lindex $component 1]} {
        lassign $component . . component_desc component_file component_body
    }
}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
