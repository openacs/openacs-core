# /packages/acs-tcl/tcl/tdom-procs.tcl

ad_library {

    Procedures to make parsing XML using
    TDOM a little easier


    @author avni@ucla.edu (AK)
    @creation-date 2004/10/19
    @cvs-id $Id$

    @tdom::get_node_object
    @tdom::get_parent_node_object
    @tdom::get_tag_value
    @tdom::get_attribute_value
    @tdom::get_node_xml
    
}

namespace eval tdom {}

ad_proc -public tdom::get_node_object {
    parent_node_object
    args
} {
    Returns a tDOM object to the args given
    If the tDOM object doesn't exist or the value is null, return null

    <pre>
    Example -----------------------------------------------------
    XML:     &lt;experiment&gt;
                 &lt;experimenter&gt;
                     &lt;first-name&gt;Annabelle Lee&lt;/first-name&gt;
                     &lt;last-name&gt;Poe&lt;/last-name&gt;
                 &lt;/experimenter&gt;
             &lt;/experiment&gt;
    Params:  parent_node_object=$tdom_experiment_object
             args=experimenter experimenter_two
    Returns: TDOM object for experimenter node
    End Example -------------------------------------------------
    </pre>
} {
    # Do a loop for the args. The first non null result is returned
    set node_object ""
    foreach node_name $args {
	catch {set node_object [$parent_node_object getElementsByTagName "$node_name"]}
	if {$node_object ne "" } {
	    return $node_object
	}
    }

    return $node_object
}

ad_proc -public tdom::get_parent_node_object {
    child_node_object
} {
    Returns a tDOM object for the parent node of the child node object passed in
} {
    set parent_node_object ""
    catch {set parent_node_object [$child_node_object parentNode]}

    return $parent_node_object
}

ad_proc -public tdom::get_tag_value {
    node_object
    args
} {
    Returns the tag value of the tag_name passed in
    If tag doesn't exist or the value is null, returns null

    <pre>
    Example -----------------------------------------------------
    XML:     &lt;experiment-id&gt;1222&lt;/experiment-id&gt;
    Params:  node_object=$document
             args=experiment-id EXPERIMENT-ID
    Returns: 1222
    End Example -------------------------------------------------
    </pre>
} {
    # Do a loop for the args. The first non null result is returned
    set tag_value ""

    foreach tag_name $args {
	catch {set tag_value [[$node_object getElementsByTagName "$tag_name"] text]} errormsg
	if {[string trim $tag_value] ne "" } {
	    return $tag_value
	}
    }

    return $tag_value
}

ad_proc -public tdom::get_attribute_value {
    node_object
    attribute_name
    {default_value ""}
} {
    Returns the value of the attribute specified
} {
    set attribute_value ""
    catch {set attribute_value [$node_object getAttribute $attribute_name $default_value]}

    return [string trim $attribute_value]
}

ad_proc -public tdom::get_node_xml {
    node_object
} {
    Returns xml of the data pointed to by the node object
    If tag doesn't exist or the value is null, returns null
} {
    set node_xml ""
    catch {set node_xml [$node_object asXML]}

    return [string trim $node_xml]
}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
