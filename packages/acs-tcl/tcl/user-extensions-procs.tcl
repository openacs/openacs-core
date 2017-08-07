
ad_library {

    Procs to manage extensions to user data.
    This calls the UserData service contract for allowing packages to be notified 
    of changes in user information.

    @author ben@openforce.net
    @creation-date 2002-01-22
    @cvs-id $Id$

}

namespace eval acs_user_extension {
    
    ad_proc -private dispatch {
        {-op:required}
        {-list_of_args:required}
        {-impl ""}
    } {
    
    	Dispatches (calls the service contract routines) the requested
	method so that the operation gets executed, and packages are
	notified of changes in user information.

    } {
        if {$impl eq ""} {
            set extensions [list_extensions]
        } else {
            set extensions [list $impl]
        }

        # Loop through the extensions
        foreach extension $extensions {
            set r [acs_sc::invoke -contract UserData -operation $op -call_args $list_of_args -impl $extension]
        }
    }

    ad_proc -public list_extensions {} {
        List the extensions (User Data contract)
    } {
        return [db_list select_extensions {}]
    }

    ad_proc -public user_new {
        {-user_id:required}
    } {
        Notifies packages when a new user is added to the system.

	@see dispatch
    } {
        dispatch -op UserNew -list_of_args [list $user_id]
    }

    ad_proc -public user_approve {
        {-user_id:required}
    } {
        Notifies packages when a user is approved.
	
	@see dispatch
    } {
        dispatch -op UserApprove -list_of_args [list $user_id]
    }

    ad_proc -public user_deapprove {
        {-user_id:required}
    } {
        Notifies packages when a user is deapproved.
	
	@see dispatch
    } {
        dispatch -op UserDeapprove -list_of_args [list $user_id]
    }

    ad_proc -public user_modify {
        {-user_id:required}
    } {
        Notifies packages when a user is modified. 
	
	@see dispatch
    } {
        dispatch -op UserModify -list_of_args [list $user_id]
    }

    ad_proc -public user_delete {
        {-user_id:required}
    } {
        Notifies packages when a user is deleted.

	@see dispatch
    } {
        dispatch -op UserDelete -list_of_args [list $user_id]
    }

}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
