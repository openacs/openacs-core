# /packages/acs-tcl/tcl/tdom-procs.tcl

ad_library {

    Procedures to make parsing XML using
    TDOM a little easier

    @author avni@ucla.edu (AK)
    @creation-date 2004/10/19
    @cvs-id $Id$

    @tdom::get_node_pointer
    @tdom::get_parent_node_pointer
    @tdom::get_tag_value
    @tdom::get_attribute_value
    @tdom::get_node_xml
    
}

namespace eval tdom {}

ad_proc -public tdom::get_node_pointer {
    parent_node_pointer
    args
} {
    Returns a pointer to the args given
    If the pointer doesn't exist or the value is null, return null

    <pre>
    Example -----------------------------------------------------
    XML:     &lt;experiment&gt;
                 &lt;experimenter&gt;
                     &lt;first-name&gt;Annabelle Lee&lt;/first-name&gt;
                     &lt;last-name&gt;Poe&lt;/last-name&gt;
                 &lt;/experimenter&gt;
             &lt;/experiment&gt;
    Params:  parent_node_pointer=$pointer_to_experiment
             args=experimenter experimenter_two
    Returns: Pointer to experimenter node
    End Example -------------------------------------------------
    </pre>
} {
    # Do a loop for the args. The first non null result is returned
    set node_pointer ""
    foreach node_name $args {
	catch {set node_pointer [$parent_node_pointer getElementsByTagName "$node_name"]}
	if {![empty_string_p [string trim $node_pointer]]} {
	    return $node_pointer
	}
    }

    return $node_pointer
}

ad_proc -public tdom::get_parent_node_pointer {
    child_node_pointer
} {
    Returns a pointer to the parent node
} {
    set parent_node_pointer ""
    catch {set parent_node_pointer [$child_node_pointer parentNode]}

    return [string trim $parent_node_pointer]
}

ad_proc -public tdom::get_tag_value {
    node_pointer
    args
} {
    Returns the tag value of the tag_name passed in
    If tag doesn't exist or the value is null, returns null

    <pre>
    Example -----------------------------------------------------
    XML:     &lt;experiment-id&gt;1222&lt;/experiment-id&gt;
    Params:  node_pointer=$document
             args=experiment-id EXPERIMENT-ID
    Returns: 1222
    End Example -------------------------------------------------
    </pre>
} {
    # Do a loop for the args. The first non null result is returned
    set tag_value ""

    foreach tag_name $args {
	catch {set tag_value [[$node_pointer getElementsByTagName "$tag_name"] text]} errormsg
	if {![empty_string_p [string trim $tag_value]]} {
	    return $tag_value
	}
    }

    return $tag_value
}

ad_proc -public tdom::get_attribute_value {
    node_pointer
    attribute_name
    {default_value ""}
} {
    Returns the value of the attribute specified
} {
    set attribute_value ""
    catch {set attribute_value [$node_pointer getAttribute $attribute_name $default_value]}

    return [string trim $attribute_value]
}

ad_proc -public tdom::get_node_xml {
    node_pointer
} {
    Returns xml of the data pointed to by the node pointer
    If tag doesn't exist or the value is null, returns null
} {
    set node_xml ""
    catch {set node_xml [$node_pointer asXML]}

    return [string trim $node_xml]
}

