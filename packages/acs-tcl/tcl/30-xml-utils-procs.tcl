ad_library {
    This set of utilities was created back in the days when ns_xml was
    the preferred AOLserver XML api. It came in handy to have such an
    abstraction when the project switched to the tDOM library, so it
    stayed around, even if now is composed mostly by trivial
    one-liners.

    It is not clear whether it would make more sense to use tDOM
    directly and avoid this extra layer altogether in the future.
    Notable places where this library is in use are the APM and
    xml-rpc package (which also provides some automated tests for it).
}

ad_proc -public xml_support_ok {varname} {
    The proc that checks that XML support is complete

    @arg varname a variable name in the caller namespace where the
         eventual error message will be reported

    @return boolean
} {
    upvar $varname xml_status_msg

    set ok_p 1

    if {[info commands ::tdom] eq ""} {
        set xml_status_msg "tDOM is not installed! You must have tDOM installed, or nothing will work."
        set ok_p 0
    }

    return $ok_p
}

ad_proc -public xml_parse {
    -persist:boolean
    xml
} {
    Parse a document and return a doc_id

    @param persist decides whether returned document object will be
    deleted when the connection is closed or will be kept in server
    memory

    @arg xml XML document

    @return parsed document object handle
} {
    if {$persist_p} {
        return [dom parse -simple $xml]
    } else {
        dom parse -simple $xml doc
        return $doc
    }
}

ad_proc -public xml_doc_free {doc_id} {
    Free the doc
} {
#   ns_log notice "xml_doc_free $doc_id"
    $doc_id delete
}

ad_proc xml_doc_get_first_node {doc_id} {
    Get first node
} {
#   ns_log notice "xml_doc_get_first_node $doc_id --> [[$doc_id documentElement] nodeName]"
    return [$doc_id documentElement]
}

ad_proc -public xml_node_get_children {parent_node} {
    Get children nodes
} {
    return [$parent_node child all]
}

ad_proc -public xml_node_get_children_by_name {
    parent_node
    name
} {
    Find nodes of a parent that have a given name
} {
#   set msg "xml_node_get_children_by_name [$parent_node nodeName] $name --> "
#   foreach child [$parent_node child all $name] {
#	append msg "[$child nodeName] "
#   }
#   ns_log notice $msg
    return [$parent_node child all $name]
}

ad_proc -public xml_node_get_first_child {parent_node} {
    Returns the first child node
} {
#   ns_log notice "xml_node_get_first_child [$parent_node nodeName] --> [[$parent_node child 1] nodeName]"
    return [$parent_node child 1]
}

ad_proc -public xml_node_get_first_child_by_name {
    parent_node
    name
} {
    Returns the first child node that has a given name
} {
#   ns_log notice "xml_node_get_first_child_by_name [$parent_node nodeName] $name --> [[$parent_node child 1 $name] nodeName]"
    return [$parent_node child 1 $name]
}

ad_proc -public xml_node_get_name {node_id} {
    Get Node Name
} {
    return [$node_id nodeName]
}

ad_proc -public xml_node_get_attribute {
    node_id
    attribute_name
    {default ""}
} {
    Get Node Attribute
} {
#   ns_log notice "xml_node_get_attribute [$node_id nodeName] $attribute_name --> [$node_id getAttribute $attribute_name $default]"
    return [$node_id getAttribute $attribute_name $default]
}

ad_proc -public xml_node_set_attribute {
    node_id
    attribute_name
    value
} {
    Set Node Attribute
} {
    $node_id setAttribute $attribute_name $value
}

ad_proc -public xml_node_get_content {node_id} {
    Get Content
} {
#   ns_log notice "xml_node_get_content [$node_id nodeName] --> [$node_id text]"
    return [$node_id text]
}

ad_proc -public xml_node_get_type {node_id} {
    Get Node Type
} {
    return [$node_id nodeType]
}

ad_proc -public xml_doc_render {
    doc_id
    {indent_p f}
} {
    Render the doc

    @arg indent_p decides whether results should be indented or not

    @return XML
} {
    if { [string is true $indent_p] } {
        return [$doc_id asXML]
    } else {
        return [$doc_id asXML -indent none]
    }
}

ad_proc -public xml_node_get_children_by_select {
    parent_node
    xpath
} {
    Get children of given node that match supplied XPATH query
} {
    return [$parent_node selectNodes $xpath]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
