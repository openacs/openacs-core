ad_library {

    Procs to support a simple callback mechanism that allows other
    applications to register callbacks triggered when objects, like
    groups, in the subsite application are created.

    @author mbryzek@arsdigita.com
    @creation-date Wed Feb 21 17:10:24 2001
    @cvs-id $Id$

}

ad_proc -deprecated subsite_callback args {
    Executes any registered callbacks for this object.
    <p>
    <b>Example:</b>
    <pre>
    # Execute any callbacks registered for this object type or one of
    # its parent object types
    subsite_callback -object_type $object_type $object_id
    </pre>


    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

    @param object_type The object's type. We look this up in the db if
    not specified

    DEPRECATED: does not comply with OpenACS naming convention

    @see subsite::callback
} {
    return [subsite::callback {*}$args]
}

ad_proc -public subsite::callback {
    { -object_type "" }
    event_type
    object_id
} {
    Executes any registered callbacks for this object.
    <p>
    <b>Example:</b>
    <pre>
    # Execute any callbacks registered for this object type or one of
    # its parent object types
    subsite::callback -object_type $object_type $object_id
    </pre>


    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

    @param object_type The object's type. We look this up in the db if
    not specified
} {
    set node_id [ad_conn node_id]
    set package_id [ad_conn package_id]

    # Check to see if we have any callbacks registered for this object
    # type or one of its parent object types. Put the callbacks into
    # a list as each callback may itself require a database
    # handle. Note that we need the distinct in case two callbacks are
    # registered for an object and its parent object type.
    db_foreach get_callbacks {} {
        switch -- $type {
            tcl {
                # Execute the Tcl procedure
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
    Callback for changing the value of an instance parameter.

    @param package_id The package_id of the package the parameter was changed for.
    @param parameter The parameter value.
    @param value The new value.

    @see package::set_value
} -

ad_proc -public -callback subsite::global_parameter_changed {
   -package_key:required
   -parameter:required
   -value:required
} {
    Callback for changing the value of a global parameter.

    @param package_key The package_key of the package the parameter was changed for.
    @param parameter The parameter value.
    @param value The new value.

    @see package::set_value
} -

ad_proc -public -callback subsite::url {
    -package_id:required
    -object_id:required
    {-type ""}
} {
    Callback for creating a URL for an object_id. This is usually called in /o.vuh, but
    you could think of scenarios where using this hook makes sense as well.

    The type lets you define what kind of URL you are looking for (e.g. admin/edit/display)
} -

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
