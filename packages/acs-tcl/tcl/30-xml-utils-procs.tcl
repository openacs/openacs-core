
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

# Clean stuff up if we have to
# I'm unhappy about this, but there seem to be bugs in the XML parser!! (ben)
proc xml_prepare_data {xml_data} {
    # remove comments
    regsub -all {<!--[^>]*-->} $xml_data "" new_xml_data
    return $new_xml_data
}

# Find nodes of a parent that have a given name
proc xml_find_child_nodes {parent_node name} {
    set children [ns_xml node children $parent_node]

    set list_of_appropriate_children [list]

    foreach child $children {
	if {[ns_xml node name $child] == $name} {
	    lappend list_of_appropriate_children $child
	}
    }

    return $list_of_appropriate_children
}

