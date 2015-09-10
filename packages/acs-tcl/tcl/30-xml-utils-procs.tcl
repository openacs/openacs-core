# This is a set of utilities for dealing with XML in a nice way,
# using tDOM. 
#
# It would be nice if this could be used without the ACS, so we're not
# using ad_proc constructs for this at this point.

##
## The proc that checks that XML support is complete
##
proc xml_support_ok {varname} {
    upvar $varname xml_status_msg
    
    set ok_p 1

    if {[llength [info commands tdom]] < 1} {
	set xml_status_msg "tDOM is not installed! You must have tDOM installed, or nothing will work."
	set ok_p 0
    } 

    return $ok_p
}

# Parse a document and return a doc_id
proc xml_parse args {
#   ns_log notice "xml_parse $args"
    if {[lindex $args 0] eq "-persist"} {
	return [dom parse -simple [lindex $args 1]]
    } else {
	dom parse -simple [lindex $args 0] doc
	return $doc
    }
}

# Free the doc
proc xml_doc_free {doc_id} {
#   ns_log notice "xml_doc_free $doc_id"
    $doc_id delete
}

# Get first node
proc xml_doc_get_first_node {doc_id} {
#   ns_log notice "xml_doc_get_first_node $doc_id --> [[$doc_id documentElement] nodeName]"
    return [$doc_id documentElement]
}

# Get children nodes
proc xml_node_get_children {parent_node} {
    return [$parent_node child all]
}

# Find nodes of a parent that have a given name
proc xml_node_get_children_by_name {parent_node name} {
#   set msg "xml_node_get_children_by_name [$parent_node nodeName] $name --> "
#   foreach child [$parent_node child all $name] {
#	append msg "[$child nodeName] "
#   }
#   ns_log notice $msg
    return [$parent_node child all $name]
}

proc xml_node_get_first_child {parent_node } {
#   ns_log notice "xml_node_get_first_child [$parent_node nodeName] --> [[$parent_node child 1] nodeName]"
    return [$parent_node child 1]
}

proc xml_node_get_first_child_by_name {parent_node name} {
#   ns_log notice "xml_node_get_first_child_by_name [$parent_node nodeName] $name --> [[$parent_node child 1 $name] nodeName]"
    return [$parent_node child 1 $name]
}

# Get Node Name
proc xml_node_get_name {node_id} {
    return [$node_id nodeName]
}

# Get Node Attribute
proc xml_node_get_attribute {node_id attribute_name {default ""}} {
#   ns_log notice "xml_node_get_attribute [$node_id nodeName] $attribute_name --> [$node_id getAttribute $attribute_name $default]"
    return [$node_id getAttribute $attribute_name $default]
}

# Set Node Attribute
proc xml_node_set_attribute {node_id attribute_name value} {
  $node_id setAttribute $attribute_name $value
}

# Get Content
proc xml_node_get_content {node_id} {
#   ns_log notice "xml_node_get_content [$node_id nodeName] --> [$node_id text]"
    return [$node_id text]
}

# Get Node Type
proc xml_node_get_type {node_id} {
    return [$node_id nodeType]
}

# Render the doc
proc xml_doc_render {doc_id {indent_p f}} {
    if { [string is true $indent_p] } {
        return [$doc_id asXML]
    } else {
        return [$doc_id asXML -indent none]
    }
}

proc xml_node_get_children_by_select {parent_node xpath} {
    return [$parent_node selectNodes $xpath]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
