
# 50-xml-utils-procs.tcl
# (ben for OpenACS)
#
# This is a set of utilities for dealing with XML in a nice way,
# using ns_xml. Since ns_xml only offers a very basic interface to
# accessing XML documents, we add additional functions. As ns_xml gets
# better, it's perfectly conceivable that these functions will be
# implemented more efficiently by calling ns_xml more directly.
#
# It would be nice if this could be used without the ACS, so we're not
# using ad_proc constructs for this at this point.


##
## The proc that checks that XML support is complete
##
proc xml_support_ok {varname} {
    upvar $varname xml_status_msg
    
    set ok_p 1

    if {[llength [info commands ns_xml]] < 1} {
	set xml_status_msg "ns_xml is not installed! You must have ns_xml installed, or nothing will work."
	set ok_p 0
    } else {
	if {![_nsxml_comments_ok_p]} {
	    append xml_status_msg "Your ns_xml doesn't support XML comments correctly. This issue is currently handled smoothly by some internal work-arounds, but you might want to upgrade ns_xml to the latest version.<p>"
	    set ok_p 0
	}

	if {![_nsxml_root_node_ok_p]} {
	    append xml_status_msg "Your ns_xml doesn't correctly return the root XML node. This issue is currently handled smoothly by some internal work-arounds, but you might want to upgrade ns_xml to the latest version.<p>"
	    set ok_p 0
	}

        if {![_nsxml_version_2_p]} {
            append xml_status_msg "Your ns_xml doesn't support the most recent command syntax.  This issue is currently handled smoothly by some internal work-arounds, but you might want to upgrade ns_xml to the latest version.<p>"
        }
    }

    return $ok_p
}


# Clean stuff up if we have to
# I'm unhappy about this, but there seem to be bugs in the XML parser!! (ben)
proc xml_prepare_data {xml_data} {
    if {[_nsxml_comments_ok_p]} {
	return $xml_data
    } else {
	# remove comments
	regsub -all {<!--[^>]*-->} $xml_data "" new_xml_data
	return $new_xml_data
    }
}

#
# We need some very simple features here:
#    - parse
#    - get root node
#    - get first real node
#    - get children node
#    - get children node with a particular name
#    - get attribute
#    - get value
#

# Parse a document and return a doc_id
proc xml_parse args {
    if {[lindex $args 0] == "-persist"} {
	return [ns_xml parse -persist [lindex $args 1]]
    } else {
	return [ns_xml parse [lindex $args 0]]
    }
}

# Free the doc
proc xml_doc_free {doc_id} {
    ns_xml doc free $doc_id
}

# Get root node
proc xml_doc_get_root_node {doc_id} {
    return [ns_xml doc root $doc_id]
}

# Get first node
proc xml_doc_get_first_node {doc_id} {

    # get the root from ns_xml
    set root_node [ns_xml doc root $doc_id]

    if {[_nsxml_root_node_ok_p]} {
	set first_node [lindex [ns_xml node children $root_node] 0]
    } else {
	set first_node $root_node
    }

    return $first_node
}

# Get first node with a given name
proc xml_doc_get_first_node_by_name {doc_id name} {

    # get the root from ns_xml
    set root_node [ns_xml doc root $doc_id]

    if {[_nsxml_root_node_ok_p]} {
	set first_node [lindex [xml_node_get_children_by_name $root_node $name] 0]
    } else {
	# You'd better hope this is the right node, baby,
	# because ns_xml is broken in this case (ben).
	set first_node $root_node
    }

    return $first_node
}

# Get children nodes
proc xml_node_get_children {parent_node} {
    return [ns_xml node children $parent_node]
}

# Find nodes of a parent that have a given name
proc xml_node_get_children_by_name {parent_node name} {
    set children [xml_node_get_children $parent_node]

    set list_of_appropriate_children [list]

    foreach child $children {
	if {[ns_xml node name $child] == $name} {
	    lappend list_of_appropriate_children $child
	}
    }

    return $list_of_appropriate_children
}

proc xml_node_get_first_child_by_name {parent_node name} {
    set children [xml_node_get_children_by_name $parent_node $name]
    return [lindex $children 0]
}

# Get Node Name
proc xml_node_get_name {node_id} {
    return [ns_xml node name $node_id]
}

# Get Node Attribute
proc xml_node_get_attribute {node_id attribute_name} {
    if { [_nsxml_version_2_p] } {
        return [ns_xml node get attr $node_id $attribute_name]
    } else {
        return [ns_xml node getattr $node_id $attribute_name]
    }
}

# Get Content
proc xml_node_get_content {node_id} {
    if { [_nsxml_version_2_p] } {
        return [ns_xml node get content $node_id]
    } else {
        return [ns_xml node getcontent $node_id]
    }
}

##
## Broken ns_xml
##


# This procedure will test the root node function of ns_xml
# Since this test will use a sample XML parse to figure out
# whether or not things work, we want to cache the result so
# that an additional XML parse isn't performed every time (ben).
proc _nsxml_root_node_ok_p {} {

    # Check cache
    if {[nsv_exists NSXML root_node_ok_p]} {
	return [nsv_get NSXML root_node_ok_p]
    }

    # try to parse a sample XML document with a comment
    set sample_xml "<?xml version=\"1.0\"?><root>text</root>"
    set doc_id [ns_xml parse $sample_xml]
    set root [ns_xml doc root $doc_id]
    set children [ns_xml node children $root]

    if {[catch {set name [ns_xml node name [lindex $children 0]]} errmsg]} {
	set result 0
    } else {
	# If the root node is okay, then we're set
	if { $name == "root" } {
	    set result 1
	} else {
	    set result 0
	}
    }

    # store in cache and return
    nsv_set NSXML root_node_ok_p $result
    return $result
}

# Check if comments are okay
proc _nsxml_comments_ok_p {} {

    # Check cache
    if {[nsv_exists NSXML comments_ok_p]} {
	return [nsv_get NSXML comments_ok_p]
    }

    # try to parse a sample XML document with a comment
    set sample_xml "<?xml version=\"1.0\"?><!-- Random Test Comment --><root>text</root>"
    set doc_id [ns_xml parse $sample_xml]
    set root [ns_xml doc root $doc_id]
    set children [ns_xml node children $root]

    if {[catch {set name [ns_xml node name [lindex $children 0]]} errmsg]} {
	set result 0
    } else {
	# If we're talking about a comment node, we're all set
	if { $name == "comment" } {
	    set result 1
	} else {
	    set result 0
	}
    }

    # store in cache and return
    nsv_set NSXML comments_ok_p $result
    return $result
}

# Check if comments are okay
proc _nsxml_version_2_p {} {

    # Check cache
    if {[nsv_exists NSXML version_2_p]} {
	return [nsv_get NSXML version_2_p]
    }

    # try to parse a sample XML document with content
    set sample_xml "<?xml version=\"1.0\"?><root>text</root>"
    set doc_id [ns_xml parse $sample_xml]

    if { [catch {ns_xml node get attr $doc_id root} errmsg] &&
         [string equal $errmsg "unknown command"] } {
        set result 0
    } else {
        set result 1
    }

    # store in cache and return
    nsv_set NSXML version_2_p $result
    return $result
}

