# /packages/acs-subsite/tcl/group-callback-procs.tcl

ad_library {

    Procs to support a simple callback mechanism that allows other
    applications to register callbacks triggered when objects, like
    groups, in the subsite application are created.

    @author mbryzek@arsdigita.com
    @creation-date Wed Feb 21 17:10:24 2001
    @cvs-id $Id$

}

ad_proc -public subsite_callback {
    { -object_type "" }
    event_type
    object_id
} {
    Executes any registered callbacks for this object. 
    <p>
    <b>Example:</b>
    <pre>
    # Execute any callbacks registered for this object type or one of
    # it's parent object types
    subsite_callback -object_type $object_type $object_id
    </pre>
    

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

    @param object_type The object's type. We look this up in the db if
    not specified
} {

    if { [empty_string_p $object_type] } {
	db_1row select_object_type {
	    select object_type
	      from acs_objects 
	     where object_id = :object_id
	}
    }

    # Check to see if we have any callbacks registered for this object
    # type or one of it's parent object types. Put the callbacks into
    # a list as each callback may itself require a database
    # handle. Note that we need the distinct in case two callbacks are
    # registered for an object and it's parent object type.

    set callback_list [db_list_of_lists select_callbacks {
	select distinct callback, callback_type
	  from subsite_callbacks
	 where object_type in (select t.object_type
	                        from acs_object_types t
	                     connect by prior t.supertype = t.object_type
	                       start with t.object_type = :object_type)
	   and event_type = :event_type
    }]

    set node_id [ad_conn node_id]
    set package_id [ad_conn package_id]

    foreach row $callback_list {
	set callback [lindex $row 0]
	set type [lindex $row 1]

	switch -- $type {
	    tcl { 
		# Execute the tcl procedure
		$callback -object_id $object_id -node_id $node_id -package_id $package_id
	    }
	    default { error "Callbacks of type $type not supported" }
	}
    }
}

ad_proc -public -callback subsite::parameter_changed {
   -package_id:required
   -parameter:required
   -value:required
} {
    Callback for changing the value of a parameter.

    @param package_id The package_id of the package the parameter was changed for.
    @param parameter The parameter value.
    @param value The new value.

    @see package::set_value
} -

ad_proc -public -callback subsite::parameter_changed -impl subsite {
   -package_id:required
   -parameter:required
   -value:required
} {
    Implementation of subsite::parameter_changed for subsite itself. This proc will simply set the parameter

    @author Nima Mazloumi (nima.mazloumi@gmx.de)
    @creation-date 2005-08-17

    @param package_id the package_id of the package the parameter was changed for
    @param parameter  the parameter name
    @param value      the new value

    @see package::set_value
} {
    ns_log Debug "subsite::parameter_changed -impl subsite changing $parameter to $value"

    parameter::set_value \
	-package_id $package_id \
	-parameter $parameter \
	-value $value
}

ad_proc -public -callback subsite::url {
    -package_id:required
    -object_id:required
    {-type ""}
} {
    Callback for creating a URL for an object_id. THis is usually called in /o.vuh, but
    you could think of scenarios where using this hook makes sense as well.

    The type let's you define what kind of URL you are looking for (e.g. admin/edit/display)
} -
