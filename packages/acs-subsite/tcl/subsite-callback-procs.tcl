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
